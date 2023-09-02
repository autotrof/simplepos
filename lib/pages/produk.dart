// import 'package:barcode/barcode.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:bootstrap_grid/bootstrap_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:simplepos/globals.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:path/path.dart' as path;

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
  late TextEditingController _cariProdukController;
  late bool _showClearButton;

  

  @override
  void initState() {
    super.initState();
    _cariProdukController = TextEditingController();
    _showClearButton = false;

    _page = 1;
    _pageList = [];
    _sort = ['kode', 'desc'];
    _items = <Produk>[];
    getProduk();
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
    ListView tampilanHp = ListView(
      children: _items.asMap().entries.map((e){
        return Column(
          children: [
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => ModalProduk(
                  produk: e.value,
                  onDone: (Produk? produkDataResult) {
                    if (produkDataResult != null) {
                      showTopSnackBar(
                        // ignore: use_build_context_synchronously
                        Overlay.of(context),
                        const CustomSnackBar.success(
                          message: "Berhasil menyimpan produk",
                        ),
                        displayDuration: const Duration(seconds: 2),
                      );
                      getProduk(reset: false);
                    }
                  }
                )
              ),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.black12))),
                child: Row(
                  children: [
                    Container(
                      clipBehavior: Clip.antiAlias,
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(50), border: Border.all(color: Colors.black12)),
                      child: e.value.gambar != null ? Image.file(File(e.value.gambar!), alignment: Alignment.center, isAntiAlias: true) : const Icon(Icons.image, color: Colors.black45),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(padding: const EdgeInsets.only(bottom: 3), child: Text(e.value.nama, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 17))),
                          Text("Sisa : ${e.value.stok ?? 'UNLIMITED'}", style: const TextStyle(color: Colors.black87)),
                        ]
                      )
                    ),
                    Text(formatter.format(e.value.harga), style: const TextStyle(fontWeight: FontWeight.w500),)
                  ],
                ),
              ),
            ),
            e.key == _items.length - 1 ? const Padding(padding: EdgeInsets.only(bottom: 80)) : const SizedBox.shrink()
          ],
        );
      }).toList(),
    );

    SingleChildScrollView tampilanTablet() { 
      const jumlahKolom = 3;
      for (int i = 0; i < _items.length; i+=3) {
        Row row = Row(
          children: [
            Text(_items[i].nama),
            Text(_items[i+1].nama),
            Text(_items[i+2].nama),
          ],
        );
      }
      return SingleChildScrollView(
        child: Row(
          children: [],
        )
      );
    }


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
                child: (
                  Device.get().isTablet ? 
                  tampilanTablet :
                  tampilanHp
                )
              )
            ),
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, builder: (context) => ModalProduk(onDone: (Produk? produkDataResult) {
          if (produkDataResult != null) {
            showTopSnackBar(
              // ignore: use_build_context_synchronously
              Overlay.of(context),
              const CustomSnackBar.success(
                message: "Berhasil menyimpan produk",
              ),
              displayDuration: const Duration(seconds: 2),
            );
            getProduk(reset: true);
          }
        })),
        label: const Row(children: [Icon(Icons.add), Text("Tambah Produk Baru")])
      ),
    );
  }
}

class ModalProduk extends StatefulWidget {
  final Produk? produk;
  final Function? onDone;
  const ModalProduk({super.key, this.produk, this.onDone});

  @override
  State<ModalProduk> createState() => _ModalProdukState();
}

class _ModalProdukState extends State<ModalProduk> {
  late GlobalKey<FormState> _formKey;
  late TextEditingController _inputKodeProdukController;
  late TextEditingController _inputNamaProdukController;
  late TextEditingController _inputHargaProdukController;
  late TextEditingController _inputStokProdukController;
  File? _gambar;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _inputKodeProdukController = TextEditingController();
    _inputNamaProdukController = TextEditingController();
    _inputHargaProdukController = TextEditingController();
    _inputStokProdukController = TextEditingController();
    _requestPermission();

    _inputKodeProdukController.text = '';
    _inputNamaProdukController.text = '';
    _inputHargaProdukController.text = '';
    _inputStokProdukController.text = '';
    if (widget.produk != null) {
      _inputKodeProdukController.text = widget.produk!.kode;
      _inputNamaProdukController.text = widget.produk!.nama;
      _inputHargaProdukController.text = widget.produk!.harga.toString();
      if (widget.produk?.stok != null) {
        _inputStokProdukController.text = widget.produk!.stok.toString();
      }
      if (widget.produk?.gambar != null) {
        _gambar = File(widget.produk!.gambar!);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 50),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey, 
          child: Wrap(
            children: [
              Container(
                alignment: Alignment.topCenter,
                margin: const EdgeInsets.only(bottom: 20), 
                child: const Text('Form Produk', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'barlow', fontWeight: FontWeight.w500, fontSize: 24))
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 15),

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
                )
              ),
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
                )
              ),
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
                )
              ),
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
                )
              ),
              Row(
                children: [
                  (
                    _gambar != null ?
                    Padding(padding: const EdgeInsets.only(right: 10), child: Container(
                      width: 90,
                      height: 90,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                      child: Image.file(_gambar!, height: 90, width: 90, isAntiAlias: true)
                    ))
                    :
                    const SizedBox.shrink()
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _gambar != null ? 
                      ElevatedButton(
                        onPressed: () {
                          showDialog(context: context, builder: (BuildContext ctx) {
                            return AlertDialog(
                              title: const Text("Anda yakin akan menghapus gambar produk ini ?"),
                              content: Row(
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _gambar = null;
                                      });
                                      Navigator.pop(context);
                                    },
                                    child: const Text("Ya Hapus")
                                  ),
                                  const Expanded(child: Row()),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    }, 
                                    child: const Text("Batal")
                                  ),
                                ],
                              )
                            );
                          });
                        },
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                          foregroundColor: MaterialStatePropertyAll(Colors.red[800]),
                          elevation: MaterialStateProperty.all(1),
                          backgroundColor: MaterialStatePropertyAll(Colors.red[50]),
                          padding: const MaterialStatePropertyAll(EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20))
                        ),
                        child: const Text('Hapus Gambar'),
                      ) : const SizedBox.shrink(),
                      ElevatedButton(
                        onPressed: () {
                          processImage();
                        },
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                          foregroundColor: MaterialStatePropertyAll(Colors.green[800]),
                          elevation: MaterialStateProperty.all(1),
                          backgroundColor: MaterialStatePropertyAll(Colors.green[100]),
                          padding: const MaterialStatePropertyAll(EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20))
                        ),
                        child: Text(_gambar == null ? 'Pilih Gambar' : 'Ganti Gambar'),
                      )
                    ],
                  )
                ],
              ),
              Container(
                padding: const EdgeInsets.only(top: 15),
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: () async {
                    await simpanProduk();
                  },
                  style: ButtonStyle(
                    shape: MaterialStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    foregroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorDark),
                    elevation: MaterialStateProperty.all(1),
                    backgroundColor: MaterialStatePropertyAll(Theme.of(context).primaryColorLight),
                    padding: const MaterialStatePropertyAll(EdgeInsets.only(top: 10, bottom: 10, left: 20, right: 20)),
                    fixedSize: MaterialStatePropertyAll(Size(MediaQuery.of(context).size.width, 50))
                  ),
                  child: const Text('Simpan'),
                ),
              )
            ]
          )
        ),
      )
    ));
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

  Future<void> simpanProduk() async {
    if (_formKey.currentState!.validate()) {
      final harga = double.parse(_inputHargaProdukController.text.replaceAll(',', ''));
      dynamic stok;
      if (_inputStokProdukController.text.isNotEmpty) {
        stok = int.parse(_inputStokProdukController.text.replaceAll(',', ''));
      }
      try {
        Produk produk = Produk(
          kode: _inputKodeProdukController.text, 
          nama: _inputNamaProdukController.text, 
          harga: harga, 
          stok: stok,
          gambar: _gambar?.path
        );
        await produk.save();
        _inputKodeProdukController.clear();
        _inputNamaProdukController.clear();
        _inputHargaProdukController.clear();
        _inputStokProdukController.clear();

        if (widget.onDone != null) {
          widget.onDone!(produk);
        }
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } catch (e) {
        // ignore: use_build_context_synchronously
        alertError(context: context, text: "Gagal menyimpan produk : ${e.toString()}");
      }
    }
  }

  Future<File?> getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  Future<String?> cropImage(String imagePath) async {
    const title = "Sesuaikan Gambar";
    ImageCropper imageCropper = ImageCropper();
    File? croppedfile = await imageCropper.cropImage(
      sourcePath: imagePath,
      aspectRatio: const CropAspectRatio(ratioX: 400, ratioY: 400),
      aspectRatioPresets: [
        CropAspectRatioPreset.square
      ],
      androidUiSettings: AndroidUiSettings(
        toolbarTitle: title,
        toolbarColor: Theme.of(context).primaryColor,
        toolbarWidgetColor: Colors.white,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
      ),
      iosUiSettings: const IOSUiSettings(
        minimumAspectRatio: 1.0,
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: true,
        title: title,
        cancelButtonTitle: "Batal",
        doneButtonTitle: "Simpan",
        showCancelConfirmationDialog: true
      )
    );

    if (croppedfile != null) {
      Uint8List bytes = await croppedfile.readAsBytes();
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String newImagePath = path.join(documentsDirectory.path, "${DateTime.now().millisecondsSinceEpoch}${randomString(3).toUpperCase()}.jpg");
      File file = File(newImagePath);
      await file.writeAsBytes(bytes);
      return newImagePath;
    }
    return null;
  }

  Future<void> processImage() async {
    if (Platform.isAndroid || Platform.isIOS) {
      showDialog(context: context, builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text("Pilih Gambar Dari"),
          content: Row(
            children: [
              TextButton(onPressed: () async {
                File? image = await getImage(ImageSource.camera);
                if (image != null) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                  String? imagePath = await cropImage(image.path);
                  if (imagePath != null) {
                    setState(() {
                      _gambar = File(imagePath);
                    });
                  }
                }
              }, child: const Text("Kamera")),
              const Expanded(child: Row()),
              TextButton(onPressed: () async {
                File? image = await getImage(ImageSource.gallery);
                if (image != null) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                  String? imagePath = await cropImage(image.path);
                  if (imagePath != null) {
                    setState(() {
                      _gambar = File(imagePath);
                    });
                  }
                }
              }, child: const Text("Galeri")),
            ],
          )
        );
      });
    } else {
      File? image = await getImage(ImageSource.gallery);
      if (image != null) {
        String? imagePath = await cropImage(image.path);
        if (imagePath != null) {
          setState(() {
            _gambar = File(imagePath);
          });
        }
      }
    }
  }
}