import 'package:flutter/material.dart';
import '../services/pdf_service.dart';
import '../services/scheduler_service.dart';
import 'classroom_screen.dart';
import 'nearby_connections_screen.dart';

class DashboardScreen extends StatefulWidget {
  static const String routeName = '/';
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final PdfService _pdfService;

  @override
  void initState() {
    super.initState();
    _pdfService = PdfService();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime nextClassTime = DateTime(now.year, now.month, now.day, 9);
    final bool isTodayPast = now.isAfter(nextClassTime);
    final DateTime effectiveClassTime = isTodayPast
        ? nextClassTime.add(const Duration(days: 1))
        : nextClassTime;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'GyanSetu Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Welcome to GyanSetu',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your next class starts at ${_formatTime(effectiveClassTime)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.video_call,
                    title: 'Join Class',
                    subtitle: 'Live Lecture',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        ClassroomScreen.routeName,
                        arguments: const ClassroomArgs(
                          audioStreamUrl:
                              'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.download,
                    title: 'Download PPT',
                    subtitle: 'Overnight',
                    color: const Color(0xFFFF9800),
                    onTap: () async {
                      final hour = await _pickOvernightHour(context);
                      if (hour != null) {
                        await SchedulerService.instance.scheduleOvernightDownload(hour24: hour);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Overnight download scheduled at ${_format24h(hour)}')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.picture_as_pdf,
                    title: 'Install Demo',
                    subtitle: 'PDF Slides',
                    color: const Color(0xFF9C27B0),
                    onTap: () async {
                      try {
                        await _pdfService.downloadAndSavePdf(
                          url:
                              'https://basponccollege.org/LMS/EMaterial/Science/Comp/HVP/JS%20Notes.pdf',
                          title: 'Demo_Slides',
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Demo PDF installed')),
                        );
                        setState(() {});
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed to install demo PDF: $e')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.share,
                    title: 'Share Files',
                    subtitle: 'P2P Transfer',
                    color: const Color(0xFF4CAF50),
                    onTap: () {
                      // Navigate to NearbyConnectionsScreen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NearbyConnectionsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Downloaded Materials
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_open,
                        color: Color(0xFF2196F3),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Downloaded Materials',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 300,
                    child: FutureBuilder<List<LocalPdf>>(
                      future: _pdfService.listDownloadedPdfs(),
                      builder: (context, snapshot) {
                        final items = snapshot.data ?? [];
                        if (items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  'No PDFs downloaded yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Download materials to get started',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2196F3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${(item.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFFF5722),
                                    ),
                                    onPressed: () async {
                                      await _pdfService.deletePdf(item.filePath);
                                      setState(() {});
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      color: Color(0xFF2196F3),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).pushNamed(
                                        ClassroomScreen.routeName,
                                        arguments: ClassroomArgs(
                                          audioStreamUrl:
                                              'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service',
                                          initialPdfPath: item.filePath,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    final String hh = two(dt.hour % 12 == 0 ? 12 : dt.hour % 12);
    final String mm = two(dt.minute);
    final String ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hh:$mm $ampm';
  }

  Future<int?> _pickOvernightHour(BuildContext context) async {
    // Show a simple bottom sheet with hour options 22..23 and 0..5
    final options = <int>[22, 23, 0, 1, 2, 3, 4, 5];
    return showModalBottomSheet<int>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Choose download hour', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ...options.map((h) => ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text(_format24h(h)),
                    onTap: () => Navigator.pop(ctx, h),
                  )),
            ],
          ),
        );
      },
    );
  }

  String _format24h(int h) {
    final dt = DateTime(2020, 1, 1, h);
    return _formatTime(dt);
  }
}
