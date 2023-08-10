import 'package:flutter/material.dart';
import 'package:simplepos/db.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 58, 83, 183)),
        useMaterial3: true,
      ),
      home: const ProdukPage(title: 'Pengaturan Produk'),
    );
  }
}

class Layout extends StatefulWidget {
  const Layout({super.key});

  @override
  State<StatefulWidget> createState() => _LayoutState();

}

class _LayoutState extends State<Layout> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

}