using System;
using System.IO;
using System.Text.RegularExpressions;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        // 1. Replace the bottomNavigationBar
        string oldBottomNav = @"      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: AppButton(
            text: _selectedCategoryId == null ? l10n.selectCategory : l10n.saveTransaction,
            onPressed: _selectedCategoryId == null ? null : () => _save(context, isDark),
            backgroundColor: _selectedCategoryId == null 
                ? (isDark ? Colors.grey[800] : Colors.grey[300]) 
                : AppColors.accent,
            textColor: _selectedCategoryId == null 
                ? (isDark ? Colors.grey[500] : Colors.grey[600]) 
                : Colors.white,
          ),
        ),
      ),";
      
        string newBottomNav = @"      bottomNavigationBar: InkWell(
        onTap: _selectedCategoryId == null ? null : () => _save(context, isDark),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom + 10 : 20,
          ),
          decoration: BoxDecoration(
            color: _selectedCategoryId == null 
                ? (isDark ? Colors.grey[800] : Colors.grey[300]) 
                : AppColors.accent,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Text(
            _selectedCategoryId == null ? 'Pilih Kategori' : 'Simpan Transaksi',
            textAlign: TextAlign.center,
            style: AppTypography.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: _selectedCategoryId == null 
                  ? (isDark ? Colors.grey[500] : Colors.grey[600]) 
                  : Colors.white,
            ),
          ),
        ),
      ),";
        content = content.Replace(oldBottomNav, newBottomNav);
        
        File.WriteAllText(path, content);
    }
}
