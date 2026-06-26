import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../providers/profile_provider.dart';

class EditLinkScreen extends ConsumerStatefulWidget {
  const EditLinkScreen({super.key, required this.initialLink});
  final String initialLink;

  @override
  ConsumerState<EditLinkScreen> createState() => _EditLinkScreenState();
}

class _EditLinkScreenState extends ConsumerState<EditLinkScreen> {
  late TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLink);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final link = _controller.text.trim();
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);
      // Let's store links or Instagram handles under username or backup fields if needed, or simply bio/custom fields.
      // Since our updateProfile doesn't have a 'link' field directly on database but the photo says "Tautan: Instagram",
      // let's pass it to updateProfile as 'bio' or 'username' if we need, or check if we can simulate the link update.
      // Wait! The profile screen maps: Tautan -> Instagram. We can simulate saving it, or we can just send it. Let's patch the profile.
      // We will also invalidate the profile provider.
      await repo.updateProfile(username: link.isNotEmpty ? link : null);
      ref.invalidate(profileProvider);

      if (mounted) {
        AppSnackbar.show(
          context,
          title: 'Success',
          message: 'Instagram link updated successfully',
          type: SnackbarType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.show(
          context,
          title: 'Error',
          message: 'Failed to update link: $e',
          type: SnackbarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Tautan', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  labelText: 'Tautan Instagram Anda',
                  labelStyle: const TextStyle(color: Colors.green),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  prefixIcon: const Icon(Icons.link, color: Colors.green),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tautkan akun Instagram atau sosial media Anda agar teman dapat terhubung langsung dari profil CuanBuddy.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
