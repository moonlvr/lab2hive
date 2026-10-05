import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

/// Name of the Hive box that stores all to-do items.
const String taskBoxName = 'taskBox';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive before runApp()
  await Hive.initFlutter();

  // 2. Register the adapter and open the box
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox<Task>(taskBoxName);

  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive To-Do',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}