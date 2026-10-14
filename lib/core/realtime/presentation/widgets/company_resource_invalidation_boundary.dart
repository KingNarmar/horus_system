import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/company_invalidation_resource.dart';
import '../cubit/company_realtime_cubit.dart';
import '../cubit/company_realtime_state.dart';

/// An interest in authoritative resources exists only while this widget
/// is mounted. It does not own a channel or keep hidden screens refreshing.
final class CompanyResourceInvalidationBoundary extends StatelessWidget {
  final String companyId;
  final Set<CompanyInvalidationResource> resources;
  final Future<void> Function(BuildContext context) onInvalidate;
  final Widget child;

  const CompanyResourceInvalidationBoundary({
    required this.companyId,
    required this.resources,
    required this.onInvalidate,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<CompanyRealtimeCubit, CompanyRealtimeState>(
      listenWhen: (previous, current) =>
          previous.companyId == companyId &&
          current.companyId == companyId &&
          resources.any(
            (resource) =>
                previous.revisionFor(resource) != current.revisionFor(resource),
          ),
      listener: (context, _) => unawaited(onInvalidate(context)),
      child: child,
    );
  }
}
