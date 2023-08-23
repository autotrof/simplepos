// ignore_for_file: non_constant_identifier_names

import 'package:simplepos/models/model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db.dart';

class Pengaturan extends Model {
  static const tableName = 'pengaturan';
  final String key;
  final String value;
  int updated_at;

  Pengaturan({required this.key, required this.value, this.updated_at = 0});
  @override
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updated_at': updated_at
    };
  }

  @override
  String toString() {
    return "Pengaturan{key:$key, value:$value, updated_at:$updated_at}";
  }

  @override
  Future<Pengaturan> save() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (updated_at == 0) {
      updated_at = now;
    }
    List<Map<String, dynamic>> data = await db.query(tableName, where: "key = ?", whereArgs: [key]);
    if (data.isNotEmpty) {
      await db.update(tableName, {'value': value, 'updated_at': updated_at}, where: "key = ?", whereArgs: [key]);
    } else {
      await db.insert(tableName, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return this;
  }
}