import 'package:flutter/material.dart';
import '../../utils/routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Paneli"),
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
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.fastfood),
            title: const Text("Yemek Ekle"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.addFood),
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text("Egzersiz Ekle"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.addExercise),
          ),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text("Program Ekle"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.addProgram),
          ),
        ],
      ),
    );
  }
}
