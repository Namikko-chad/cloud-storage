import 'package:fixnum/fixnum.dart';

import 'i18n.dart';

/// `YYYY-MM-DD HH:MM:SS` in local time.
String formatTime(Int64 unix) {
  if (unix == Int64.ZERO) return '—';
  final t = DateTime.fromMillisecondsSinceEpoch(unix.toInt() * 1000).toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

String formatDate(Int64 unix) => formatTime(unix).split(' ').first;

String formatSize(num bytes) {
  final units = lang.value == Lang.ru ? const ['Б', 'КБ', 'МБ', 'ГБ', 'ТБ'] : const ['B', 'KB', 'MB', 'GB', 'TB'];
  var v = bytes.toDouble();
  var i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return i == 0 ? '${v.toInt()} ${units[i]}' : '${v.toStringAsFixed(v < 10 ? 1 : 0)} ${units[i]}';
}

String platformName(String p) => switch (p) {
  'linux' => 'Linux',
  'windows' => 'Windows',
  'android' => 'Android',
  'darwin' => 'macOS',
  _ => p,
};
