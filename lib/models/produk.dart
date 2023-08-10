// ignore_for_file: non_constant_identifier_names

import 'dart:developer';

import 'package:simplepos/models/model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db.dart';

class Produk extends Model{
  static const tableName = 'produk';
  static const collectionName = 'produk';
  static const limit = 50;

  String kode;
  String nama;
  double harga;
  int? stok;
  int created_at;
  int updated_at;

  Produk({required this.kode, required this.nama, required this.harga, this.stok, this.created_at = 0, this.updated_at = 0});
  
  @override
  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'nama': nama,
      'harga': harga,
      'stok': stok,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  @override
  String toString() {
    return 'Produk{kode: $kode, nama: $nama, harga: $harga, stok: $stok, created_at: $created_at, updated_at: $updated_at}';
  }

  static Produk fromMap(Map<String, dynamic> data) {
    dynamic stok;
    if (data["stok"] != null) {
      stok = int.parse(data["stok"].toString());
    } else {
      stok = null;
    }
    
    return Produk(kode: data["kode"], nama: data["nama"], harga: double.parse(data["harga"].toString()), stok: stok, created_at: int.parse(data["created_at"].toString()), updated_at: int.parse(data["updated_at"].toString()));
  }

  @override
  Future<Produk> save() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (created_at == 0) {
      created_at = now;
    }
    updated_at = now;
    await db.insert(tableName, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return this;
  }  

  static Future<int> saveMany(List<Produk> produkList) async {
    Database db = await getDatabase();
    Batch batch = db.batch();
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (Produk produk in produkList) {
      if (produk.created_at == 0) {
        produk.created_at = now;
      }
      produk.updated_at = now;
      batch.insert(tableName, produk.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    List<Object?> objs = await batch.commit();
    return objs.length;
  }

  static Future<Map<String, dynamic>> get({String search = '', List<String> sort = const ['kode', 'ASC'], int page = 1}) async {
    Database db = await getDatabase();
    String query = 'SELECT $tableName.* FROM $tableName';
    String queryCount = 'SELECT COUNT(*) as total FROM $tableName';
    if (search.isNotEmpty) {
      final String whereQuery = " WHERE (LOWER(kode) like '%${search.toLowerCase()}%' OR LOWER(nama) like '%${search.toLowerCase()}%')";
      query += whereQuery;
      queryCount += whereQuery;
    }
    final result = await db.rawQuery(queryCount);
    final totalPage = (int.parse(result[0]["total"].toString()) / limit).ceil();

    if (sort.isNotEmpty) {
      query += " ORDER BY ${sort[0]} ${sort[1]}";
    }
    final int offset = (page - 1) * limit;
    query += " LIMIT $limit OFFSET $offset";

    List<Map<String, dynamic>> maps = await db.rawQuery(query);
    List<Produk> produkList = [];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        produkList.add(Produk.fromMap(map));
      }
    }
    return {
      "totalData": result[0]["total"],
      "totalPage": totalPage,
      "currentPage": page,
      "produkList": produkList
    };
  }
}