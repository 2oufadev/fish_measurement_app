import 'package:fish_measurement_app/theme.dart';
import 'package:fish_measurement_app/tournamets_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget with ThemeUtils {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: buildTheme(),
      home: const TournamentsScreen(),
    );
  }
}

