import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_list_screen.dart';
import 'search_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key});

  Future<bool> isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> categories = [
      {
        'title': 'Ev Egzersizleri',
        'image': 'assets/images/homeworkout.jpg',
      },
      {
        'title': 'Esneme',
        'image': 'assets/images/stretch.jpg',
      },
      {
        'title': 'Gym',
        'image': 'assets/images/gym.jpg',
      },
      {
        'title': 'Dövüş Antrenmanı',
        'image': 'assets/images/martialarts.jpg',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Egzersizler', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF212121),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          FutureBuilder<bool>(
            future: isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.data == true) {
                return IconButton(
                  icon: const Icon(Icons.message, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin_messages');
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseListScreen(
                    category: categories[index]['title']!,
                  ),
                ),
              );
            },
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: DecorationImage(
                      image: AssetImage(categories[index]['image']!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  left: 25,
                  child: Text(
                    categories[index]['title']!,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 5,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
