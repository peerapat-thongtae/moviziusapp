import 'package:flutter/material.dart';

import '../../../core/widgets/star_rating_picker.dart';

/// Bottom sheet shown when marking an item watched, letting the user rate it
/// 1-10 (0.5 steps) or skip. Returns the chosen rating via `Navigator.pop`,
/// or `null` if skipped/dismissed.
class RatingPickerModal extends StatefulWidget {
  const RatingPickerModal({super.key, this.initialRating});

  final double? initialRating;

  static Future<double?> show(BuildContext context, {double? initialRating}) {
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => RatingPickerModal(initialRating: initialRating),
    );
  }

  @override
  State<RatingPickerModal> createState() => _RatingPickerModalState();
}

class _RatingPickerModalState extends State<RatingPickerModal> {
  late double _rating = widget.initialRating ?? 6.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rate this', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 16),
                  StarRatingPicker(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      '${_rating.toStringAsFixed(1)} / 10',
                      key: ValueKey(_rating),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.amber,
                      ),
                    ),
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
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Skip'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _rating),
                      child: const Text('Save'),
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
