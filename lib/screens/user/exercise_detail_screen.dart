import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  final String? programId;
  final String? category;
  final List<DocumentReference>? programExerciseRefs;
  final int currentIndex;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseId,
    this.programId,
    this.category,
    this.programExerciseRefs,
    this.currentIndex = 0,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late Future<DocumentSnapshot> _exerciseFuture;
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    _exerciseFuture =
        _firestore.collection('exercises').doc(widget.exerciseId).get();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userDoc = await _firestore.collection('users').doc(uid).get();
    final data = userDoc.data();

    if (data != null && data['favoriteExercises'] != null) {
      List favs = data['favoriteExercises'];
      setState(() {
        isFavorite = favs.contains(widget.exerciseId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);
    final action = isFavorite
        ? FieldValue.arrayRemove([widget.exerciseId])
        : FieldValue.arrayUnion([widget.exerciseId]);

    await userRef.update({'favoriteExercises': action});

    setState(() {
      isFavorite = !isFavorite;
    });
  }

  Future<void> _goToNextExercise(BuildContext context) async {
    if (widget.programId != null && widget.programExerciseRefs != null) {
      int nextIndex = widget.currentIndex + 1;
      if (nextIndex < widget.programExerciseRefs!.length) {
        String nextId = widget.programExerciseRefs![nextIndex].id;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(
              exerciseId: nextId,
              programId: widget.programId,
              programExerciseRefs: widget.programExerciseRefs,
              currentIndex: nextIndex,
            ),
          ),
        );
      } else {
        // Program son egzersizi tamamladı
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          final userRef = _firestore.collection('users').doc(uid);
          final userDoc = await userRef.get();
          final data = userDoc.data();

          if (data != null && data['ongoingPrograms'] != null) {
            List<dynamic> ongoingPrograms = List.from(data['ongoingPrograms']);
            for (int i = 0; i < ongoingPrograms.length; i++) {
              if (ongoingPrograms[i]['programId'] == widget.programId) {
                ongoingPrograms[i]['completedDays'] =
                    (ongoingPrograms[i]['completedDays'] ?? 0) + 1;

                if (ongoingPrograms[i]['completedDays'] >=
                    (ongoingPrograms[i]['totalDays'] ?? 1)) {
                  ongoingPrograms.removeAt(i);
                }
                break;
              }
            }

            await userRef.update({'ongoingPrograms': ongoingPrograms});
          }
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Tebrikler!"),
            content: const Text("Programı başarıyla tamamladınız."),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text("Ana Sayfa"),
              )
            ],
          ),
        );
      }
    } else if (widget.category != null) {
      var snapshot = await _firestore
          .collection('exercises')
          .where('category', isEqualTo: widget.category)
          .get();

      var exercises = snapshot.docs;
      int currentIndex = exercises.indexWhere((doc) => doc.id == widget.exerciseId);

      if (currentIndex != -1 && currentIndex + 1 < exercises.length) {
        String nextId = exercises[currentIndex + 1].id;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseDetailScreen(
              exerciseId: nextId,
              category: widget.category,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Son egzersize ulaşıldı.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: _exerciseFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var exercise = snapshot.data!.data() as Map<String, dynamic>;

          return Stack(
            children: [
              Image.asset(
                exercise['gifUrl'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Container(color: Colors.black.withOpacity(0.3)),
              Positioned(
                top: 40,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                top: 40,
                right: 10,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
              Positioned(
                bottom: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'],
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Kategori: ${exercise['category']}"),
                          Text("Ekipman: ${exercise['equipment']}"),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Set x Tekrar: ${exercise['sets']} x ${exercise['reps']}"),
                          Text(exercise['description']),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _goToNextExercise(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text("Bir Sonraki"),
                      ),
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
