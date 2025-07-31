import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:flutter_word_app/services/isar_service.dart';
import 'package:image_picker/image_picker.dart';

class AddWordScreen extends StatefulWidget {
  final IsarService isarService;
  final VoidCallback onSave;
  final Word? wordToEdit;
  const AddWordScreen(
      {super.key,
      required this.isarService,
      required this.onSave,
      this.wordToEdit});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _englishController = TextEditingController();
  final _turkishController = TextEditingController();
  final _storyController = TextEditingController();
  String _selectedWordType = "Noun-Isim";
  bool _isLearned = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  List<String> wordType = [
    'Noun-Isim',
    'Adjective-Sifat',
    'Verb-Fiil',
    'Adverb-Zarf',
    'Phrasal Verb-Fiiller',
    'Idiom-Deyim',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.wordToEdit != null) {
      //bu sayfa bir kelimenin güncellemesi için açılmıştır ve
      // listedeki kelimelerin de oraydaki ilgili yerlere taşınması

      var guncellenecekKelime = widget.wordToEdit;
      _englishController.text = guncellenecekKelime!.englishWord;
      _turkishController.text = guncellenecekKelime.turkishWord;
      _storyController.text = guncellenecekKelime.story!;
      _selectedWordType = guncellenecekKelime.wordType;
      _isLearned = guncellenecekKelime.isLearned;
    }
  }

  Future<void> _saveWord() async {
    if (_formKey.currentState!.validate()) {
      var englishWord = _englishController.text;
      var turkishWord = _turkishController.text;
      var story = _storyController.text;
      var kelime = Word(
        englishWord: englishWord,
        turkishWord: turkishWord,
        wordType: _selectedWordType,
        isLearned: _isLearned,
        story: story,
      );

      if (widget.wordToEdit == null) {
        //kullanıcı bir kelime eklemek istiyor
        kelime.imageBytes =
            _imageFile != null ? await _imageFile!.readAsBytes() : null;
        await widget.isarService.saveWord(kelime);
      } else {
        //bir update işlemi var
        kelime.id = widget.wordToEdit!
            .id; //günceleye tıkladıktan sonra id yi de güncelliyoruz yoksa iki ayrı öge oluşuyor eski ve yeni diye
        kelime.imageBytes = _imageFile != null
            ? await _imageFile!.readAsBytes() //resim seçmişse bekle
            : widget.wordToEdit
                ?.imageBytes; //yoksa da zaten bir resim vardır ordaki degeri al
        await widget.isarService.updateWord(kelime);
      }

      widget.onSave();
    }
  }

  @override
  void dispose() {
    _englishController.dispose(); // silme işlemleri
    _turkishController.dispose();
    _storyController.dispose();
    super.dispose();
  }

  Future<void> _resimSec() async {
    //image_picker kütüphanesi kullanıyoruz
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        // ile secilen resim ekrana da hemen yansıyor
        _imageFile = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                // kelime girilen yer
                validator: (value) {
                  // kullanıcı burayı boş geçmesin diye
                  if (value == null || value.isEmpty) {
                    return "Please enter english word";
                  }
                  return null;
                },
                controller: _englishController,
                decoration: const InputDecoration(
                  labelText: 'English Word',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              TextFormField(
                // kelime girilen yer
                controller: _turkishController,
                validator: (value) {
                  // kullanıcı burayı boş geçmesin diye
                  if (value == null || value.isEmpty) {
                    return "Please enter turkish word";
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Turkish Word',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 16,
              ),

              // kelimenin türünü seciyoruz
              DropdownButtonFormField<String>(
                value:
                    _selectedWordType, // ilk degeri atıyor ,iyileştirilebilir
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  label: Text('Word Type'),
                ),
                items: wordType.map(
                  (e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  //secildiğinde
                  setState(() {
                    _selectedWordType = value!;
                  });
                },
              ),
              const SizedBox(
                height: 16,
              ),
              TextFormField(
                // aklımızda kalması için story girilen yer
                controller: _storyController,
                decoration: const InputDecoration(
                    labelText: 'Word Story', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(
                height: 16,
              ),
              Row(
                // story kısmının alındaki kaydırmalı buton
                children: [
                  const Text("Learned"), //yazı
                  Switch(
                    //buton
                    value: _isLearned,
                    onChanged: (value) {
                      setState(() {
                        _isLearned = !_isLearned;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(
                height: 16,
              ), //resim ekle butonu
              ElevatedButton.icon(
                onPressed: _resimSec,
                label: const Text("Add Image"),
                icon: const Icon(Icons.image),
              ),
              const SizedBox(
                height: 8,
              ),
              if (_imageFile != null ||
                  widget.wordToEdit?.imageBytes != null) ...[
                // resim gelmiş mi yoksa kullanıcı seçmiş mi
                if (_imageFile !=
                    null) // resim boş değilse secilen resim altta da görünecek
                  Image.file(_imageFile!, height: 150, fit: BoxFit.cover)
                else if (widget.wordToEdit?.imageBytes !=
                    null) // resim boş ise secilen resim veri tabanından gelecek
                  Image.memory(
                      Uint8List.fromList(widget.wordToEdit!.imageBytes!),
                      height: 150,
                      fit: BoxFit.cover),
              ],
              const SizedBox(
                height: 8,
              ), //kaydetme butonu
              ElevatedButton(
                onPressed: _saveWord,
                child: widget.wordToEdit == null
                    ? const Text("Save Word")
                    : const Text("Update Word"),
              ),
            ],
          )),
    );
  }
}
