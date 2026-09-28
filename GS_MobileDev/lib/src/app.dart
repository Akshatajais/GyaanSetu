import 'package:flutter/material.dart';

import 'routes.dart';
import 'screens/home_shell.dart';

class LiveClass extends StatelessWidget {
  const LiveClass({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Abeja Classroom',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.blue,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.black54,
          backgroundColor: Colors.white,
          elevation: 8,
          showUnselectedLabels: true,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}


