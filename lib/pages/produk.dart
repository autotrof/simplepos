import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

import '../models/produk.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key, required this.title});

  final String title;

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  List<Produk> _items = <Produk>[];
  final _cariProdukController = TextEditingController();
  List<String> _sort = ['kode', 'desc'];
  int _page = 1;

  void addNewProduk() {}

  @override
  void initState() {
    super.initState();
    getProduk();
  }

  void getProduk({bool reset = false}) async {
    if (reset) {
      _page = 1;
    }
    Map<String, dynamic> produkData = await Produk.get(search: _cariProdukController.text, sort: _sort, page: _page);
    _items = produkData["produkList"];
    setState(() {});
  }

  void changeSort(String kolom) {
    String direction = 'asc';
    if (kolom == _sort[0]) {
      direction = _sort[1] == 'asc' ? 'desc' : 'asc';
    }
    setState(() {
      _sort = [kolom, direction];
    });
    getProduk();
  }

  Widget tableHeader ({required String data, String label = '', bool sortable = true}) {
    Widget sortView = const SizedBox.shrink();
    Color? bgColor = Colors.white;
    if (_sort[0] == data) {
      String img = 'assets/images/sort_asc.svg';
      bgColor = Colors.green[50];
      if (_sort[1] == 'desc') {
        img = 'assets/images/sort_desc.svg';
        bgColor = Colors.orange[50];
      }
      sortView = SvgPicture.asset(img, width: 18, height: 18);
    }


    Widget innerWidget = Container(
      decoration: BoxDecoration(color: bgColor),
      padding: const EdgeInsets.all(10), 
      child: Row(
        children: [
          Expanded(child: Text(label.isEmpty ? data : label, style: const TextStyle(fontWeight: FontWeight.bold))),
          sortView
        ],
      )
    );

    if (!sortable) {
      return innerWidget;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        changeSort(data);
      }, 
      child: innerWidget
    );
  }

  @override
  Widget build(BuildContext context) {
    List<TableRow> tableBody = [];
    var formatter = NumberFormat('#,###');
    for (Produk produk in _items) {
      tableBody.add(
        TableRow(
          children: [
            Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text(produk.kode)),
            Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text(produk.nama)),
            Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text("Rp ${formatter.format(produk.harga.ceil())}")),
            produk.stok.toString() == 'null' ? 
            Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: const Text("∞", style: TextStyle(color: Colors.green)))
            :
            Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text(formatter.format(produk.stok).toString()))
            ,
            Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: const Text('#')),
          ]
        )
      );
    }

    List<TableRow> rows = [
      TableRow(
        children: [
          tableHeader(data: 'kode', label: 'Kode'),
          tableHeader(data: 'nama', label: 'Produk'),
          tableHeader(data: 'harga', label: 'Harga'),
          tableHeader(data: 'stok', label: 'Stok'),
          tableHeader(data: '#'),
        ]
      ),
      ...tableBody
    ];
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[200]),
        padding: const EdgeInsets.all(8),
        child: Column(children: [
          Container(decoration: const BoxDecoration(color: Colors.white), margin: const EdgeInsets.only(bottom: 15, top: 10), child: TextFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Cari Produk',
            ),
            onChanged: (text) {
              getProduk(reset: true);
            },
            controller: _cariProdukController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nominal tidak boleh kosong';
              }
              return null;
            },
            // inputFormatters: [ThousandsSeparatorInputFormatter()],
          )),
          Expanded(child: SingleChildScrollView(child: Column(children: [
            Table(
              border: TableBorder.all(color: Colors.black38),
              children: rows,
            )
          ]))),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewProduk,
        tooltip: 'Tambah Produk Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}