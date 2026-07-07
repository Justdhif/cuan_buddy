using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        // 1. Remove the wrapper Container color and pass correct colors to _buildTypeTab
        string oldTabArea = @"            Container(
              color: isDark ? const Color(0xFF232838) : AppColors.primary.withOpacity(0.05),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTypeTab(
                        context: context,
                        targetType: 'expense',
                        label: l10n.expenseType,
                        activeColor: isDark ? const Color(0xFF2A3043) : AppColors.primary.withOpacity(0.1),
                        isDark: isDark,
                        icon: Icons.arrow_drop_down_rounded,
                        iconColor: AppColors.danger,
                      ),
                      _buildTypeTab(
                        context: context,
                        targetType: 'income',
                        label: l10n.incomeType,
                        activeColor: isDark ? const Color(0xFF2A3043) : AppColors.primary.withOpacity(0.1),
                        isDark: isDark,
                        icon: Icons.arrow_drop_up_rounded,
                        iconColor: AppColors.success,
                      ),
                    ],
                  ),";

        string newTabArea = @"            Container(
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTypeTab(
                        context: context,
                        targetType: 'expense',
                        label: l10n.expenseType,
                        activeColor: typeColor.withOpacity(0.1),
                        isDark: isDark,
                        icon: Icons.arrow_drop_down_rounded,
                        iconColor: AppColors.danger,
                      ),
                      _buildTypeTab(
                        context: context,
                        targetType: 'income',
                        label: l10n.incomeType,
                        activeColor: typeColor.withOpacity(0.1),
                        isDark: isDark,
                        icon: Icons.arrow_drop_up_rounded,
                        iconColor: AppColors.success,
                      ),
                    ],
                  ),";
        content = content.Replace(oldTabArea, newTabArea);

        // 2. Fix Title & Notes Area to match BudgetFormScreen (remove Container/Divider)
        string oldNotesArea = @"                      // -- Title & Notes Area ---------------------------------
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _titleController,
                              hint: l10n.transactionTitleHint,
                              prefixIcon: const Icon(Icons.title_rounded),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.titleRequired;
                                }
                                return null;
                              },
                            ),
                            const Divider(height: 1, indent: 48),
                            AppTextField(
                              controller: _noteController,
                              hint: l10n.transactionNoteHint,
                              prefixIcon: const Icon(Icons.notes_rounded),
                            ),
                          ],
                        ),
                      ),";

        string newNotesArea = @"                      // -- Title & Notes Area ---------------------------------
                      AppTextField(
                        controller: _titleController,
                        label: l10n.transactionTitleHint,
                        hint: l10n.transactionTitleHint,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.titleRequired;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _noteController,
                        label: l10n.transactionNoteHint,
                        hint: l10n.transactionNoteHint,
                      ),";
        content = content.Replace(oldNotesArea, newNotesArea);

        // 3. Fix _showCategoryPickerSheet to use AppBottomSheet.show
        string oldCatSheet = @"  void _showCategoryPickerSheet(BuildContext context, bool isDark, AsyncValue<List<dynamic>> categoriesAsync) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih Kategori',
              style: AppTypography.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),";

        string newCatSheet = @"  void _showCategoryPickerSheet(BuildContext context, bool isDark, AsyncValue<List<dynamic>> categoriesAsync) {
    AppBottomSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'Pilih Kategori',
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),";
        content = content.Replace(oldCatSheet, newCatSheet);

        File.WriteAllText(path, content);
    }
}
