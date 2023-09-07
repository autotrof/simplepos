// import 'package:barcode/barcode.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_image/crop_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:flutter_svg/svg.dart';
import 'dart:ui' as ui;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
  late List<bool> _longPressState;
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
    _longPressState = <bool>[];
    getProduk();
  }

  void getProduk({bool reset = false}) async {
    if (reset) {
      _page = 1;
    }
    Map<String, dynamic> produkData = await Produk.get(search: _cariProdukController.text, sort: _sort, page: _page, limit: Device.get().isTablet ? 100 : 50);
    _items = produkData["produkList"];
    _longPressState = _items.map((e) => false).toList();
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

  void showModalProduk({Produk? produk}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ModalProduk(
        produk: produk,
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
    ).whenComplete(() {
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  void showModalHapusProduk(Produk produk) {
    showDialog(context: context, builder: (BuildContext context) {
      return ModalHapusProduk(produk, onDone: () => getProduk());
    });
  }

  @override
  Widget build(BuildContext context) {
    late Widget tampilan;
    const chunkSize = 5;
    List columns = <int>[];
    for (int i = 0; i < chunkSize; i++) {
      columns.add(i);
    }
    if (Device.get().isTablet) {
      List<List<dynamic>> itemsChunked = chunk(_items, chunkSize);
      tampilan = SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 90),
        child: Column(
          children: itemsChunked.asMap().entries.map((list) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columns.map((e) => list.value.asMap().containsKey(e) ? Expanded(child: Padding(padding: const EdgeInsets.all(4), child: GestureDetector(
              onTap: () => showModalProduk(produk: list.value[e]), 
              child: Container(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 20, bottom: 20),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(7), border: Border.all(color: Colors.grey[400]!, width: 0.5)),
                child: Column(children: [
                  Container(padding: const EdgeInsets.only(bottom: 8), child: list.value[e].gambar != null ? Image.file(File(list.value[e].gambar!), height: 80, alignment: Alignment.center, isAntiAlias: true) : const Icon(Icons.image, color: Colors.black45, size: 80)),
                  Text(list.value[e].nama, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                  Text(list.value[e].stok != null ? "Stok: ${formatter.format(list.value[e].stok)}" : "Stok: UNLIMITED", style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15)),
                ]),
              ))
            )) : Expanded(child: Container())).toList(),
          )).toList(),
        ),
      );
    } else {
      tampilan = ListView(
        children: _items.asMap().entries.map((e){
          return Column(
            children: [
              Material( child: InkWell(
                hoverColor: Colors.grey[150],
                highlightColor: Colors.grey[350],
                splashColor: Theme.of(context).primaryColorLight,
                onTap: () => showModalProduk(produk: e.value),
                onLongPress: () => showModalHapusProduk(e.value),
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
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
                            Padding(padding: const EdgeInsets.only(bottom: 3), child: Flexible(child: Text(e.value.nama, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 17)))),
                            Text("Sisa : ${e.value.stok ?? 'UNLIMITED'}", style: const TextStyle(color: Colors.black87)),
                          ]
                        )
                      ),
                      Text("Rp ${formatter.format(e.value.harga)}", style: const TextStyle(fontWeight: FontWeight.w500),)
                    ],
                  ),
                ),
              )),
              e.key == _items.length - 1 ? const Padding(padding: EdgeInsets.only(bottom: 80)) : const SizedBox.shrink()
            ],
          );
        }).toList(),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.grey[100]),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(left: 10, top: Device.get().isTablet ? 10 : 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.black26, ))
              ),
              child: Row(
                children: [
                  SizedBox.fromSize(
                    size: const Size(95, 30),
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
                    autocorrect: false,
                    autofocus: false,
                    enableSuggestions: false,
                    onTapOutside: (event) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    },
                    keyboardType: TextInputType.streetAddress,
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
                child: tampilan
              )
            ),
          ]
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalProduk(),
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
  bool _permissionCamera = false;
  bool _permissionStorage = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _inputKodeProdukController = TextEditingController();
    _inputNamaProdukController = TextEditingController();
    _inputHargaProdukController = TextEditingController();
    _inputStokProdukController = TextEditingController();

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
        physics: const ClampingScrollPhysics(),
        child: Form(
          key: _formKey, 
          child: Wrap(
            children: [
              Container(
                alignment: Alignment.topCenter,
                margin: const EdgeInsets.only(bottom: 20), 
                child: const Flexible(flex: 1, child: Text('Form Produk', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'barlow', fontWeight: FontWeight.w500, fontSize: 24)))
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 15),

              ),
              Container(
                margin: const EdgeInsets.only(bottom: 15), 
                child: TextFormField(
                  autocorrect: false,
                  autofocus: false,
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
                  autocorrect: false,
                  autofocus: false,
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
                  autocorrect: false,
                  autofocus: false,
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
                  autocorrect: false,
                  autofocus: false,
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
                      Padding(padding: const EdgeInsets.only(bottom: 5), child: TextButton.icon(
                        onPressed: () {
                          showDialog(context: context, builder: (BuildContext ctx) {
                            return AlertDialog(
                              title: const Flexible(child: Text("Anda yakin akan menghapus gambar produk ini ?")),
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
                          foregroundColor: MaterialStatePropertyAll(Colors.red[800]),
                          elevation: MaterialStateProperty.all(1),
                          backgroundColor: MaterialStatePropertyAll(Colors.red[50]),
                          side: MaterialStatePropertyAll(BorderSide(color: Colors.red[300]!, width: 1)),
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10)))
                        ),
                        label: const Text('Hapus Gambar'),
                        icon: const Icon(Icons.close_sharp)
                      )) : const SizedBox.shrink(),
                      TextButton.icon(
                        onPressed: () {
                          chooseImage();
                        },
                        style: ButtonStyle(
                          shape: MaterialStatePropertyAll(ContinuousRectangleBorder(borderRadius: BorderRadius.circular(10))),
                          foregroundColor: MaterialStatePropertyAll(Colors.green[800]),
                          elevation: MaterialStateProperty.all(1),
                          backgroundColor: MaterialStatePropertyAll(Colors.green[100]),
                          side: MaterialStatePropertyAll(BorderSide(color: Colors.green[400]!, width: 1))
                        ),
                        icon: const Icon(Icons.image_search),
                        label: Text(_gambar == null ? 'Pilih Gambar' : 'Ganti Gambar'),
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
    if (!Platform.isAndroid && !Platform.isIOS && !Platform.isWindows){
      setState(() {
        _permissionStorage = true;
        _permissionCamera = true;
      });
      return true;
    }

    Map<Permission, PermissionStatus> result = await [Permission.mediaLibrary, Permission.photos, Permission.storage, Permission.camera, Permission.photos].request();
    debugPrint("result permission = ${result.toString()}");
    setState(() {
      _permissionStorage = 
        result[Permission.storage] == PermissionStatus.granted && 
        result[Permission.photos] == PermissionStatus.granted &&
        result[Permission.mediaLibrary] == PermissionStatus.granted
        ;
      _permissionCamera = result[Permission.camera] == PermissionStatus.granted;
    });
    return _permissionCamera || _permissionStorage;
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
          id: widget.produk?.id,
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

  Future<File?> cropImage(String imagePath) async {
    File? result;
    await showDialog(context: context, builder: (BuildContext ctx) {
      return ModalCropImage(imagePath: imagePath, onDone: (res) {
        result = res;
      });
    });
    return result;
  }

  Future<void> chooseImage() async {
    await _requestPermission();
    bool platformWithCamera = Platform.isAndroid || Platform.isIOS;
    if (_permissionCamera && _permissionStorage && platformWithCamera) {
      // ignore: use_build_context_synchronously
      showDialog(context: context, builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text("Pilih Gambar Dari", style: TextStyle(fontSize: 18)))
          ]),
          actions: [
            TextButton.icon(
              onPressed: () async {
                File? image = await getImage(ImageSource.camera);
                if (image != null) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                  File? imageResult = await cropImage(image.path);
                  if (imageResult != null) {
                    setState(() {
                      _gambar = imageResult;
                    });
                  }
                }
              }, 
              icon: const Icon(Icons.camera_enhance),
              label: const Text("Kamera")
            ),
            TextButton.icon(
              onPressed: () async {
                File? image = await getImage(ImageSource.gallery);
                if (image != null) {
                  // ignore: use_build_context_synchronously
                  Navigator.pop(ctx);
                  File? imageResult = await cropImage(image.path);
                  if (imageResult != null) {
                    setState(() {
                      _gambar = imageResult;
                    });
                  }
                }
              }, 
              icon: const Icon(Icons.folder_open),
              label: const Text("Galeri")
            )
          ]
        );
      });
    } else if (!_permissionCamera && !_permissionStorage) {
      // ignore: use_build_context_synchronously
      showDialog(context: context, builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Flexible(child: Text("Izinkan aplikasi mengakses kamera dan galeri/storage")),
          content: TextButton(
            onPressed: () async {
              await openAppSettings();
            }, 
            child: const Text("Buka Pengaturan")
          ),
        );
      });
    } else {
      File? image;
      if (_permissionStorage) {
        image = await getImage(ImageSource.gallery);
      } else if (_permissionCamera) {
        image = await getImage(ImageSource.camera);
      }

      if (image != null) {
        File? imageResult = await cropImage(image.path);
        if (imageResult != null) {
          setState(() {
            _gambar = imageResult;
          });
        }
      }
    }
  }
}


class ModalHapusProduk extends StatefulWidget {
  final Produk produk;
  final Function? onDone;
  const ModalHapusProduk(this.produk, {super.key, this.onDone});

  @override
  State<ModalHapusProduk> createState() => _ModalHapusProdukState();
}

class _ModalHapusProdukState extends State<ModalHapusProduk> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          widget.produk.gambar != null ? 
          Padding(
            padding: const EdgeInsets.only(right: 10), 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(55),
              child: Image.file(File(widget.produk.gambar!), width: 55, height: 55)
            )) 
          : const SizedBox.shrink(),
          Flexible(child: Text("Anda yakin akan menghapus data ${widget.produk.nama}?"))
        ]
      ),
      actions: [
        Padding(padding: const EdgeInsets.only(right: 20), child: TextButton(
          style: const ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(Colors.transparent)
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Batal")
        )),
        TextButton(
          style: ButtonStyle(
            backgroundColor: MaterialStatePropertyAll(Colors.red[100]),
            foregroundColor: MaterialStatePropertyAll(Colors.red[600])
          ),
          onPressed: () async {
            dynamic deleteResult = await widget.produk.delete();
            if (deleteResult == true) {
              // ignore: use_build_context_synchronously
              showTopSnackBar(
                  // ignore: use_build_context_synchronously
                  Overlay.of(context),
                  CustomSnackBar.success(
                    message: "Berhasil menghapus produk ${widget.produk.nama}",
                  ),
              );
              if (widget.onDone != null) {
                await widget.onDone!();
              }
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            } else {
              // ignore: use_build_context_synchronously
              alertError(context: context, text: deleteResult.toString());
            }
          },
          child: const Text("Ya, hapus produk")
        ),
      ],
    );
  }
}

class ModalCropImage extends StatefulWidget {
  final String imagePath;
  final Function? onDone;
  const ModalCropImage({super.key, required this.imagePath, this.onDone});

  @override
  State<ModalCropImage> createState() => _ModalCropImageState();
}

class _ModalCropImageState extends State<ModalCropImage> {
  late CropController cropController;
  late bool cropping;
  final bool isPhone = Device.get().isPhone;

  @override
  void initState() {
    super.initState();
    cropController = CropController(
      aspectRatio: 1
    );
    cropping = false;
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;
    return AlertDialog(
      content: SizedBox(
        width: (Device.get().isTablet ? height : width) - (isPhone ? 0 : 100),
        height: (Device.get().isTablet ? height : width) - (isPhone ? 0 : 100),
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.only(bottom: 20), child: Flexible(child: Text("Sesuaikan Gambar", textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)))),
            Expanded(
              child: CropImage(
                controller: cropController,
                image: Image.file(File(widget.imagePath)),
              )
            ),
            Padding(padding: const EdgeInsets.all(10), child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    cropController.rotateRight();
                  }, 
                  icon: const Icon(Icons.rotate_90_degrees_cw_outlined)
                ),
                IconButton(
                  onPressed: () async {
                    cropController.rotateRight();
                  }, 
                  icon: const Icon(Icons.rotate_90_degrees_ccw)
                ),
                !isPhone ? Padding(padding: const EdgeInsets.only(right: 40, left: 40), child: ElevatedButton(
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.red),
                    foregroundColor: MaterialStatePropertyAll(Colors.white),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal")
                )) : const SizedBox.shrink(),
                ElevatedButton(
                  style: ButtonStyle(backgroundColor: MaterialStatePropertyAll(cropping ? Colors.black12 : Theme.of(context).primaryColorLight)),
                  onPressed: () async {
                    if (cropping) return;
                    setState(() {
                      cropping = true;
                    });

                    ui.Image bitmap = await cropController.croppedBitmap();
                    ByteData? data = await bitmap.toByteData(format: ui.ImageByteFormat.png);
                    Uint8List bytes = data!.buffer.asUint8List();
                    Directory tempDir = await getTemporaryDirectory();
                    String tempImagePath = "${tempDir.path}/${randomString(16)}.jpg";
                    File result = File(tempImagePath);
                    await result.writeAsBytes(bytes);
                    if (widget.onDone!=null) {
                      widget.onDone!(result);
                    }
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context);
                  }, 
                  child: const Text("Crop")
                )
              ]
            ))
          ]
        )
      )
    );
  }

}