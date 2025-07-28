import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepCounterWidget extends StatefulWidget {
  const StepCounterWidget({super.key});

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  Stream<StepCount>? _stepCountStream;
  int _stepsToday = 0;
  int? _initialSteps;

  @override
  void initState() {
    super.initState();
    requestPermissionAndStart();
  }

  Future<void> requestPermissionAndStart() async {
    if (await Permission.activityRecognition.isGranted) {
      await initPedometer();
    } else {
      final result = await Permission.activityRecognition.request();
      if (result.isGranted) {
        await initPedometer();
      }
    }
  }

  Future<void> initPedometer() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();

    if (prefs.containsKey(todayKey)) {
      _initialSteps = prefs.getInt(todayKey);
    }

    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen((event) {
      if (_initialSteps == null) {
        _initialSteps = event.steps;
        prefs.setInt(todayKey, _initialSteps!); // günün ilk değeri kaydedilir
      }

      final stepsNow = event.steps - (_initialSteps ?? 0);
      setState(() {
        _stepsToday = stepsNow;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'stepsToday': _stepsToday,
        });
      }
    }).onError((error) {
      print("Adım sensör hatası: $error");
    });
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "initialSteps_${now.year}_${now.month}_${now.day}";
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "$_stepsToday adım",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
