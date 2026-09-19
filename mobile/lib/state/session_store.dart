import 'package:shared_preferences/shared_preferences.dart';

/// Remembers who is signed in (and their UPI ID) between launches.
class SessionStore {
  const SessionStore();

  static const _reg = 'omw.regNumber';
  static const _name = 'omw.name';
  static const _upi = 'omw.upi';

  Future<({String regNumber, String name, String? upi})?> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final reg = p.getString(_reg);
      final name = p.getString(_name);
      if (reg == null || name == null) return null;
      return (regNumber: reg, name: name, upi: p.getString(_upi));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(String regNumber, String name) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_reg, regNumber);
      await p.setString(_name, name);
    } catch (_) {}
  }

  Future<void> saveUpi(String upi) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_upi, upi);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(_reg);
      await p.remove(_name);
      await p.remove(_upi);
    } catch (_) {}
  }
}

/// In-memory store for tests.
class MemorySessionStore implements SessionStore {
  ({String regNumber, String name, String? upi})? _value;

  @override
  Future<({String regNumber, String name, String? upi})?> load() async =>
      _value;

  @override
  Future<void> save(String regNumber, String name) async =>
      _value = (regNumber: regNumber, name: name, upi: _value?.upi);

  @override
  Future<void> saveUpi(String upi) async => _value = (
    regNumber: _value?.regNumber ?? '',
    name: _value?.name ?? '',
    upi: upi,
  );

  @override
  Future<void> clear() async => _value = null;
}
