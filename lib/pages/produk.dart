// import 'package:barcode/barcode.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simplepos/globals.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import '../models/produk.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  late List<Produk> _items;
  late List<String> _sort;
  late int _page;
  late List<int> _pageList;

  late GlobalKey<FormState> _formKey;
  late TextEditingController _cariProdukController;
  late TextEditingController _inputKodeProdukController;
  late TextEditingController _inputNamaProdukController;
  late TextEditingController _inputHargaProdukController;
  late TextEditingController _inputStokProdukController;
  late bool _showClearButton;

  @override
  void initState() {
    super.initState();
    _cariProdukController = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _inputKodeProdukController = TextEditingController();
    _inputNamaProdukController = TextEditingController();
    _inputHargaProdukController = TextEditingController();
    _inputStokProdukController = TextEditingController();
    _showClearButton = false;

    _page = 1;
    _pageList = [];
    _sort = ['kode', 'desc'];
    _items = <Produk>[];
    getProduk();
    _requestPermission();
  }

  Future<bool> _requestPermission() async {
    Map<Permission, PermissionStatus> result = await [Permission.storage, Permission.camera].request();
    debugPrint(result[Permission.storage].toString());
    debugPrint(result[Permission.camera].toString());
    if (result[Permission.storage] == PermissionStatus.granted && result[Permission.camera] == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  Future<void> hapusProduk(Produk produk) async {
    final bool confirmed = await alertConfirmation(context: context, text: "Anda yakin akan menghapus data produk ${produk.nama} ?");
    if (confirmed) {
      dynamic deleteResult = await produk.delete();
      if (deleteResult == true) {
        // ignore: use_build_context_synchronously
        showTopSnackBar(
            // ignore: use_build_context_synchronously
            Overlay.of(context),
            CustomSnackBar.success(
              message: "Berhasil menghapus produk ${produk.nama}",
            ),
        );
        getProduk();
      } else {
        // ignore: use_build_context_synchronously
        alertError(context: context, text: deleteResult.toString());
      }
    }
  }

  Future<void> simpanProduk() async {
    if (_formKey.currentState!.validate()) {
      final harga = double.parse(_inputHargaProdukController.text.replaceAll(',', ''));
      dynamic stok;
      if (_inputStokProdukController.text.isNotEmpty) {
        stok = int.parse(_inputStokProdukController.text.replaceAll(',', ''));
      }
      try {
        Produk produk = Produk(kode: _inputKodeProdukController.text, nama: _inputNamaProdukController.text, harga: harga, stok: stok);
        await produk.save();
        getProduk();
        _inputKodeProdukController.clear();
        _inputNamaProdukController.clear();
        _inputHargaProdukController.clear();
        _inputStokProdukController.clear();
      } catch (e) {
        // ignore: use_build_context_synchronously
        alertError(context: context, text: "Gagal menyimpan produk : ${e.toString()}");
      }
    }
  }

  void showModalProduk({String type = 'create', Produk? produk}) {
    _inputKodeProdukController.text = '';
    _inputNamaProdukController.text = '';
    _inputHargaProdukController.text = '';
    _inputStokProdukController.text = '';
    if (type == 'edit') {
      _inputKodeProdukController.text = produk!.kode;
      _inputNamaProdukController.text = produk.nama;
      _inputHargaProdukController.text = produk.harga.toString();
      if (produk.stok != null) {
        _inputStokProdukController.text = produk.stok.toString();
      }
    }

    showModalBottomSheet(context: context, builder: (BuildContext ctx) {
      Future<File?> getImage(ImageSource source) async {
          final bool isGranted = await _requestPermission();
          if (!isGranted) {
            return null;
          }
          final ImagePicker picker = ImagePicker();
          final XFile? image = await picker.pickImage(source: source);
          if (image != null) {
            return File(image.path);
          }
          return null;
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 50),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Form(
              key: _formKey, child: Wrap(
                children: [
                  Container(
                    alignment: Alignment.topCenter,
                    margin: const EdgeInsets.only(bottom: 20), 
                    child: const Text('Form Produk', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'barlow', fontWeight: FontWeight.w500, fontSize: 24))
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15), 
                    child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Kode',
                      suffixIcon: GestureDetector(onTap: () => _inputKodeProdukController.clear(), child: const Icon(Icons.clear)),
                      hintText: 'Kode Produk',
                    ),
                    controller: _inputKodeProdukController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kode tidak boleh kosong';
                      }
                      return null;
                    }
                  )),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15), 
                    child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Nama Produk',
                      suffixIcon: GestureDetector(onTap: () => _inputNamaProdukController.clear(), child: const Icon(Icons.clear)),
                      hintText: 'Nama Produk',
                    ),
                    controller: _inputNamaProdukController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    }
                  )),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15), 
                    child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Harga',
                      suffixIcon: GestureDetector(onTap: () => _inputHargaProdukController.clear(), child: const Icon(Icons.clear)),
                      hintText: 'Harga Produk',
                    ),
                    controller: _inputHargaProdukController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Harga tidak boleh kosong';
                      }
                      return null;
                    }
                  )),
                  Container(
                    margin: const EdgeInsets.only(bottom: 15), 
                    child: TextFormField(
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Stok',
                      suffixIcon: GestureDetector(onTap: () => _inputStokProdukController.clear(), child: const Icon(Icons.clear)),
                      hintText: 'Stok Produk',
                    ),
                    controller: _inputStokProdukController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [ThousandsSeparatorInputFormatter()],
                  )),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          showDialog(context: context, builder: (BuildContext ctx) {
                            return AlertDialog(
                              title: const Text("Pilih Gambar Dari"),
                              content: Row(
                                children: [
                                  TextButton(onPressed: () async {
                                    await getImage(ImageSource.camera);
                                    Navigator.pop(ctx);
                                  }, child: const Text("Kamera")),
                                  const Expanded(child: Row()),
                                  TextButton(onPressed: () async {
                                    await getImage(ImageSource.gallery);
                                    Navigator.pop(ctx);
                                  }, child: const Text("Galeri")),
                                ],
                              )
                            );
                          });
                        },
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          foregroundColor: MaterialStatePropertyAll(Colors.green[800]),
                          elevation: MaterialStateProperty.all(1),
                          backgroundColor: const MaterialStatePropertyAll(Colors.greenAccent),
                          padding: const MaterialStatePropertyAll(EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20))
                        ),
                        child: const Text('Pilih Gambar'),
                      ),
                      const Expanded(
                        child: Row()
                      ),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            await simpanProduk();

                            showTopSnackBar(
                                // ignore: use_build_context_synchronously
                                Overlay.of(context),
                                const CustomSnackBar.success(
                                  message: "Berhasil menyimpan produk",
                                ),
                                displayDuration: const Duration(seconds: 2),
                            );
                          },
                          style: ButtonStyle(
                            shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            foregroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorDark),
                            elevation: MaterialStateProperty.all(1),
                            backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight),
                            padding: const MaterialStatePropertyAll(EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20))
                          ),
                          child: const Text('Simpan'),
                        ),
                      )
                    ],
                  )
                ]
              )
            ),
          ),
        )
      );
    });
  }

  void getProduk({bool reset = false}) async {
    if (reset) {
      _page = 1;
    }
    Map<String, dynamic> produkData = await Produk.get(search: _cariProdukController.text, sort: _sort, page: _page);
    _items = produkData["produkList"];
    _pageList.clear();
    for (int i = 1; i <= produkData["totalPage"]; i++) {
      _pageList.add(i);
    }
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
        bgColor = Colors.blue[50];
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
    /* List<TableRow> tableBody = [];
    if (_items.isNotEmpty) {
      for (Produk produk in _items) {
        tableBody.add(
          TableRow(
            decoration: const BoxDecoration(color: Colors.white),
            children: [
              Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: SvgPicture.string(height: 50, Barcode.code128().toSvg(produk.kode))),
              Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text(produk.kode)),
              Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text(produk.nama)),
              Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text("Rp ${formatter.format(produk.harga.ceil())}")),
              (
                produk.stok.toString() == 'null' ? 
                Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: const Text("∞", style: TextStyle(color: Colors.green)))
                :
                Container(decoration: const BoxDecoration(color: Colors.white), padding: const EdgeInsets.all(10), child: Text(formatter.format(produk.stok).toString()))
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
                      backgroundColor: Theme.of(context).primaryColorLight
                    ),
                    onPressed: () => showModalProduk(type: 'edit', produk: produk), 
                    child: const Text("Edit")
                  ),
                  const Padding(padding: EdgeInsets.all(5), child: SizedBox.shrink()),
                  TextButton(
                    style: TextButton.styleFrom(
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.red[50]
                    ),
                    onPressed: () => hapusProduk(produk), 
                    child: const Text("Hapus")
                  )
                ],
              ),
            ]
          )
        );
      }
    } else {
      tableBody.add(
        TableRow(
          decoration: const BoxDecoration(color: Colors.white),
          children: [
            Container(
              decoration: const BoxDecoration(color: Colors.white), 
              padding: const EdgeInsets.all(10), 
              child: const Text("Data tidak ditemukan")
            ),
            Container(
              decoration: const BoxDecoration(color: Colors.white), 
              padding: const EdgeInsets.all(10), 
              child: const Text("Data tidak ditemukan")
            ),
            Container(
              decoration: const BoxDecoration(color: Colors.white), 
              padding: const EdgeInsets.all(10), 
              child: const Text("Data tidak ditemukan")
            ),
            Container(
              decoration: const BoxDecoration(color: Colors.white), 
              padding: const EdgeInsets.all(10), 
              child: const Text("Data tidak ditemukan")
            ),
            Container(
              decoration: const BoxDecoration(color: Colors.white), 
              padding: const EdgeInsets.all(10), 
              child: const Text("Data tidak ditemukan")
            ),
            Container(
              decoration: const BoxDecoration(color: Colors.white), 
              padding: const EdgeInsets.all(10), 
              child: const Text("Data tidak ditemukan")
            )
          ]
        )
      );
    } */
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[200]),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black26, ))
              ),
              child: Row(
                children: [
                  SizedBox.fromSize(
                    size: const Size(85, 30),
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      value: _page,
                      items: _pageList.map((e) => DropdownMenuItem(value: e, child: Text("Page $e"))).toList(), 
                      onChanged: (value) {
                        setState(() {
                          _page = value!;
                        });
                        getProduk(reset: false);
                      },
                    ),
                  ),
                  Expanded(child: TextFormField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Cari Produk',
                      labelStyle: const TextStyle(color: Colors.black54),
                      contentPadding: const EdgeInsets.only(left: 10, right: 10),
                      suffixIcon: _showClearButton ? 
                        IconButton(onPressed: () {
                          _cariProdukController.clear();
                          setState(() {
                            _showClearButton = false;
                          });
                          getProduk(reset: true);
                        }, 
                        icon: const Icon(Icons.close_outlined)) : 
                        const Icon(Icons.search_rounded)
                    ),
                    onChanged: (text) {
                      if (text != '') {
                        setState(() {
                          _showClearButton = true;
                        });
                      }
                      getProduk(reset: true);
                    },
                    controller: _cariProdukController,
                  ))
                ],
              )
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12), 
                child: ListView(
                  children: _items.map((e) => Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12))),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.black12)),
                          child: const Icon(Icons.image, color: Colors.black45),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(e.nama, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 17))),
                              Text("Sisa : ${e.stok ?? 'UNLIMITED'}", style: const TextStyle(color: Colors.black87)),
                            ]
                          )
                        ),
                        Text(formatter.format(e.harga), style: const TextStyle(fontWeight: FontWeight.w500),)
                      ],
                    ),
                  )).toList(),
                )
              )
            ),
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalProduk(type: 'create'), 
        label: const Row(children: [Icon(Icons.add), Text("Tambah Produk Baru")])
      ),
    );
  }
}