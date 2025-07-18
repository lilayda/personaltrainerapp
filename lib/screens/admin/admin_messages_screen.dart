import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminMessagesScreen extends StatelessWidget {
  const AdminMessagesScreen({super.key});

  Future<bool> isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data()?['role'] == 'admin';
  }

  Future<void> deleteMessage(String docId) async {
    await FirebaseFirestore.instance.collection('messages').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!) {
          return const Scaffold(body: Center(child: Text("Bu sayfaya erişim yetkiniz yok.")));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Gelen Mesajlar", style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.black87,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Hiç mesaj yok."));
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final data = messages[index].data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp).toDate();
                  final formattedDate = DateFormat('dd.MM.yyyy HH:mm').format(timestamp);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text(data['name'] ?? "İsim yok"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text("Mail: ${data['email'] ?? 'Mail yok'}"),
                          const SizedBox(height: 6),
                          Text("Mesaj: ${data['message'] ?? 'Mesaj yok'}"),
                          const SizedBox(height: 6),
                          Text("Tarih: $formattedDate", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Silmek istediğinize emin misiniz?"),
                              content: const Text("Bu işlem geri alınamaz."),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("İptal"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Sil"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await deleteMessage(messages[index].id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Mesaj silindi")),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
