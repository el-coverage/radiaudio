String fileNameFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.split('/').last;
}

String? directoryPathFromPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final splitIndex = normalized.lastIndexOf('/');
  if (splitIndex <= 0) return null;
  return normalized.substring(0, splitIndex);
}

String normalizedPathKey(String path) {
  return path.replaceAll('\\', '/').toLowerCase();
}
