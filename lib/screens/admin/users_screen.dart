import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  Future<void> _promoteToAdmin(String userId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'role': 'admin'});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kullanıcı admin yapıldı')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Üyeler", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final userId = users[index].id;

              return ListTile(
                title: Text(user['name'] ?? 'İsimsiz'),
                subtitle: Text(user['email'] ?? ''),
                trailing: user['role'] == 'admin'
                    ? const Text('Admin')
                    : TextButton(
                  onPressed: () => _promoteToAdmin(userId, context),
                  child: const Text('Admin yap'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
