import '../../../../core/utils/app_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../providers/profile_provider.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key, required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _currencyController;
  String? _selectedGender;
  DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile['fullName']);
    _usernameController =
        TextEditingController(text: widget.profile['username']);
    _phoneController = TextEditingController(
        text: widget.profile['phoneNumber'] ?? widget.profile['phone'] ?? '');
    _emailController = TextEditingController(text: widget.profile['email']);
    _bioController = TextEditingController(text: widget.profile['bio']);
    _currencyController =
        TextEditingController(text: widget.profile['currency'] ?? 'IDR');
    _selectedGender = widget.profile['gender'];
    final birthDateStr = widget.profile['birthDate'] as String?;
    if (birthDateStr != null) {
      _selectedDate = DateTime.tryParse(birthDateStr);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await ref.read(profileRepositoryProvider).updateProfile(
            fullName: _nameController.text.trim(),
            username: _usernameController.text.trim().isNotEmpty
                ? _usernameController.text.trim()
                : null,
            phoneNumber: _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            currency: _currencyController.text.trim().isNotEmpty
                ? _currencyController.text.trim().toUpperCase()
                : null,
            birthDate: _selectedDate?.toUtc().toIso8601String(),
            gender: _selectedGender,
            bio: _bioController.text.trim().isNotEmpty
                ? _bioController.text.trim()
                : null,
          );

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
        final l10n = AppLocalizations.of(context);
        AppSnackbar.show(context,
            title: l10n.error,
            message: '${l10n.failedToUpdateProfile}: $e',
            type: SnackbarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Profile',
                style: AppTypography.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'Email address',
                  readOnly: true,
                  // We add a little helper text or visual cue that it's read-only
                ),
                const SizedBox(height: 8),
                Text(
                  'Email address cannot be changed.',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phoneController,
                  label: 'Phone Number (Optional)',
                  hint: '+62...',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                AppTextField(
                  controller: _usernameController,
                  label: 'Username (Optional)',
                  hint: 'Enter your username',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender (Optional)',
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
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) => setState(() => _selectedGender = value),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _bioController,
                  label: 'Bio (Optional)',
                  hint: 'Tell us about yourself',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _currencyController,
                  label: 'Currency',
                  hint: 'IDR, USD, etc.',
                ),
                const SizedBox(height: 32),
                AppButton(
                  label: _isSaving ? 'Saving...' : 'Save Changes',
                  onPressed: _isSaving ? null : _save,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showEditProfileSheet(BuildContext context, Map<String, dynamic> profile) {
  AppBottomSheet.show(
    context: context,
    isScrollControlled: true,
    builder: (_) => EditProfileSheet(profile: profile),
  );
}
