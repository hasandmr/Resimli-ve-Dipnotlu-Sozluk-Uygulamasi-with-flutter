import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/services/isar_service.dart';

class WordList extends StatefulWidget {
  final IsarService isarService;
  final Function(Word) onEditWord;
  const WordList(
      {super.key, required this.isarService, required this.onEditWord});

  @override
  State<WordList> createState() => _WordListState();
}

class _WordListState extends State<WordList> {
  late Future<List<Word>> _getAllWords;
  List<Word> _kelimeler = [];
  List<Word> _filtrelenmisKelimeler = [];
  List<String> wordType = [
    'All-Hepsi',
    'Noun-Isim',
    'Adjective-Sifat',
    'Verb-Fiil',
    'Adverb-Zarf',
    'Phrasal Verb-Fiiller',
    'Idiom-Deyim',
  ];
  String _selectedWordType = 'All-Hepsi'; //ilk açılışta hepsi gelsin
  bool _showLearned = false;

  _applyFilter() {
    _filtrelenmisKelimeler = List.from(_kelimeler);

    if (_selectedWordType != 'All-Hepsi') {
      //filtreleme yapılmış türden
      _filtrelenmisKelimeler = _filtrelenmisKelimeler
          .where((element) =>
              element.wordType.toLowerCase() == _selectedWordType.toLowerCase())
          .toList();
    }

    if (_showLearned) {
      //filtreleme yapılmış swich ile
      _filtrelenmisKelimeler = _filtrelenmisKelimeler
          .where(
            (element) => element.isLearned != _showLearned,
          )
          .toList();
    }
  }

  @override
  void initState() {
    //alt butonlarda geçiş yapıldığında da çalışır
    // bir defa çalışır onun için uygulama ilk başladığında veri getirmek için kullanıyoruz
    super.initState();
    _getAllWords = _getWordsFromDB();
  }

  Widget _buildFilterCard() {
    //Filtreleme cartını oluşturuyoruz
    return Card(
      //color: Theme.of(context)
      //    .colorScheme
      //    .surfaceDim, // filtreleme card alanı rengi
      color: Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Kelime Türü',
                    border: OutlineInputBorder(),
                  ),
                  value: _selectedWordType,
                  items: wordType
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedWordType = value!;
                      _applyFilter(); //seçildiğinde filtrelemeyi başlat
                    });
                  },
                )),
                const Icon(Icons.filter_alt_rounded),
                const SizedBox(
                  width: 8,
                ),
                const Text('Filtrele'),
                const SizedBox(
                  width: 8,
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Öğrendiklerimi gizle'),
                Switch(
                  value: _showLearned,
                  onChanged: (value) {
                    setState(() {
                      _showLearned = !_showLearned;
                      _applyFilter(); // swich kaydırıldığında filtrelemyi başlat
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Word>> _getWordsFromDB() async {
    var dbDenGelenKelimeler = await widget.isarService.getAllWords();
    _kelimeler = dbDenGelenKelimeler.reversed.toList();
    return dbDenGelenKelimeler;
  }

  void _deleteWord(Word silinecekKelime) async {
    await widget.isarService
        .deleteWord(silinecekKelime.id); //resim silindi veri tabanından
    _kelimeler.removeWhere((element) =>
        element.id == silinecekKelime.id); // yukardaki listemizden sildik
    //debugPrint("liste boyutu ${_kelimeler.length}"); verilerin silindiğini console dan test ediyoruz
  }

  // void _refreshWords() {
  //   setState(() {
  //     _getAllWords = _getWordsFromDB();
  //   });
  // }

  void _toggleUpdateWord(Word oankiKelime) async {
    await widget.isarService.toggleWordLearned(
        oankiKelime.id); //veri tabanındaki bool degerini değiştiriyor

    setState(() {
      final index = _kelimeler.indexWhere(
        (element) => element.id == oankiKelime.id,
      );
      var degistirilecekKelime =
          _kelimeler[index]; //kelimenin herseyini alıyoruz
      degistirilecekKelime.isLearned = !degistirilecekKelime.isLearned;
      _kelimeler[index] = degistirilecekKelime;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilterCard(),
        Expanded(
            child: FutureBuilder<List<Word>>(
          future: _getAllWords,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child:
                    CircularProgressIndicator(), //veri tabanı işlemi sürerken ekranda gözükecek
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text("Hata var ${snapshot.error.toString()}"),
              );
            }
            if (snapshot.hasData) {
              //veri geldğinde
              // ignore: prefer_is_empty
              return snapshot.data?.length == 0
                  ? const Center(
                      child: Text("Lütfen kelime ekleyin"),
                    )
                  : _buildListView(snapshot.data!);
            } else {
              return const SizedBox();
            }
          },
        )),
      ],
    );
  }

  _buildListView(List<Word> data) {
    _applyFilter(); //
    // debugPrint("kelimeler liste uzunlugu ${_filtrelenmisKelimeler.length}"); verilerin gercekten silindiğini console dan test ediyoruz
    return ListView.builder(
      itemBuilder: (context, index) {
        var oankiKelime = _filtrelenmisKelimeler[index];
        return Dismissible(
          //soldan sağa kaydırarak silme için  gerekli witget
          key: UniqueKey(),
          direction: DismissDirection.endToStart, //soldan sağa
          background: Container(
            //sola cekerken arka plan rengini kırmzı yapma
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment:
                Alignment.centerRight, //çöp kutusunun sağda görünmesi için
            padding: const EdgeInsets.only(
                right: 20), //ikonun sağ tarafa boşluk bırakıyoruz
            child: Icon(
              Icons.delete_rounded, // çöp ikonu cıkacak arka planda
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
          ),
          onDismissed: (direction) =>
              _deleteWord(oankiKelime), //sola cektikten sonra
          confirmDismiss: (direction) async {
            // true deger veirse on dismis calışacak
            return await showDialog(
              //kullanıcıya bir dialog veriyoruz
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Kelime Sil'),
                  content: Text(
                      '${oankiKelime.englishWord} kelimesini silmek istediğinize emin misiniz ?'),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); //dialog kapatacak
                        },
                        child: const Text("Vazgeç")),
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); //dialog kapatacak
                        },
                        child: const Text('Sil')),
                  ],
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                vertical: 8), // bütün elemanlar arasında dikey boşluk
            child: GestureDetector(
              onTap: () => widget.onEditWord(oankiKelime),
              child: Card(
                // color: Theme.of(context)
                //     .colorScheme
                //   .tertiaryFixedDim, //herbir card ın arka planı
                color: Colors.pink.shade50,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 8), // her bir card içindeki boşluk
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(oankiKelime.englishWord),
                        subtitle: Text(oankiKelime.turkishWord),
                        leading: Chip(
                          label: Text(oankiKelime.wordType),
                        ),
                        trailing: Switch(
                            value: oankiKelime.isLearned,
                            onChanged: (value) =>
                                _toggleUpdateWord(oankiKelime)),
                      ),
                      if (oankiKelime.story != null &&
                          oankiKelime.story!
                              .isNotEmpty) //kelimenin story si yoksa görünmeyecek
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            //  color: Theme.of(context)
                            //      .colorScheme
                            //      .secondaryContainer
                            //      .withOpacity(0.6),
                            // color: Theme.of(context).colorScheme.secondaryFixed,
                            //color: Colors.white, // story kısmı arka rengi

                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment
                                .start, // hatırlatıcı not ve story aynı hiada olması için
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb),
                                  SizedBox(
                                    //ikonla yazı arasındaki boşluk
                                    width: 8,
                                  ),
                                  Text("Kelimeyi Hatırlatıcı Not-Hikaye"),
                                ],
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  oankiKelime.story ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      //resmi listelenme ekranına yazdırma işlemi
                      if (oankiKelime.imageBytes != null)
                        Image.memory(
                            Uint8List.fromList(oankiKelime.imageBytes!),
                            height: 120,
                            width: double.infinity, // genişliği full yayılsın
                            fit: BoxFit.cover)
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      itemCount: _filtrelenmisKelimeler.length,
    );
  }
}
