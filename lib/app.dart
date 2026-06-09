import 'package:flutter/material.dart';

import 'core/constants/app_spacing.dart';
import 'core/responsive/responsive_layout.dart';
import 'core/theme/app_theme.dart';

class HorusApp extends StatelessWidget {
  const HorusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H.O.R.U.S System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HorusLaunchPage(),
    );
  }
}

class HorusLaunchPage extends StatelessWidget {
  const HorusLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: _LaunchLayout(
            maxWidth: 420,
            horizontalPadding: AppSpacing.lg,
          ),
          tablet: _LaunchLayout(
            maxWidth: 620,
            horizontalPadding: AppSpacing.xl,
          ),
          desktop: _LaunchLayout(
            maxWidth: 720,
            horizontalPadding: AppSpacing.xxl,
          ),
        ),
      ),
    );
  }
}

class _LaunchLayout extends StatelessWidget {
  final double maxWidth;
  final double horizontalPadding;

  const _LaunchLayout({
    required this.maxWidth,
    required this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: const _LaunchContent(),
        ),
      ),
    );
  }
}

class _LaunchContent extends StatelessWidget {
  const _LaunchContent();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'H.O.R.U.S System',
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Heavy Operations & Route Unified System',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'SaaS platform for heavy transport operations.',
          textAlign: TextAlign.center,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.xxl),
        const _ArchitectureBadge(),
      ],
    );
  }
}

class _ArchitectureBadge extends StatelessWidget {
  const _ArchitectureBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Text(
          'Clean Architecture by the book • SOLID Principles',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
