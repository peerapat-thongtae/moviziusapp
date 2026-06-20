import 'package:flutter/material.dart';

class _NavTab {
  const _NavTab(this.icon, this.selectedIcon);

  final IconData icon;
  final IconData selectedIcon;
}

const _tabs = [
  _NavTab(Icons.home_outlined, Icons.home),
  _NavTab(Icons.search_outlined, Icons.search),
  _NavTab(Icons.explore_outlined, Icons.explore),
  _NavTab(Icons.person_outline, Icons.person),
];

/// Minimal icon-only bottom dock: no labels, just icons that enlarge and
/// change color when active, with a small dot sliding underneath to mark
/// the selected tab.
class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _dotSize = 6.0;
  static const _indicatorDuration = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / _tabs.length;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: _indicatorDuration,
                    curve: Curves.easeOutCubic,
                    left: tabWidth * currentIndex + tabWidth / 2 - _dotSize / 2,
                    bottom: 8,
                    width: _dotSize,
                    height: _dotSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        Expanded(
                          child: _NavIconButton(
                            tab: _tabs[i],
                            selected: i == currentIndex,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  const _NavIconButton({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _NavTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Center(
        child: AnimatedScale(
          scale: selected ? 1.15 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              selected ? tab.selectedIcon : tab.icon,
              key: ValueKey(selected),
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
