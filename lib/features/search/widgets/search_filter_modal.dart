import 'package:flutter/material.dart';

import '../models/search_filters.dart';

/// Consolidated filter modal (Sort / Genre / Year / Min rating). Genre is
/// multi-select; the rest are single-select. Returns the applied
/// [SearchFilters] via `Navigator.pop`, or `null` if dismissed.
class SearchFilterModal extends StatefulWidget {
  const SearchFilterModal({
    super.key,
    required this.kind,
    required this.initial,
  });

  final MediaKind kind;
  final SearchFilters initial;

  static Future<SearchFilters?> show(
    BuildContext context, {
    required MediaKind kind,
    required SearchFilters initial,
  }) {
    return showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SearchFilterModal(kind: kind, initial: initial),
    );
  }

  @override
  State<SearchFilterModal> createState() => _SearchFilterModalState();
}

class _SearchFilterModalState extends State<SearchFilterModal> {
  late SearchFilters _filters = widget.initial;
  late Set<int> _genreIds = {...widget.initial.genreIds};

  void _reset() {
    setState(() {
      _filters = const SearchFilters();
      _genreIds = {};
    });
  }

  void _apply() {
    Navigator.pop(context, _filters.copyWith(genreIds: _genreIds));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sortOptions = SearchOptions.sortOptionsFor(widget.kind);
    final genreOptions = SearchOptions.genresFor(widget.kind);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                children: [
                  Text('Filters', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Text('Sort by', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in sortOptions)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: _filters.sortBy == option.value,
                          onSelected: (_) => setState(
                            () => _filters =
                                _filters.copyWith(sortBy: option.value),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Genre', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in genreOptions)
                        FilterChip(
                          label: Text(option.label),
                          selected: _genreIds.contains(option.value),
                          onSelected: (selected) => setState(() {
                            if (selected) {
                              _genreIds.add(option.value);
                            } else {
                              _genreIds.remove(option.value);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Year', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in SearchOptions.years())
                        ChoiceChip(
                          label: Text(option.label),
                          selected: _filters.year == option.value,
                          onSelected: (_) => setState(
                            () => _filters = _filters.year == option.value
                                ? _filters.copyWith(clearYear: true)
                                : _filters.copyWith(year: option.value),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Min rating', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in SearchOptions.ratingOptions)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: _filters.minRating == option.value,
                          onSelected: (_) => setState(
                            () => _filters = _filters.minRating == option.value
                                ? _filters.copyWith(clearRating: true)
                                : _filters.copyWith(minRating: option.value),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _reset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _apply,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
