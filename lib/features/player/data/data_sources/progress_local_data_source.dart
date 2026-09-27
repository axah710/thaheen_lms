import '../../../../core/storage/local_storage_service.dart';
import '../models/progress_envelope_dto.dart';

/// Local data source for reading and persisting learning progress.
class ProgressLocalDataSource {
  final LocalStorageService _storageService;

  const ProgressLocalDataSource(this._storageService);

  /// Reads the current progress envelope from storage.
  /// If data is missing or corrupt, returns an empty ProgressEnvelopeDto.
  ProgressEnvelopeDto getEnvelope({void Function()? onCorruptReset}) {
    final json = _storageService.getProgressEnvelopeJson(
      onCorruptDataRecovered: onCorruptReset,
    );
    if (json.isEmpty) {
      return ProgressEnvelopeDto.empty();
    }
    return ProgressEnvelopeDto.fromJson(json);
  }

  /// Persists the updated [envelope] to durable storage.
  Future<bool> saveEnvelope(ProgressEnvelopeDto envelope) async {
    return await _storageService.saveProgressEnvelopeJson(envelope.toJson());
  }

  /// Resets all local progress records.
  Future<bool> clearAll() async {
    return await _storageService.remove(LocalStorageService.progressKey);
  }
}
