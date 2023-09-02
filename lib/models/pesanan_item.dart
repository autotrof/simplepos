// ignore_for_file: non_constant_identifier_names
import 'package:simplepos/models/model.dart';
import 'package:simplepos/models/pesanan.dart';
import 'package:simplepos/models/produk.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../db.dart';

class PesananItem extends Model{
  static const tableName = 'pesanan_item';

  String kode_produk;
  String kode_pesanan;
  int urutan;
  double harga;
  int jumlah;
  late double subtotal;
  int created_at;
  int updated_at;
  Pesanan? pesanan;
  Produk? produk;

  PesananItem({
    required this.kode_produk, 
    required this.kode_pesanan, 
    this.urutan = 1, 
    required this.harga, 
    required this.jumlah, 
    this.created_at = 0, 
    this.updated_at = 0, 
    this.produk
  }) {
    subtotal = harga * jumlah;
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'kode_produk': kode_produk,
      'kode_pesanan': kode_pesanan,
      'harga': harga,
      'jumlah': jumlah,
      'subtotal': subtotal,
      'created_at': created_at,
      'updated_at': updated_at,
      'produk': produk
    };
  }

  @override
  String toString() {
    String data = 'PesananItem{kode_produk: $kode_produk, kode_pesanan: $kode_pesanan, harga: $harga, jumlah: $jumlah, subtotal: $subtotal, created_at: $created_at, updated_at: $updated_at';
    if (pesanan != null) {
      data += ', pesanan: ${pesanan.toString()}';
    }
    if (produk != null) {
      data += ', produk: ${produk.toString()}';
    }
    data += '}';
    return data;
  }

  static PesananItem fromMap(Map<String, dynamic> data) {
    PesananItem pesananItem = PesananItem(
      kode_produk: data["kode_produk"], 
      kode_pesanan: data["kode_pesanan"], 
      harga: double.parse(data["harga"].toString()), 
      jumlah: int.parse(data["jumlah"].toString()), 
      created_at: int.parse(data["created_at"].toString()), 
      updated_at: int.parse(data["updated_at"].toString()),
    );
    if (data.containsKey('produk')) {
      pesananItem.produk = Produk(nama: data['produk']['nama'], harga: data['produk']['harga'], stok: data['produk']['stok'], kode: data['produk']['kode'], created_at: data['produk']['created_at'], updated_at:data['produk']['updated_at'], deleted_at: data['produk']['deleted_at']);
    }
    return pesananItem;
  }

  @override
  Future<PesananItem> save() async {
    Database db = await getDatabase();
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (created_at == 0) {
      created_at = now;
    }
    updated_at = now;
    Map<String, dynamic> data = toMap();
    data.remove("subtotal");
    data.remove("produk");
    data.remove("pesanan");
    await db.insert(tableName, data, conflictAlgorithm: ConflictAlgorithm.replace);
    List res = await db.query(tableName, where: "kode_pesanan = ? AND kode_produk = ?", whereArgs: [kode_pesanan, kode_produk]);
    urutan = int.parse(res[0]['urutan'].toString());
    subtotal = double.parse(res[0]['subtotal'].toString());
    return this;
  }

  static Future<PesananItem> firstWhere(String where,  List<Object> whereArgs) async {
    Database db = await getDatabase();
    final QueryCursor res = await db.queryCursor(tableName, where: where, whereArgs: whereArgs);
    await res.moveNext();
    String kode_pesanan = res.current['kode_pesanan'].toString();
    String kode_produk = res.current['kode_produk'].toString();
    int jumlah = int.parse(res.current['jumlah'].toString());
    double harga = double.parse(res.current['harga'].toString());
    int created_at = int.parse(res.current['created_at'].toString());
    int updated_at = int.parse(res.current['updated_at'].toString());
    await res.close();
    return PesananItem(kode_produk: kode_produk, kode_pesanan: kode_pesanan, harga: harga, jumlah: jumlah, created_at: created_at, updated_at: updated_at);
  }

  @override
  Future<dynamic> delete() async {
    Database db = await getDatabase();
    try {
      await db.delete(tableName, where: "kode_produk = ? AND kode_pesanan = ?", whereArgs: [kode_produk, kode_pesanan]);
    } catch (exception) {
      return exception;
    }
    return true;
  }

  static Future<int> saveMany(List<PesananItem> dataList) async {
    Database db = await getDatabase();
    Batch batch = db.batch();
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (PesananItem data in dataList) {
      if (data.created_at == 0) {
        data.created_at = now;
      }
      data.updated_at = now;
      batch.insert(tableName, data.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    List<Object?> objs = await batch.commit();
    return objs.length;
  }

  static Future<Map<String, dynamic>> get({String search = '', List<String> sort = const ['kode', 'ASC'], int page = 1}) async {
    Database db = await getDatabase();
    String query = 'SELECT $tableName.* FROM $tableName WHERE 1 = 1';
    String queryCount = 'SELECT COUNT(*) as total FROM $tableName WHERE 1 = 1';
    if (search.isNotEmpty) {
      final String whereQuery = " AND (LOWER(kode_produk) like '%${search.toLowerCase()}%' AND LOWER(kode_pesanan) like '%${search.toLowerCase()}%')";
      query += whereQuery;
      queryCount += whereQuery;
    }
    final result = await db.rawQuery(queryCount);

    if (sort.isNotEmpty) {
      query += " ORDER BY ${sort[0]} ${sort[1]}";
    }

    List<Map<String, dynamic>> maps = await db.rawQuery(query);
    List<PesananItem> dataList = [];
    if (maps.isNotEmpty) {
      for (var map in maps) {
        dataList.add(PesananItem.fromMap(map));
      }
    }

    return {
      "totalData": result[0]["total"],
      "totalPage": 1,
      "currentPage": page,
      "produkList": dataList
    };
  }
}