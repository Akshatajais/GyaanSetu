import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class LocalPdf {
  final String title;
  final String filePath;
  final int sizeBytes;
  LocalPdf({required this.title, required this.filePath, required this.sizeBytes});
}

class PdfService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 30)));

  Future<Directory> _getPdfDir() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory pdfDir = Directory('${dir.path}/pdfs');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    return pdfDir;
  }

  Future<List<LocalPdf>> listDownloadedPdfs() async {
    final Directory dir = await _getPdfDir();
    final List<FileSystemEntity> files = await dir.list().toList();
    final List<LocalPdf> result = [];
    for (final fse in files) {
      if (fse is File && fse.path.toLowerCase().endsWith('.pdf')) {
        final String name = fse.uri.pathSegments.last;
        final int size = await fse.length();
        result.add(LocalPdf(title: name, filePath: fse.path, sizeBytes: size));
      }
    }
    result.sort((a, b) => a.title.compareTo(b.title));
    return result;
  }

  Future<String> downloadAndSavePdf({required String url, required String title}) async {
    final Directory pdfDir = await _getPdfDir();
    final String sanitized = title.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '').replaceAll(' ', '_');
    final String filePath = '${pdfDir.path}/$sanitized.pdf';
    final File outFile = File(filePath);
    if (await outFile.exists()) {
      await outFile.delete();
    }
    final Response<void> resp = await _dio.download(url, filePath, options: Options(responseType: ResponseType.bytes));
    if (resp.statusCode != 200) {
      throw Exception('Failed to download PDF');
    }
    return filePath;
  }

  Future<void> deletePdf(String filePath) async {
    final File f = File(filePath);
    if (await f.exists()) {
      await f.delete();
    }
  }
}


