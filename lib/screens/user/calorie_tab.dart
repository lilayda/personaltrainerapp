
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'food_list_page.dart';
import 'today_meals_page.dart';
import '../admin/add_food_screen.dart';

class CalorieTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final int age;
  final VoidCallback onRefresh;

  const CalorieTab({
    super.key,
    required this.userData,
    required this.age,
    required this.onRefresh,
  });

  @override
  State<CalorieTab> createState() => _CalorieTabState();
}

class _CalorieTabState extends State<CalorieTab> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _targetCaloriesController = TextEditingController();

  int caloriesToday = 0;
  late int goal;
  bool _isAdminUser = false;

  @override
  void initState() {
    super.initState();
    _weightController.text = widget.userData['weight'].toString();
    _heightController.text = widget.userData['height'].toString();
    _targetWeightController.text = widget.userData['targetWeight'].toString();
    _targetCaloriesController.text = widget.userData['targetCalories'].toString();
    goal = widget.userData['targetCalories'] ?? 0;
    _checkAndResetCalories();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    setState(() {
      _isAdminUser = doc.data()?['role'] == 'admin';
    });
  }

  Future<void> _checkAndResetCalories() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userData['uid']);
    final snapshot = await userRef.get();
    final data = snapshot.data();

    Timestamp? lastReset = data?['lastCalorieReset'];
    DateTime now = DateTime.now().toUtc();
    DateTime today = DateTime.utc(now.year, now.month, now.day);

    if (lastReset == null || lastReset.toDate().isBefore(today)) {
      await userRef.update({
        'caloriesToday': 0,
        'lastCalorieReset': Timestamp.fromDate(today),
      });
      setState(() {
        caloriesToday = 0;
      });

      final startOfDay = today;
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final mealsSnapshot = await FirebaseFirestore.instance
          .collection('today_meals')
          .where('userId', isEqualTo: widget.userData['uid'])
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      for (var doc in mealsSnapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      setState(() {
        caloriesToday = data?['caloriesToday'] ?? 0;
      });
    }
  }

  Future<void> _updateUserInfo() async {
    if (!_formKey.currentState!.validate()) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userData['uid']);

    int newWeight = int.parse(_weightController.text);
    int newHeight = int.parse(_heightController.text);
    int newTargetWeight = int.parse(_targetWeightController.text);
    int newTargetCalories = int.parse(_targetCaloriesController.text);

    await userRef.update({
      'weight': newWeight,
      'height': newHeight,
      'targetWeight': newTargetWeight,
      'targetCalories': newTargetCalories,
      'weightHistory': FieldValue.arrayUnion([
        {'date': Timestamp.now(), 'weight': newWeight}
      ])
    });

    setState(() {
      goal = newTargetCalories;
    });

    widget.onRefresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Bilgiler güncellendi")),
    );
  }

  Future<void> _queryCalories() async {
    final input = _queryController.text.trim().toLowerCase();
    if (input.isEmpty) return;

    final foods = await FirebaseFirestore.instance.collection('foods').get();
    QueryDocumentSnapshot<Map<String, dynamic>>? found;
    try {
      found = foods.docs.firstWhere(
            (doc) => (doc.data()['name'] as String).toLowerCase() == input,
      );
    } catch (_) {}

    if (found != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(found!['name']),
          content: Text("${found!['kalori']} kcal"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tamam"),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Yemek Bulunamadı"),
          content: Text('"' + _queryController.text + '" adlı yemek bulunamadı.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFormField(String label, TextEditingController controller, String unit, int min, int max) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label giriniz';
          final v = int.tryParse(value);
          if (v == null) return 'Geçerli bir sayı giriniz';
          if (v < min || v > max) return '$label $min - $max $unit aralığında olmalı';
          return null;
        },
      ),
    );
  }

  Widget _buildWeightChart(List<FlSpot> spots, double targetWeight, double height) {
    double currentWeight = spots.isNotEmpty ? spots.last.y : 0;
    double initialWeight = spots.isNotEmpty ? spots.first.y : 0;
    double givenWeight = (initialWeight - currentWeight).clamp(0, double.infinity);
    double bmi = height != 0 ? currentWeight / ((height / 100) * (height / 100)) : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 200,
          child: spots.length < 2
              ? const Center(child: Text("Grafik için en az 2 veri noktası gerekli"))
              : LineChart(
            LineChartData(
              minY: (spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 2).clamp(0, 100),
              maxY: spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2,
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Text(DateFormat('MM/dd').format(date), style: const TextStyle(fontSize: 10));
                    },
                    interval: 3 * 24 * 60 * 60 * 1000,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 2,
                  dotData: FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: spots.map((e) => FlSpot(e.x, targetWeight)).toList(),
                  isCurved: false,
                  color: Colors.green,
                  barWidth: 1,
                  isStrokeCapRound: true,
                  dashArray: [5, 5],
                  dotData: FlDotData(show: false),
                ),
              ],
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: true),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _infoBox("Mevcut Kilo", "${currentWeight.toStringAsFixed(1)} kg"),
            _infoBox("Hedef Kilo", "${targetWeight.toStringAsFixed(1)} kg"),
            _infoBox("Verilen Kilo", "${givenWeight.toStringAsFixed(1)} kg"),
            _infoBox("VKİ", bmi.toStringAsFixed(1)),
          ],
        ),
      ],
    );
  }

  Widget _infoBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> weightHistory = widget.userData['weightHistory'] ?? [];
    List<FlSpot> spots = weightHistory.map((entry) {
      final date = (entry['date'] as Timestamp).toDate();
      final xValue = date.millisecondsSinceEpoch.toDouble();
      final yValue = (entry['weight'] as num).toDouble();
      return FlSpot(xValue, yValue);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Alınan Kalori: $caloriesToday / $goal", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: goal != 0 ? caloriesToday / goal : 0,
              backgroundColor: Colors.grey[300],
              color: caloriesToday > goal ? Colors.red : Colors.green,
              minHeight: 12,
            ),
            const SizedBox(height: 20),
            _buildFormField("Güncel Kilo", _weightController, "kg", 20, 300),
            _buildFormField("Güncel Boy", _heightController, "cm", 50, 250),
            _buildFormField("Hedef Kilo", _targetWeightController, "kg", 20, 300),
            _buildFormField("Hedef Kalori", _targetCaloriesController, "kcal", 500, 6000),
            const SizedBox(height: 10),
            Text("Yaş: ${widget.age}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _updateUserInfo,
              icon: const Icon(Icons.save),
              label: const Text("Bilgileri Kaydet"),
            ),
            const SizedBox(height: 30),
            const Text("Kilo Geçmişi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildWeightChart(spots, widget.userData['targetWeight']?.toDouble() ?? 0, widget.userData['height']?.toDouble() ?? 170),
            const SizedBox(height: 30),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                hintText: "Yemek adıyla kalori sorgula",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _queryCalories,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            if (_isAdminUser)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddFoodScreen()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text("Yeni Yemek Ekle"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodListPage(userId: widget.userData['uid']),
                  ),
                ).then((_) => _checkAndResetCalories());
              },
              child: const Text("Yemek Ekle"),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TodayMealsPage(userId: widget.userData['uid']),
                  ),
                ).then((_) => _checkAndResetCalories());
              },
              child: const Text("Bugün Yedikleriniz"),
            ),
          ],
        ),
      ),
    );
  }
}
