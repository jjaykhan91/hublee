import 'dart:convert';
import 'dart:io';
// ignore_for_file: avoid_print

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: dart run tools/pretty_print_json.dart <path_to_json>');
    exit(1);
  }

  final file = File(args[0]);
  if (!file.existsSync()) {
    print('File not found: ${args[0]}');
    exit(1);
  }

  final content = file.readAsStringSync();
  final jsonData = json.decode(content);
  final pretty = const JsonEncoder.withIndent('  ').convert(jsonData);

  print(pretty);
}
