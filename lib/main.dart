import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/screens/add_word_screen.dart';
import 'package:flutter_word_app/screens/word_list_screen.dart';
import 'package:flutter_word_app/services/isar_service.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); //uygulamaya girildiğinde veri çekerken uygulama hataya düşmesin diye yazıldı
  final isarService =
      IsarService(); //servis classındaki fonksiyonları çagırmak için
  try {
    await isarService.init();

    // Word eklenecekKelime = Word(englishWord: "garden", turkishWord: "bahçe", wordType: "noun");
    // await isarService.saveWord(eklenecekKelime);
    final words = await isarService.getAllWords();
    debugPrint(words.toString());
  } catch (e) {
    debugPrint("Main dartda isar service baslatılamadı $e");
  }
  runApp(
    MyApp(
      isarService: isarService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final IsarService isarService;
  const MyApp({super.key, required this.isarService});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainPage(
        isarService: isarService,
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  final IsarService isarService;
  const MainPage({super.key, required this.isarService});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedScreen = 0;
  Word? _wordToEdit;

  void _editWord(Word guncellenecekKelime) {
    setState(() {
      _selectedScreen = 1; // ekle sayfasına yönlendiriyor ancak güncelle olarak
      _wordToEdit = guncellenecekKelime;
    });
  }

  List<Widget> getScreens() {
    return [
      WordList(
        isarService: widget.isarService,
        onEditWord: _editWord,
      ),
      AddWordScreen(
          //kelime ekleme ekranı
          isarService: widget.isarService,
          wordToEdit: _wordToEdit,
          onSave: () {
            // kaydet diyince
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Kelime kaydedildi"),
              ),
            );
            setState(() {
              _selectedScreen = 0; // ana ekrana döndürüyor
              _wordToEdit =
                  null; //kaydet tuşuna bastıktan sonra input alanlarını boşaltıyor
            });
          }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kelimelerim"),
        backgroundColor: Colors.lightBlue.shade100,
      ),
      body: getScreens()[_selectedScreen], //açılış ekranı
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.lightBlue.shade100,
        //aşagıdaki nav
        selectedIndex: _selectedScreen,
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.list_alt), label: "Kelimeler"),
          NavigationDestination(
              icon: const Icon(Icons.add_circle_outline),
              label: _wordToEdit == null
                  ? "Ekle"
                  : 'Güncelle'), // eger listedeki bir kelimeye basılırsa güncelleme ekranına git
        ],
        onDestinationSelected: (value) {
          setState(() {
            _selectedScreen = value;
            if (_selectedScreen == 0) {
              _wordToEdit = null;
            }
          });
        },
      ),
    );
  }
}
