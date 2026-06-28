import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await _openHiveBoxes();
  runApp(const ProviderScope(child: NeoLogApp()));
}

Future<void> _openHiveBoxes() async {
  await Hive.openBox('babies');
  await Hive.openBox('daily_logs');
  await Hive.openBox('growth');
  await Hive.openBox('screenings');
  await Hive.openBox('medications');
  await Hive.openBox('events');
  await Hive.openBox('investigations');
  await Hive.openBox('auth');
  await Hive.openBox('settings');
}
