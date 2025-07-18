import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exercise_detail_screen.dart';
import '../admin/edit_program_screen.dart';
import '../admin/add_exercise_to_program_screen.dart';

class ProgramDetailScreen extends StatefulWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  State<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends State<ProgramDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  Future<void> _checkIfAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('users').doc(uid).get();
    setState(() {
      isAdmin = doc.data()?['role'] == 'admin';
    });
  }

  Future<void> _removeExerciseFromProgram(DocumentReference ref) async {
    await _firestore.collection('programs').doc(widget.programId).update({
      'exercises': FieldValue.arrayRemove([ref])
    });
    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('programs').doc(widget.programId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var programData = snapshot.data!.data() as Map<String, dynamic>;
          var exercisesRaw = programData['exercises'] as List<dynamic>;

          var exercises = exercisesRaw
              .where((ref) => ref != null && ref.toString().isNotEmpty)
              .map((ref) {
            if (ref is DocumentReference) {
              return ref;
            } else if (ref is String && ref.trim().isNotEmpty) {
              return _firestore.doc(ref.trim());
            } else {
              return null;
            }
          }).where((ref) => ref != null).cast<DocumentReference>().toList();

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(programData['imageAssetPath']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(color: Colors.black.withOpacity(0.5)),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                        onPressed: () async {
                          final uid = FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;

                          final userDoc = await _firestore.collection('users').doc(uid).get();
                          List<dynamic> ongoingPrograms = userDoc.data()?['ongoingPrograms'] ?? [];

                          bool alreadyAdded = ongoingPrograms.any((p) => p['programId'] == widget.programId);
                          if (!alreadyAdded) {
                            ongoingPrograms.add({
                              'programId': widget.programId,
                              'completedDays': 0,
                              'totalDays': programData['duration'],
                            });

                            await _firestore.collection('users').doc(uid).update({
                              'ongoingPrograms': ongoingPrograms,
                            });
                          }

                          if (exercises.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseDetailScreen(
                                  exerciseId: exercises[0].id,
                                  programId: widget.programId,
                                  programExerciseRefs: exercises,
                                  currentIndex: 0,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Programda egzersiz bulunmuyor.")),
                            );
                          }
                        },
                        child: Text(
                          'Başla',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        programData['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        programData['description'],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            '${programData['duration']} Gün',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (isAdmin)
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProgramScreen(programId: widget.programId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Programı Düzenle'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddExerciseToProgramScreen(programId: widget.programId),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Egzersiz Ekle'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      ...exercises.map((ref) => FutureBuilder<DocumentSnapshot>(
                        future: ref.get(),
                        builder: (context, snap) {
                          if (!snap.hasData) return const SizedBox();
                          var data = snap.data!.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(data['name'], style: const TextStyle(color: Colors.white)),
                            trailing: isAdmin
                                ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeExerciseFromProgram(ref),
                            )
                                : null,
                          );
                        },
                      )),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
