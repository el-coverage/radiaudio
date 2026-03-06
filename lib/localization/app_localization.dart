import 'translations/ar.dart';
import 'translations/bn.dart';
import 'translations/de.dart';
import 'translations/en.dart';
import 'translations/es.dart';
import 'translations/fa.dart';
import 'translations/fr.dart';
import 'translations/hi.dart';
import 'translations/id.dart';
import 'translations/it.dart';
import 'translations/ja.dart';
import 'translations/ko.dart';
import 'translations/nl.dart';
import 'translations/pl.dart';
import 'translations/pt_br.dart';
import 'translations/ru.dart';
import 'translations/sw.dart';
import 'translations/th.dart';
import 'translations/tl.dart';
import 'translations/tr.dart';
import 'translations/ur.dart';
import 'translations/vi.dart';
import 'translations/zh_hans.dart';
import 'translations/zh_hant.dart';

const List<String> supportedLanguageCodes = [
  'ja',
  'en',
  'fr',
  'es',
  'de',
  'ru',
  'zhHans',
  'zhHant',
  'ko',
  'vi',
  'tl',
  'th',
  'ar',
  'sw',
  'ptBR',
  'id',
  'hi',
  'bn',
  'ur',
  'tr',
  'it',
  'pl',
  'nl',
  'fa',
];

const Map<String, String> languageDisplayNames = {
  'ja': '日本語 (日本語)',
  'en': '英語 (English)',
  'fr': 'フランス語 (Français)',
  'es': 'スペイン語 (Español)',
  'de': 'ドイツ語 (Deutsch)',
  'ru': 'ロシア語 (Русский)',
  'zhHans': '簡体中国語 (简体中文)',
  'zhHant': '繁体中国語 (繁體中文)',
  'ko': '韓国語 (한국어)',
  'vi': 'ベトナム語 (Tiếng Việt)',
  'tl': 'タガログ語 (Filipino)',
  'th': 'タイ語 (ไทย)',
  'ar': 'アラビア語 (العربية)',
  'sw': 'スワヒリ語 (Kiswahili)',
  'ptBR': 'ポルトガル語 (Português - Brasil)',
  'id': 'インドネシア語 (Bahasa Indonesia)',
  'hi': 'ヒンディー語 (हिन्दी)',
  'bn': 'ベンガル語 (বাংলা)',
  'ur': 'ウルドゥー語 (اردو)',
  'tr': 'トルコ語 (Turkce)',
  'it': 'イタリア語 (Italiano)',
  'pl': 'ポーランド語 (Polski)',
  'nl': 'オランダ語 (Nederlands)',
  'fa': 'ペルシャ語 (فارسی)',
};

final Map<String, Map<String, String>> localizedText = {
  'ja': jaText,
  'en': enText,
  'fr': frText,
  'es': esText,
  'de': deText,
  'ru': ruText,
  'zhHans': zhHansText,
  'zhHant': zhHantText,
  'ko': koText,
  'vi': viText,
  'tl': tlText,
  'th': thText,
  'ar': arText,
  'sw': swText,
  'ptBR': ptBrText,
  'id': idText,
  'hi': hiText,
  'bn': bnText,
  'ur': urText,
  'tr': trText,
  'it': itText,
  'pl': plText,
  'nl': nlText,
  'fa': faText,
};

String tr(
  String languageCode,
  String key, [
  Map<String, String> params = const {},
]) {
  final langMap = localizedText[languageCode] ?? localizedText['ja']!;
  var text =
      langMap[key] ?? localizedText['ja']![key] ?? localizedText['en']![key] ?? key;
  params.forEach((k, v) {
    text = text.replaceAll('{$k}', v);
  });
  return text;
}

