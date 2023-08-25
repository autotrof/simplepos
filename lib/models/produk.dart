// ignore_for_file: non_constant_identifier_names
import 'package:flutter/foundation.dart';
import 'package:nanoid/async.dart';
import 'package:simplepos/models/model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db.dart';

class Produk extends Model{
  static const tableName = 'produk';

  late String kode;
  String nama;
  double harga;
  int? stok;
  int aktif;
  int created_at;
  int updated_at;
  int? deleted_at;

  static Future<String> generateKode () async {
    String prefix = DateTime.now().millisecondsSinceEpoch.toString();
    String randomKey = await customAlphabet('QWERTYUIOPASDFGHJKLZXCVBNM1234567890', 3);
    return prefix + randomKey;
  }

  Produk({this.kode = '', required this.nama, required this.harga, this.stok, this.aktif = 0, this.created_at = 0, this.updated_at = 0, this.deleted_at});

  @override
  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'aktif': aktif,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  @override
  String toString() {
    return 'Produk{kode: $kode, nama: $nama, harga: $harga, stok: $stok, aktif: $aktif, created_at: $created_at, updated_at: $updated_at, deleted_at: $deleted_at}';
  }

  static Produk fromMap(Map<String, dynamic> data) {
    dynamic stok;
    if (data["stok"] != null) {
      stok = int.parse(data["stok"].toString());
    } else {
      stok = null;
    }
    
    Produk p = Produk(
      nama: data["nama"],
      harga: double.parse(data["harga"].toString()),
      stok: stok,
      aktif: data["aktif"],
      created_at: data["created_at"],
      updated_at: data["updated_at"]
    );
    p.kode = data["kode"];
    p.deleted_at = data["deleted_at"];
    return p;
  }

  @override
  Future<Produk> save() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (created_at == 0) {
      created_at = now;
    }
    updated_at = now;
    if (kode == '') {
      kode = await generateKode();
    }
    await db.insert(tableName, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return this;
  }

  @override
  Future<dynamic> delete() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    try {
      final String randomId = await customAlphabet('1234567890QWERTYUIOPASDFGHJKLXCVBNMZ', 16);
      final String newKode = "$kode$randomId".substring(0, 16);
      await db.update (
        tableName, {
          "deleted_at": now,
          "kode": newKode,
        }, 
        where: "kode = ?", 
        whereArgs: [kode]
      );
    } catch (exception) {
      return exception;
    }
    return true;
  }

  static Future<int> saveMany(List<Produk> dataList) async {
    Database db = await getDatabase();
    Batch batch = db.batch();
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (Produk data in dataList) {
      if(data.kode == '') {
        data.kode = await generateKode();
      }
      
      if (data.created_at == 0) {
        data.created_at = now;
      }
      data.updated_at = now;
      batch.insert(tableName, data.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    List<Object?> objs = await batch.commit();
    return objs.length;
  }

  static Future<Map<String, dynamic>> get({String search = '', List<String> sort = const ['kode', 'ASC'], int page = 1, int limit = 50, bool withTrashed = false}) async {
    Database db = await getDatabase();
    String query = 'SELECT $tableName.* FROM $tableName';
    String queryCount = 'SELECT COUNT(*) as total FROM $tableName';
    if (!withTrashed) {
      query += ' WHERE deleted_at IS NULL';
      queryCount += ' WHERE deleted_at IS NULL';
    } else {
      query += ' WHERE kode != NULL';
      queryCount += ' WHERE kode != NULL';
    }
    if (search.isNotEmpty) {
      final String whereQuery = " AND (LOWER(kode) like '%${search.toLowerCase()}%' OR LOWER(nama) like '%${search.toLowerCase()}%')";
      query += whereQuery;
      queryCount += whereQuery;
    }
    final result = await db.rawQuery(queryCount);

    final totalPage = limit == 0 ? 1 : (int.parse(result[0]["total"].toString()) / limit).ceil();

    if (sort.isNotEmpty) {
      query += " ORDER BY ${sort[0]} ${sort[1]}";
    }
    if (limit != 0) {
      final int offset = (page - 1) * 50;
      query += " LIMIT $limit OFFSET $offset";
    }

    List<Map<String, dynamic>> maps = await db.rawQuery(query);
    List<Produk> produkList = [];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        produkList.add(Produk.fromMap(map));
      }
    }

    debugPrint("GET");
    return {
      "totalData": result[0]["total"],
      "totalPage": totalPage,
      "currentPage": page,
      "produkList": produkList
    };
  }
}