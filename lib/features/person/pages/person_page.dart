import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/tmdb_image.dart';
import '../../../core/router/route_paths.dart';
import '../../../core/widgets/overlay_icon_button.dart';
import '../models/person_detail.dart';
import '../providers/person_provider.dart';

class PersonPage extends ConsumerWidget {
  const PersonPage({super.key, required this.personId, this.name});

  final int personId;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(personDetailProvider(personId));

    return Scaffold(
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 300),
            builder: (context, opacity, child) =>
                Opacity(opacity: opacity, child: child),
            child: personAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, e2) => _ErrorBody(name: name),
              data: (person) => _PersonBody(person: person),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: OverlayIconButton(
                icon: Icons.arrow_back,
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({this.name});
  final String? name;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name ?? 'Person',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text('Failed to load person details.'),
          ],
        ),
      ),
    );
  }
}

class _PersonBody extends StatelessWidget {
  const _PersonBody({required this.person});
  final PersonDetail person;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final profilePath = person.profilePath;

    final topCredits = (person.combinedCredits?.cast ?? [])
      ..sort((a, b) => b.popularity.compareTo(a.popularity));
    final visibleCredits = topCredits.take(20).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage:
                        profilePath != null && profilePath.isNotEmpty
                            ? NetworkImage(TmdbImage.profile(profilePath))
                            : null,
                    child: profilePath == null || profilePath.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(person.name, style: textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          person.knownForDepartment,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        if (person.birthday.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatBirthInfo(person),
                            style: textTheme.bodySmall,
                          ),
                        ],
                        if (person.placeOfBirth.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            person.placeOfBirth,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (person.biography.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Text('Biography', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _ExpandableBio(biography: person.biography),
                ],
              ),
            ),
          ),
        if (visibleCredits.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 32),
                  Text('Known For', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: visibleCredits.length,
                      itemBuilder: (context, index) {
                        final credit = visibleCredits[index];
                        return _CreditCard(
                          credit: credit,
                          isLast: index == visibleCredits.length - 1,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatBirthInfo(PersonDetail p) {
    final parts = <String>[];
    if (p.birthday.isNotEmpty) parts.add('Born ${p.birthday}');
    if (p.deathday != null) parts.add('Died ${p.deathday}');
    return parts.join(' • ');
  }
}

class _ExpandableBio extends StatefulWidget {
  const _ExpandableBio({required this.biography});
  final String biography;

  @override
  State<_ExpandableBio> createState() => _ExpandableBioState();
}

class _ExpandableBioState extends State<_ExpandableBio> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          firstChild: Text(
            widget.biography,
            style: textTheme.bodyMedium,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(widget.biography, style: textTheme.bodyMedium),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Show more',
            style: textTheme.labelMedium?.copyWith(color: colorScheme.primary),
          ),
        ),
      ],
    );
  }
}

class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.credit, required this.isLast});
  final PersonCredit credit;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final posterPath = credit.posterPath;

    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : 12),
      child: GestureDetector(
        onTap: () {
          if (credit.mediaType == 'movie') {
            context.push(RoutePaths.movieDetailPath(credit.id), extra: credit.title);
          } else if (credit.mediaType == 'tv') {
            context.push(RoutePaths.seriesDetailPath(credit.id), extra: credit.title);
          }
        },
        child: SizedBox(
          width: 100,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: posterPath != null && posterPath.isNotEmpty
                      ? Image.network(
                          TmdbImage.poster(posterPath, size: 'w342'),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : ColoredBox(
                                      color: colorScheme.surfaceContainerHighest,
                                    ),
                          errorBuilder: (context, _, e2) => ColoredBox(
                            color: colorScheme.surfaceContainerHighest,
                          ),
                        )
                      : ColoredBox(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.movie_outlined,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                credit.title,
                style: textTheme.labelSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
