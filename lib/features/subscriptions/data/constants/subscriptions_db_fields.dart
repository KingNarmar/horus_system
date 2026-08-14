abstract final class SubscriptionsDbFields {
  static const subscriptionPlansTable = 'subscription_plans';
  static const companySubscriptionsTable = 'company_subscriptions';

  static const id = 'id';
  static const companyId = 'company_id';
  static const planId = 'plan_id';
  static const code = 'code';
  static const name = 'name';
  static const monthlyPrice = 'monthly_price';
  static const maxUsers = 'max_users';
  static const maxVehicles = 'max_vehicles';
  static const maxTripsPerMonth = 'max_trips_per_month';
  static const hasDriverApp = 'has_driver_app';
  static const hasAdvancedReports = 'has_advanced_reports';
  static const hasDocumentUpload = 'has_document_upload';
  static const hasMaintenance = 'has_maintenance';
  static const hasWhatsappNotifications = 'has_whatsapp_notifications';
  static const isActive = 'is_active';
  static const status = 'status';
  static const trialEndsAt = 'trial_ends_at';
  static const currentPeriodStart = 'current_period_start';
  static const currentPeriodEnd = 'current_period_end';
  static const externalProvider = 'external_provider';
  static const createdAt = 'created_at';
  static const updatedAt = 'updated_at';

  static const planRelation = 'subscription_plans';

  static const planColumns =
      '$id,$code,$name,$monthlyPrice,$maxUsers,$maxVehicles,'
      '$maxTripsPerMonth,$hasDriverApp,$hasAdvancedReports,'
      '$hasDocumentUpload,$hasMaintenance,$hasWhatsappNotifications,'
      '$isActive,$createdAt,$updatedAt';

  static const companySubscriptionColumns =
      '$id,$companyId,$planId,$status,$trialEndsAt,$currentPeriodStart,'
      '$currentPeriodEnd,$externalProvider,$createdAt,$updatedAt,'
      '$planRelation($planColumns)';
}
