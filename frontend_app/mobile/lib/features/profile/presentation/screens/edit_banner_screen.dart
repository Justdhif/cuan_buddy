import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:dio/dio.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/profile_provider.dart';
import '../providers/achievement_provider.dart';
import '../widgets/banner_border_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/user_banner.dart';

final List<String> _premiumColors = [
  '#6C63FF', // Primary Indigo
  '#0EA5E9', // Sky Blue
  '#10B981', // Emerald Green
  '#F59E0B', // Amber
  '#EF4444', // Red Rose
  '#8B5CF6', // Violet
  '#EC4899', // Pink
  '#F97316', // Orange
  '#1E293B', // Dark Slate
  '#64748B', // Cool Slate
];

class EditBannerScreen extends ConsumerStatefulWidget {
  const EditBannerScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditBannerScreen> createState() => _EditBannerScreenState();
}

class _EditBannerScreenState extends ConsumerState<EditBannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _hexController = TextEditingController();

  String _selectedBannerType = 'color';
  String _selectedBannerColor = '#6C63FF';
  String? _selectedBannerImage;
  File? _selectedLocalFile;
  
  String _selectedBorderId = 'none';
  String _selectedBorderAsset = '';
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _selectedBannerType = widget.profile['bannerType'] as String? ?? 'color';
    _selectedBannerColor = widget.profile['bannerColor'] as String? ?? '#6C63FF';
    _selectedBannerImage = widget.profile['bannerImage'] as String?;
    _hexController.text = _selectedBannerColor;
    
    _initBorder();
  }

  Future<void> _initBorder() async {
    final profileBorderId = widget.profile['bannerBorder'] as String?;
    
    String targetId = 'none';
    if (profileBorderId != null && profileBorderId.isNotEmpty) {
      targetId = profileBorderId;
    } else {
      final prefs = await SharedPreferences.getInstance();
      targetId = prefs.getString(kBannerBorderPrefKey) ?? 'none';
    }

    final validBorder = bannerBorderInfoFromId(targetId);
    if (mounted) {
      setState(() {
        _selectedBorderId = validBorder.id;
        _selectedBorderAsset = validBorder.asset;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _hexController.dispose();
    super.dispose();
  }

  Color _parseHexColor(String hexString) {
    try {
      final cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        return Color(int.parse('FF$cleanHex', radix: 16));
      } else if (cleanHex.length == 8) {
        return Color(int.parse(cleanHex, radix: 16));
      }
    } catch (_) {}
    return const Color(0xFF6C63FF);
  }

  Future<void> _pickBannerAndCrop() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 400,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 3, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Banner',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Banner',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _selectedLocalFile = File(croppedFile.path);
        _selectedBannerImage = null; // Prioritize local
        _selectedBannerType = 'image';
      });
    }
  }

  Future<void> _saveAll() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isSaving = true);

    try {
      String? finalBannerImage = _selectedBannerImage;
      final finalBannerType = _selectedBannerType;

      // 1. If local file picked, upload to Cloudinary
      if (_selectedLocalFile != null && finalBannerType == 'image') {
        final dio = ref.read(dioClientProvider).dio;
        final Uint8List rawBytes = await _selectedLocalFile!.readAsBytes();
        final ext = _selectedLocalFile!.path.split('.').last.toLowerCase();
        final filename = 'banner_${DateTime.now().millisecondsSinceEpoch}.$ext';

        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(rawBytes, filename: filename),
        });

        final response = await dio.post(
          '/profiles/banner/upload',
          data: formData,
          options: Options(headers: {'Content-Type': 'multipart/form-data'}),
        );
        finalBannerImage = response.data['bannerImage'] as String;
      }

      // 2. Save profile banner settings to backend
      final rep = ref.read(profileRepositoryProvider);
      await rep.updateProfile(
        bannerType: finalBannerType,
        bannerColor: _selectedBannerColor,
        bannerImage: finalBannerType == 'image' ? finalBannerImage : null,
        bannerBorder: _selectedBorderId,
      );
      
      // 3. Save border to cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kBannerBorderPrefKey, _selectedBorderId);

      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.success,
          message: 'Profile banner updated successfully',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: l10n.error,
          message: 'Failed to update banner: $e',
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
    final bordersAsync = ref.watch(bannerBordersProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile Banner',
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
            // ── Top Section: Preview Banner ──
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
                  UserBanner(
                    bannerColor: _selectedBannerColor,
                    bannerType: _selectedBannerType,
                    bannerImage: _selectedBannerImage,
                    borderAsset: _selectedBorderAsset,
                    localFile: _selectedLocalFile,
                  ),
                ],
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
                    Tab(text: 'Background'),
                    Tab(text: 'Border'),
                  ],
                ),
              ),
            ),

            // ── Tab View Content ──
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Background (Color, Upload & Wallpaper)
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Upload Image Section ──
                        Text(
                          'Upload Image',
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildUploadBox(isDark),
                        const SizedBox(height: 32),

                        // ── Preset Wallpapers Section ──
                        Text(
                          'Preset Wallpapers',
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildWallpaperGrid(unlockedBordersAsync, isDark),
                        const SizedBox(height: 32),

                        // ── Preset Colors Section ──
                        Text(
                          'Preset Colors',
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: _premiumColors.length,
                          itemBuilder: (context, index) {
                            final colorHex = _premiumColors[index];
                            final colorVal = _parseHexColor(colorHex);
                            final isSelected = _selectedBannerType == 'color' && 
                                _selectedBannerColor.toLowerCase() == colorHex.toLowerCase();

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedBannerColor = colorHex;
                                  _hexController.text = colorHex;
                                  _selectedBannerType = 'color';
                                  _selectedLocalFile = null;
                                  _selectedBannerImage = null; // Clear wallpaper
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: colorVal,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : Colors.transparent,
                                    width: 3.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorVal.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: isSelected
                                    ? const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : null,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // ── Custom Hex Code Section ──
                        Text(
                          'Custom Hex Code',
                          style: AppTypography.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _parseHexColor(_selectedBannerColor),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? Colors.white30 : Colors.black12,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _hexController,
                                decoration: InputDecoration(
                                  hintText: '#FFFFFF',
                                  filled: true,
                                  fillColor: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.borderLight.withValues(alpha: 0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                onChanged: (value) {
                                  if (value.startsWith('#') &&
                                      (value.length == 7 || value.length == 9)) {
                                    setState(() {
                                      _selectedBannerColor = value;
                                      _selectedBannerType = 'color';
                                      _selectedLocalFile = null;
                                      _selectedBannerImage = null;
                                    });
                                  } else if (!value.startsWith('#') &&
                                      (value.length == 6 || value.length == 8)) {
                                    setState(() {
                                      _selectedBannerColor = '#$value';
                                      _selectedBannerType = 'color';
                                      _selectedLocalFile = null;
                                      _selectedBannerImage = null;
                                    });
                                  }
                                },
                                onTap: () {
                                  setState(() {
                                    _selectedBannerType = 'color';
                                    _selectedLocalFile = null;
                                    _selectedBannerImage = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tab 2: Border Selection
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: _buildBorderGrid(unlockedBordersAsync, bordersAsync, isDark),
                  ),
                ],
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

  Widget _buildUploadBox(bool isDark) {
    final hasUploadedImage = _selectedLocalFile != null || 
        (_selectedBannerType == 'image' &&
         _selectedBannerImage != null &&
         _selectedBannerImage!.isNotEmpty &&
         !kAllWallpapers.any((w) => w.asset == _selectedBannerImage));

    return hasUploadedImage
        ? Container(
            height: 140,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _selectedLocalFile != null
                        ? Image.file(
                            _selectedLocalFile!,
                            fit: BoxFit.cover,
                          )
                        : CachedNetworkImage(
                            imageUrl: _selectedBannerImage!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 16),
                            onPressed: _pickBannerAndCrop,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 18,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                            onPressed: () {
                              setState(() {
                                _selectedLocalFile = null;
                                _selectedBannerImage = null;
                                _selectedBannerType = 'color';
                              });
                            },
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        : GestureDetector(
            onTap: _pickBannerAndCrop,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 44,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select Photo from Gallery',
                    style: AppTypography.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended Aspect Ratio: 3:1',
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildBorderGrid(AsyncValue<List<String>> unlockedBordersAsync, AsyncValue<List<dynamic>> bordersAsync, bool isDark) {
    return bordersAsync.when(
      data: (bordersData) {
        final List<dynamic> allBorders = bordersData;
        final globalBorders = allBorders.where((b) => b['isGlobal'] == true).toList();
        final bronzeBorders = allBorders.where((b) => b['isGlobal'] == false && b['tier'] == 'bronze').toList();
        final silverBorders = allBorders.where((b) => b['isGlobal'] == false && b['tier'] == 'silver').toList();
        final goldBorders = allBorders.where((b) => b['isGlobal'] == false && b['tier'] == 'gold').toList();
        final platinumBorders = allBorders.where((b) => b['isGlobal'] == false && b['tier'] == 'platinum').toList();

        Widget buildCategorySection(String title, List<dynamic> categoryBorders) {
          if (categoryBorders.isEmpty) return const SizedBox.shrink();

          return unlockedBordersAsync.when(
            data: (unlockedBorders) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 12),
                    child: Text(
                      title,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: categoryBorders.length,
                    itemBuilder: (context, index) {
                      final border = categoryBorders[index];
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
                              isNoBorder
                                  ? Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: isDark ? Colors.white10 : Colors.black12,
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.block, size: 24, color: Colors.grey),
                                      ),
                                    )
                                  : border['asset'].toString().startsWith('http')
                                      ? CachedNetworkImage(
                                          imageUrl: border['asset'],
                                          fit: BoxFit.fill,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                                        )
                                      : Image.asset(
                                          border['asset'],
                                          fit: BoxFit.fill,
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
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Gagal memuat border: $error')),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildCategorySection('Biasa', globalBorders),
            buildCategorySection('Platinum', platinumBorders),
            buildCategorySection('Gold', goldBorders),
            buildCategorySection('Silver', silverBorders),
            buildCategorySection('Bronze', bronzeBorders),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildWallpaperGrid(AsyncValue<List<String>> unlockedBordersAsync, bool isDark) {
    return unlockedBordersAsync.when(
      data: (unlockedBorders) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
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
              final isSelected = (!isNoWallpaper && _selectedBannerType == 'image' && _selectedBannerImage == wp.asset) ||
                                 (isNoWallpaper && _selectedBannerType == 'image' && (_selectedBannerImage == null || _selectedBannerImage!.isEmpty) && _selectedLocalFile == null);
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
                      _selectedBannerType = 'color';
                      _selectedLocalFile = null;
                      _selectedBannerImage = null;
                    } else {
                      _selectedBannerType = 'image';
                      _selectedBannerImage = wp.asset;
                      _selectedLocalFile = null;
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
                                  fit: BoxFit.cover, // Banner image is cover or fill
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
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Gagal memuat wallpaper: $error')),
    );
  }
}
