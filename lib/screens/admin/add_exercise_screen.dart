import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExerciseScreen extends StatelessWidget {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController equipmentController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();
  final TextEditingController gifUrlController = TextEditingController();

  AddExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Egzersiz Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Egzersiz Adı')),
            TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Açıklama')),
            TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Kategori')),
            TextField(controller: equipmentController, decoration: const InputDecoration(labelText: 'Ekipman')),
            TextField(controller: setsController, decoration: const InputDecoration(labelText: 'Set Sayısı'), keyboardType: TextInputType.number),
            TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Tekrar Sayısı'), keyboardType: TextInputType.number),
            TextField(controller: coverUrlController, decoration: const InputDecoration(labelText: 'Kapak Görseli URL')),
            TextField(controller: gifUrlController, decoration: const InputDecoration(labelText: 'GIF URL')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('exercises').add({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': categoryController.text.trim(),
                  'equipment': equipmentController.text.trim(),
                  'sets': int.parse(setsController.text),
                  'reps': int.parse(repsController.text),
                  'coverUrl': coverUrlController.text.trim(),
                  'gifUrl': gifUrlController.text.trim(),
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Egzersiz eklendi')),
                );
              },
              child: const Text('Kaydet'),
            )
          ],
        ),
      ),
    );
  }
}
