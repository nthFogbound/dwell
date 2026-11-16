import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/settings/settings_provider.dart';

Future<void> showSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _SettingsDialog(),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog();

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  Object? _saveError;

  Future<void> _updateTheme(ThemeMode? mode) async {
    if (mode == null) return;
    try {
      await context.read<SettingsProvider>().setThemeMode(mode);
      if (mounted) setState(() => _saveError = null);
    } catch (error) {
      if (mounted) setState(() => _saveError = error);
    }
  }

  Future<void> _updateLanguage(AppLanguage? language) async {
    if (language == null) return;
    try {
      await context.read<SettingsProvider>().setLanguage(language);
      if (mounted) setState(() => _saveError = null);
    } catch (error) {
      if (mounted) setState(() => _saveError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    String strings(String value) => AppStrings.text(value, settings.language);

    return AlertDialog(
      title: Text(strings('Settings')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings('Appearance'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              initialValue: settings.themeMode,
              decoration: InputDecoration(labelText: strings('Theme')),
              items: [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text(strings('System')),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text(strings('Light')),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text(strings('Dark')),
                ),
              ],
              onChanged: _updateTheme,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppLanguage>(
              initialValue: settings.language,
              decoration: InputDecoration(labelText: strings('Language')),
              items: [
                DropdownMenuItem(
                  value: AppLanguage.english,
                  child: Text(strings('English')),
                ),
                DropdownMenuItem(
                  value: AppLanguage.filipino,
                  child: Text(strings('Filipino (Tagalog)')),
                ),
              ],
              onChanged: _updateLanguage,
            ),
            if (settings.loadError != null || _saveError != null) ...[
              const SizedBox(height: 12),
              Text(
                '${strings('Settings could not be saved or loaded:')} '
                '${_saveError ?? settings.loadError}',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings('Done')),
        ),
      ],
    );
  }
}
