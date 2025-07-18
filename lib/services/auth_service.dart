import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı girişi
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Giriş Hatası: ${e.message}");
      return null;
    }
  }

  // Yeni kullanıcı kaydı
  Future<User?> register(String name, String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      await _firestore.collection('users').doc(user!.uid).set({
        'name': name,
        'email': email,
        'phone': '',
        'stepsToday': 0,
        'caloriesToday': 0,
        'weeklyExerciseMinutes': 0,
        'goalCompletion': 0,
        'savedExercises': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // E-posta doğrulama bağlantısı gönder
      await user.sendEmailVerification();

      return user;
    } on FirebaseAuthException catch (e) {
      print("Kayıt Hatası: ${e.message}");
      return null;
    }
  }

  // Şifre sıfırlama
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print("Şifre Sıfırlama Hatası: ${e.message}");
    }
  }

  // Oturumu kapatma
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
