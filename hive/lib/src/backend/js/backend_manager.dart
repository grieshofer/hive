import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';

import 'native/backend_manager.dart' as native;
import 'web_worker/backend_manager.dart' as web_worker;

/// Opens IndexedDB databases
abstract class BackendManager {
  // caching the backend manager as it makes no sense to have different backends
  // within the same application
  static BackendManagerInterface? _manager;

  const BackendManager._();

  static BackendManagerInterface select(
      [HiveStorageBackendPreference? backendPreference]) {
    if(_manager==null) {
      if (backendPreference is HiveStorageBackendPreferenceWebWorker) {
        _manager = web_worker.BackendManagerWebWorker(backendPreference.path);
      } else if (backendPreference == HiveStorageBackendPreference.native) {
        _manager = native.BackendManager();
      } else if (backendPreference == HiveStorageBackendPreference.memory) {
        _manager = native.BackendManager();
      } else {
        throw UnimplementedError(
            '$backendPreference is not a known HiveStorageBackendPreference');
      }
    }
    return _manager!;
  }
}
