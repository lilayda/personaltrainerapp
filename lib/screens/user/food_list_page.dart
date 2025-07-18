import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodListPage extends StatefulWidget {
  final String userId;
  const FoodListPage({super.key, required this.userId});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allFoods = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filteredFoods = [];

  @override
  void initState() {
    super.initState();
    _loadFoods();
  }

  Future<void> _loadFoods() async {
    final snapshot = await FirebaseFirestore.instance.collection('foods').get();
    setState(() {
      _allFoods = snapshot.docs;
      _filteredFoods = snapshot.docs;
    });
  }

  void _filterFoods(String query) {
    final lower = query.toLowerCase();
    setState(() {
      _filteredFoods = _allFoods.where((doc) {
        final name = doc.data()['name']?.toString().toLowerCase() ?? '';
        return name.contains(lower);
      }).toList();
    });
  }

  Future<void> _addMeal(String name, int calories) async {
    final now = DateTime.now().toUtc();;
    final todayMealRef = FirebaseFirestore.instance.collection('today_meals');
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    await todayMealRef.add({
      'userId': widget.userId,
      'yemek': name,
      'kalori': calories,
      'date': Timestamp.fromDate(now),
    });

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final currentCalories = snapshot['caloriesToday'] ?? 0;
      transaction.update(userRef, {
        'caloriesToday': currentCalories + calories,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name eklendi")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yemek Ekle")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Yemek ara...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filterFoods,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredFoods.length,
              itemBuilder: (context, index) {
                final data = _filteredFoods[index].data();
                return ListTile(
                  title: Text(data['name']),
                  subtitle: Text("${data['kalori']} kcal"),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addMeal(data['name'], data['kalori']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
