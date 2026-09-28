import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/services/scheduler_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SchedulerService.instance.initialize();
  runApp(const LiveClass());
}