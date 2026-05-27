import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/models.dart';
import 'services/api_service.dart';
import 'ui/theme/theme_controller.dart';

part 'app/cornerstone_app.dart';
part 'ui/screens/home_screen.dart';
part 'ui/widgets/home_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = CornerstoneThemeController();
  await themeController.load();
  runApp(CornerstoneApp(themeController: themeController));
}