import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizService {
  QuizService({Dio? client, String? baseUrl})
      : _client = client ?? Dio(),
        _baseUrl = baseUrl ?? const String.fromEnvironment('QUIZ_API_BASE_URL', defaultValue: '') {
    _resolvedBase = _baseUrl.isNotEmpty ? _baseUrl : _detectDefaultBaseUrl();
    _client.options = BaseOptions(
      baseUrl: '$_resolvedBase/api',
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 6),
      sendTimeout: const Duration(seconds: 6),
    );
    // Debug output
    debugPrint('[QuizService] baseUrl=${_client.options.baseUrl}');
  }

  final Dio _client;
  final String _baseUrl;
  String _resolvedBase = '';

  String get resolvedBaseUrl => _resolvedBase;

  static const String _pendingKey = 'quiz_pending_queue_v1';
  static String _quizCacheKey(String quizId) => 'quiz_cache_v1_$quizId';

  Future<Map<String, dynamic>> fetchQuiz(String quizId) async {
    try {
      final resp = await _client.get('/quizzes/$quizId');
      final data = Map<String, dynamic>.from(resp.data as Map);
      await _saveQuizCache(quizId, data);
      return data;
    } catch (e) {
      debugPrint('[QuizService] fetchQuiz error: $e');
      final cached = await _loadQuizCache(quizId);
      if (cached != null) return cached;
      // Fallback: return a small demo quiz so the screen is not empty
      final demo = _demoQuiz(quizId);
      await _saveQuizCache(quizId, demo);
      return demo;
    }
  }

  Future<void> downloadQuizForOffline(String quizId) async {
    try {
      final data = await _client.get('/quizzes/$quizId');
      await _saveQuizCache(quizId, Map<String, dynamic>.from(data.data as Map));
    } catch (e) {
      // If server unavailable, save demo quiz instead
      debugPrint('[QuizService] downloadQuizForOffline fallback demo: $e');
      await _saveQuizCache(quizId, _demoQuiz(quizId));
    }
  }

  Future<Map<String, dynamic>?> loadOfflineQuiz(String quizId) async {
    return _loadQuizCache(quizId);
  }

  Future<void> submitResponse({
    required String quizId,
    required String studentId,
    required String questionId,
    required int selectedIndex,
  }) async {
    final payload = {
      'studentId': studentId,
      'questionId': questionId,
      'selectedIndex': selectedIndex,
    };
    if (await _isOnline()) {
      try {
        await _client.post('/quizzes/$quizId/respond', data: payload);
        return;
      } catch (_) {
        // fall through to queue
      }
    }
    await _enqueue({'type': 'respond', 'quizId': quizId, 'body': payload});
  }

  Future<Map<String, dynamic>> completeQuiz({
    required String quizId,
    required String studentId,
  }) async {
    final payload = {'studentId': studentId};
    if (await _isOnline()) {
      try {
        final resp = await _client.post('/quizzes/$quizId/complete', data: payload);
        return Map<String, dynamic>.from(resp.data as Map);
      } catch (_) {
        // queue and return placeholder
      }
    }
    await _enqueue({'type': 'complete', 'quizId': quizId, 'body': payload});
    return {'message': 'queued_offline', 'total': 0, 'correct': 0, 'percentage': 0};
  }

  Future<void> flushQueue() async {
    if (!await _isOnline()) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return;
    final List list = jsonDecode(raw) as List;
    final queue = List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e as Map)));
    final remaining = <Map<String, dynamic>>[];
    for (final item in queue) {
      try {
        if (item['type'] == 'respond') {
          await _client.post('/quizzes/${item['quizId']}/respond', data: item['body']);
        } else if (item['type'] == 'complete') {
          await _client.post('/quizzes/${item['quizId']}/complete', data: item['body']);
        }
      } catch (_) {
        remaining.add(item);
      }
    }
    if (remaining.isEmpty) {
      await prefs.remove(_pendingKey);
    } else {
      await prefs.setString(_pendingKey, jsonEncode(remaining));
    }
  }

  Future<void> _enqueue(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    final List list = raw == null || raw.isEmpty ? [] : (jsonDecode(raw) as List);
    list.add(item);
    await prefs.setString(_pendingKey, jsonEncode(list));
  }

  Future<void> _saveQuizCache(String quizId, Map<String, dynamic> quiz) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quizCacheKey(quizId), jsonEncode(quiz));
  }

  Future<Map<String, dynamic>?> _loadQuizCache(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_quizCacheKey(quizId));
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Map<String, dynamic> _demoQuiz(String quizId) {
    return {
      'quizId': quizId,
      'title': 'Sample Quiz',
      'questions': [
        {
          'questionId': 'q1',
          'prompt': 'Which data structure uses FIFO order?',
          'options': ['Stack', 'Queue', 'Tree', 'Graph'],
          'correct': 1,
        },
        {
          'questionId': 'q2',
          'prompt': 'HTTP is built on top of which protocol?',
          'options': ['TCP', 'UDP', 'ICMP', 'ARP'],
          'correct': 0,
        },
        {
          'questionId': 'q3',
          'prompt': 'Which SQL keyword is used to remove duplicate rows?',
          'options': ['GROUP BY', 'UNION', 'DISTINCT', 'HAVING'],
          'correct': 2,
        },
      ],
    };
  }

  String _detectDefaultBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:4000';
    }
    try {
      if (Platform.isAndroid) {
        // Android emulator special loopback
        return 'http://10.0.2.2:4000';
      }
      // iOS simulator, macOS, Windows, Linux
      return 'http://localhost:4000';
    } catch (_) {
      return 'http://localhost:4000';
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile) || result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.ethernet);
  }
}


