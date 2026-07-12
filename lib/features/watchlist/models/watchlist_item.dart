class WatchlistItem {
  const WatchlistItem({
    required this.id,
    required this.mediaType,
    required this.accountStatus,
    this.watchlistedAt,
    this.watchedAt,
    this.rating,
  });

  final int id;
  final String mediaType;
  final String accountStatus;
  final DateTime? watchlistedAt;
  final DateTime? watchedAt;
  final double? rating;

  factory WatchlistItem.fromJson(Map<String, dynamic> json) {
    return WatchlistItem(
      id: json['id'] as int,
      mediaType: json['media_type'] as String? ?? '',
      accountStatus: json['account_status'] as String? ?? '',
      watchlistedAt: switch (json['watchlisted_at']) {
        String value => DateTime.tryParse(value),
        _ => null,
      },
      watchedAt: switch (json['watched_at']) {
        String value => DateTime.tryParse(value),
        _ => null,
      },
      rating: switch (json['rating']) {
        num value => value.toDouble(),
        _ => null,
      },
    );
  }
}
