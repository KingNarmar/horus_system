import '../../domain/entities/driver_write_data.dart';
import '../models/driver_model.dart';

final class DriverChangeDetector {
  const DriverChangeDetector();

  bool hasDriverChanges(DriverModel oldModel, DriverWriteData data) {
    return _textChanged(oldModel.fullName, data.fullName) ||
        _textChanged(oldModel.phone, data.phone) ||
        _textChanged(oldModel.nationalId, data.nationalId) ||
        _textChanged(oldModel.licenseNumber, data.licenseNumber) ||
        _dateChanged(oldModel.licenseExpiryDate, data.licenseExpiryDate) ||
        _textChanged(oldModel.profileImagePath, data.profileImagePath) ||
        _textChanged(oldModel.licenseImagePath, data.licenseImagePath) ||
        _textChanged(
          oldModel.licenseBackImagePath,
          data.licenseBackImagePath,
        ) ||
        _textChanged(oldModel.nationalIdImagePath, data.nationalIdImagePath) ||
        _textChanged(
          oldModel.nationalIdBackImagePath,
          data.nationalIdBackImagePath,
        ) ||
        _textChanged(oldModel.notes, data.notes);
  }

  bool _textChanged(String? oldValue, String? newValue) {
    return _normalizeText(oldValue) != _normalizeText(newValue);
  }

  String? _normalizeText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  bool _dateChanged(DateTime? oldValue, DateTime? newValue) {
    return _dateOnly(oldValue) != _dateOnly(newValue);
  }

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final local = value.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
