import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class DatabaseService {
  Database? _db;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    final appDir = await getApplicationDocumentsDirectory();
    await appDir.create(recursive: true);
    final dbPath = join(appDir.path, 'monitor_history.db');
    _db = await databaseFactoryIo.openDatabase(dbPath);
    _isInitialized = true;
  }

  Database get db {
    if (!_isInitialized || _db == null) {
      throw StateError('DatabaseService is not initialized. Call init() first.');
    }
    return _db!;
  }

  bool get isInitialized => _isInitialized;
}
