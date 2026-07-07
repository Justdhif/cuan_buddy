using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\widgets\amount_calculator_sheet.dart";
        string content = File.ReadAllText(path);
        
        string oldTop = @"    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),";
        
        string newTop = @"    final l10n = AppLocalizations.of(context);
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(
              l10n.amount,
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Top section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),";
              
        content = content.Replace(oldTop, newTop);
        
        // Let's also wrap the final elements in child: Column -> ), correctly.
        // Wait, I just wrapped the Column in a SafeArea>Padding. So I need to close it.
        // I will just use regex to replace the last );
        int lastParen = content.LastIndexOf(");");
        if (lastParen != -1) {
            content = content.Substring(0, lastParen) + @"        ),
      ),
    );" + content.Substring(lastParen + 2);
        }
        
        File.WriteAllText(path, content);
    }
}
