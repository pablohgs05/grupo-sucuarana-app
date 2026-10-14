import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:grupo_sucuarana_app/pdf/report_pdf_images.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('reduz JPEG de alta resolução preservando original', () async {
    final source = img.Image(width: 640, height: 420);
    for (final pixel in source) {
      pixel
        ..r = (pixel.x * 11 + pixel.y * 7) % 256
        ..g = (pixel.x * 17 + pixel.y * 3) % 256
        ..b = (pixel.x * 5 + pixel.y * 19) % 256;
    }

    final original = Uint8List.fromList(img.encodeJpg(source, quality: 95));
    final optimized = await optimizePdfImage(
      original,
      maxDimension: 240,
      minBytes: 0,
    );

    final decoded = img.decodeImage(optimized);
    expect(decoded, isNotNull);
    expect(decoded!.width, 240);
    expect(decoded.height, lessThanOrEqualTo(240));
    expect(optimized.lengthInBytes, lessThan(original.lengthInBytes));

    final stored = img.decodeImage(original)!;
    expect(stored.width, 640);
    expect(stored.height, 420);
  });

  test('preserva PNG com transparência durante redução', () async {
    final source = img.Image(width: 500, height: 320, numChannels: 4);
    for (final pixel in source) {
      pixel
        ..r = (pixel.x * 17 + pixel.y * 11) % 256
        ..g = (pixel.x * 3 + pixel.y * 23) % 256
        ..b = (pixel.x * 29 + pixel.y * 7) % 256
        ..a = (pixel.x + pixel.y) % 5 == 0 ? 0 : 255;
    }
    final original = Uint8List.fromList(img.encodePng(source));
    final optimized = await optimizePdfImage(
      original,
      maxDimension: 200,
      minBytes: 0,
    );

    final decoded = img.decodeImage(optimized);
    expect(decoded, isNotNull);
    expect(decoded!.width, 200);
    expect(decoded.hasAlpha, isTrue);
    expect(optimized.lengthInBytes, lessThan(original.lengthInBytes));
  });

  test('não reprocessa arquivos pequenos', () async {
    final original = Uint8List.fromList(<int>[1, 2, 3, 4]);
    final result = await optimizePdfImage(original);
    expect(identical(result, original), isTrue);
  });
}
