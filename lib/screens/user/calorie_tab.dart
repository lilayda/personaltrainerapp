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
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _queryController = TextEditingController();

  late int calories;
  late int goal;

  @override
  void initState() {
    super.initState();
    _weightController.text = widget.userData['weight'].toString();
    _heightController.text = widget.userData['height'].toString();
    _targetWeightController.text = widget.userData['targetWeight'].toString();

    calories = widget.userData['caloriesToday'] ?? 0;
    goal = widget.userData['targetCalories'] ?? 0;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _updateUserInfo() async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userData['uid']);

    int newWeight = int.tryParse(_weightController.text) ?? 0;
    int newHeight = int.tryParse(_heightController.text) ?? 0;
    int newTargetWeight = int.tryParse(_targetWeightController.text) ?? 0;

    await userRef.update({
      'weight': newWeight,
      'height': newHeight,
      'targetWeight': newTargetWeight,
      'weightHistory': FieldValue.arrayUnion([
        {
          'date': Timestamp.now(),
          'weight': newWeight,
        }
      ])
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
          content: Text("“${_queryController.text}” adlı yemek bulunamadı."),
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

  Future<bool> _isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
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

    final double minY = spots.isNotEmpty
        ? (spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 5).clamp(0, double.infinity)
        : 0;
    final double maxY = spots.isNotEmpty
        ? spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5
        : 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Alınan Kalori: $calories / $goal", style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: goal != 0 ? calories / goal : 0,
            backgroundColor: Colors.grey[300],
            color: calories > goal ? Colors.red : Colors.green,
            minHeight: 12,
          ),
          const SizedBox(height: 20),
          _buildFormField("Güncel Kilo", _weightController),
          _buildFormField("Güncel Boy", _heightController),
          _buildFormField("Hedef Kilo", _targetWeightController),
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
          SizedBox(
            height: 200,
            child: spots.length < 2
                ? const Center(child: Text("Grafik için en az 2 veri noktası gerekli"))
                : LineChart(LineChartData(
              minY: minY,
              maxY: maxY,
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 3 * 24 * 60 * 60 * 1000,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      final formatted = DateFormat('MM/dd').format(date);
                      return Text(formatted, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  spots: spots,
                  color: Colors.purple,
                  barWidth: 2,
                  dotData: FlDotData(show: false),
                ),
              ],
            )),
          ),
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

          // YENİ EKLENEN KISIM: SADECE ADMIN'LER İÇİN YEMEK EKLE BUTONU
          FutureBuilder<bool>(
            future: _isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
                return ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddFoodScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Yeni Yemek Ekle"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodListPage(userId: widget.userData['uid']),
                ),
              );
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
              );
            },
            child: const Text("Bugün Yedikleriniz"),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
