import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/vehicle_status.dart';
import '../../domain/entities/vehicle_status_filter.dart';

const Object _notSet = Object();

sealed class FleetState {
  const FleetState();
}

class FleetInitial extends FleetState {
  const FleetInitial();
}

class FleetLoading extends FleetState {
  const FleetLoading();
}

enum FleetAssetTab { tractorHeads, trailers }

class FleetLoaded extends FleetState {
  final CurrentCompanyContext currentCompanyContext;
  final List<TractorHead> allTractorHeads;
  final List<TrailerEntity> allTrailers;
  final bool canManageFleet;
  final String searchQuery;
  final VehicleStatusFilter statusFilter;
  final FleetAssetTab selectedTab;
  final Set<String> activeStateChangingAssetIds;
  final String? selectedAssetId;
  final List<AuditLog> selectedAssetActivity;
  final bool isActivityLoading;
  final Failure? activityFailure;

  const FleetLoaded({
    required this.currentCompanyContext,
    required this.allTractorHeads,
    required this.allTrailers,
    required this.canManageFleet,
    this.searchQuery = '',
    this.statusFilter = VehicleStatusFilter.active,
    this.selectedTab = FleetAssetTab.tractorHeads,
    this.activeStateChangingAssetIds = const <String>{},
    this.selectedAssetId,
    this.selectedAssetActivity = const [],
    this.isActivityLoading = false,
    this.activityFailure,
  });

  bool isActiveStateChanging(String id) => activeStateChangingAssetIds.contains(id);

  List<TractorHead> get tractorHeads {
    final query = searchQuery.trim().toLowerCase();
    return allTractorHeads.where((item) {
      if (!statusFilter.matches(item.isActive)) return false;
      if (query.isEmpty) return true;
      return [item.plateNumber, item.status.value, item.expectedFuelConsumption?.toString(), item.notes]
          .whereType<String>()
          .any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  List<TrailerEntity> get trailers {
    final query = searchQuery.trim().toLowerCase();
    return allTrailers.where((item) {
      if (!statusFilter.matches(item.isActive)) return false;
      if (query.isEmpty) return true;
      return [item.plateNumber, item.status.value, item.technicalNotes]
          .whereType<String>()
          .any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  FleetLoaded copyWith({
    List<TractorHead>? allTractorHeads,
    List<TrailerEntity>? allTrailers,
    bool? canManageFleet,
    String? searchQuery,
    VehicleStatusFilter? statusFilter,
    FleetAssetTab? selectedTab,
    Set<String>? activeStateChangingAssetIds,
    Object? selectedAssetId = _notSet,
    List<AuditLog>? selectedAssetActivity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
  }) {
    return FleetLoaded(
      currentCompanyContext: currentCompanyContext,
      allTractorHeads: allTractorHeads ?? this.allTractorHeads,
      allTrailers: allTrailers ?? this.allTrailers,
      canManageFleet: canManageFleet ?? this.canManageFleet,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      selectedTab: selectedTab ?? this.selectedTab,
      activeStateChangingAssetIds: activeStateChangingAssetIds ?? this.activeStateChangingAssetIds,
      selectedAssetId: selectedAssetId == _notSet ? this.selectedAssetId : selectedAssetId as String?,
      selectedAssetActivity: selectedAssetActivity ?? this.selectedAssetActivity,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      activityFailure: activityFailure == _notSet ? this.activityFailure : activityFailure as Failure?,
    );
  }
}

class FleetFailure extends FleetState {
  final Failure failure;

  const FleetFailure(this.failure);
}
