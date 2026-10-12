import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'report_attachment.dart';

typedef AttachmentDirectoryProvider = Future<Directory> Function();
typedef AttachmentIdFactory = String Function();

abstract class AttachmentStorage {
  Future<ReportAttachment> persistImage({
    required String reportId,
    required String originalName,
    required Uint8List bytes,
  });

  Future<void> delete(ReportAttachment attachment);
}

class LocalAttachmentStorage implements AttachmentStorage {
  LocalAttachmentStorage({
    AttachmentDirectoryProvider? documentsDirectoryProvider,
    AttachmentIdFactory? idFactory,
  })  : _documentsDirectoryProvider =
            documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
        _idFactory = idFactory ?? const Uuid().v4;

  final AttachmentDirectoryProvider _documentsDirectoryProvider;
  final AttachmentIdFactory _idFactory;

  @override
  Future<ReportAttachment> persistImage({
    required String reportId,
    required String originalName,
    required Uint8List bytes,
  }) async {
    final root = await _managedRoot();
    final reportDirectory = Directory(
      p.join(root.path, _safeSegment(reportId), 'attachments'),
    );
    await reportDirectory.create(recursive: true);

    final id = _safeSegment(_idFactory());
    final extension = _safeExtension(originalName);
    final file = File(p.join(reportDirectory.path, '$id$extension'));
    await file.writeAsBytes(bytes, flush: true);

    return ReportAttachment(
      id: id,
      localPath: file.path,
      originalName: _displayName(originalName),
      caption: '',
      managedLocalFile: true,
    );
  }

  @override
  Future<void> delete(ReportAttachment attachment) async {
    if (!attachment.managedLocalFile || attachment.localPath.isEmpty) {
      return;
    }

    final root = await _managedRoot();
    final rootPath = p.normalize(p.absolute(root.path));
    final candidatePath = p.normalize(p.absolute(attachment.localPath));

    if (!p.isWithin(rootPath, candidatePath)) {
      throw StateError(
        'Refusing to delete attachment outside managed local storage.',
      );
    }

    final file = File(candidatePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Directory> _managedRoot() async {
    final documents = await _documentsDirectoryProvider();
    return Directory(
      p.join(documents.path, 'grupo_sucuarana', 'reports'),
    );
  }

  String _safeSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    return sanitized.isEmpty ? 'item' : sanitized;
  }

  String _safeExtension(String originalName) {
    final extension = p.extension(originalName);
    if (RegExp(r'^\.[A-Za-z0-9]{1,10}$').hasMatch(extension)) {
      return extension.toLowerCase();
    }
    return '.bin';
  }

  String _displayName(String originalName) {
    final name = p.basename(originalName.trim());
    return name.isEmpty ? 'imagem' : name;
  }
}
