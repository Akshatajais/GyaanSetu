import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class DataUsageSnapshot {
  final int totalBytes;
  final double bytesPerMinute;
  final double recentUtilization01;

  DataUsageSnapshot({required this.totalBytes, required this.bytesPerMinute, required this.recentUtilization01});
}

class AudioStreamingService {
  final AudioPlayer _player = AudioPlayer();
  final Dio _dio = Dio();

  final StreamController<DataUsageSnapshot> _usageCtrl = StreamController.broadcast();
  Stream<DataUsageSnapshot> get dataUsageStream => _usageCtrl.stream;

  final StreamController<bool> _recordingCtrl = StreamController<bool>.broadcast();
  Stream<bool> get recordingStream => _recordingCtrl.stream;

  Timer? _usageTimer;
  int _bytesSinceLast = 0;
  int _totalBytes = 0;
  DateTime _lastTick = DateTime.now();

  bool _isRecording = false;
  IOSink? _recordSink;
  File? _recordFile;
  String? _lastRecordingPath;

  bool get isRecording => _isRecording;
  String? get lastRecordingPath => _lastRecordingPath;

  Future<void> _configureSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> startStreaming(String url) async {
    await _configureSession();
    await _player.setUrl(url);
    _player.play();
    _startUsageTicker();
    _startByteCounting(url);
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
    _stopUsageTicker();
  }

  void _startUsageTicker() {
    _lastTick = DateTime.now();
    _usageTimer?.cancel();
    _usageTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final now = DateTime.now();
      final seconds = now.difference(_lastTick).inSeconds;
      _lastTick = now;
      final double perMinute = seconds == 0 ? 0 : (_bytesSinceLast * 60 / seconds);
      final double util = perMinute / (64 * 1024); // normalize against ~64KB/min baseline
      _usageCtrl.add(DataUsageSnapshot(totalBytes: _totalBytes, bytesPerMinute: perMinute, recentUtilization01: util));
      _bytesSinceLast = 0;
    });
  }

  void _stopUsageTicker() {
    _usageTimer?.cancel();
    _usageTimer = null;
  }

  CancelToken? _streamCancel;
  Future<void> _startByteCounting(String url) async {
    _streamCancel?.cancel();
    _streamCancel = CancelToken();
    try {
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream, followRedirects: true),
        cancelToken: _streamCancel,
      );
      await for (final chunk in response.data!.stream) {
        final int bytes = chunk.length;
        _bytesSinceLast += bytes;
        _totalBytes += bytes;
        if (_isRecording && _recordSink != null) {
          _recordSink!.add(chunk);
        }
      }
    } catch (_) {
      // Swallow errors silently for counting stream
    }
  }

  Future<String?> toggleRecording() async {
    if (_isRecording) {
      await _recordSink?.flush();
      await _recordSink?.close();
      _recordSink = null;
      _isRecording = false;
      _recordingCtrl.add(false);
      return _lastRecordingPath;
    }
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final String filePath = '${audioDir.path}/class_${DateTime.now().millisecondsSinceEpoch}.mp3';
    _recordFile = File(filePath);
    _recordSink = _recordFile!.openWrite();
    _isRecording = true;
    _lastRecordingPath = filePath;
    _recordingCtrl.add(true);
    return null;
  }

  Future<List<File>> listRecordings() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory audioDir = Directory('${dir.path}/audio');
    if (!await audioDir.exists()) return [];
    final entities = await audioDir.list().toList();
    final files = entities.whereType<File>().where((f) => f.path.toLowerCase().endsWith('.mp3')).toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  Future<void> playLocal(String filePath) async {
    await _player.stop();
    _stopUsageTicker();
    await _player.setFilePath(filePath);
    await _player.play();
  }

  Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  void dispose() {
    _streamCancel?.cancel();
    _stopUsageTicker();
    _player.dispose();
    _usageCtrl.close();
    _recordingCtrl.close();
  }
}


