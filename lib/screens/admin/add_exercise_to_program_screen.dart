import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddExerciseToProgramScreen extends StatefulWidget {
  final String programId;

  const AddExerciseToProgramScreen({super.key, required this.programId});

  @override
  State<AddExerciseToProgramScreen> createState() => _AddExerciseToProgramScreenState();
}

class _AddExerciseToProgramScreenState extends State<AddExerciseToProgramScreen> {
  List<String> alreadyAddedExerciseIds = [];
  List<String> selectedExerciseIds = [];

  @override
  void initState() {
    super.initState();
    _fetchProgramExercises();
  }

  Future<void> _fetchProgramExercises() async {
    final programDoc = await FirebaseFirestore.instance.collection('programs').doc(widget.programId).get();
    final data = programDoc.data();
    if (data != null && data['exercises'] != null) {
      setState(() {
        alreadyAddedExerciseIds = List<String>.from(
          (data['exercises'] as List).map((ref) {
            if (ref is DocumentReference) return ref.id;
            if (ref is String) return ref;
            return '';
          }),
        );
      });
    }
  }

  Future<void> _saveSelectedExercises() async {
    final batch = FirebaseFirestore.instance.batch();
    final programRef = FirebaseFirestore.instance.collection('programs').doc(widget.programId);

    final exerciseRefs = selectedExerciseIds.map((id) => FirebaseFirestore.instance.collection('exercises').doc(id)).toList();

    batch.update(programRef, {
      'exercises': FieldValue.arrayUnion(exerciseRefs),
    });

    await batch.commit();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Egzersizler başarıyla eklendi')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Egzersiz Ekle")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('exercises').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allExercises = snapshot.data!.docs.where((doc) => !alreadyAddedExerciseIds.contains(doc.id)).toList();

          return ListView.builder(
            itemCount: allExercises.length,
            itemBuilder: (context, index) {
              final exercise = allExercises[index];
              final data = exercise.data() as Map<String, dynamic>;

              final isSelected = selectedExerciseIds.contains(exercise.id);

              return ListTile(
                title: Text(data['name']),
                subtitle: Text(data['category']),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.circle_outlined),
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      selectedExerciseIds.remove(exercise.id);
                    } else {
                      selectedExerciseIds.add(exercise.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: selectedExerciseIds.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _saveSelectedExercises,
        label: const Text("Kaydet"),
        icon: const Icon(Icons.save),
      )
          : null,
    );
  }
}
