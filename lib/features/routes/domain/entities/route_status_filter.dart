enum RouteStatusFilter { active, inactive, all }

extension RouteStatusFilterX on RouteStatusFilter {
  bool matches(bool isActive) {
    return switch (this) {
      RouteStatusFilter.active => isActive,
      RouteStatusFilter.inactive => !isActive,
      RouteStatusFilter.all => true,
    };
  }
}
