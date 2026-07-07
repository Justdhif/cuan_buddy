using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\widgets\amount_calculator_sheet.dart";
        string content = File.ReadAllText(path);
        
        string oldTop = @"  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultFormatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top section
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),";
          
        string newTop = @"  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final resultFormatter = NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0);

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
        
        // Find the last "});" or something closing the Widget build method
        string oldEnd = @"          ),
        );
      }).toList(),
            ),
      ),
    );
  }
}";
        string newEnd = @"          ),
        );
      }).toList(),
            ),
      ),
    ],
  ),
      ),
    );
  }
}";
        content = content.Replace(oldEnd, newEnd);
        File.WriteAllText(path, content);
    }
}
