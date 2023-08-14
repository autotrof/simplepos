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
  static const int topHeightAdjustment = -290;
  AppBar appBar = AppBar(
    title: const Text('Test'),
  );

  List<Produk> _items = <Produk>[];
  final List<Produk> _itemSelected = <Produk>[];
  // search produk by kode or nama controller
  late TextEditingController _cariProdukController;
  late FocusNode _inputCariProdukNode;
  final Map<String, TextEditingController> _inputJumlahPembelian = {};

  final formatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

  void getProduk() async {
    Map<String, dynamic> produkData = await Produk.get(search: _cariProdukController.text, limit: 0, sort: ['nama', 'asc']);
    _items = produkData["produkList"];
    setState(() {});
  }

  String getTotal({bool rounded = false}) {
    double total = 0;
    for (Produk produk in _itemSelected) {
      if (int.tryParse(_inputJumlahPembelian[produk.kode]!.text) != null) {
        int jumlah = int.parse(_inputJumlahPembelian[produk.kode]!.text);
        total += jumlah * produk.harga;
      }
    }
    if (rounded) {
      double potongan = (total % 100);
      if (potongan > 50) {
        return formatter.format(total + 100 - potongan);
      }
      return formatter.format(total - potongan);
    }
    return formatter.format(total);
  }

  @override
  void initState() {
    super.initState();
    _cariProdukController = TextEditingController();
    _inputCariProdukNode = FocusNode();
    getProduk();
  }

  Widget tableHeader ({required String data, String label = '', bool sortable = true}) {
    Widget innerWidget = Container(
      decoration: BoxDecoration(color: Theme.of(context).primaryColorLight),
      padding: const EdgeInsets.all(10), 
      child: SelectableText(label.isEmpty ? data : label, style: const TextStyle(fontWeight: FontWeight.bold))
    );

    return innerWidget;
  }

  void addProduk(Produk produk) {
    if (_inputJumlahPembelian[produk.kode] == null) {
      _inputJumlahPembelian[produk.kode] = TextEditingController();
    }

    Produk? produkSelected;
    for (int i = 0; i < _itemSelected.length; i++) {
      if (_itemSelected[i].kode == produk.kode) {
        produkSelected = _itemSelected.firstWhere((element) => element.kode == produk.kode);
        break;
      }
    }

    if (produkSelected == null) {
      _itemSelected.add(produk);
      _inputJumlahPembelian[produk.kode]!.text = "1";
    } else {
      int jumlah = int.parse(_inputJumlahPembelian[produk.kode]!.text);
      jumlah++;
      _inputJumlahPembelian[produk.kode]!.text = jumlah.toString();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Column(children: [
        BootstrapRow(children: [
          BootstrapCol(
            xs: 6,
            sm: 7,
            md: 7,
            lg: 7,
            xl: 7,
            xxl: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 15, top: 10),
                  child: TextFormField(
                    autocorrect: true,
                    focusNode: _inputCariProdukNode,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(9)), borderSide: BorderSide(color: Colors.black38)),
                      labelText: 'Cari Produk',
                      filled: true,
                      fillColor: Colors.white
                    ),
                    onChanged: (text) {
                      getProduk();
                    },
                    onFieldSubmitted: (text) {
                      if (text.trim().isNotEmpty) {
                        Produk? produkInput = _items.firstWhere((element) => element.kode == text.trim());
                        if (produkInput == null && _items.length == 1) {
                          produkInput = _items[0];
                        } else if (produkInput == null) {
                          return ;
                        }
                        addProduk(produkInput);
                        _cariProdukController.clear();
                        getProduk();
                        _inputCariProdukNode.requestFocus();
                      }
                    },
                    controller: _cariProdukController
                  )
                ),
                Column(
                  children: [
                    Table(
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
                        )
                      ]
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - appBar.preferredSize.height + topHeightAdjustment,
                      child: SingleChildScrollView(
                        primary: true,
                        physics: const ClampingScrollPhysics(),
                        child: _items.isNotEmpty ? Table(
                          columnWidths: const {
                            3: FixedColumnWidth(100),
                            4: FixedColumnWidth(60)
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder.all(color: Colors.black26),
                          children: <TableRow>[
                            ..._items.map((produk) => TableRow(
                              decoration: const BoxDecoration(color: Colors.white),
                              children: [
                                Container(padding: const EdgeInsets.all(10), child: SelectableText(produk.kode)),
                                Container(padding: const EdgeInsets.all(10), child: SelectableText(produk.nama)),
                                Container(padding: const EdgeInsets.all(10), child: SelectableText("Rp ${formatter.format(produk.harga.ceil())}")),
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(10), 
                                  child: produk.stok.toString() == 'null' ? 
                                    const Text("∞", style: TextStyle(color: Colors.green))
                                    :
                                    SelectableText(formatter.format(produk.stok).toString())
                                ),
                                Container(alignment: Alignment.centerRight, padding: const EdgeInsets.all(10), child: IconButton(color: Theme.of(context).primaryColor, icon: const Icon(Icons.shopping_cart_checkout_outlined), onPressed: (){ addProduk(produk); }))
                              ]
                            ))
                            .toList()
                          ],
                        ) : Table(
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder.all(color: Colors.black26),
                          children: <TableRow>[
                            TableRow(
                              children: [
                                Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                                  decoration: BoxDecoration(color: Colors.amber[50]),
                                  child: const Text("Produk tidak ditemukan", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                                )
                              ]
                            )
                          ],
                        ),
                      ),
                    ),
                    Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12, width: 2))))
                  ],
                )
              ])
            )
          ),
          BootstrapCol(
            xs: 6,
            sm: 5,
            md: 5,
            lg: 5,
            xl: 5,
            xxl: 4,
            child: Padding(
              padding: const EdgeInsets.only(top:18, left: 8, right: 8, bottom: 8),
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
                      columnWidths: const {
                        4: FixedColumnWidth(60)
                      },
                      children: [
                        TableRow(
                          children: [
                            tableHeader(data: 'kode', label: 'Produk'),
                            tableHeader(data: 'nama', label: 'Jumlah'),
                            tableHeader(data: 'harga', label: 'Harga'),
                            tableHeader(data: 'harga', label: 'Subtotal'),
                            tableHeader(data: 'kode', label: ' '),
                          ]
                        )
                      ]
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - appBar.preferredSize.height - 25 + topHeightAdjustment,
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Table(
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder.all(color: Colors.black26),
                          columnWidths: const {
                            4: FixedColumnWidth(60)
                          },
                          children: [
                            ..._itemSelected.asMap().entries.map((entry) => TableRow(
                                decoration: const BoxDecoration(color: Colors.white),
                                children: [
                                  Container(padding: const EdgeInsets.all(10), child: SelectableText(entry.value.nama)),
                                  Padding(
                                    padding: const EdgeInsets.all(10), 
                                    child: TextFormField(
                                      decoration: InputDecoration(
                                        prefixIcon: IconButton(
                                          icon: Icon(Icons.remove, color: Colors.red[400]),
                                          onPressed: () {
                                            String jumlah = _inputJumlahPembelian[entry.value.kode]!.text;
                                            if (int.tryParse(_inputJumlahPembelian[entry.value.kode]!.text) != null && jumlah != "1") {
                                              int jumlahBaru = int.parse(jumlah) - 1;
                                              _inputJumlahPembelian[entry.value.kode]!.text = jumlahBaru.toString();
                                              setState(() {});
                                            }
                                          },
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            addProduk(entry.value);
                                          },
                                        )
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (text) {
                                        if (int.tryParse(text) != null) {
                                          if (text.isEmpty) {
                                            _inputJumlahPembelian[entry.value.kode]?.text = "1";
                                          }
                                          setState(() {});
                                        }
                                      },
                                      controller: _inputJumlahPembelian[entry.value.kode]
                                    )
                                  ),
                                  Container(padding: const EdgeInsets.all(10), child: SelectableText(formatter.format(entry.value.harga.ceil()))),
                                  Container(padding: const EdgeInsets.all(10), child: SelectableText(formatter.format((entry.value.harga * int.parse(_inputJumlahPembelian[entry.value.kode]!.text)).ceil()))),
                                  Container(
                                    padding: const EdgeInsets.all(10), 
                                    alignment: Alignment.center,
                                    child: IconButton(
                                      style: ButtonStyle(
                                        padding: const MaterialStatePropertyAll(EdgeInsets.all(0)),
                                        shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(18)))
                                      ),
                                      tooltip: "Hapus item",
                                      icon: const Icon(
                                        Icons.delete_forever_rounded, 
                                        color: Colors.redAccent, 
                                        weight: 1
                                      ),
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
                        ),
                      ),
                    ),

                  ],
                ),
              ))
            )
        ]),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7), 
                      child: TextButton(
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight),
                          alignment: Alignment.centerLeft
                        ),
                        onPressed: () {}, 
                        child: const Text("Cetak")
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7), 
                      child: TextButton(
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight),
                          alignment: Alignment.centerLeft
                        ),
                        onPressed: () {}, 
                        child: const Text("Bayar")
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 0), 
                      child: TextButton(
                        style: ButtonStyle(
                          textStyle: MaterialStatePropertyAll(TextStyle(color: Colors.red[400])),
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          backgroundColor: MaterialStatePropertyAll(Colors.red[200]),
                          alignment: Alignment.centerLeft
                        ),
                        onPressed: () {}, 
                        child: const Text("Tahan")
                      )
                    ),
                  ]
                ),
              ),
              Expanded(child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    SelectableText("Rp ${getTotal()}", style: const TextStyle(color: Colors.black87, fontSize: 40, fontWeight: FontWeight.bold)),
                    SelectableText("  ${double.parse(getTotal(rounded: true)) > 0 ? getTotal(rounded: true) : ''}", style: const TextStyle(color: Colors.black12, fontSize: 40, fontWeight: FontWeight.bold)),
                  ]
                ),
              ))
            ],
          ),
        )
      ])
    );
  }
}