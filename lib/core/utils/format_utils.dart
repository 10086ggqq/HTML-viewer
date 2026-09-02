/// Relative-time formatting for recent lists ("3 分钟前").
String formatRelativeTime(DateTime time, DateTime now) {
  final diff = now.difference(time);
  if (diff.inSeconds < 45) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';
  final y = time.year == now.year ? '' : '${time.year}/';
  return '$y${time.month}/${time.day}';
}

/// Human-readable file size ("12.4 MB"); null stays as "—".
String formatFileSize(int? bytes) {
  if (bytes == null) return '—';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
