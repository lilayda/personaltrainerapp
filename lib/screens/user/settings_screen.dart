import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isAdminUser = false;
  final TextEditingController _termsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final doc = await _firestore.collection('users').doc(uid).get();
      setState(() {
        isAdminUser = doc.data()?['role'] == 'admin';
      });
    }
  }

  Future<void> _showTermsEditor(BuildContext context) async {
    final doc = await _firestore.collection('settings').doc('terms').get();
    _termsController.text = doc.exists ? doc['content'] ?? '' : '';

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kullanım Koşullarını Düzenle'),
        content: TextField(
          controller: _termsController,
          maxLines: 10,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection('settings').doc('terms').set({
                'content': _termsController.text.trim(),
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kullanım koşulları güncellendi')),
              );
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReadOnlyTerms(BuildContext context) async {
    final doc = await _firestore.collection('settings').doc('terms').get();
    final content = doc.exists ? doc['content'] ?? '' : 'Kullanım koşulları bulunamadı.';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanım Koşulları'),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF212121),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('users').doc(_auth.currentUser!.uid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Email:',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                controller: TextEditingController(text: userData['email']),
              ),
              const SizedBox(height: 20),
              ListTile(
                title: const Text('Dil:'),
                trailing: const Text('Türkçe'),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 15),
              ListTile(
                title: const Text('Kullanım Koşulları'),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                onTap: () {
                  isAdminUser ? _showTermsEditor(context) : _showReadOnlyTerms(context);
                },
              ),
              const SizedBox(height: 15),
              if (isAdminUser)
                ListTile(
                  title: const Text('Üyeler'),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/users');
                  },
                )
              else
                ListTile(
                  title: const Text('Bizimle İletişime Geçin'),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/contact_us');
                  },
                ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  bool confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Emin misiniz?'),
                      content: const Text('Hesabınızı kalıcı olarak silmek istediğinizden emin misiniz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hayır')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Evet')),
                      ],
                    ),
                  );

                  if (confirm) {
                    await _firestore.collection('users').doc(_auth.currentUser!.uid).delete();
                    await _auth.currentUser!.delete();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                  }
                },
                child: const Text('Hesabı Sil'),
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await _auth.signOut();
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                },
                child: const Text('Çıkış Yap'),
              ),
            ],
          );
        },
      ),
    );
  }
}
