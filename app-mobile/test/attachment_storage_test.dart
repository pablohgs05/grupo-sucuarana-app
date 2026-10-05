import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/attachment_storage.dart';
import 'package:grupo_sucuarana_app/report_attachment.dart';

void main() {
  late Directory tempDirectory;

  setUp(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('attachment_storage_test_');
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('persists image bytes under managed report storage', () async {
    final storage = LocalAttachmentStorage(
      documentsDirectoryProvider: () async => tempDirectory,
      idFactory: () => 'attachment-001',
    );
    final bytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

    final attachment = await storage.persistImage(
      reportId: 'report-test-001',
      originalName: 'imagem-ficticia.JPG',
      bytes: bytes,
    );

    expect(attachment.id, 'attachment-001');
    expect(attachment.originalName, 'imagem-ficticia.JPG');
    expect(attachment.caption, isEmpty);
    expect(attachment.managedLocalFile, isTrue);
    expect(
      attachment.localPath,
      contains('grupo_sucuarana${Platform.pathSeparator}reports'),
    );

    final persisted = File(attachment.localPath);
    expect(await persisted.exists(), isTrue);
    expect(await persisted.readAsBytes(), bytes);

    await storage.delete(attachment);
    expect(await persisted.exists(), isFalse);
  });

  test('does not delete legacy or unmanaged attachment paths', () async {
    final storage = LocalAttachmentStorage(
      documentsDirectoryProvider: () async => tempDirectory,
      idFactory: () => 'unused',
    );
    final external = File(
      '${tempDirectory.path}${Platform.pathSeparator}external-ficticio.jpg',
    );
    await external.writeAsBytes(<int>[7, 8, 9]);

    await storage.delete(
      ReportAttachment(
        id: 'legacy-0',
        localPath: external.path,
        originalName: 'external-ficticio.jpg',
        caption: '',
        managedLocalFile: false,
      ),
    );

    expect(await external.exists(), isTrue);
  });

  test('refuses managed deletion outside app attachment root', () async {
    final storage = LocalAttachmentStorage(
      documentsDirectoryProvider: () async => tempDirectory,
      idFactory: () => 'unused',
    );
    final external = File(
      '${tempDirectory.path}${Platform.pathSeparator}outside-ficticio.jpg',
    );
    await external.writeAsBytes(<int>[4, 5, 6]);

    await expectLater(
      storage.delete(
        ReportAttachment(
          id: 'unsafe',
          localPath: external.path,
          originalName: 'outside-ficticio.jpg',
          caption: '',
          managedLocalFile: true,
        ),
      ),
      throwsA(isA<StateError>()),
    );

    expect(await external.exists(), isTrue);
  });
}
