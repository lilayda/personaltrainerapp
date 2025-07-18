import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise_detail_screen.dart';
import 'program_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> searchResults = [];

  void searchItems(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults.clear());
      return;
    }

    List<Map<String, dynamic>> results = [];

    final exercisesSnapshot = await _firestore.collection('exercises').get();
    for (var doc in exercisesSnapshot.docs) {
      var name = doc['name'] ?? '';
      if (name.toLowerCase().contains(query.toLowerCase())) {
        results.add({
          'id': doc.id,
          'name': name,
          'type': 'exercise',
        });
      }
    }

    final programsSnapshot = await _firestore.collection('programs').get();
    for (var doc in programsSnapshot.docs) {
      var name = doc['name'] ?? '';
      if (name.toLowerCase().contains(query.toLowerCase())) {
        results.add({
          'id': doc.id,
          'name': name,
          'type': 'program',
        });
      }
    }

    setState(() => searchResults = results);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        iconTheme: const IconThemeData(color: Colors.white),
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Egzersiz ya da program ara...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
          onChanged: searchItems,
        ),
      ),
      body: searchResults.isEmpty
          ? const Center(child: Text('Sonuç bulunamadı'))
          : ListView.builder(
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final result = searchResults[index];
          return ListTile(
            title: Text(result['name']),
            subtitle: Text(result['type'] == 'exercise'
                ? 'Egzersiz'
                : 'Program'),
            leading: Icon(result['type'] == 'exercise'
                ? Icons.fitness_center
                : Icons.list_alt),
            onTap: () {
              if (result['type'] == 'exercise') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseDetailScreen(
                      exerciseId: result['id'],
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgramDetailScreen(
                      programId: result['id'],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
