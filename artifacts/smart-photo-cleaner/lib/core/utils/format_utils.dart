/// Shared formatting utilities used across the app.
class FormatUtils {
  FormatUtils._();

  /// Format bytes into a human-readable string.
  static String formatBytes(int bytes) {
    if (bytes < 1024)         return '$bytes B';
    if (bytes < 1048576)      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824)   return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  /// Format a DateTime as a readable date string.
  static String formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7)  return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} weeks ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} months ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  /// Format a quality score [0–1] as a percentage string.
  static String formatScore(double score) => '${(score * 100).toInt()}%';
}
