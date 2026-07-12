import 'package:flutter/material.dart';

import '../models/search_filters.dart';
import 'search_filter_modal.dart';

/// Trigger row that opens [SearchFilterModal] with the consolidated
/// Sort / Genre / Year / Min rating controls. Only visible in discover mode
/// (no active search query).
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

  Future<void> _openModal() async {
    final result = await SearchFilterModal.show(
      context,
      kind: widget.kind,
      initial: _filters,
    );
    if (result == null || !mounted) return;
    setState(() => _filters = result);
    widget.onChanged(result);
  }

  int get _activeCount {
    var count = 0;
    if (_filters.sortBy != const SearchFilters().sortBy) count++;
    count += _filters.genreIds.length;
    if (_filters.year != null) count++;
    if (_filters.minRating != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FilterChip(
          label: Text(active > 0 ? 'Filters · $active' : 'Filters'),
          avatar: const Icon(Icons.tune, size: 18),
          selected: active > 0,
          showCheckmark: false,
          onSelected: (_) => _openModal(),
        ),
      ),
    );
  }
}
