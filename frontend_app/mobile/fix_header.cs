using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        int startIndex = content.IndexOf("class TransactionFormHeader extends StatelessWidget");
        if (startIndex == -1) { Console.WriteLine("Not found"); return; }
        
        string newHeader = @"class TransactionFormHeader extends StatelessWidget {
  const TransactionFormHeader({
    super.key,
    required this.amount,
    required this.currencyCode,
    this.categoryEmoji,
    this.categoryColor,
    required this.type,
    required this.isDark,
    required this.onCategoryTap,
    required this.onAmountTap,
  });

  final double amount;
  final String currencyCode;
  final String? categoryEmoji;
  final Color? categoryColor;
  final String type;
  final bool isDark;
  final VoidCallback onCategoryTap;
  final VoidCallback onAmountTap;

  @override
  Widget build(BuildContext context) {
    final typeColor = type == 'income' ? AppColors.success : AppColors.danger;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Category Hitbox (Left Side)
          Material(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: InkWell(
              onTap: onCategoryTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: categoryEmoji == null 
                        ? (isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B))
                        : (categoryColor ?? typeColor).withOpacity(0.2),
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: categoryEmoji == null ? Colors.transparent : (categoryColor ?? typeColor),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: categoryEmoji == null
                        ? null
                        : Text(categoryEmoji!, style: const TextStyle(fontSize: 28)),
                  ),
                ),
              ),
            ),
          ),
          
          // Amount Hitbox (Right Side)
          Expanded(
            child: Material(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              child: InkWell(
                onTap: onAmountTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            currencyCode,
                            style: AppTypography.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              amount == 0 ? '0' : NumberFormat('#,###').format(amount),
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
";

        content = content.Substring(0, startIndex) + newHeader;
        File.WriteAllText(path, content);
    }
}
