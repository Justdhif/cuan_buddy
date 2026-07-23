import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/avatar_border_helper.dart';

const List<String> _avatarSeeds = [
  'alpha',
  'bravo',
  'charlie',
  'delta',
  'echo',
  'foxtrot',
  'golf',
  'hotel',
  'india',
];

String _dicebearUrl(String seed) =>
    'https://api.dicebear.com/8.x/avataaars/png?seed=$seed';

class EditAvatarScreen extends ConsumerStatefulWidget {
  const EditAvatarScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditAvatarScreen> createState() => _EditAvatarScreenState();
}

class _EditAvatarScreenState extends ConsumerState<EditAvatarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String? _selectedAvatarUrl;
  File? _selectedLocalFile;
  late List<String> _avatarOptions;

  String _selectedBorderId = 'none';
  String _selectedBorderAsset = '';
  String _selectedWingsId = 'none';
  String _selectedWingsAsset = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _selectedAvatarUrl = widget.profile['avatar'] as String?;
    _avatarOptions = _avatarSeeds.map(_dicebearUrl).toList();
    _initBorder();
    _initWings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initBorder() async {
    final profileBorderId = widget.profile['avatarBorder'] as String?;
    if (profileBorderId != null && profileBorderId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedBorderId = profileBorderId;
          _selectedBorderAsset = borderAssetFromId(profileBorderId);
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString(kBorderPrefKey) ?? 'none';
    if (mounted) {
      setState(() {
        _selectedBorderId = savedId;
        _selectedBorderAsset = borderAssetFromId(savedId);
      });
    }
  }

  Future<void> _initWings() async {
    final profileWingsId = widget.profile['avatarWings'] as String?;
    if (profileWingsId != null && profileWingsId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedWingsId = profileWingsId;
          _selectedWingsAsset = wingsAssetFromId(profileWingsId);
        });
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedWingsId = prefs.getString(kWingsPrefKey) ?? 'none';
    if (mounted) {
      setState(() {
        _selectedWingsId = savedWingsId;
        _selectedWingsAsset = wingsAssetFromId(savedWingsId);
      });
    }
  }

  Future<void> _pickAvatarAndCrop() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Avatar',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Avatar',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedLocalFile = File(croppedFile.path);
        _selectedAvatarUrl = null; // Prioritize local file
      });
    }
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      String? finalAvatarUrl = _selectedAvatarUrl;

      // 1. Upload local file if picked
      if (_selectedLocalFile != null) {
        final dio = ref.read(dioClientProvider).dio;
        final Uint8List rawBytes = await _selectedLocalFile!.readAsBytes();
        final ext = _selectedLocalFile!.path.split('.').last.toLowerCase();
        final filename = 'avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(rawBytes, filename: filename),
        });

        final response = await dio.post(
          '/profiles/avatar/upload',
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );
        finalAvatarUrl = response.data['avatar'] as String;
      }

      // 2. Save avatar to backend if changed
      final currentAvatar = widget.profile['avatar'] as String?;
      if (finalAvatarUrl != null && finalAvatarUrl != currentAvatar) {
        await ref
            .read(profileRepositoryProvider)
            .updateAvatar(avatarUrl: finalAvatarUrl);
      }

      // 3. Save border to cache and backend
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBorderPrefKey, _selectedBorderId);
      try {
        await ref
            .read(profileRepositoryProvider)
            .updateBorder(borderId: _selectedBorderId);
      } catch (_) {
        // Backend failure for border sync does not prevent success
      }

      // 4. Save wings to cache and backend
      await prefs.setString(kWingsPrefKey, _selectedWingsId);
      try {
        await ref
            .read(profileRepositoryProvider)
            .updateWings(wingsId: _selectedWingsId);
      } catch (_) {
        // Backend failure for wings sync does not prevent success
      }

      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: l10n.profilePhotoUpdatedSuccess,
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: l10n.failedToUpdateAvatar(e.toString()),
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
    final bordersAsync = ref.watch(avatarBordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.profilePhoto,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
            // ── Top Section: Preview Avatar (No Shadow) ──
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: UserAvatar(
                    size: 160,
                    borderAsset: _selectedBorderAsset,
                    wingsAsset: _selectedWingsAsset,
                    avatarUrl: _selectedAvatarUrl,
                    localFile: _selectedLocalFile,
                    fallbackName: '?',
                  ),
                ),
              ),
            ),

            // ── Tabs Header ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  indicatorColor: AppColors.primary,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Avatar'),
                    Tab(text: 'Border'),
                    Tab(text: 'Wings'),
                  ],
                ),
              ),
            ),

            // ── Tab View Content (Gesture Enabled via TabBarView) ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Avatar Grid
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: _buildAvatarGrid(isDark),
                  ),
                  // Tab 2: Border Grid (Categorized)
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: _buildBorderGrid(unlockedBordersAsync, bordersAsync, isDark),
                  ),
                  // Tab 3: Wings Grid
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: _buildWingsGrid(unlockedBordersAsync, isDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      // ── Save Button matching Budget Form screen style ──
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

  Widget _buildAvatarGrid(bool isDark) {
    // 4 columns to match the border grid chip size
    const int crossAxisCount = 4;
    
    // We add 1 for the upload photo button at index 0
    final int totalCount = _avatarOptions.length + 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Index 0: Upload File Option
          final bool hasLocalFile = _selectedLocalFile != null;
          final bool isSelected = hasLocalFile && _selectedAvatarUrl == null;

          return GestureDetector(
            onTap: () async {
              if (isSelected) {
                // If already selected, tap again to change/crop new photo
                await _pickAvatarAndCrop();
              } else if (hasLocalFile) {
                // If there's a cached local file, switch back to it
                setState(() {
                  _selectedAvatarUrl = null;
                });
              } else {
                // Pick new photo
                await _pickAvatarAndCrop();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
              child: ClipOval(
                child: hasLocalFile
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            _selectedLocalFile!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        child: Icon(
                          Icons.add_rounded,
                          size: 28,
                          color: AppColors.primary,
                        ),
                      ),
              ),
            ),
          );
        }

        // Normal seed avatar options
        final optionIndex = index - 1;
        final url = _avatarOptions[optionIndex];
        final isSelected = url == _selectedAvatarUrl && _selectedLocalFile == null;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedAvatarUrl = url;
              _selectedLocalFile = null;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
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
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBorderGrid(AsyncValue<List<String>> unlockedBordersAsync, AsyncValue<List<dynamic>> bordersAsync, bool isDark) {
    return bordersAsync.when(
      data: (bordersData) {
        final List<dynamic> allBorders = bordersData;

        return unlockedBordersAsync.when(
          data: (unlockedBorders) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: allBorders.length,
              itemBuilder: (context, index) {
                final border = allBorders[index];
                final isNoBorder = border['id'] == 'none';
                final isSelected = border['id'] == _selectedBorderId;
                final isUnlocked = border['isGlobal'] == true || unlockedBorders.contains(border['id']);
                final tierColor = border['tier'] == 'platinum' ? const Color(0xFFE5E4E2) :
                                  border['tier'] == 'gold' ? const Color(0xFFFFD700) :
                                  border['tier'] == 'silver' ? const Color(0xFFC0C0C0) :
                                  border['tier'] == 'bronze' ? const Color(0xFFCD7F32) : Colors.grey;

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
                              Icon(Icons.lock, color: tierColor),
                              const SizedBox(width: 8),
                              Text(border['label']),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tier: ${border['tier']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: tierColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(border['requirementDescription'] ?? ''),
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
                      _selectedBorderId = border['id'];
                      _selectedBorderAsset = border['asset'];
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
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
                        isNoBorder
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? Colors.white10 : Colors.black12,
                                ),
                                child: const Center(
                                  child: Icon(Icons.block, size: 24, color: Colors.grey),
                                ),
                              )
                            : border['asset'].toString().startsWith('http')
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: border['asset'],
                                      fit: BoxFit.fill,
                                      width: double.infinity,
                                      height: double.infinity,
                                      errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                    ),
                                  )
                                : ClipOval(
                                    child: Image.asset(
                                      border['asset'],
                                      fit: BoxFit.fill,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                        if (!isUnlocked)
                          Container(
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.lock_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (err, _) => Center(
            child: Text('Gagal memuat border: $err'),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, _) => Center(
        child: Text('Gagal memuat border: $err'),
      ),
    );
  }

  Widget _buildWingsGrid(AsyncValue<List<String>> unlockedBordersAsync, bool isDark) {
    return unlockedBordersAsync.when(
      data: (unlockedBorders) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: kWingsOptions.length,
          itemBuilder: (context, index) {
            final wings = kWingsOptions[index];
            final isNoWings = wings.isNone;
            final isSelected = wings.id == _selectedWingsId;
            final isUnlocked = wings.isGlobal ||
                unlockedBorders.contains('border-all-completed') ||
                unlockedBorders.contains(wings.id);

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
                          Icon(Icons.lock, color: wings.tier.color),
                          const SizedBox(width: 8),
                          Text(wings.label),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tier: ${wings.tier.label}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: wings.tier.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(wings.requirementDescription),
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
                  _selectedWingsId = wings.id;
                  _selectedWingsAsset = wings.asset;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
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
                    isNoWings
                        ? Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? Colors.white10 : Colors.black12,
                            ),
                            child: const Center(
                              child: Icon(Icons.block, size: 24, color: Colors.grey),
                            ),
                          )
                        : wings.asset.startsWith('http')
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: wings.asset,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                ),
                              )
                            : Image.asset(
                                wings.asset,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                    if (!isUnlocked)
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, _) => Center(
        child: Text('Gagal memuat status sayap: $err'),
      ),
    );
  }
}
