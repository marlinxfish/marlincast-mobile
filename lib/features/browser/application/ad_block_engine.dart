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
    if (requestType == 'image' && !_isKnownAdHost(url.host)) {
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

bool _isKnownAdHost(String host) {
  final normalizedHost = host.toLowerCase();
  return _knownAdHosts.any(normalizedHost.endsWith);
}

const _knownAdHosts = [
  'doubleclick.net',
  'googlesyndication.com',
  'adservice.google.com',
  'adnxs.com',
  'popads.net',
];

class RuleBasedAdBlockEngine implements AdBlockEngine {
  static const _blockedHosts = [
    ..._knownAdHosts,
    'google-analytics.com',
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
      return _isKnownAdHost(url.host);
    }

    final host = url.host.toLowerCase();
    final path = url.path.toLowerCase();

    return _blockedHosts.any(host.endsWith) ||
        _blockedPathTerms.any(path.contains);
  }
}
