// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:nanoid/async.dart';
import 'package:simplepos/models/model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db.dart';

class Produk extends Model{
  static const tableName = 'produk';
  static const collectionName = 'produk';

  String? kode;
  String nama;
  double harga;
  int? stok;
  int created_at;
  int updated_at;

  static Future<String> generateKode () async {
    return await customAlphabet('1234567890QWERTYUIOPASDFGHJKLZXCVBNM', 10);
  }

  Produk({String? kode, required this.nama, required this.harga, this.stok, this.created_at = 0, this.updated_at = 0}) {
    kode ??= '';
  }

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
    
    Produk p = Produk(nama: data["nama"], harga: double.parse(data["harga"].toString()), stok: stok, created_at: int.parse(data["created_at"].toString()), updated_at: int.parse(data["updated_at"].toString()));
    p.kode = data["kode"];
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
    kode ??= await generateKode();
    await db.insert(tableName, toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return this;
  }

  @override
  Future<dynamic> delete() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    try {
      var randomId = await nanoid(6);
      await db.update(
        tableName, {
          "deleted_at": now,
          "kode": "$kode$randomId",
        }, 
        where: "kode = ?", 
        whereArgs: [kode]
      );
    } catch (exception) {
      return exception;
    }
    return true;
  }

  static Future<int> saveMany(List<Produk> produkList) async {
    Database db = await getDatabase();
    Batch batch = db.batch();
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (Produk produk in produkList) {
      produk.kode ??= await generateKode();
      if (produk.created_at == 0) {
        produk.created_at = now;
      }
      produk.updated_at = now;
      batch.insert(tableName, produk.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
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
    // debugPrint(produkList.toString());
    // debugPrint("ABCDEFG");

    return {
      "totalData": result[0]["total"],
      "totalPage": totalPage,
      "currentPage": page,
      "produkList": produkList
    };
  }
}