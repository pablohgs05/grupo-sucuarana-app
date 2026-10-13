import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Prepare an image for an A4 annex without touching the stored original.
///
/// Large images are decoded/resized in a background isolate on Android.
/// Small files are used as-is to avoid unnecessary quality loss.
/// Transparency is retained for PNG images with an alpha channel.
Future<Uint8List> optimizePdfImage(
  Uint8List bytes, {
  int maxDimension = 1800,
  int minBytes = 700 * 1024,
}) async {
  if (bytes.lengthInBytes < minBytes) return bytes;
  if (maxDimension <= 0 || minBytes < 0) {
    throw ArgumentError('Image optimization bounds must be positive.');
  }

  try {
    return await compute(
      _optimizePdfImageInIsolate,
      (bytes: bytes, maxDimension: maxDimension),
    );
  } catch (_) {
    // An optimization failure must not remove a valid field attachment.
    return bytes;
  }
}

Uint8List _optimizePdfImageInIsolate(
  ({Uint8List bytes, int maxDimension}) input,
) {
  final image = img.decodeImage(input.bytes);
  if (image == null) return input.bytes;

  final largest = math.max(image.width, image.height);
  final target = largest > input.maxDimension
      ? (image.width >= image.height
          ? img.copyResize(
              image,
              width: input.maxDimension,
              interpolation: img.Interpolation.linear,
            )
          : img.copyResize(
              image,
              height: input.maxDimension,
              interpolation: img.Interpolation.linear,
            ))
      : image;

  final isPng = input.bytes.length >= 8 &&
      input.bytes[0] == 0x89 &&
      input.bytes[1] == 0x50 &&
      input.bytes[2] == 0x4E &&
      input.bytes[3] == 0x47;

  final optimized = isPng && target.hasAlpha
      ? img.encodePng(target, level: 6)
      : img.encodeJpg(target, quality: 78);

  if (optimized.length >= input.bytes.length) return input.bytes;
  return Uint8List.fromList(optimized);
}
