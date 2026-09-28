import 'package:flutter/material.dart';
import '../../video_list_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<_Course> _allCourses = const [
    _Course(
      title: 'Data Structures',
      description: 'Arrays, linked lists, stacks, queues, trees, graphs.',
      thumbnailColor: Color(0xFF2196F3),
    ),
    _Course(
      title: 'Algorithms',
      description: 'Sorting, searching, greedy, DP, complexity analysis.',
      thumbnailColor: Color(0xFF1976D2),
    ),
    _Course(
      title: 'Object-Oriented Programming',
      description: 'Classes, objects, inheritance, polymorphism, design basics.',
      thumbnailColor: Color(0xFF42A5F5),
    ),
    _Course(
      title: 'Database Systems',
      description: 'ER modeling, SQL, normalization, transactions, indexing.',
      thumbnailColor: Color(0xFF64B5F6),
    ),
    _Course(
      title: 'Computer Networks',
      description: 'OSI/TCP-IP, routing, HTTP, DNS, sockets, security.',
      thumbnailColor: Color(0xFF90CAF9),
    ),
    _Course(
      title: 'Operating Systems',
      description: 'Processes, threads, scheduling, memory, filesystems.',
      thumbnailColor: Color(0xFF1E88E5),
    ),
    _Course(
      title: 'Software Engineering',
      description: 'Requirements, testing, version control, CI/CD, patterns.',
      thumbnailColor: Color(0xFF0D47A1),
    ),
    _Course(
      title: 'Web Development',
      description: 'HTML/CSS/JS, REST, state management, performance.',
      thumbnailColor: Color(0xFF1565C0),
    ),
  ];

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_Course> filtered = _allCourses
        .where((c) => c.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final course = filtered[index];
                  return _buildCourseCard(context, course);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          hintText: 'Search courses',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search),
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, _Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const VideoListScreen()),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: course.thumbnailColor,
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [course.thumbnailColor, course.thumbnailColor.withOpacity(0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.library_books, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      course.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF666666)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Course {
  final String title;
  final String description;
  final Color thumbnailColor;
  const _Course({required this.title, required this.description, required this.thumbnailColor});
}


