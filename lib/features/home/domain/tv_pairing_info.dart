class TvPairingInfo {
  const TvPairingInfo({
    required this.host,
    required this.port,
    required this.token,
  });

  final String host;
  final int port;
  final String token;

  String get address => '$host:$port';
  Uri get websocketUri => Uri.parse('ws://$address?token=$token');

  static TvPairingInfo? parse(String value) {
    final uri = Uri.tryParse(value.contains('://') ? value : 'http://$value');
    if (uri == null || uri.host.isEmpty) {
      return null;
    }

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) {
      return null;
    }

    return TvPairingInfo(
      host: uri.host,
      port: uri.hasPort ? uri.port : 8080,
      token: token,
    );
  }
}
