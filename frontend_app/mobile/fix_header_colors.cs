using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        // Update TransactionFormHeader colors
        string oldHeaderColors = @"          // Category Hitbox (Left Side)
          Material(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),";
        string newHeaderColors = @"          // Category Hitbox (Left Side)
          Material(
            color: typeColor.withOpacity(0.1),";
            
        string oldAmountColors = @"          // Amount Hitbox (Right Side)
          Expanded(
            child: Material(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),";
        string newAmountColors = @"          // Amount Hitbox (Right Side)
          Expanded(
            child: Material(
              color: typeColor.withOpacity(0.15),";
              
        content = content.Replace(oldHeaderColors, newHeaderColors);
        content = content.Replace(oldAmountColors, newAmountColors);
        
        // Update inactive tab color
        string oldInactiveTab = @"          decoration: BoxDecoration(
            color: isSelected 
                ? activeColor 
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0)),";
        string newInactiveTab = @"          decoration: BoxDecoration(
            color: isSelected 
                ? activeColor 
                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8F9FA)),";
        content = content.Replace(oldInactiveTab, newInactiveTab);
        
        File.WriteAllText(path, content);
    }
}
