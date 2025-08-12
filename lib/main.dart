import 'package:flutter/material.dart';
import 'core/cache.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JsonCache.init();
  runApp(const HubleeApp());
}
