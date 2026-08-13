import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'features/reminders/reminder_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await reminderService.init();

  runApp(const ProviderScope(child: WaterApp()));
}
