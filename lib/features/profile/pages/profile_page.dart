import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_notifier.dart';
import '../../../core/widgets/app_refresh_indicator.dart';
import '../../../core/auth/auth_state.dart';
import '../../../core/router/route_paths.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final displayName = user?.name ?? user?.email ?? 'there';
    final email = user?.email;
    final pictureUrl = user?.pictureUrl?.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
          ),
        ],
      ),
      body: AppRefreshIndicator(
        onRefresh: () async => ref.invalidate(authNotifierProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 16),
                  child: child,
                ),
              ),
              child: _ProfileHeader(
                name: displayName,
                email: email,
                pictureUrl: pictureUrl,
              ),
            ),
            const SizedBox(height: 24),
            Text('Library', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.movie_outlined),
                    title: const Text('Movies'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.movieLibrary),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.tv_outlined),
                    title: const Text('TV'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RoutePaths.tvLibrary),
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, this.email, this.pictureUrl});

  final String name;
  final String? email;
  final String? pictureUrl;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: colorScheme.surfaceContainerHighest,
          backgroundImage:
              pictureUrl != null ? NetworkImage(pictureUrl!) : null,
          child: pictureUrl == null
              ? Icon(Icons.person, size: 32, color: colorScheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email != null) ...[
                const SizedBox(height: 4),
                Text(
                  email!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
