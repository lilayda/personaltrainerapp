import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personaltrainer/screens/user/exercise_detail_screen.dart';
import 'package:personaltrainer/screens/user/program_detail_screen.dart';
import 'package:personaltrainer/widgets/step_counter_widget.dart';

class ActivityTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ActivityTab({super.key, required this.userData});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  List<Map<String, dynamic>> ongoingPrograms = [];
  int steps = 0;
  int totalBurnedCalories = 0;

  @override
  void initState() {
    super.initState();
    _checkAndResetDailyCalories().then((_) {
      _loadOngoingPrograms();
      _calculateBurnedCalories();
    });
  }

  Future<void> _checkAndResetDailyCalories() async {
    final userId = widget.userData['uid'];
    final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
    final userDoc = await userDocRef.get();

    final now = DateTime.now().toUtc();
    final today = DateTime(now.year, now.month, now.day);

    Timestamp? lastResetTimestamp = userDoc.data()?['lastCaloriesResetDate'];
    DateTime? lastResetDate = lastResetTimestamp?.toDate();

    if (lastResetDate == null || lastResetDate.isBefore(today)) {
      await userDocRef.update({
        'caloriesBurned': 0,
        'lastCaloriesResetDate': Timestamp.fromDate(today),
      });

      setState(() {
        totalBurnedCalories = 0;
      });
    }
  }

  Future<void> _loadOngoingPrograms() async {
    final userId = widget.userData['uid'];
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final List<dynamic> programs = userDoc.data()?['ongoingPrograms'] ?? [];
    setState(() {
      ongoingPrograms = List<Map<String, dynamic>>.from(programs);
    });
  }

  Future<Map<String, dynamic>?> _getProgramDetails(String programId) async {
    final doc = await FirebaseFirestore.instance.collection('programs').doc(programId).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> _removeProgram(String programIdToRemove) async {
    final userId = widget.userData['uid'];
    ongoingPrograms.removeWhere((p) => p['programId'] == programIdToRemove);
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'ongoingPrograms': ongoingPrograms,
    });
    setState(() {});
  }

  Future<void> _calculateBurnedCalories() async {
    final userId = widget.userData['uid'];
    final now = DateTime.now().toUtc();
    final todayStart = DateTime.utc(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    int burnedFromExercises = 0;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('completed_exercises')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThanOrEqualTo: todayStart)
        .where('timestamp', isLessThan: todayEnd)
        .get();

    for (var doc in querySnapshot.docs) {
      final cal = doc['calories'];
      burnedFromExercises += (cal is int) ? cal : (cal as num).toInt();
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    int stepCount = userDoc['stepsToday'] ?? 0;
    double caloriesPerStep = 0.04;
    int stepCalories = (stepCount * caloriesPerStep).round();

    int total = burnedFromExercises + stepCalories;

    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'caloriesBurned': total,
    });

    setState(() {
      totalBurnedCalories = total;
      steps = stepCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic> favoriteExerciseIds = widget.userData['favoriteExercises'] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ListView(
        children: [
          const SizedBox(height: 10),
          _buildCard(
            icon: Icons.directions_walk,
            title: "Bugünkü Adım Sayısı",
            customWidget: StepCounterWidget(),
          ),
          const SizedBox(height: 10),
          _buildCard(
            icon: Icons.local_fire_department,
            title: "Günlük Yakılan Kalori",
            value: "$totalBurnedCalories kcal",
          ),
          const SizedBox(height: 20),
          const Text("Devam Eden Programlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...ongoingPrograms.map((program) {
            final String programId = program['programId'];
            final int completed = program['completedDays'] ?? 0;
            final int total = program['totalDays'] ?? 1;

            return FutureBuilder<Map<String, dynamic>?>(
              future: _getProgramDetails(programId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final data = snapshot.data!;
                final name = data['name'] ?? 'Program';

                return ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(name),
                  subtitle: Text("Tamamlanan Gün: $completed / $total"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Programı kaldır?"),
                          content: const Text("Bu programı kaldırmak istediğinize emin misiniz?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil")),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await _removeProgram(programId);
                      }
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgramDetailScreen(programId: programId),
                      ),
                    );
                  },
                );
              },
            );
          }),
          const SizedBox(height: 20),
          const Text("Favori Egzersizlerim", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          FutureBuilder<List<Map<String, String>>>(
            future: _fetchFavoriteExerciseNames(favoriteExerciseIds),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox();
              final favorites = snapshot.data ?? [];
              if (favorites.isEmpty) return const Text("Henüz favori egzersiz yok.");

              return Column(
                children: favorites.map((exercise) => ListTile(
                  leading: const Icon(Icons.star, color: Colors.orange),
                  title: Text(exercise['name']!),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExerciseDetailScreen(exerciseId: exercise['id']!),
                      ),
                    );
                  },
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  static Future<List<Map<String, String>>> _fetchFavoriteExerciseNames(List<dynamic> ids) async {
    List<Map<String, String>> exercises = [];
    for (var id in ids) {
      final doc = await FirebaseFirestore.instance.collection('exercises').doc(id).get();
      if (doc.exists && doc.data()!.containsKey('name')) {
        exercises.add({'id': doc.id, 'name': doc['name']});
      }
    }
    return exercises;
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    String? value,
    Widget? customWidget,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                customWidget ?? Text(value ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }
}
