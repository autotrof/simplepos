import 'package:bootstrap_grid/bootstrap_grid.dart';
import 'package:flutter/material.dart';
import 'package:simplepos/models/pesanan.dart';
import 'package:simplepos/models/pesanan_item.dart';
import 'package:simplepos/models/produk.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../globals.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  static const int topHeightAdjustment = -350;
  static final AppBar appBar = AppBar(
    title: const Text('Aplikasi POS'),
  );

  late Pesanan _currentPesanan;
  late List<Produk> _items;
  late List<Produk> _itemSelected;
  late TextEditingController _cariProdukController;
  late FocusNode _inputCariProdukNode;
  late Map<String, TextEditingController> _inputJumlahPembelian;
  late ScrollController _scrollPembelianItemController;

  @override
  void initState() {
    super.initState();
    _currentPesanan = Pesanan();
    _currentPesanan.items = [];
    _cariProdukController = TextEditingController();
    _scrollPembelianItemController = ScrollController();
    _inputCariProdukNode = FocusNode();
    _items = <Produk>[];
    _itemSelected = <Produk>[];
    _inputJumlahPembelian = {};
    getProduk();

    getPembelianDraft();
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
                        Produk produkInput = _items.firstWhere((element) => element.kode == text.trim());
                        if (produkInput == null && _items.length == 1) {
                          produkInput = _items[0];
                        } else if (produkInput == null) {
                          return ;
                        }
                        tambahItemPesanan(produkInput);
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
                        physics: const ClampingScrollPhysics(),
                        child: _items.isNotEmpty ? Table(
                          columnWidths: const {
                            3: FixedColumnWidth(100),
                            4: FixedColumnWidth(60)
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder.all(color: Colors.black26),
                          children: <TableRow>[
                            ..._items.map((produk) {
                              return TableRow(
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
                                Container(
                                  alignment: Alignment.centerRight, 
                                  padding: const EdgeInsets.all(10), 
                                  child: IconButton(
                                    color: Theme.of(context).primaryColor, 
                                    icon: const Icon(Icons.shopping_cart_checkout_outlined), 
                                    onPressed: () => tambahItemPesanan(produk)
                                  )
                                )
                              ]
                            );
                            })
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
                    Row(
                      children: [
                        const Expanded(child: Text("Pembelian", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                        Padding(
                          padding: const EdgeInsets.only(right: 10), 
                          child: ElevatedButton.icon (
                            style: ButtonStyle(
                              shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              backgroundColor: _currentPesanan.items!.isNotEmpty ? MaterialStatePropertyAll(Colors.red[100]) : const MaterialStatePropertyAll(Colors.grey),
                              alignment: Alignment.centerLeft
                            ),
                            onPressed: () {
                              if (_currentPesanan.items!.isNotEmpty) {
                                tahanPesanan();
                              }
                            },
                            icon: Icon(Icons.pause, color: _currentPesanan.items!.isNotEmpty ? Colors.red : Colors.black54),
                            label: Text("Tahan", style: TextStyle(color: _currentPesanan.items!.isNotEmpty ? Colors.red : Colors.black54, fontWeight: FontWeight.bold))
                          )
                        ),
                        ElevatedButton.icon(
                          onPressed: resumePesanan, 
                          style: ButtonStyle(
                            shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            backgroundColor: MaterialStatePropertyAll(Colors.green[100]),
                            alignment: Alignment.centerLeft
                          ),
                          icon: Icon(Icons.rotate_left_outlined, color: Colors.green[600]), 
                          label: Text("Resume pembelian", style: TextStyle(color: Colors.green[600]))
                        )
                      ]
                    ),
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
                            tableHeader(data: 'nama', label: 'Produk'),
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
                        controller: _scrollPembelianItemController,
                        physics: const ClampingScrollPhysics(),
                        child: _itemSelected.isNotEmpty ? Table(
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
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        prefixIcon: IconButton(
                                          icon: const Icon(Icons.remove, color: Colors.red,  size: 18),
                                          onPressed: () {
                                            kurangiItemPesanan(entry.value);
                                          },
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(Icons.add, color: Colors.green, size: 18),
                                          onPressed: () {
                                            tambahItemPesanan(entry.value);
                                          },
                                        )
                                      ),
                                      textAlign: TextAlign.center,
                                      onChanged: (text) async {
                                        if (text.isEmpty || text.trim() == '' || text.trim() == '0') {
                                          _inputJumlahPembelian[entry.value.kode]?.text = "1";
                                        }
                                        if (int.tryParse(text) != null) {
                                          PesananItem item = _currentPesanan.items!.firstWhere((element) => element.kode_produk == entry.value.kode);
                                          item.jumlah = int.parse(_inputJumlahPembelian[entry.value.kode]!.text);
                                          await item.save();
                                          await _currentPesanan.save();
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
                                        Icons.highlight_remove, 
                                        color: Colors.redAccent, 
                                        weight: 1
                                      ),
                                      onPressed: () {
                                        hapusItemPesanan(entry.value);
                                      }
                                    )
                                  )
                                ]
                              )
                            ).toList()
                          ],
                        ) : Table(
                          border: TableBorder.all(color: Colors.black26),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(color: Colors.yellow[50]),
                              children: const [
                                Padding(padding: EdgeInsets.all(10), child: Text('Tidak ada item dipilih', textAlign: TextAlign.center, style: TextStyle(color: Colors.red)))
                              ]
                            )
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
                      child: ElevatedButton.icon (
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight),
                          alignment: Alignment.centerLeft
                        ),
                        onPressed: () {}, 
                        icon: const Icon(Icons.print),
                        label: const Text("Cetak"),
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7), 
                      child: ElevatedButton.icon (
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight),
                          alignment: Alignment.centerLeft
                        ),
                        onPressed: () async {
                          await payPesanan();
                        }, 
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text("Bayar")
                      )
                    ),
                  ]
                ),
              ),
              Expanded(child: Container(
                padding: const EdgeInsets.only(bottom: 8, left: 16),
                decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    SelectableText("Rp ${getTotal(rounded: true)}", style: const TextStyle(color: Colors.black, fontSize: 40, fontWeight: FontWeight.bold)),
                    SelectableText("  ${getTotal() !='0' ? getTotal() : ''}", style: const TextStyle(color: Colors.black12, fontSize: 40, fontWeight: FontWeight.bold))
                  ]
                ),
              ))
            ],
          ),
        )
      ])
    );
  }
  
  Future<void> getProduk() async {
    _items.clear();
    Map<String, dynamic> produkData = await Produk.get(search: _cariProdukController.text, limit: 0, sort: ['nama', 'asc']);
    _items = produkData["produkList"];
    setState(() {});
  }

  Future<void> getPembelianDraft() async {
    _itemSelected.clear();
    Pesanan? pesananDraft = await Pesanan.firstWhere("is_draft = ? AND is_paused = ? AND deleted_at IS NULL", [1, 0]);
    if (pesananDraft == null) return;

    await pesananDraft.getItem();
    _currentPesanan = pesananDraft;

    for (PesananItem item in _currentPesanan.items!) {
      Produk produk = item.produk!;
      _inputJumlahPembelian[produk.kode] = TextEditingController();
      _itemSelected.add(produk);
      _inputJumlahPembelian[produk.kode]!.text = item.jumlah.toString();
    }
    _scrollPembelianItemController.animateTo(_scrollPembelianItemController.position.maxScrollExtent + 1000, duration: const Duration(milliseconds: 50), curve: Curves.easeInOut);

    setState(() {});
  }

  String getTotal({bool rounded = false}) {
    double total = _currentPesanan.total;
    if (rounded) {
      double potongan = (total % 100);
      if (potongan > 50) {
        return formatter.format(total + 100 - potongan);
      }
      return formatter.format(total - potongan);
    }
    return formatter.format(total);
  }

  Future<void> kurangiItemPesanan (Produk produk) async {
    String jumlah = _inputJumlahPembelian[produk.kode]!.text;
    if (int.tryParse(_inputJumlahPembelian[produk.kode]!.text) != null) {
      int jumlahBaru = int.parse(jumlah) - 1;
      if (jumlahBaru == 0) {
        return await hapusItemPesanan(produk);
      }
      PesananItem item = _currentPesanan.items!.firstWhere((element) => element.kode_produk == produk.kode);
      item.jumlah = jumlahBaru;
      await item.save();
      await _currentPesanan.save();
      _inputJumlahPembelian[produk.kode]!.text = jumlahBaru.toString();
      setState(() {});
    }
  }

  Future<void> tambahItemPesanan (Produk produk) async {
    if (_inputJumlahPembelian[produk.kode] == null) {
      _inputJumlahPembelian[produk.kode] = TextEditingController();
    }

    if (int.tryParse(_inputJumlahPembelian[produk.kode]!.text) == null && _inputJumlahPembelian[produk.kode]!.text != '') {
      return;
    }

    Produk? produkSelected;
    for (int i = 0; i < _itemSelected.length; i++) {
      if (_itemSelected[i].kode == produk.kode) {
        produkSelected = _itemSelected.firstWhere((element) => element.kode == produk.kode);
        break;
      }
    }

    late int jumlah;
    late PesananItem pesananItem;
    if (produkSelected == null) {
      _inputJumlahPembelian[produk.kode]!.text = "1";
      _itemSelected.add(produk);
      _scrollPembelianItemController.animateTo(_scrollPembelianItemController.position.maxScrollExtent + 1000, duration: const Duration(milliseconds: 50), curve: Curves.easeInOut);

      await _currentPesanan.save();
      jumlah = 1;
      pesananItem = PesananItem(kode_pesanan: _currentPesanan.kode, kode_produk: produk.kode, harga: produk.harga, jumlah: jumlah);
    } else {
      jumlah = int.parse(_inputJumlahPembelian[produk.kode]!.text);
      jumlah++;

      pesananItem = await PesananItem.firstWhere("kode_pesanan = ? AND kode_produk = ?", [_currentPesanan.kode, produk.kode]);
      pesananItem.jumlah = jumlah;
    }
    PesananItem item = await pesananItem.save();
    _currentPesanan.items!.add(item);
    await _currentPesanan.save();

    _inputJumlahPembelian[produk.kode]!.text = jumlah.toString();
    setState(() {});
  }

  Future<void> hapusItemPesanan (Produk produk) async {
    PesananItem item = _currentPesanan.items!.firstWhere((element) => element.kode_produk == produk.kode);
    await item.delete();
    await _currentPesanan.save();
    _itemSelected.removeWhere((element) => element.kode == item.kode_produk);
    setState(() {});
  }

  Future<void> payPesanan() async {
    _currentPesanan.is_draft = 0;
    await _currentPesanan.save();
    showTopSnackBar(
        // ignore: use_build_context_synchronously
        Overlay.of(context),
        const CustomSnackBar.success(
          message: "Berhasil menyimpan pesanan",
        ),
    );
  }

  Future<void> tahanPesanan() async {
    _currentPesanan.is_paused = 1;
    await _currentPesanan.save();
    _currentPesanan = Pesanan();
    _currentPesanan.items = [];
    _itemSelected = [];
    setState(() {});
  }

  void resumePesanan() {
    showDialog(context: context, builder: (BuildContext ctx1) {
      return const AlertDialog(
        content: ResumePembelianPopup()
      );
    })
    .then((value) {
      getPembelianDraft();
    });
  }
}

class ResumePembelianPopup extends StatefulWidget {
  const ResumePembelianPopup({super.key});

  @override
  State<ResumePembelianPopup> createState() => _ResumePembelianPopupState();
}

class _ResumePembelianPopupState extends State<ResumePembelianPopup> {
  List<Pesanan> listPesananDitahan = [];

  @override
  void initState() {
    super.initState();
    getPesananDitahan();
  }

  Future<void> getPesananDitahan() async {
    listPesananDitahan = await Pesanan.getPesananDitahan();
    setState((){});
  }

  void hapusPembelianDraft(Pesanan pesanan) {
    AlertDialog alert = AlertDialog(
      title: const Text("Konfirmasi hapus draft pembelian"),
      content: const Text("Anda yakin akan menghapus draft pembelian tersebut ?"),
      actions: [
        TextButton(
          onPressed: () async {
            await pesanan.delete();
            listPesananDitahan.removeWhere((element) => element.kode == pesanan.kode);
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
            setState((){});
          }, 
          child: const Text("Ya Hapus", style: TextStyle(color: Colors.red))
        ),
        const Padding(padding: EdgeInsets.all(10)),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text("Batal", style: TextStyle(color: Theme.of(context).primaryColor))
        )
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width - 100;
    double screenHeight = MediaQuery.of(context).size.height - 100;

    if (screenWidth > 1200) {
      screenWidth = 1200;
    } else {
      screenWidth -= 100;
    }
    
    return SizedBox(
      width: screenWidth,
      height: screenHeight,
      child: Column(
        children: [
          const Padding(padding: EdgeInsets.only(top:10, bottom: 20), child: Text("Daftar Pembelian Ditahan", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600))),
          Expanded(
            child: listPesananDitahan.isNotEmpty ? 
            ListView(
              children: listPesananDitahan.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 15), 
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.black12, width: 1),
                    color: Colors.white70
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(100)
                              },
                              children: [
                                TableRow(
                                  children: [
                                    const Text("Kode"),
                                    Text(": ${e.kode}")
                                  ]
                                ),
                                TableRow(
                                  children: [
                                    const Text("Waktu"),
                                    Text(": ${DateTime.fromMillisecondsSinceEpoch(e.created_at).toString()}")
                                  ]
                                ),
                                TableRow(
                                    children: [
                                      const Text("Total"),
                                      Text(": ${e.total.toString()}")
                                    ]
                                )
                              ]
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                style: ButtonStyle(
                                  shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(7), side: BorderSide(color: Theme.of(context).primaryColor, width: 0.1))),
                                  backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight)
                                ),
                                onPressed: () async {
                                  await Pesanan.resumePesanan(e);
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                }, 
                                child: const Text("Buka")
                              ),
                              const Padding(padding: EdgeInsets.all(3)),
                              TextButton(
                                style: ButtonStyle(
                                  shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(7), side: BorderSide(color: Colors.red[300]!, width: 0.1))),
                                  foregroundColor: const MaterialStatePropertyAll(Colors.red),
                                  backgroundColor: MaterialStatePropertyAll(Colors.red[100])
                                ),
                                onPressed: (){
                                  hapusPembelianDraft(e);
                                },
                                child: const Text("Hapus")
                              )
                            ],
                          )
                        ],
                      ),
                      const Padding(padding: EdgeInsets.only(top: 15)),
                      Table(
                        border: TableBorder.all(color: Colors.black26, width: 0.4),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Colors.white),
                            children: [
                              tableHeader(data: 'nama', label: 'Produk', padding: 6),
                              tableHeader(data: 'nama', label: 'Jumlah', padding: 6),
                              tableHeader(data: 'harga', label: 'Harga', padding: 6),
                              tableHeader(data: 'harga', label: 'Subtotal', padding : 6),
                            ]
                          ),
                          ...e.items!.map((item) => TableRow(
                            children: [
                              Container(
                                padding: const EdgeInsets.only(left:5, right: 5, top: 10, bottom: 10),
                                child: SelectableText(item.produk!.nama)
                              ),
                              Container(
                                padding: const EdgeInsets.only(left:5, right: 5, top: 10, bottom: 10),
                                child: SelectableText(item.jumlah.toString())
                              ),
                              Container(
                                padding: const EdgeInsets.only(left:5, right: 5, top: 10, bottom: 10),
                                child: SelectableText(item.produk!.harga.toString())
                              ),
                              Container(
                                padding: const EdgeInsets.only(left:5, right: 5, top: 10, bottom: 10),
                                child: SelectableText(item.subtotal.toString())
                              )
                            ]
                          )).toList()
                        ],
                      )
                    ],
                  ),
                )
              )).toList(),
            )
            :
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: const Text("Data Pesanan Ditahan Tidak Ditemukan", style: TextStyle(fontSize: 30, color: Colors.grey)),
            )
          )
        ],
      )
    );
  }
}