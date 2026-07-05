String _str(dynamic v) => v is String ? v : '';
String? _strOrNull(dynamic v) => v is String ? v : null;
int _int(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);

/// A single "watch provider" (streaming service) as returned by TMDB's
/// `GET /watch/providers/tv`. Persisted locally so future features can filter
/// or badge titles by the providers available in the user's region.
class WatchProvider {
  final int providerId;
  final String providerName;
  final String? logoPath;
  final int displayPriority;

  const WatchProvider({
    required this.providerId,
    required this.providerName,
    this.logoPath,
    required this.displayPriority,
  });

  factory WatchProvider.fromJson(Map<String, dynamic> json) {
    return WatchProvider(
      providerId: _int(json['provider_id']),
      providerName: _str(json['provider_name']),
      logoPath: _strOrNull(json['logo_path']),
      displayPriority: _int(json['display_priority']),
    );
  }

  Map<String, dynamic> toJson() => {
    'provider_id': providerId,
    'provider_name': providerName,
    'logo_path': logoPath,
    'display_priority': displayPriority,
  };
}
