import 'dart:async';

import 'package:flutter/material.dart';

import '../services/audio_service.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_viewer.dart';
import '../widgets/data_wallet.dart';

class ClassroomArgs {
  final String audioStreamUrl;
  final String? initialPdfPath;
  const ClassroomArgs({required this.audioStreamUrl, this.initialPdfPath});
}

class ClassroomScreen extends StatefulWidget {
  static const String routeName = '/classroom';
  final ClassroomArgs? args;
  const ClassroomScreen({super.key, this.args});

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  late final AudioStreamingService _audioService;
  late final PdfService _pdfService;
  StreamSubscription<DataUsageSnapshot>? _usageSub;
  DataUsageSnapshot? _usage;
  String? _pdfPath;
  bool _isRecording = false;
  List<String> _recordings = [];

  @override
  void initState() {
    super.initState();
    _audioService = AudioStreamingService();
    _pdfService = PdfService();
    _pdfPath = widget.args?.initialPdfPath;
    // Auto-pick most recent PDF if none provided
    if (_pdfPath == null) {
      _pdfService.listDownloadedPdfs().then((list) {
        if (list.isNotEmpty && mounted) {
          setState(() => _pdfPath = list.first.filePath);
        }
      });
    }
    _usageSub = _audioService.dataUsageStream.listen((e) {
      setState(() => _usage = e);
    });
    _audioService.recordingStream.listen((isRec) {
      setState(() => _isRecording = isRec);
    });
    _refreshRecordings();
  }

  @override
  void dispose() {
    _usageSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String streamUrl = widget.args?.audioStreamUrl ?? 'https://stream.live.vc.bbcmedia.co.uk/bbc_world_service';
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Live Class',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Pick PDF',
            onPressed: () async {
              final list = await _pdfService.listDownloadedPdfs();
              if (!mounted) return;
              if (list.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No PDFs available. Download from dashboard.')),
                );
                return;
              }
              final selected = await showModalBottomSheet<LocalPdf>(
                context: context,
                builder: (ctx) => ListView(
                  children: list
                      .map((e) => ListTile(
                            title: Text(e.title),
                            subtitle: Text('${(e.sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB'),
                            onTap: () => Navigator.pop(ctx, e),
                          ))
                      .toList(),
                ),
              );
              if (selected != null) {
                setState(() => _pdfPath = selected.filePath);
              }
            },
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 700;
          final sidePanel = Container(
            width: isNarrow ? double.infinity : 320,
            decoration: BoxDecoration(
              border: isNarrow
                  ? Border(top: BorderSide(color: Colors.grey.shade300))
                  : Border(left: BorderSide(color: Colors.grey.shade300)),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Audio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      ElevatedButton.icon(
                        onPressed: () => _audioService.startStreaming(streamUrl),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _audioService.pause,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pause'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _audioService.stop,
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final saved = await _audioService.toggleRecording();
                          if (!mounted) return;
                          if (saved == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Recording started...')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Saved recording: ${saved.split('/').last}')),
                            );
                            await _refreshRecordings();
                          }
                        },
                        icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
                        label: Text(_isRecording ? 'Stop & Save' : 'Record'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording ? Colors.red : null,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    const Text('Data Wallet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    DataWallet(snapshot: _usage),
                    const SizedBox(height: 16),
                    const Text('Recordings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (_recordings.isEmpty)
                      const Text('No recordings yet.')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recordings.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final path = _recordings[index];
                          final name = path.split('/').last;
                          return ListTile(
                            title: Text(name),
                            trailing: Wrap(spacing: 8, children: [
                              IconButton(
                                icon: const Icon(Icons.play_arrow),
                                onPressed: () => _audioService.playLocal(path),
                                tooltip: 'Play',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  await _audioService.deleteRecording(path);
                                  if (!mounted) return;
                                  await _refreshRecordings();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Deleted $name')),
                                  );
                                },
                              ),
                            ]),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );

          final Widget pdfContent = _pdfPath == null
              ? const Center(child: Text('Select a PDF'))
              : PdfViewer(path: _pdfPath!);

          if (isNarrow) {
            return Column(
              children: [
                SizedBox(height: 300, child: pdfContent),
                Expanded(child: sidePanel),
              ],
            );
          }
          return Row(children: [Expanded(child: pdfContent), sidePanel]);
        },
      ),
    );
  }

  Future<void> _refreshRecordings() async {
    final files = await _audioService.listRecordings();
    setState(() => _recordings = files.map((e) => e.path).toList());
  }
}


