class CastCommand {
  const CastCommand.directPlay({required this.url}) : type = 'DIRECT_PLAY';

  final String type;
  final Uri url;

  Map<String, Object> toJson() {
    return {
      'cmd': type,
      'url': url.toString(),
    };
  }
}
