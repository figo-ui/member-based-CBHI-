import 'package:flutter/material.dart';

import 'src/cbhi_app.dart';
import 'src/cbhi_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await CbhiRepository.create();
  runApp(CbhiApp(repository: repository));
}
