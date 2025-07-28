import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();

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
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen doğum tarihi seçiniz")),
      );
      return;
    }

    final weight = int.parse(_weightController.text);
    final height = int.parse(_heightController.text);
    final targetWeight = int.parse(_targetWeightController.text);
    final targetCalories = int.parse(_targetCaloriesController.text);
    final age = calculateAge(_birthDate!);

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'weight': weight,
      'height': height,
      'targetWeight': targetWeight,
      'targetCalories': targetCalories,
      'birthDate': Timestamp.fromDate(_birthDate!),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Güncel Kilo",
                    hintText: "Örn: 65",
                    suffixText: "kg",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Kilo zorunlu';
                    final v = int.tryParse(value);
                    if (v == null) return 'Geçerli bir sayı girin';
                    if (v < 20 || v > 300) return 'Kilo 20-300 kg arası olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Boy",
                    hintText: "Örn: 170",
                    suffixText: "cm",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Boy zorunlu';
                    final v = int.tryParse(value);
                    if (v == null) return 'Geçerli bir sayı girin';
                    if (v < 50 || v > 250) return 'Boy 50-250 cm arası olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetWeightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Hedef Kilo",
                    hintText: "Örn: 60",
                    suffixText: "kg",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Hedef kilo zorunlu';
                    final v = int.tryParse(value);
                    if (v == null) return 'Geçerli bir sayı girin';
                    if (v < 20 || v > 300) return 'Hedef kilo 20-300 kg arası olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _targetCaloriesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Günlük Kalori Hedefi",
                    hintText: "Örn: 2000",
                    suffixText: "kcal",
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Kalori hedefi zorunlu';
                    final v = int.tryParse(value);
                    if (v == null) return 'Geçerli bir sayı girin';
                    if (v < 500 || v > 6000) return 'Kalori 500-6000 arasında olmalı';
                    return null;
                  },
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
                        : 'Seçilen Tarih: ${_birthDate!.toLocal().toString().split(' ')[0]}',
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
      ),
    );
  }
}
