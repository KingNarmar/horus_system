import 'package:flutter/material.dart';

class HorusApp extends StatelessWidget {
  const HorusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'H.O.R.U.S System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F3A5F),
        ),
      ),
      home: const HorusLaunchPage(),
    );
  }
}

class HorusLaunchPage extends StatelessWidget {
  const HorusLaunchPage({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'H.O.R.U.S System',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Heavy Operations & Route Unified System',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Text(
                  'SaaS platform for heavy transport operations.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                const _ArchitectureBadge(),
              ],
            ),
          ),
        ),
      ),
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
