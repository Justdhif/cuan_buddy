import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../providers/category_provider.dart';
import '../widgets/category_form_sheet.dart';

class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  void _showCategoryForm(BuildContext context, {Map<String, dynamic>? category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormSheet(initialCategory: category),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String slug) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(l10n.deleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(categoryNotifierProvider.notifier).deleteCategory(slug);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(categoryNotifierProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageCategories, style: AppTypography.textTheme.titleMedium),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showCategoryForm(context),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: state.isLoading && state.categories.isEmpty
          ? const _CategorySkeletonLoader()
          : state.categories.isEmpty
              ? Center(
                  child: Text(l10n.noCategoriesFound, style: AppTypography.textTheme.bodyMedium),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
                  itemCount: state.categories.length,
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        ),
                      ),
                      child: ListTile(
                        leading: Text(
                          category['emojiIcon'] ?? '📁',
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(category['name'], style: AppTypography.textTheme.labelLarge),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showCategoryForm(context, category: category),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              onPressed: () => _confirmDelete(context, ref, category['slug']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _CategorySkeletonLoader extends StatefulWidget {
  const _CategorySkeletonLoader();

  @override
  State<_CategorySkeletonLoader> createState() => _CategorySkeletonLoaderState();
}

class _CategorySkeletonLoaderState extends State<_CategorySkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.85).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0);

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80),
      itemCount: 6,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => Opacity(
            opacity: _anim.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: baseColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(width: 24, height: 24, decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.5), shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Container(width: 120, height: 16, decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8))),
                  const Spacer(),
                  Container(width: 20, height: 20, decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.5), shape: BoxShape.circle)),
                  const SizedBox(width: 16),
                  Container(width: 20, height: 20, decoration: BoxDecoration(color: baseColor.withValues(alpha: 0.5), shape: BoxShape.circle)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
