// Stub implementation for non-web platforms.
// This file is used when `dart:html` is not available.

Future<bool> openUrl(String url) async {
  // Not supported on non-web here; return false so caller can fallback.
  return false;
}
