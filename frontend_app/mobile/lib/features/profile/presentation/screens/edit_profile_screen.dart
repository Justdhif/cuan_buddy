import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/profile_provider.dart';

// ─── DiceBear Avatar Seeds ────────────────────────────────────────────────────
// We use the avataaars style (same as backend) with fixed seeds to create
// a diverse set of 9 extra avatars to display alongside the user's own avatar.
const List<String> _avatarSeeds = [
  'alpha', 'bravo', 'charlie', 'delta', 'echo',
  'foxtrot', 'golf', 'hotel', 'india',
];

String _dicebearUrl(String seed) =>
    'https://api.dicebear.com/8.x/avataaars/png?seed=$seed';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  DateTime? _selectedDate;
  bool _isSaving = false;

  // Avatar
  late String? _selectedAvatarUrl;
  late List<String> _avatarOptions;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.profile['fullName'] as String? ?? '');
    _phoneController = TextEditingController(
        text: widget.profile['phoneNumber'] as String? ??
            widget.profile['phone'] as String? ??
            '');

    final birthDateStr = widget.profile['birthDate'] as String?;
    if (birthDateStr != null) {
      _selectedDate = DateTime.tryParse(birthDateStr);
    }

    // Current avatar
    final currentAvatar = widget.profile['avatar'] as String?;
    _selectedAvatarUrl = currentAvatar;

    // Build avatar list: current user avatar + 9 fixed seeds = 10 total
    // The user's avatar may already use one of the seeds but we show it
    // separately at index 0 so the user always sees their current one first.
    final extraAvatars = _avatarSeeds.map(_dicebearUrl).toList();
    _avatarOptions = [
      if (currentAvatar != null) currentAvatar,
      ...extraAvatars,
    ];

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      // Update profile fields
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            dateOfBirth: _selectedDate?.toUtc().toIso8601String(),
          );

      // Update avatar if changed
      final currentAvatar = widget.profile['avatar'] as String?;
      if (_selectedAvatarUrl != null &&
          _selectedAvatarUrl != currentAvatar) {
        await ref
            .read(profileRepositoryProvider)
            .updateAvatar(avatarUrl: _selectedAvatarUrl!);
      }

      ref.invalidate(profileProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        AppSnackbar.show(context, title: 'Error', message: 'Failed to update profile: $e', type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Avatar Picker ─────────────────────────────────────────
                _AvatarPickerSection(
                  avatarOptions: _avatarOptions,
                  selectedAvatarUrl: _selectedAvatarUrl,
                  onSelected: (url) => setState(() => _selectedAvatarUrl = url),
                  isDark: isDark,
                ),
                const SizedBox(height: 32),

                // ─── Full Name ─────────────────────────────────────────────
                Text(
                  'Personal Info',
                  style: AppTypography.textTheme.titleSmall
                      ?.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Phone Number ──────────────────────────────────────────
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hint: '+62...',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // ─── Date of Birth ─────────────────────────────────────────
                InkWell(
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ??
                          DateTime.now()
                              .subtract(const Duration(days: 365 * 20)),
                      firstDate: DateTime(1900),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() => _selectedDate = pickedDate);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (Optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate != null
                              ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                              : 'Select date',
                          style: AppTypography.textTheme.bodyLarge?.copyWith(
                            color: _selectedDate == null
                                ? (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight)
                                : null,
                          ),
                        ),
                        const Icon(Icons.calendar_today_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ─── Save Button ───────────────────────────────────────────
                AppButton(
                  label: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar Picker Section ────────────────────────────────────────────────────
class _AvatarPickerSection extends StatelessWidget {
  const _AvatarPickerSection({
    required this.avatarOptions,
    required this.selectedAvatarUrl,
    required this.onSelected,
    required this.isDark,
  });

  final List<String> avatarOptions;
  final String? selectedAvatarUrl;
  final ValueChanged<String> onSelected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Avatar',
          style: AppTypography.textTheme.titleSmall
              ?.copyWith(color: AppColors.primary),
        ),
        const SizedBox(height: 16),

        // Large preview of selected avatar
        Center(
          child: Hero(
            tag: 'avatar',
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: selectedAvatarUrl != null
                    ? CachedNetworkImage(
                        imageUrl: selectedAvatarUrl!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (_, __, ___) => const Icon(
                          Icons.person,
                          size: 48,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.white,
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Avatar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: avatarOptions.length,
          itemBuilder: (context, index) {
            final url = avatarOptions[index];
            final isSelected = url == selectedAvatarUrl;
            final isCurrentUser = index == 0;

            return GestureDetector(
              onTap: () => onSelected(url),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.borderLight.withValues(alpha: 0.4),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.person,
                              color: AppColors.primary, size: 24),
                        ),
                      ),
                    ),
                    // "Mine" badge for first (current user) avatar
                    if (isCurrentUser)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    // Checkmark overlay when selected
                    if (isSelected)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '★ = your current avatar',
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
