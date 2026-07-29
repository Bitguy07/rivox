import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Extracts a global image descriptor based on color histograms.
///
/// Divides the image into an NxN grid and computes an RGB color
/// histogram for each cell. All histograms are concatenated and
/// L2-normalized into a compact descriptor vector for image retrieval.
class DescriptorExtractor {
  static const int gridN = 4;
  static const int binsPerChannel = 8;

  /// Extract a global descriptor from raw image bytes (JPEG/PNG).
  ///
  /// Returns a normalized Float32List of length gridN² × 3 × binsPerChannel.
  static Float32List extractGlobalDescriptor(List<int> imageBytes) {
    final image = img.decodeImage(Uint8List.fromList(imageBytes));
    if (image == null) return Float32List(0);

    final cellWidth = image.width ~/ gridN;
    final cellHeight = image.height ~/ gridN;

    final descriptorLength = gridN * gridN * 3 * binsPerChannel;
    final descriptor = Float32List(descriptorLength);

    int descIndex = 0;

    for (int r = 0; r < gridN; r++) {
      for (int c = 0; c < gridN; c++) {
        final histR = List<double>.filled(binsPerChannel, 0);
        final histG = List<double>.filled(binsPerChannel, 0);
        final histB = List<double>.filled(binsPerChannel, 0);

        final startX = c * cellWidth;
        final startY = r * cellHeight;

        for (int y = startY; y < startY + cellHeight && y < image.height; y++) {
          for (int x = startX; x < startX + cellWidth && x < image.width; x++) {
            final pixel = image.getPixel(x, y);

            final rVal = pixel.r.toInt();
            final gVal = pixel.g.toInt();
            final bVal = pixel.b.toInt();

            histR[(rVal ~/ (256 ~/ binsPerChannel)).clamp(0, binsPerChannel - 1)] += 1.0;
            histG[(gVal ~/ (256 ~/ binsPerChannel)).clamp(0, binsPerChannel - 1)] += 1.0;
            histB[(bVal ~/ (256 ~/ binsPerChannel)).clamp(0, binsPerChannel - 1)] += 1.0;
          }
        }

        for (int i = 0; i < binsPerChannel; i++) {
          descriptor[descIndex++] = histR[i];
        }
        for (int i = 0; i < binsPerChannel; i++) {
          descriptor[descIndex++] = histG[i];
        }
        for (int i = 0; i < binsPerChannel; i++) {
          descriptor[descIndex++] = histB[i];
        }
      }
    }

    // L2 normalize
    double sumSq = 0;
    for (int i = 0; i < descriptorLength; i++) {
      sumSq += descriptor[i] * descriptor[i];
    }

    if (sumSq > 0) {
      final norm = math.sqrt(sumSq);
      for (int i = 0; i < descriptorLength; i++) {
        descriptor[i] /= norm;
      }
    }

    return descriptor;
  }
}
