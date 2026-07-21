import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/profile_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/banner_border_helper.dart';
import '../widgets/avatar_border_helper.dart'; // Using this since kAllWallpapers is here
import '../../../../core/widgets/user_list_tile.dart';

class EditListBackgroundScreen extends ConsumerStatefulWidget {
  const EditListBackgroundScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditListBackgroundScreen> createState() => _EditListBackgroundScreenState();
}

class _EditListBackgroundScreenState extends ConsumerState<EditListBackgroundScreen> {
  String? _selectedListBackground;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedListBackground = widget.profile['listBackground'] as String?;
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      final rep = ref.read(profileRepositoryProvider);
      await rep.updateProfile(
        listBackground: _selectedListBackground,
      );

      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: 'List background updated successfully',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: 'Failed to update list background: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlockedBordersAsync = ref.watch(unlockedBordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'List Background',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  UserListTile(
                    name: widget.profile['fullName'] ?? widget.profile['username'] ?? 'User Name',
                    username: widget.profile['username'],
                    avatarUrl: widget.profile['avatar'],
                    avatarBorderAsset: borderAssetFromId(widget.profile['avatarBorder'] as String?),
                    listBackground: _selectedListBackground,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Wallpaper',
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This wallpaper will be displayed as the background card when you appear in the user lists (e.g., search results, room members).',
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildWallpaperGrid(unlockedBordersAsync, isDark),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: GestureDetector(
        onTap: _isSaving ? null : _saveAll,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: _isSaving
                  ? const Center(
                      child: SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        l10n.saveButton,
                        style: AppTypography.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWallpaperGrid(AsyncValue<List<String>> unlockedBordersAsync, bool isDark) {
    return unlockedBordersAsync.when(
      data: (unlockedBorders) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 2.5,
          ),
          itemCount: kAllWallpapers.length,
          itemBuilder: (context, index) {
            final wp = kAllWallpapers[index];
            final isNoWallpaper = wp.id == 'none';
            final isSelected = !isNoWallpaper && _selectedListBackground == wp.asset || 
                               isNoWallpaper && (_selectedListBackground == null || _selectedListBackground!.isEmpty);
            final isUnlocked = wp.isGlobal || unlockedBorders.contains(wp.id);
            
            return GestureDetector(
              onTap: () {
                if (!isUnlocked) {
                  showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: Row(
                        children: [
                          const Icon(Icons.lock, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(wp.label),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tier: ${wp.tier.name.toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(wp.requirementDescription),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                setState(() {
                  if (isNoWallpaper) {
                    _selectedListBackground = null;
                  } else {
                    _selectedListBackground = wp.asset;
                  }
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    width: 3.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    isNoWallpaper
                        ? Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                            child: const Center(
                              child: Icon(Icons.block, size: 24, color: Colors.grey),
                            ),
                          )
                        : wp.asset.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: wp.asset,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                              )
                            : Image.asset(
                                wp.asset,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                    if (!isUnlocked)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(Icons.lock_outline_rounded,
                              color: Colors.white70, size: 24),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Gagal memuat wallpaper: $error')),
    );
  }
}

