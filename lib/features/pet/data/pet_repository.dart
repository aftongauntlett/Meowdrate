import '../../../core/storage/local_store.dart';
import '../models/pet_state.dart';

const _storageKey = 'pet.state.v1';

class PetRepository {
  const PetRepository(this._store);

  final LocalStore _store;

  Future<PetState> getState() async {
    final json = await _store.readJson(_storageKey);
    if (json == null) {
      return const PetState();
    }
    return PetState.fromJson(json);
  }

  Future<void> saveState(PetState state) async {
    await _store.writeJson(_storageKey, state.toJson());
  }
}
