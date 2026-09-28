import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'course_list_screen.dart';
import 'nearby_connections_screen.dart';
import 'quiz_screen.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const DashboardScreen(),
      const CourseListScreen(),
      const NearbyConnectionsScreen(),
      const QuizScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF2196F3),
          unselectedItemColor: const Color(0xFF666666),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Courses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.share_outlined),
              activeIcon: Icon(Icons.share),
              label: 'Share',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: 'Quiz',
            ),
          ],
        ),
      ),
    );
  }
}


