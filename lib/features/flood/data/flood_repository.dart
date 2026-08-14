import '../../../core/storage/local_store.dart';
import '../models/flood_state.dart';

const _storageKey = 'flood.state.v1';

class FloodRepository {
  const FloodRepository(this._store);

  final LocalStore _store;

  Future<FloodState> getState() async {
    final json = await _store.readJson(_storageKey);
    if (json == null) {
      return const FloodState();
    }
    return FloodState.fromJson(json);
  }

  Future<void> saveState(FloodState state) async {
    await _store.writeJson(_storageKey, state.toJson());
  }
}
