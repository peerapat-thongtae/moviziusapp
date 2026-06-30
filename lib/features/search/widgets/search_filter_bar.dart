import 'package:flutter/material.dart';

import '../models/search_filters.dart';

/// Horizontally-scrollable discover filter controls (Sort / Genre / Year /
/// Min rating). Only visible in discover mode (no active search query).
class SearchFilterBar extends StatefulWidget {
  const SearchFilterBar({
    super.key,
    required this.kind,
    required this.onChanged,
  });

  final MediaKind kind;
  final ValueChanged<SearchFilters> onChanged;

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  SearchFilters _filters = const SearchFilters();

  void _emit(SearchFilters next) {
    setState(() => _filters = next);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = SearchOptions.sortOptionsFor(widget.kind);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final option in sortOptions) ...[
            ChoiceChip(
              label: Text(option.label),
              selected: _filters.sortBy == option.value,
              onSelected: (_) =>
                  _emit(_filters.copyWith(sortBy: option.value)),
            ),
            const SizedBox(width: 8),
          ],
          const _Divider(),
          _SelectChip<int>(
            label: 'Genre',
            value: _filters.genreId,
            options: SearchOptions.genresFor(widget.kind),
            onSelected: (v) => _emit(
              v == null
                  ? _filters.copyWith(clearGenre: true)
                  : _filters.copyWith(genreId: v),
            ),
          ),
          const SizedBox(width: 8),
          _SelectChip<int>(
            label: 'Year',
            value: _filters.year,
            options: SearchOptions.years(),
            onSelected: (v) => _emit(
              v == null
                  ? _filters.copyWith(clearYear: true)
                  : _filters.copyWith(year: v),
            ),
          ),
          const SizedBox(width: 8),
          _SelectChip<double>(
            label: 'Rating',
            value: _filters.minRating,
            options: SearchOptions.ratingOptions,
            onSelected: (v) => _emit(
              v == null
                  ? _filters.copyWith(clearRating: true)
                  : _filters.copyWith(minRating: v),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: VerticalDivider(
        width: 1,
        indent: 8,
        endIndent: 8,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _SelectChip<T> extends StatelessWidget {
  const _SelectChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  final String label;
  final T? value;
  final List<FilterOption<T>> options;
  final ValueChanged<T?> onSelected;

  String get _displayLabel {
    if (value == null) return label;
    final match = options.where((o) => o.value == value);
    return match.isEmpty ? label : match.first.label;
  }

  Future<void> _open(BuildContext context) async {
    final selected = await showModalBottomSheet<FilterOption<T>>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(option.label),
                trailing: option.value == value
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      onSelected(selected.value == value ? null : selected.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return FilterChip(
      label: Text(_displayLabel),
      avatar: selected ? null : const Icon(Icons.arrow_drop_down, size: 20),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => _open(context),
      onDeleted: selected ? () => onSelected(null) : null,
      deleteIcon: selected ? const Icon(Icons.close, size: 18) : null,
    );
  }
}
