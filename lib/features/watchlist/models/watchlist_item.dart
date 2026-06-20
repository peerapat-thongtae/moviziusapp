class WatchlistItem {
  const WatchlistItem({
    required this.id,
    required this.mediaType,
    required this.accountStatus,
    this.watchlistedAt,
    this.watchedAt,
  });

  final int id;
  final String mediaType;
  final String accountStatus;
  final DateTime? watchlistedAt;
  final DateTime? watchedAt;

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
    );
  }
}
