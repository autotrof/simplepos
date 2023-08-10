import 'dart:io' as io;
import 'dart:math';
import 'package:path/path.dart' as p;
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
      CREATE TABLE IF NOT EXISTS produk(
        kode VARCHAR(10) PRIMARY KEY,
        nama VARCHAR(255) NOT NULL,
        harga DOUBLE NOT NULL,
        stok INT NULL,
        created_at INT DEFAULT 0,
        updated_at INT DEFAULT 0
      )
  ''';
  await db.execute(sql1);

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
  for (int i = 0; i < 230; i++) { 
    bool isStokNull = Random().nextBool();
    produkList.add(Produk(
      kode: 'P$i', 
      nama: 'Produk $i', 
      stok: isStokNull ? Random().nextInt(100) : null,
      harga: Random().nextDouble() * 100000
    ));
  }
  await Produk.saveMany(produkList);
}

/* Future<Database> getDatabase() async {
  if (_database != null) {
    return _database!;
  }
  String dbPath = join(await getDatabasesPath(), _dbName);
  _database = await openDatabase(dbPath, onCreate: (db, version) {
    // RECREATE ALL TABLES
    const sql1 = '''
      CREATE TABLE IF NOT EXISTS produk(
        kode VARCHAR(10) PRIMARY KEY,
        nama VARCHAR(255) NOT NULL,
        harga DOUBLE NOT NULL
        stok INT NULL,
        created_at INT DEFAULT 0,
        updated_at INT DEFAULT 0
      )
    ''';
    /* const sql2 = '''
      CREATE TABLE IF NOT EXISTS pembelian(
        id VARCHAR(40) PRIMARY KEY,
        tanggal VARCHAR(10) NOT NULL,
        total_pembelian DOUBLE NOT NULL,
        total_pajak DOUBLE NOT NULL,
        created_at INT DEFAULT 0,
        updated_at INT DEFAULT 0
      )
    ''';
    const sql3 = '''
      CREATE TABLE IF NOT EXISTS pembelian_produk(
        id VARCHAR(40) PRIMARY KEY,
        produk_kode VARCHAR(10) NOT NULL,
        jumlah SMALLINT NOT NULL,
        harga DOUBLE NOT NULL,
        sub_total DOUBLE NOT NULL,
        pajak DOUBLE NOT NULL,
        created_at INT DEFAULT 0,
        updated_at INT DEFAULT 0,
        FOREIGN KEY (produk_kode) REFERENCES produk(kode)
      )
    '''; */
    // const sqlCreateUniqueIndexLabelProgramsTable = 'CREATE UNIQUE INDEX label ON program(label)';
    // const sqlCreateIndexTanggalTransaksiTable = 'CREATE INDEX tanggal ON transaksi(tanggal)';
    // const sqlCreateIndexNominalTransaksiTable = 'CREATE INDEX nominal ON transaksi(nominal)';
    // const sqlCreateIndexCreatedAtTransaksiTable = 'CREATE INDEX createdAt ON transaksi(nominal)';
    // const sqlCreateIndexUpdatedAtTransaksiTable = 'CREATE INDEX updatedAt ON transaksi(nominal)';

    // TABLE
    db.execute(sql1);
    // db.execute(sqlCreateTransaksiTable);

    // INDEX
    // db.execute(sqlCreateUniqueIndexLabelProgramsTable);
    // db.execute(sqlCreateIndexTanggalTransaksiTable);
    // db.execute(sqlCreateIndexNominalTransaksiTable);
    // db.execute(sqlCreateIndexCreatedAtTransaksiTable);
    // db.execute(sqlCreateIndexUpdatedAtTransaksiTable);
  }, version: _dbVersion);
  return _database!;
} */