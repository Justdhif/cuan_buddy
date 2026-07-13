import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/category_icon_shape.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/category_icon_shape_provider.dart';
import '../../../../core/widgets/color_picker_sheet.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';

class ThemeLanguageScreen extends ConsumerStatefulWidget {
  const ThemeLanguageScreen({super.key});

  @override
  ConsumerState<ThemeLanguageScreen> createState() => _ThemeLanguageScreenState();
}

class _ThemeLanguageScreenState extends ConsumerState<ThemeLanguageScreen> {
  String _getThemeLabel(AppThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case AppThemeMode.system:
        return l10n.system;
      case AppThemeMode.light:
        return l10n.light;
      case AppThemeMode.dark:
        return l10n.dark;
      case AppThemeMode.sunrise:
        return 'Sunrise & Sunset';
    }
  }

  String _getLanguageLabel(WidgetRef ref) {
    final langCode = ref.read(languageProvider);
    if (langCode == 'id') return 'Indonesia';
    return 'English';
  }

  String _getShapeLabel(CategoryIconShape shape) => shape.displayName;

  String _getAccentLabel(Color color) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0');
    return '#${hex.substring(2).toUpperCase()}';
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentMode = ref.read(themeModeProvider);
    await AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ThemePickerSheet(
        currentMode: currentMode,
        l10n: l10n,
        onSelect: (mode) {
          Navigator.pop(ctx);
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
      ),
    );
  }

  Future<void> _showLanguagePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentCode = ref.read(languageProvider);
    await AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _LanguagePickerSheet(
        currentCode: currentCode,
        l10n: l10n,
        onSelect: (code) async {
          Navigator.pop(ctx);
          await ref.read(languageProvider.notifier).setLanguage(code);
        },
      ),
    );
  }

  Future<void> _showShapePicker(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final currentShape = ref.read(categoryIconShapeProvider);
    await AppBottomSheet.show<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ShapePickerSheet(
        currentShape: currentShape,
        l10n: l10n,
        onSelect: (shape) async {
          Navigator.pop(ctx);
          await ref.read(categoryIconShapeProvider.notifier).setShape(shape);
        },
      ),
    );
  }

  Future<void> _showAccentPicker(BuildContext context) async {
    final currentColor = ref.read(accentColorProvider);
    final pickedColor = await showCustomColorPicker(
      context: context,
      initialColor: currentColor,
    );

    if (pickedColor != null) {
      await ref.read(accentColorProvider.notifier).setAccentColor(pickedColor);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);
    final shapeMode = ref.watch(categoryIconShapeProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.appearanceMenu,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _buildListTile(
            context: context,
            icon: Icons.palette_outlined,
            title: l10n.theme,
            subtitle: _getThemeLabel(themeMode, l10n),
            onTap: () => _showThemePicker(context),
          ),
          _buildColorTile(
            context: context,
            icon: Icons.color_lens_outlined,
            title: l10n.accentColor,
            subtitle: _getAccentLabel(accentColor),
            color: accentColor,
            onTap: () => _showAccentPicker(context),
          ),
          _buildListTile(
            context: context,
            icon: Icons.language_outlined,
            title: l10n.language,
            subtitle: _getLanguageLabel(ref),
            onTap: () => _showLanguagePicker(context),
          ),
          _buildListTile(
            context: context,
            icon: Icons.category_outlined,
            title: 'Category Icon Shape',
            subtitle: _getShapeLabel(shapeMode),
            onTap: () => _showShapePicker(context),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white60 : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white60 : Colors.black54,
              size: 24,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Theme Picker Sheet ──────────────────────────────────────────
class _ThemePickerSheet extends StatelessWidget {
  const _ThemePickerSheet({
    required this.currentMode,
    required this.l10n,
    required this.onSelect,
  });

  final AppThemeMode currentMode;
  final AppLocalizations l10n;
  final ValueChanged<AppThemeMode> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themes = [
      {
        'mode': AppThemeMode.system,
        'name': l10n.system,
        'icon': Icons.brightness_auto_outlined,
        'desc': 'Follows your device setting',
      },
      {
        'mode': AppThemeMode.light,
        'name': l10n.light,
        'icon': Icons.light_mode_outlined,
        'desc': 'Always light mode',
      },
      {
        'mode': AppThemeMode.dark,
        'name': l10n.dark,
        'icon': Icons.dark_mode_outlined,
        'desc': 'Always dark mode',
      },
      {
        'mode': AppThemeMode.sunrise,
        'name': 'Sunrise & Sunset',
        'icon': Icons.wb_twilight_rounded,
        'desc': 'Light 06:00–18:00 • Dark 18:00–06:00',
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.theme,
              style: AppTypography.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ...themes.map((theme) {
              final mode = theme['mode'] as AppThemeMode;
              final isSelected = mode == currentMode;
              return GestureDetector(
                onTap: () => onSelect(mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.borderLight.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(theme['icon'] as IconData,
                          size: 28,
                          color: isSelected ? AppColors.primary : null),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              theme['name'] as String,
                              style: AppTypography.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              theme['desc'] as String,
                              style: AppTypography.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.8)
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Language Picker Sheet ──────────────────────────────────────────────────
class _LanguagePickerSheet extends StatelessWidget {
  const _LanguagePickerSheet({
    required this.currentCode,
    required this.l10n,
    required this.onSelect,
  });

  final String currentCode;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'native': 'English'},
    {
      'code': 'id',
      'name': 'Indonesia',
      'flag': '🇮🇩',
      'native': 'Bahasa Indonesia'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.selectLanguage,
              style: AppTypography.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ..._languages.map((lang) {
              final isSelected = lang['code'] == currentCode;
              return GestureDetector(
                onTap: () => onSelect(lang['code']!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.borderLight.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang['name']!,
                              style:
                                  AppTypography.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected ? AppColors.primary : null,
                              ),
                            ),
                            Text(
                              lang['native']!,
                              style:
                                  AppTypography.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ─── Shape Picker Sheet ──────────────────────────────────────────────────
class _ShapePickerSheet extends StatelessWidget {
  const _ShapePickerSheet({
    required this.currentShape,
    required this.l10n,
    required this.onSelect,
  });

  final CategoryIconShape currentShape;
  final AppLocalizations l10n;
  final ValueChanged<CategoryIconShape> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shapes = [
      {
        'shape': CategoryIconShape.circle,
        'name': CategoryIconShape.circle.displayName,
      },
      {
        'shape': CategoryIconShape.square,
        'name': CategoryIconShape.square.displayName,
      },
      {
        'shape': CategoryIconShape.hexagon,
        'name': CategoryIconShape.hexagon.displayName,
      },
      {
        'shape': CategoryIconShape.diamond,
        'name': CategoryIconShape.diamond.displayName,
      },
      {
        'shape': CategoryIconShape.sharp,
        'name': CategoryIconShape.sharp.displayName,
      },
      {
        'shape': CategoryIconShape.squircle,
        'name': CategoryIconShape.squircle.displayName,
      },
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Icon Shape',
              style: AppTypography.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            ...shapes.map((s) {
              final shape = s['shape'] as CategoryIconShape;
              final isSelected = shape == currentShape;
              final previewColor = isSelected ? AppColors.primary : (isDark ? Colors.white30 : Colors.black12);
              final previewShape = shape.toShapeBorder(32);

              return GestureDetector(
                onTap: () => onSelect(shape),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.borderLight.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CustomPaint(
                          painter: _ShapePreviewPainter(
                            shapeBorder: previewShape,
                            color: previewColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          s['name'] as String,
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
// ─── Shape Preview Painter ─────────────────────────────────────────────────────
class _ShapePreviewPainter extends CustomPainter {
  _ShapePreviewPainter({required this.shapeBorder, required this.color});

  final ShapeBorder shapeBorder;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = shapeBorder.getOuterPath(rect);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ShapePreviewPainter old) =>
      old.color != color || old.shapeBorder != shapeBorder;
}
