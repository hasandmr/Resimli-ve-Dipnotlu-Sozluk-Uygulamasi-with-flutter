import 'package:isar/isar.dart';

part 'word.g.dart';

@collection
class Word {
  Id id = Isar.autoIncrement;
  late String englishWord;
  late String turkishWord;
  late String wordType;
  String? story;
  List<int>? imageBytes;
  bool isLearned = false;
  Word({
    required this.englishWord,
    required this.turkishWord,
    required this.wordType,
    this.story,
    this.isLearned = false,
    this.imageBytes,
  });

  @override
  String toString() {
    return 'Word(id: $id, englishWord: $englishWord, turkishWord: $turkishWord, wordType: $wordType, story: $story, imageBytes: $imageBytes, isLearned: $isLearned)';
  }
}
