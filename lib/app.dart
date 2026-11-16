import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/settings/settings_provider.dart';
import 'shared/widgets/app_shell.dart';

class DwellApp extends StatelessWidget {
  const DwellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: 'Dwell',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const AppShell(),
        ),
      ),
    );
  }
}
