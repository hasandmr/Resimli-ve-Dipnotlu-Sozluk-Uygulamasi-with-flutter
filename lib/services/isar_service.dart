import 'package:flutter/material.dart';
import 'package:flutter_word_app/models/word.dart';
import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';

class IsarService {
  late Isar isar;

  Future<void> init() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      isar = await Isar.open([WordSchema], directory: directory.path);
      debugPrint("Isar baslatıldı ${directory.path}");
    } catch (e) {
      debugPrint("Isar init olurken hata $e");
    }
  }

  Future<void> saveWord(Word word) async {
    try {
      await isar.writeTxn(
        //arka planda yapıyor
        () async {
          final id = await isar.words.put(word);
          debugPrint(
              "Yeni kelime olan ${word.englishWord} $id idsiyle eklendi");
        },
      );
    } catch (e) {
      debugPrint("Kelime eklenirken hata çıktı $e");
    }
  }

  Future<List<Word>> getAllWords() async {
    // veri tabanındaki tüm verileri getirme
    try {
      final words = await isar.words.where().findAll();
      return words;
    } catch (e) {
      debugPrint("Tüm kelimeler getirilirken hata $e");
      return [];
    }
  }

  Future<void> deleteWord(int id) async {
    try {
      await isar.writeTxn(
        () async {
          await isar.words.delete(id);
          debugPrint("Id degeri $id olan kelime silindi");
        },
      );
    } catch (e) {
      debugPrint("Kelime silinirken hata çıktı $e");
    }
  }

  Future<void> updateWord(Word word) async {
    //güncellenecek kelimenin tüm bilgilerini alıyoruz
    try {
      await isar.writeTxn(
        () async {
          final id = await isar.words.put(word);
          debugPrint("Kelime olan ${word.englishWord} $id idsiyle güncellendi");
        },
      );
    } catch (e) {
      debugPrint("Kelime güncellenirken hata çıktı $e");
    }
  }

  Future<void> toggleWordLearned(int id) async {
    //
    try {
      await isar.writeTxn(
        () async {
          final word = await isar.words.get(id);
          if (word != null) {
            word.isLearned = !word.isLearned;
            await isar.words.put(word);
            debugPrint("Kelime güncellendi");
          } else {
            debugPrint("Kelime bulunamadı");
          }
        },
      );
    } catch (e) {
      debugPrint("Kelime güncellenirken hata çıktı $e");
    }
  }
}
