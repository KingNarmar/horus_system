import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/tractor_head.dart';
import '../../domain/entities/trailer_entity.dart';
import '../../domain/entities/vehicle_status.dart';
import '../../domain/entities/vehicle_status_filter.dart';

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

  const FleetLoaded({
    required this.currentCompanyContext,
    required this.allTractorHeads,
    required this.allTrailers,
    required this.canManageFleet,
    this.searchQuery = '',
    this.statusFilter = VehicleStatusFilter.active,
    this.selectedTab = FleetAssetTab.tractorHeads,
    this.activeStateChangingAssetIds = const <String>{},
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
    );
  }
}

class FleetFailure extends FleetState {
  final Failure failure;

  const FleetFailure(this.failure);
}
