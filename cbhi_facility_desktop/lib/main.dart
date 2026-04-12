import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/data/facility_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = FacilityRepository();
  runApp(CbhiFacilityApp(repository: repository));
}
