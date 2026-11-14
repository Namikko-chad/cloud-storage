import 'package:flutter/widgets.dart';

/// UI languages. English is the default; Russian is an option in settings.
enum Lang { en, ru }

/// The current UI language. Changing it rebuilds the whole app (see
/// [CloudSyncApp]), so plain `tr()` calls in build methods are enough.
final lang = ValueNotifier<Lang>(Lang.en);

/// Picks the string for the current language.
String tr(String en, String ru) => lang.value == Lang.ru ? ru : en;

/// Locale for date/number formatting and Material widgets.
Locale get currentLocale => Locale(lang.value.name);
