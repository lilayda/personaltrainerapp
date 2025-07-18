import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final int age;

  const AccountTab({super.key, required this.userData, required this.age});

  @override
  Widget build(BuildContext context) {
    DateTime birthDate;

    if (userData['birthDate'] is Timestamp) {
      birthDate = (userData['birthDate'] as Timestamp).toDate();
    } else if (userData['birthDate'] is DateTime) {
      birthDate = userData['birthDate'];
    } else {
      birthDate = DateTime.now();
    }
    String formattedDate = DateFormat('dd.MM.yyyy').format(birthDate);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: [
          const SizedBox(height: 20),
          _infoTile("Kullanıcı Adı", userData['name'] ?? ""),
          _infoTile("Doğum Günü", formattedDate),
          _infoTile("Yaş", age.toString()),
          _infoTile("E-posta", userData['email'] ?? ""),
          const SizedBox(height: 20),

          /// ✅ Şifreyi Değiştir Butonu
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const ChangePasswordDialog(),
              );
            },
            icon: const Icon(Icons.lock),
            label: const Text("Şifreyi Değiştir"),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
        leading: const Icon(Icons.info_outline),
        tileColor: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final TextEditingController _currentPassword = TextEditingController();
  final TextEditingController _newPassword = TextEditingController();
  final TextEditingController _confirmPassword = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String _errorMessage = '';

  Future<void> _changePassword() async {
    setState(() {
      _errorMessage = '';
      _loading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;

      if (user == null || email == null) {
        throw FirebaseAuthException(code: 'user-not-found', message: 'Kullanıcı oturumu yok.');
      }

      // 1. Yeniden kimlik doğrulama
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPassword.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Yeni şifreleri kontrol et
      if (_newPassword.text.trim() != _confirmPassword.text.trim()) {
        setState(() {
          _errorMessage = 'Yeni şifreler uyuşmuyor.';
          _loading = false;
        });
        return;
      }

      if (_newPassword.text.trim().length < 6) {
        setState(() {
          _errorMessage = 'Şifre en az 6 karakter olmalı.';
          _loading = false;
        });
        return;
      }

      // 3. Şifreyi değiştir
      await user.updatePassword(_newPassword.text.trim());

      setState(() {
        _loading = false;
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Şifre başarıyla değiştirildi.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? "Bir hata oluştu.";
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Şifreyi Değiştir"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Mevcut Şifre"),
            ),
            TextField(
              controller: _newPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Yeni Şifre"),
            ),
            TextField(
              controller: _confirmPassword,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Yeni Şifre (Tekrar)"),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _changePassword,
          child: _loading
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("Kaydet"),
        ),
      ],
    );
  }
}
