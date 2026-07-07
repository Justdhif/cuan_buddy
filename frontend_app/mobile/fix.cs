using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        // 1. Fix import
        content = content.Replace("import 'package:cuan_buddy/features/transactions/presentation/widgets/amount_calculator_sheet.dart';", "import '../widgets/amount_calculator_sheet.dart';");
        
        // 2. Add _selectedTime
        content = content.Replace("DateTime _selectedDate = DateTime.now();", "DateTime _selectedDate = DateTime.now();\n  TimeOfDay _selectedTime = TimeOfDay.now();");
        
        // 3. Fix AppTextField parameters
        content = content.Replace("hintText: l10n.transactionTitleHint,", "hint: l10n.transactionTitleHint,");
        content = content.Replace("prefixIcon: Icons.title_rounded,", "prefixIcon: const Icon(Icons.title_rounded),");
        content = content.Replace("hintText: l10n.noteOptional,", "hint: l10n.noteOptional,");
        content = content.Replace("prefixIcon: Icons.notes_rounded,", "prefixIcon: const Icon(Icons.notes_rounded),");
        
        // 4. Fix _SkeletonChip parameter
        content = content.Replace("return const _SkeletonChip();", "return _SkeletonChip(isDark: isDark);");
        
        // 5. Fix AsyncValue type
        content = content.Replace("AsyncValue<List<Map<String, dynamic>>> categoriesAsync", "AsyncValue<List<dynamic>> categoriesAsync");
        
        // 6. Fix c typing in filtered
        content = content.Replace("final catType = c['type'] as String?;", "final catType = (c as Map)['type'] as String?;");
        
        // Another instance of categories map
        content = content.Replace("final cat = filtered[index];", "final cat = filtered[index] as Map;");

        File.WriteAllText(path, content);
    }
}
