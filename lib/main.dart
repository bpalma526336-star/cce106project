import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:smart_quiz/firebase_options.dart';
import 'package:smart_quiz/theme/theme.dart';
import 'package:smart_quiz/view/admin/admin_home_screen.dart';
import 'package:smart_quiz/view/user/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Smart Quiz",
      theme: AppTheme.theme,
      home: HomeScreen(),
    );
  }
}
