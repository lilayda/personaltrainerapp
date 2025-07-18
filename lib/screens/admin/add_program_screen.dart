import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProgramScreen extends StatefulWidget {
  const AddProgramScreen({Key? key}) : super(key: key);

  @override
  State<AddProgramScreen> createState() => _AddProgramScreenState();
}

class _AddProgramScreenState extends State<AddProgramScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController durationController = TextEditingController();
  final TextEditingController imageAssetPathController = TextEditingController();

  List<String> selectedExercisePaths = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Program Ekle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Program Adı'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Açıklama'),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(labelText: 'Süre (gün)'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imageAssetPathController,
              decoration: const InputDecoration(labelText: 'Görsel Yol (imageAssetPath)'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Programa Dahil Edilecek Egzersizleri Seç',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance.collection('exercises').get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final name = doc['name'];
                    final fullPath = "/exercises/${doc.id}";

                    return CheckboxListTile(
                      title: Text(name),
                      value: selectedExercisePaths.contains(fullPath),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedExercisePaths.add(fullPath);
                          } else {
                            selectedExercisePaths.remove(fullPath);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty ||
                    durationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
                  );
                  return;
                }

                await FirebaseFirestore.instance.collection('programs').add({
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'duration': int.parse(durationController.text.trim()),
                  'imageAssetPath': imageAssetPathController.text.trim(),
                  'exercises': selectedExercisePaths,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Program başarıyla eklendi.")),
                );

                nameController.clear();
                descriptionController.clear();
                durationController.clear();
                imageAssetPathController.clear();
                setState(() {
                  selectedExercisePaths.clear();
                });
              },
              child: const Text('Kaydet'),
            )
          ],
        ),
      ),
    );
  }
}
