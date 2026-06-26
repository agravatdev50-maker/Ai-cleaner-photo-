import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Implements perceptual hashing (pHash / dHash) entirely on-device.
/// No network calls — all computation happens in isolates on the device CPU.
///
/// Algorithm:
///  1. Resize image to 32×32 (configurable) grayscale.
///  2. Compute DCT (Discrete Cosine Transform) over the image.
///  3. Take the top-left 8×8 sub-image of DCT coefficients.
///  4. Compare each coefficient to the median — bit = 1 if above, 0 if below.
///  5. Pack 64 bits into a hex string.
///
/// Two images with Hamming distance ≤ 6 are considered exact duplicates.
/// Two images with Hamming distance ≤ 14 are considered similar.
class PerceptualHashService {
  static const int _hashSize = 8;   // 8×8 = 64-bit hash
  static const int _dctSize  = 32;  // resize target before DCT

  /// Compute pHash for raw image bytes.
  /// Returns a 16-character hex string (64 bits).
  Future<String> computeHash(Uint8List imageBytes) async {
    try {
      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) return '';

      // Step 1: Convert to grayscale and resize to 32×32
      final resized = img.copyResize(
        img.grayscale(image),
        width: _dctSize,
        height: _dctSize,
        interpolation: img.Interpolation.average,
      );

      // Step 2: Build 2D pixel matrix
      final pixels = List.generate(
        _dctSize,
        (y) => List.generate(
          _dctSize,
          (x) => img.getLuminance(resized.getPixel(x, y)).toDouble(),
        ),
      );

      // Step 3: Compute 2D DCT
      final dct = _dct2d(pixels);

      // Step 4: Extract top-left 8×8
      final topLeft = <double>[];
      for (int y = 0; y < _hashSize; y++) {
        for (int x = 0; x < _hashSize; x++) {
          topLeft.add(dct[y][x]);
        }
      }

      // Remove DC component (index 0) — it's dominated by overall brightness
      final withoutDC = topLeft.sublist(1);
      final median = _median(withoutDC);

      // Step 5: Build bit string
      final bits = topLeft.map((v) => v > median ? 1 : 0).toList();

      // Step 6: Pack into hex
      return _bitsToHex(bits);
    } catch (e) {
      return '';
    }
  }

  /// Compute difference hash (dHash) — faster and good for detecting resized copies.
  Future<String> computeDHash(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return '';

      // Resize to 9×8 — compare adjacent pixels horizontally → 64 bits
      final resized = img.copyResize(
        img.grayscale(image),
        width: 9,
        height: 8,
        interpolation: img.Interpolation.average,
      );

      final bits = <int>[];
      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left  = img.getLuminance(resized.getPixel(x, y));
          final right = img.getLuminance(resized.getPixel(x + 1, y));
          bits.add(left > right ? 1 : 0);
        }
      }

      return _bitsToHex(bits);
    } catch (e) {
      return '';
    }
  }

  /// Compute Hamming distance between two hex hash strings.
  /// Lower = more similar. Returns -1 if hashes have different lengths.
  static int hammingDistance(String hash1, String hash2) {
    if (hash1.isEmpty || hash2.isEmpty) return 64;
    if (hash1.length != hash2.length)   return 64;

    int distance = 0;
    for (int i = 0; i < hash1.length; i += 2) {
      final b1 = int.parse(hash1.substring(i, i + 2), radix: 16);
      final b2 = int.parse(hash2.substring(i, i + 2), radix: 16);
      distance += _popcount(b1 ^ b2);
    }
    return distance;
  }

  // ── DCT implementation ────────────────────────────────────────────────────

  /// 2D Discrete Cosine Transform (Type II, un-normalized).
  List<List<double>> _dct2d(List<List<double>> matrix) {
    final n = matrix.length;
    final m = matrix[0].length;

    // Apply 1D DCT to each row
    final rowDct = matrix.map(_dct1d).toList();

    // Transpose
    final transposed = List.generate(
      m,
      (i) => List.generate(n, (j) => rowDct[j][i]),
    );

    // Apply 1D DCT to each column (now row after transpose)
    final colDct = transposed.map(_dct1d).toList();

    // Transpose back
    return List.generate(
      n,
      (i) => List.generate(m, (j) => colDct[j][i]),
    );
  }

  /// 1D DCT Type II.
  List<double> _dct1d(List<double> x) {
    final n = x.length;
    final result = List<double>.filled(n, 0);
    for (int k = 0; k < n; k++) {
      double sum = 0;
      for (int i = 0; i < n; i++) {
        sum += x[i] * math.cos(math.pi * k * (2 * i + 1) / (2 * n));
      }
      result[k] = sum;
    }
    return result;
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[mid]
        : (sorted[mid - 1] + sorted[mid]) / 2;
  }

  String _bitsToHex(List<int> bits) {
    final buffer = StringBuffer();
    for (int i = 0; i < bits.length; i += 8) {
      int byte = 0;
      for (int b = 0; b < 8 && i + b < bits.length; b++) {
        byte = (byte << 1) | bits[i + b];
      }
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Brian Kernighan's bit-counting algorithm.
  int _popcount(int n) {
    int count = 0;
    while (n > 0) {
      count += n & 1;
      n >>= 1;
    }
    return count;
  }
}
