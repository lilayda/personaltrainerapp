import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetCaloriesController = TextEditingController();
  DateTime? _birthDate;

  int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  void _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Doğum tarihi seçilmediyse uyarı göster
    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen doğum tarihi seçiniz")),
      );
      return;
    }

    final weight = int.tryParse(_weightController.text);
    final height = int.tryParse(_heightController.text);
    final targetWeight = int.tryParse(_targetWeightController.text);
    final targetCalories = int.tryParse(_targetCaloriesController.text);
    final age = calculateAge(_birthDate!);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'weight': weight,
      'height': height,
      'targetWeight': targetWeight,
      'targetCalories': targetCalories,
      'birthDate': _birthDate != null ? Timestamp.fromDate(_birthDate!) : null,
      'age': age,
      'weightHistory': FieldValue.arrayUnion([
        {
          'date': Timestamp.now(),
          'weight': weight,
        }
      ])
    });

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _targetWeightController.dispose();
    _targetCaloriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil Bilgilerini Tamamla")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Güncel Kilo (kg)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Boy (cm)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetWeightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Hedef Kilo (kg)"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetCaloriesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Günlük Kalori Hedefi"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _birthDate = date;
                    });
                  }
                },
                child: Text(
                  _birthDate == null
                      ? 'Doğum Tarihini Seç'
                      : 'Seçilen Tarih: ${Timestamp.fromDate(_birthDate!).toDate().toLocal().toString().split(' ')[0]}',
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text("Bilgileri Kaydet"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
