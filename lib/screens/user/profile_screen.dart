import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'activity_tab.dart';
import 'calorie_tab.dart';
import 'account_tab.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int selectedIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Kullanıcı oturumu bulunamadı")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data!.data() == null) {
          return const Scaffold(
            body: Center(child: Text("Kullanıcı verisi bulunamadı")),
          );
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        // UID'yi manuel olarak ekle
        userData['uid'] = uid;

        // Yaş hesaplama
        DateTime birthDate;
        if (userData['birthDate'] is Timestamp) {
          birthDate = (userData['birthDate'] as Timestamp).toDate();
        } else if (userData['birthDate'] is String) {
          birthDate = DateTime.tryParse(userData['birthDate']) ?? DateTime.now();
        } else {
          birthDate = DateTime.now();
        }
        int age = _calculateAge(birthDate);

        return Scaffold(
          appBar: AppBar(
            title: const Text("Profil"),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTabButton("Aktivitelerim", 0),
                  _buildTabButton("Kalori Takibi", 1),
                  _buildTabButton("Hesap", 2),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _buildTabContent(userData, age),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabButton(String title, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedIndex == index ? Colors.deepPurple : Colors.grey[300],
          foregroundColor: selectedIndex == index ? Colors.white : Colors.black,
        ),
        onPressed: () {
          setState(() {
            selectedIndex = index;
          });
        },
        child: Text(title),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> userData, int age) {
    switch (selectedIndex) {
      case 0:
        return ActivityTab(userData: userData);
      case 1:
        return CalorieTab(
          userData: userData,
          age: age,
          onRefresh: _refresh,
        );
      case 2:
        return AccountTab(userData: userData, age: age);
      default:
        return const SizedBox();
    }
  }

  int _calculateAge(DateTime birthDate) {
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
