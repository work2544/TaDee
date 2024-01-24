import 'package:mongo_dart/mongo_dart.dart' show Db, DbCollection;

class DBConnection {
  static DBConnection? _instance;

  final String _getConnectionString = 'mongodb+srv://worklao21:0881496697_Zaa@cluster0.b0htsww.mongodb.net/?retryWrites=true&w=majority';

  late Db _db;

  static getInstance() {
    if (_instance == null) {
      _instance = DBConnection();
    }
    return _instance;
  }

  Future<Db> getConnection() async {
    if (_db == null) {
      try {
        _db = await Db.create(_getConnectionString);
        await _db.open();
      } catch (e) {
        print(e);
      }
    }
    return _db;
  }

  closeConnection() {
    _db.close();
  }
}
