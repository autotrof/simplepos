// ignore_for_file: non_constant_identifier_names
import 'package:flutter/material.dart';
import 'package:nanoid/async.dart';
import 'package:simplepos/models/model.dart';
import 'package:simplepos/models/pesanan_item.dart';
import 'package:simplepos/models/produk.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../db.dart';

class Pesanan extends Model{
  static const tableName = 'pesanan';

  late String kode;
  double total;
  double pajak;
  double? total_akhir;//generated
  int? is_draft;
  int? is_paused;
  int created_at;
  int updated_at;
  int? deleted_at;
  List<PesananItem>? items;

  static Future<String> generateKode () async {
    String prefix = DateTime.now().millisecondsSinceEpoch.toString();
    String randomKey = await customAlphabet('QWERTYUIOPASDFGHJKLZXCVBNM1234567890', 3);
    return prefix + randomKey;
  }

  Pesanan({this.kode = '', this.total = 0, this.pajak = 0, this.is_draft = 1, this.is_paused = 0, this.created_at = 0, this.updated_at = 0, this.deleted_at, this.total_akhir, this.items});

  @override
  Map<String, dynamic> toMap() {
    return {
      'kode': kode,
      'total': total,
      'pajak': pajak,
      'total_akhir': total_akhir,
      'is_draft': is_draft,
      'is_paused': is_paused,
      'created_at': created_at,
      'updated_at': updated_at,
      'deleted_at': deleted_at,
    };
  }

  @override
  String toString() {
    return 'Pesanan{kode: $kode, total: $total, pajak: $pajak, total_akhir: $total_akhir, is_draft: $is_draft, created_at: $created_at, updated_at: $updated_at, deleted_at: $deleted_at}';
  }

  static Pesanan fromMap(Map<String, dynamic> data) {
    return Pesanan(
      kode:data["kode"], 
      total: data["total"], 
      total_akhir: data["total_akhir"], 
      pajak: data["pajak"], 
      is_draft: data["is_draft"], 
      is_paused: data["is_paused"], 
      created_at: data["created_at"], 
      updated_at: data["updated_at"], 
      deleted_at: data["deleted_at"]
    );
  }

  @override
  Future<Pesanan> save() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (created_at == 0) {
      created_at = now;
    }
    updated_at = now;
    if (kode == '') {
      kode = await generateKode();
    }
    Map<String, dynamic> data = toMap();
    data.remove("total_akhir");
    await db.transaction((txn) async {
      await txn.insert(tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.rawUpdate('''
        UPDATE $tableName 
        SET total = (SELECT IFNULL(SUM(${PesananItem.tableName}.subtotal), 0) as total FROM ${PesananItem.tableName} WHERE ${PesananItem.tableName}.kode_pesanan = ?) 
        WHERE $tableName.kode = ?
        ''', 
        [kode, kode]
      );
      var res = await txn.queryCursor(tableName, where: "kode = ?", whereArgs: [kode]);
      await res.moveNext();
      total = double.parse(res.current['total'].toString());
      total_akhir = double.parse(res.current['total_akhir'].toString());
      res.close();
    });
    return this;
  }

  static Future<Pesanan?> firstWhere(String where,  List<Object> whereArgs) async {
    Database db = await getDatabase();
    final List<Map<String, Object?>> res = await db.query(tableName, where: where, whereArgs: whereArgs);
    if (res.isEmpty) {
      return null;
    }
    String kode = res[0]['kode'].toString();
    double total = double.parse(res[0]['total'].toString());
    double pajak = double.parse(res[0]['pajak'].toString());
    double total_akhir = double.parse(res[0]['total_akhir'].toString());
    int created_at = int.parse(res[0]['created_at'].toString());
    int updated_at = int.parse(res[0]['updated_at'].toString());
    int? deleted_at = int.tryParse(res[0]['deleted_at'].toString());
    return Pesanan(kode: kode, total: total, pajak: pajak, total_akhir: total_akhir, created_at: created_at, updated_at: updated_at, deleted_at: deleted_at);
  }

  @override
  Future<dynamic> delete({bool force = false}) async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    try {
      if (force) {
        await db.transaction((txn) async {
          await txn.delete(PesananItem.tableName, where: 'kode_pesanan = ?', whereArgs: [kode]);
          await txn.delete(tableName, where: "kode = ?", whereArgs: [kode]);
        });
      } else {
        await db.update(
          tableName, {
            "deleted_at": now
          }, 
          where: "kode = ?", 
          whereArgs: [kode]
        );
      }
    } catch (exception) {
      return exception;
    }
    return true;
  }

  static Future<int> saveMany(List<Pesanan> dataList) async {
    Database db = await getDatabase();
    Batch batch = db.batch();
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (Pesanan data in dataList) {
      data.kode ??= await generateKode();
      if (data.created_at == 0) {
        data.created_at = now;
      }
      data.updated_at = now;
      final p = data.toMap();
      p.remove("total_akhir");
      batch.insert(tableName, data.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    List<Object?> objs = await batch.commit();
    return objs.length;
  }

  static Future<Map<String, dynamic>> get({
    String search = '', 
    List<String> sort = const ['kode', 'ASC'], 
    int page = 1, 
    int limit = 50, 
    bool withTrashed = false,
    bool withItem = true
  }) async {
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
      final String whereQuery = " AND (LOWER(kode) like '%${search.toLowerCase()}%')";
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
    List<Pesanan> dataList = [];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        dataList.add(Pesanan.fromMap(map));
      }
    }

    return {
      "totalData": result[0]["total"],
      "totalPage": totalPage,
      "currentPage": page,
      "produkList": dataList
    };
  }

  Future<List<PesananItem>> getItem() async {
    Database db = await getDatabase();
    List<Map<String, dynamic>> result = await db.query(PesananItem.tableName, where: "kode_pesanan = ?", whereArgs: [kode], orderBy: "urutan asc, created_at asc");
    List<PesananItem> pesanItems = [];
    List<String> listKodeProduk = result.map((e) => e['kode_produk'].toString()).toList();
    List<Map<String, dynamic>> dataProduk = await db.query(Produk.tableName, where: "kode IN (${listKodeProduk.map((e) => '?').join(',')})", whereArgs: listKodeProduk);
    Map<String, Produk> dataProdukByKode = {};
    for (dynamic data in dataProduk) {
      dataProdukByKode[data["kode"]] = Produk(nama: data["nama"], harga: data["harga"], stok: data["stok"], kode: data["kode"], created_at: data["created_at"], updated_at: data["updated_at"], deleted_at: data["deleted_at"]);
    }

    for (Map<String, dynamic> pesananData in result) {
      pesanItems.add(PesananItem(
        kode_produk: pesananData["kode_produk"], 
        kode_pesanan: pesananData["kode_pesanan"], 
        harga: pesananData["harga"], 
        jumlah: pesananData["jumlah"],
        subtotal: pesananData["subtotal"],
        created_at: pesananData["created_at"],
        updated_at: pesananData["updated_at"],
        produk: dataProdukByKode[pesananData["kode_produk"]]
      ));
    }
    items = pesanItems;
    return pesanItems;
  }

  static Future<List<Pesanan>> getPesananDitahan() async {
    Database db = await getDatabase();
    final List<Map<String, dynamic>> pesananMaps = await db.query(tableName, where: "is_paused = ? AND deleted_at IS NULL", whereArgs: [1], orderBy: "kode asc");
    List<Pesanan> dataList = <Pesanan>[];
    if (pesananMaps.isNotEmpty) {
      final List<String> listKodePesanan = pesananMaps.map((e) => e['kode'].toString()).toList();
      final List<Map<String, dynamic>> pesananItemMaps = await db.query(PesananItem.tableName, where: "kode_pesanan IN (${listKodePesanan.map((e) => '?').join(',')})", whereArgs: listKodePesanan, orderBy: "urutan asc, created_at asc");
      final listKodeProduk = pesananItemMaps.map((e) => e['kode_produk']).toList();
      final List<Map<String, dynamic>> produkMaps = await db.query(Produk.tableName, where: "kode IN (${listKodeProduk.map((e) => '?').join(',')})", whereArgs: listKodeProduk);

      for (Map<String, dynamic> pesananMap in pesananMaps) {
        Pesanan pesanan = Pesanan.fromMap(pesananMap);
        pesanan.items = pesananItemMaps.where((element) => element['kode_pesanan'] == pesanan.kode).map((e) {
            PesananItem pesananItem = PesananItem(
              kode_produk: e['kode_produk'],
              kode_pesanan: e['kode_pesanan'],
              harga: e['harga'],
              jumlah: e['jumlah'],
              created_at: e['created_at'],
              updated_at: e['updated_at'],
              urutan: e['urutan'],
              subtotal: e['subtotal'],
            );

            Map<String, dynamic> produkMap = produkMaps.firstWhere((element) => element['kode'] == e['kode_produk']);
            final Produk produk = Produk.fromMap(produkMap);
            pesananItem.produk = produk;
            return pesananItem;
          }
        ).toList();
        dataList.add(pesanan);
      }
    }
    return dataList;
  }

  static Future<void> resumePesanan(Pesanan pesanan) async {
    Database db = await getDatabase();
    await db.transaction((txn) async {
      await txn.update(tableName, {"is_draft": 1, "is_paused": 1}, where: "kode <> ? AND is_draft = 1 AND is_paused = 0 AND deleted_at IS NULL", whereArgs: [pesanan.kode]);
      await txn.update(tableName, {"is_draft": 1, "is_paused": 0}, where: "kode = ?", whereArgs: [pesanan.kode]);
    });
  }
}