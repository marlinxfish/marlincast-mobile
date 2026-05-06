import 'rust_adblock_bindings.dart';

abstract class AdBlockEngine {
  Future<bool> shouldBlock({
    required Uri url,
    required Uri sourceUrl,
    String requestType,
  });
}

class RustAdBlockEngine implements AdBlockEngine {
  RustAdBlockEngine({RustAdBlockBindings? bindings})
    : _bindings = bindings ?? RustAdBlockBindings.tryLoad();

  final RustAdBlockBindings? _bindings;

  bool get isAvailable => _bindings != null;

  @override
  Future<bool> shouldBlock({
    required Uri url,
    required Uri sourceUrl,
    String requestType = 'other',
  }) async {
    if (requestType == 'image' && _isFirstParty(url: url, sourceUrl: sourceUrl)) {
      return false;
    }

    final bindings = _bindings;
    if (bindings == null) {
      return false;
    }

    return bindings.shouldBlock(
      url: url,
      sourceUrl: sourceUrl,
      requestType: requestType,
    );
  }
}

bool _isFirstParty({required Uri url, required Uri sourceUrl}) {
  final host = url.host.toLowerCase();
  final sourceHost = sourceUrl.host.toLowerCase();
  return host == sourceHost || host.endsWith('.$sourceHost');
}

class RuleBasedAdBlockEngine implements AdBlockEngine {
  static const _blockedHosts = [
    'doubleclick.net',
    'googlesyndication.com',
    'google-analytics.com',
    'adservice.google.com',
    'adnxs.com',
    'popads.net',
  ];

  static const _blockedPathTerms = [
    '/ads/',
    '/ad/',
    'popunder',
    'prebid',
  ];

  @override
  Future<bool> shouldBlock({
    required Uri url,
    required Uri sourceUrl,
    String requestType = 'other',
  }) async {
    if (requestType == 'image') {
      return _blockedHosts.any(url.host.toLowerCase().endsWith);
    }

    final host = url.host.toLowerCase();
    final path = url.path.toLowerCase();

    return _blockedHosts.any(host.endsWith) ||
        _blockedPathTerms.any(path.contains);
  }
}
