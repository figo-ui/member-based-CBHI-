import 'dart:io';

void main(List<String> args) {
  if (args.isEmpty) return;
  final file = File(args.first);
  final content = file.readAsStringSync();
  final lines = content.split('\n');
  final newLines = <String>[];
  
  var inMap = false;
  var currentKeys = <String>{};
  
  final mapStartRegExp = RegExp(r"^('.+'):\s*\{");
  final constMapRegExp = RegExp(r"^const\s+_?[a-zA-Z0-9]+\s*=\s*<String,\s*String>\{");
  final keyRegExp = RegExp(r"^('[^']+')\s*:");

  for (final line in lines) {
    final stripped = line.trim();
    if (mapStartRegExp.hasMatch(stripped) || constMapRegExp.hasMatch(stripped)) {
      inMap = true;
      currentKeys.clear();
      newLines.add(line);
      continue;
    }
    if (inMap && (stripped.startsWith('}') || stripped == '};')) {
      inMap = false;
      newLines.add(line);
      continue;
    }
    if (inMap) {
      final match = keyRegExp.firstMatch(stripped);
      if (match != null) {
        final key = match.group(1)!;
        if (currentKeys.contains(key)) {
          print('Removing duplicate key $key');
          continue;
        } else {
          currentKeys.add(key);
        }
      }
    }
    newLines.add(line);
  }
  
  file.writeAsStringSync(newLines.join('\n'));
  print('Done.');
}
