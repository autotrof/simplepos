import 'dart:io' as io;
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:simplepos/models/pengaturan.dart';
import 'package:simplepos/models/produk.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';

Database? _database;
const _dbName = 'simple-pos.db';

Future<void> initDb({bool refresh = false, withSampleData = false}) async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final io.Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  String dbPath = p.join(appDocumentsDir.path, "databases", _dbName);

  if (refresh) {
    await databaseFactory.deleteDatabase(dbPath);
  }

  var db = await databaseFactory.openDatabase(dbPath);

  const sql1 = '''
    CREATE TABLE IF NOT EXISTS produk (
      kode VARCHAR(16) PRIMARY KEY,
      nama VARCHAR(255) NOT NULL,
      harga REAL NOT NULL,
      stok INT NULL,
      created_at INT DEFAULT 0,
      updated_at INT DEFAULT 0,
      deleted_at INT NULL
    )
  ''';
  await db.execute(sql1);

  const sql2 = '''
    CREATE TABLE IF NOT EXISTS pesanan (
      kode VARCHAR(16) PRIMARY KEY,
      total REAL NOT NULL DEFAULT 0,
      pajak REAL NOT NULL,
      total_akhir REAL NOT NULL GENERATED ALWAYS AS (total - pajak) STORED,
      is_draft TINYINT(1) NOT NULL DEFAULT 1,
      is_paused TINYINT(1) NOT NULL DEFAULT 0,
      created_at INT DEFAULT 0,
      updated_at INT DEFAULT 0,
      deleted_at INT DEFAULT 0
    )
  ''';
  await db.execute(sql2);

  const sql3 = '''
    CREATE TABLE IF NOT EXISTS pesanan_item (
      kode_produk VARCHAR(16),
      kode_pesanan VARCHAR(16),
      urutan INT NOT NULL DEFAULT 1,
      harga REAL NOT NULL,
      jumlah INT NOT NULL,
      subtotal REAL NOT NULL GENERATED ALWAYS AS (harga * jumlah) STORED,
      created_at INT DEFAULT 0,
      updated_at INT DEFAULT 0,

      FOREIGN KEY(kode_produk) REFERENCES produk(kode) ON UPDATE CASCADE ON DELETE CASCADE,
      FOREIGN KEY(kode_pesanan) REFERENCES pesanan(kode) ON UPDATE CASCADE ON DELETE CASCADE,
      PRIMARY KEY (kode_produk, kode_pesanan)
    )
  ''';
  await db.execute(sql3);

  const sql4 = '''
    CREATE TABLE IF NOT EXISTS pengaturan (
      key VARCHAR(125) PRIMARY KEY,
      value VARCHAR(255),
      created_at INT DEFAULT 0,
      updated_at INT DEFAULT 0
    )
  ''';
  await db.execute(sql4);

  if (withSampleData) {
    initSampleData();
  }
}

Future<Database> getDatabase() async {
  if (_database != null) {
    return _database!;
  }
  var databaseFactory = databaseFactoryFfi;
  final io.Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  String dbPath = p.join(appDocumentsDir.path, "databases", _dbName);
  var db = await databaseFactory.openDatabase(dbPath);
  return db;
}

void initSampleData() async {
  List<Produk> produkList = [];
  for (int i = 0; i < 100; i++) { 
    bool isStokNull = Random().nextBool();
    produkList.add(Produk(
      nama: 'Produk $i',
      stok: isStokNull ? Random().nextInt(100) : null,
      harga: (Random().nextDouble() * 100000).toInt().toDouble()
    ));
  }
  await Produk.saveMany(produkList);
  Pengaturan pengaturanPajak = Pengaturan(key: 'pajak', value: '11');
  await pengaturanPajak.save();
  Pengaturan pengaturanNamaToko = Pengaturan(key: 'nama_toko', value: 'Simple POS');
  await pengaturanNamaToko.save();
}