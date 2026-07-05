import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_timezone.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/utils/episode_type_label.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/widgets/media_row_card.dart';
import '../../movies/models/movie_discover_response.dart';
import '../../series/models/tv_discover_response.dart';
import '../../watchlist/widgets/watchlist_icon_button.dart';
import '../providers/airing_today_provider.dart';
import '../providers/releasing_today_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Movies'),
            Tab(text: 'TV Series'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_MoviesTab(), _TvSeriesTab()],
      ),
    );
  }
}

class _MoviesTab extends ConsumerStatefulWidget {
  const _MoviesTab();

  @override
  ConsumerState<_MoviesTab> createState() => _MoviesTabState();
}

class _MoviesTabState extends ConsumerState<_MoviesTab> {
  static const _daysBefore = 2;
  static const _daysAfter = 5;

  final DateTime _today = DateTime.now();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(_today);
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dateAt(int offset) =>
      _normalize(_today).add(Duration(days: offset));

  List<DateTime> get _dates => [
    for (int i = -_daysBefore; i <= _daysAfter; i++) _dateAt(i),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateSlider(
          dates: _dates,
          today: _normalize(_today),
          selected: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        Expanded(child: _MoviesList(date: _selectedDate)),
      ],
    );
  }
}

class _MoviesList extends ConsumerWidget {
  const _MoviesList({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(releasingTodayProvider(date));
    final listPadding = EdgeInsets.fromLTRB(
      12,
      12,
      12,
      12 + MediaQuery.paddingOf(context).bottom,
    );

    return async.when(
      loading: () => ListView.separated(
        padding: listPadding,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => const MediaRowCardSkeleton(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load movies',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(releasingTodayProvider(date)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (movies) {
        if (movies.isEmpty) {
          return const Center(child: Text('No movies releasing on this date'));
        }
        return AppRefreshIndicator(
          onRefresh: () async => ref.invalidate(releasingTodayProvider(date)),
          child: ListView.separated(
            padding: listPadding,
            itemCount: movies.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _MovieCard(movie: movies[i]),
          ),
        );
      },
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});

  final Movie movie;

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final local = date.toUtc().add(kAppTimezoneOffset);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return MediaRowCard(
      posterPath: movie.posterPath,
      title: movie.title,
      voteAverage: movie.voteAverage,
      subtitleLine1: _formatDate(movie.effectiveReleaseDate),
      subtitleLine2: movie.genres.isNotEmpty ? movie.genres.first.name : null,
      trailing: WatchlistIconButton(id: movie.id, mediaType: 'movie'),
      onTap: () =>
          context.push(RoutePaths.movieDetailPath(movie.id), extra: movie),
    );
  }
}

class _TvSeriesTab extends ConsumerStatefulWidget {
  const _TvSeriesTab();

  @override
  ConsumerState<_TvSeriesTab> createState() => _TvSeriesTabState();
}

class _TvSeriesTabState extends ConsumerState<_TvSeriesTab> {
  static const _daysBefore = 2;
  static const _daysAfter = 5;

  final DateTime _today = DateTime.now();
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _normalize(_today);
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime _dateAt(int offset) =>
      _normalize(_today).add(Duration(days: offset));

  List<DateTime> get _dates => [
    for (int i = -_daysBefore; i <= _daysAfter; i++) _dateAt(i),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DateSlider(
          dates: _dates,
          today: _normalize(_today),
          selected: _selectedDate,
          onSelected: (date) => setState(() => _selectedDate = date),
        ),
        Expanded(child: _SeriesList(date: _selectedDate)),
      ],
    );
  }
}

class _DateSlider extends StatelessWidget {
  const _DateSlider({
    required this.dates,
    required this.today,
    required this.selected,
    required this.onSelected,
  });

  final List<DateTime> dates;
  final DateTime today;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _label(DateTime date) {
    final wd = _weekdays[date.weekday - 1];
    final day = date.day.toString();
    return '$wd\n$day';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final date = dates[i];
          final isSelected = date == selected;
          final isToday = date == today;
          return _DateChip(
            label: _label(date),
            isSelected: isSelected,
            isToday: isToday,
            onTap: () => onSelected(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, height: 1.4);

    if (isSelected) {
      return FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          minimumSize: const Size(52, 52),
          foregroundColor: Colors.black,
        ),
        child: Text(
          label,
          style: textStyle?.copyWith(color: Colors.black),
          textAlign: TextAlign.center,
        ),
      );
    }

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        minimumSize: const Size(52, 52),
        side: isToday
            ? BorderSide(color: colorScheme.primary, width: 1.5)
            : null,
      ),
      child: Text(
        label,
        style: textStyle?.copyWith(color: isToday ? colorScheme.primary : null),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _SeriesList extends ConsumerWidget {
  const _SeriesList({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(airingTodayProvider(date));
    final listPadding = EdgeInsets.fromLTRB(
      12,
      12,
      12,
      12 + MediaQuery.paddingOf(context).bottom,
    );

    return async.when(
      loading: () => ListView.separated(
        padding: listPadding,
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => const MediaRowCardSkeleton(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              'Could not load shows',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(airingTodayProvider(date)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (shows) {
        if (shows.isEmpty) {
          return const Center(child: Text('No episodes airing on this date'));
        }
        return AppRefreshIndicator(
          onRefresh: () async => ref.invalidate(airingTodayProvider(date)),
          child: ListView.separated(
            padding: listPadding,
            itemCount: shows.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ShowCard(show: shows[i]),
          ),
        );
      },
    );
  }
}

class _ShowCard extends StatelessWidget {
  const _ShowCard({required this.show});

  final TvShow show;

  String _formatTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toUtc().add(kAppTimezoneOffset);
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  ({String? line1, String? line2}) _episodeLines() {
    final ep = show.nextEpisodeToAir;
    if (ep == null) return (line1: null, line2: null);
    final time = ep.airDate.isNotEmpty ? ' · ${_formatTime(ep.airDate)}' : '';
    final line1 = 'S${ep.seasonNumber} E${ep.episodeNumber}$time';
    final line2 = ep.name.isNotEmpty ? ep.name : null;
    return (line1: line1, line2: line2);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _episodeLines();
    final nextEp = show.nextEpisodeToAir;
    final badgeLabel = nextEp != null
        ? episodeTypeLabel(nextEp.episodeType, nextEp.episodeNumber)
        : null;
    return MediaRowCard(
      posterPath: show.posterPath,
      title: show.name,
      voteAverage: show.voteAverage,
      subtitleLine1: lines.line1,
      subtitleLine2: lines.line2,
      badgeLabel: badgeLabel,
      trailing: WatchlistIconButton(id: show.id, mediaType: 'tv'),
      onTap: () =>
          context.push(RoutePaths.seriesDetailPath(show.id), extra: show),
    );
  }
}
