import '../../../company/domain/entities/current_company_context.dart';
import '../entities/trip_status.dart';

class GetTripsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetTripsParams({required this.currentCompanyContext});
}

class GetTripDetailsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;

  const GetTripDetailsParams({
    required this.currentCompanyContext,
    required this.id,
  });
}

class GetTripFormLookupsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetTripFormLookupsParams({required this.currentCompanyContext});
}

class CreateTripParams {
  final CurrentCompanyContext currentCompanyContext;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final String? quantityTonsInput;
  final String? agreedFreightRatePerTonInput;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;

  const CreateTripParams({
    required this.currentCompanyContext,
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTonsInput,
    this.agreedFreightRatePerTonInput,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
  });
}

class SaveTripParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;
  final String customerId;
  final String routeId;
  final String? driverId;
  final String? tractorHeadId;
  final String? trailerId;
  final String? loadingOrderNumber;
  final String? waybillNumber;
  final String? quantityTonsInput;
  final String? agreedFreightRatePerTonInput;
  final DateTime? scheduledLoadingAt;
  final DateTime? scheduledDeliveryAt;
  final DateTime? actualLoadingAt;
  final DateTime? actualDeliveryAt;
  final String? notes;

  const SaveTripParams({
    required this.currentCompanyContext,
    required this.id,
    required this.customerId,
    required this.routeId,
    this.driverId,
    this.tractorHeadId,
    this.trailerId,
    this.loadingOrderNumber,
    this.waybillNumber,
    this.quantityTonsInput,
    this.agreedFreightRatePerTonInput,
    this.scheduledLoadingAt,
    this.scheduledDeliveryAt,
    this.actualLoadingAt,
    this.actualDeliveryAt,
    this.notes,
  });
}

class UpdateTripStatusParams {
  final CurrentCompanyContext currentCompanyContext;
  final String id;
  final TripStatus newStatus;
  final String? notes;

  const UpdateTripStatusParams({
    required this.currentCompanyContext,
    required this.id,
    required this.newStatus,
    this.notes,
  });
}

class GetTripStatusHistoryParams {
  final CurrentCompanyContext currentCompanyContext;
  final String tripId;

  const GetTripStatusHistoryParams({
    required this.currentCompanyContext,
    required this.tripId,
  });
}
