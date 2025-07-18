import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

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

  void requestPermissionAndStart() async {
    if (await Permission.activityRecognition.isGranted) {
      initPedometer();
    } else {
      final result = await Permission.activityRecognition.request();
      if (result.isGranted) {
        initPedometer();
      } else {
        print("İzin verilmedi.");
      }
    }
  }

  void initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen(onStepCount).onError((error) {
      print("Adım sensöründe hata: $error");
    });
  }

  void onStepCount(StepCount event) {
    if (_initialSteps == null) {
      _initialSteps = event.steps;
    }

    final stepsNow = event.steps - (_initialSteps ?? 0);
    setState(() {
      _stepsToday = stepsNow;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      "$_stepsToday adım",
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }
}
