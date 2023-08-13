import 'package:flutter/material.dart';
import 'package:simplepos/db.dart';
import 'package:simplepos/pages/kasir.dart';
import 'package:simplepos/pages/produk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDb(refresh: true, withSampleData: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Pos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 8, 89, 136)),
        useMaterial3: true,
      ),
      home: const Layout(),
    );
  }
}

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<StatefulWidget> createState() => _LayoutState();

}

class _LayoutState extends State<Layout> {
  String _activePage = 'kasir';

  static const Map<String, Map<String, dynamic>>_menus = {
    "kasir": {
      "title": "Kasir",
      "icon": Icon(Icons.add_shopping_cart),
      "page": KasirPage()
    },
    "laporan": {
      "title": "Laporan Penjualan",
      "icon": Icon(Icons.legend_toggle),
      "page": ProdukPage()
    },
    "produk": {
      "title": "Pengaturan Produk",
      "icon": Icon(Icons.layers),
      "page": ProdukPage()
    },
    "printer": {
      "title": "Pengaturan Printer",
      "icon": Icon(Icons.print),
      "page": ProdukPage()
    }
  };

  String getPageTitle() {
    return _menus[_activePage]!["title"];
  }

  Widget getPage() {
    return _menus[_activePage]!["page"];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(getPageTitle()),
        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.w500),
      ),
      drawer: Drawer(
        shape: BeveledRectangleBorder(borderRadius: BorderRadius.circular(0)),
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text('Drawer Header'),
            ),
            ..._menus.entries.map((m) => ListTile(
              tileColor: _activePage == m.key ? Theme.of(context).primaryColorLight : Colors.white,
              title: Row(children: [m.value["icon"], Padding(padding: const EdgeInsets.only(left: 5), child: Text(m.value["title"]))]),
              onTap: () {
                setState(() {
                  _activePage = m.key;
                  Navigator.pop(context);
                });
              },
            )).toList()
          ],
        ),
      ),
      body: getPage(),
    );
  }

}