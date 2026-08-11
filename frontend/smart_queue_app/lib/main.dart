import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(SmartQueueApp());
}

class SmartQueueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Patient Queue',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
      ),
      home: LoginScreen(),
    );
  }
}