class BrowserUrlResolver {
  static Uri resolve(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return Uri.parse('https://www.google.com');
    }

    if (_hasScheme(trimmed)) {
      return Uri.parse(trimmed);
    }

    if (_looksLikeDomain(trimmed)) {
      return Uri.parse('https://$trimmed');
    }

    return Uri.https('www.google.com', '/search', {'q': trimmed});
  }

  static bool _hasScheme(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _looksLikeDomain(String value) {
    if (value.contains(' ')) {
      return false;
    }

    final host = value.split('/').first;
    return host.contains('.') || host == 'localhost';
  }
}
