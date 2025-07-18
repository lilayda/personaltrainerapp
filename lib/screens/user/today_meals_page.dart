import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodayMealsPage extends StatelessWidget {
  final String userId;

  const TodayMealsPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    // Şu anki zaman (UTC)
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime.utc(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bugün Yedikleriniz"),
        backgroundColor: const Color(0xFF212121),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('today_meals')
            .where('userId', isEqualTo: userId)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
            .where('date', isLessThan: Timestamp.fromDate(endOfDay))
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Bir hata oluştu: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Bugün henüz yemek eklenmemiş.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          int totalCalories = docs.fold(0, (sum, doc) => sum + (doc['kalori'] as num).toInt());

          return Column(
            children: [
              const SizedBox(height: 10),
              Text(
                "Toplam Alınan Kalori: $totalCalories kcal",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final mealName = data['yemek'] ?? 'Bilinmeyen';
                    final calories = data['kalori'] ?? 0;
                    final time = (data['date'] as Timestamp).toDate().toLocal();
                    final formattedTime = DateFormat('HH:mm').format(time);

                    return ListTile(
                      leading: const Icon(Icons.restaurant_menu, color: Colors.deepPurple),
                      title: Text(mealName),
                      subtitle: Text("$calories kcal - $formattedTime"),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
