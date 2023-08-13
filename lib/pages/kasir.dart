import 'dart:js_interop';

import 'package:bootstrap_grid/bootstrap_grid.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplepos/models/produk.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  AppBar appBar = AppBar(
    title: const Text('Test'),
  );

  List<Produk> _items = <Produk>[];
  final List<Map<String, dynamic>> _itemSelected = <Map<String, dynamic>>[];
  // search produk by kode or nama controller
  final _cariProdukController = TextEditingController();

  void getProduk() async {
    Map<String, dynamic> produkData = await Produk.get(search: _cariProdukController.text, limit: 0, sort: ['nama', 'asc']);
    _items = produkData["produkList"];
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getProduk();
  }

  Widget tableHeader ({required String data, String label = '', bool sortable = true}) {
    Widget innerWidget = Container(
      decoration: const BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.all(10), 
      child: Text(label.isEmpty ? data : label, style: const TextStyle(fontWeight: FontWeight.bold))
    );

    return innerWidget;
  }

  var formatter = NumberFormat('#,###');

  void addProduk(Produk produk) {
    Map<String, dynamic>? produkSelected;
    int index = 0;
    for (int i = 0; i < _itemSelected.length; i++) {
      index = i;
      if (_itemSelected[i]['produk'].kode == produk.kode) {
        produkSelected = _itemSelected.firstWhere((element) => element['produk'].kode == produk.kode);
        break;
      }
    }

    if (produkSelected == null) {
      _itemSelected.add({
        "produk": produk,
        "jumlah": 1
      });
    } else {
      _itemSelected[index]['jumlah']++;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: BootstrapRow(children: [
        BootstrapCol(
          xs: 6,
          sm: 7,
          md: 7,
          lg: 7,
          xl: 8,
          xxl: 8,
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Container(
                margin: const EdgeInsets.only(bottom: 15, top: 10),
                child: TextFormField(
                  decoration: const InputDecoration(
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(9)), borderSide: BorderSide(color: Colors.black38)),
                    labelText: 'Cari Produk',
                    filled: true,
                    fillColor: Colors.white
                  ),
                  onChanged: (text) {
                    getProduk();
                  },
                  controller: _cariProdukController
                )
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height - appBar.preferredSize.height - 110,
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: const {
                      3: FixedColumnWidth(100),
                      4: FixedColumnWidth(60)
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    border: TableBorder.all(color: Colors.black26),
                    children: <TableRow>[
                      TableRow(
                        children: [
                          tableHeader(data: 'kode', label: 'Kode'),
                          tableHeader(data: 'nama', label: 'Produk'),
                          tableHeader(data: 'harga', label: 'Harga'),
                          tableHeader(data: 'stok', label: 'Stok'),
                          tableHeader(data: '', label: ''),
                        ]
                      ),
                      ..._items.map((produk) => TableRow(
                        decoration: const BoxDecoration(color: Colors.white),
                        children: [
                          Container(padding: const EdgeInsets.all(10), child: Text(produk.kode)),
                          Container(padding: const EdgeInsets.all(10), child: Text(produk.nama)),
                          Container(padding: const EdgeInsets.all(10), child: Text("Rp ${formatter.format(produk.harga.ceil())}")),
                          (
                            produk.stok.toString() == 'null' ? 
                            Container(padding: const EdgeInsets.all(10), child: const Text("∞", style: TextStyle(color: Colors.green)))
                            :
                            Container(padding: const EdgeInsets.all(10), child: Text(formatter.format(produk.stok).toString()))
                          ),
                          Container(alignment: Alignment.centerRight, padding: const EdgeInsets.all(10), child: IconButton(icon: const Icon(Icons.shopping_cart_checkout_outlined), onPressed: (){ addProduk(produk); }))
                        ]
                      ))
                      .toList()
                    ],
                  ),
                ),
              )
            ])
          )
        ),
        BootstrapCol(
          xs: 6,
          sm: 5,
          md: 5,
          lg: 5,
          xl: 4,
          xxl: 4,
          child: Padding(
            padding: const EdgeInsets.only(top:18, left: 8, right: 8, bottom: 8),
            child: Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white
                  ),
                  child: Column(
                    children: [
                      const Text("Pembelian", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      const Divider(color: Colors.black, height: 40, thickness: 0.3, indent: 0),
                      Table(
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        border: TableBorder.all(color: Colors.black26),
                        children: [
                          TableRow(
                            children: [
                              tableHeader(data: 'kode', label: 'Produk'),
                              tableHeader(data: 'nama', label: 'Jumlah'),
                              tableHeader(data: 'harga', label: 'Harga'),
                              tableHeader(data: 'harga', label: 'Subtotal'),
                              tableHeader(data: 'kode', label: '###'),
                            ]
                          ),
                          ..._itemSelected.asMap().entries.map((entry) =>
                            TableRow(
                              decoration: const BoxDecoration(color: Colors.white),
                              children: [
                                Container(padding: const EdgeInsets.all(10), child: Text(entry.value["produk"].kode)),
                                Container(padding: const EdgeInsets.all(10), child: Text(entry.value["jumlah"].toString())),
                                Container(padding: const EdgeInsets.all(10), child: Text(entry.value["produk"].harga.toString())),
                                Container(padding: const EdgeInsets.all(10), child: Text((entry.value["produk"].harga * entry.value["jumlah"]).toString())),
                                Container(
                                  padding: const EdgeInsets.all(10), 
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    style: ButtonStyle(
                                      backgroundColor: const MaterialStatePropertyAll(Colors.red),
                                      shape: MaterialStatePropertyAll(BeveledRectangleBorder(borderRadius: BorderRadius.circular(10)))
                                    ),
                                    tooltip: "Hapus pesanan",
                                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, weight: 1),
                                    onPressed: (){
                                      final index = entry.key;
                                      _itemSelected.removeAt(index);
                                      setState(() {});
                                    }
                                  )
                                )
                              ]
                            )
                          ).toList()
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ))
          )
      ])
    );
  }
}