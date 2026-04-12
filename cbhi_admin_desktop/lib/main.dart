import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/data/admin_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = AdminRepository();
  runApp(CbhiAdminApp(repository: repository));
}
