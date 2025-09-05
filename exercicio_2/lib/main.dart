import 'package:flutter/foundation.dart';
// Adicione novamente o path_provider para mobile
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class ShoppingItem {
  String name;
  bool bought;

  ShoppingItem({required this.name, this.bought = false});

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(name: json['name'], bought: json['bought'] ?? false);
  }

  Map<String, dynamic> toJson() => {'name': name, 'bought': bought};
}

class ShoppingListStorage {
  static const String fileName = 'shopping_list.json';

  Future<File> get _localFile async {
    String path;
    if (kIsWeb) {
      throw UnsupportedError('Web não suportado para arquivo local');
    } else if (Platform.isAndroid || Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      path = dir.path;
    } else {
      path = Directory.current.path;
    }
    final file = File('$path/$fileName');
    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('[]');
    }
    return file;
  }

  Future<List<ShoppingItem>> readList() async {
    try {
      final file = await _localFile;
      String contents = await file.readAsString();
      if (contents.trim().isEmpty) return [];
      List<dynamic> jsonList = json.decode(contents);
      return jsonList.map((e) => ShoppingItem.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Erro ao ler lista: $e');
      return [];
    }
  }

  Future<void> writeList(List<ShoppingItem> items) async {
    try {
      final file = await _localFile;
      String jsonList = json.encode(items.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonList);
    } catch (e) {
      debugPrint('Erro ao salvar lista: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ShoppingItem> _items = [];
  final ShoppingListStorage _storage = ShoppingListStorage();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _storage.readList();
    setState(() {
      _items = items;
    });
  }

  Future<void> _saveItems() async {
    await _storage.writeList(_items);
  }

  void _addItem(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _items.add(ShoppingItem(name: name));
    });
    _saveItems();
    _controller.clear();
  }

  void _toggleBought(int index) {
    setState(() {
      _items[index].bought = !_items[index].bought;
    });
    _saveItems();
  }

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Lista de Compras'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Adicionar item',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _addItem,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addItem(_controller.text),
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Nenhum item na lista.'))
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return ListTile(
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.bought
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        leading: Checkbox(
                          value: item.bought,
                          onChanged: (_) => _toggleBought(index),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteItem(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
