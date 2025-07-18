import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFoodScreen extends StatelessWidget {
  AddFoodScreen({Key? key}) : super(key: key);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController calorieController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yemek Ekle')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Yemek Adı'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: calorieController,
              decoration: const InputDecoration(labelText: 'Kalori (kcal)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final cal = calorieController.text.trim();

                if (name.isEmpty || cal.isEmpty) return;

                await FirebaseFirestore.instance.collection('foods').add({
                  'name': name,
                  'kalori': int.parse(cal),
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yemek başarıyla eklendi.')),
                );

                nameController.clear();
                calorieController.clear();
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
