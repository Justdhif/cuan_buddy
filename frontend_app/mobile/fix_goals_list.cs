using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        string oldList = @"                        SizedBox(
                          height: 48,
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: 2 + (savingsState.isLoading ? 3 : savingsState.goals.length),
                                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      final isSelected = _selectedSavingsGoalId == null;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedSavingsGoalId = null),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.transparent,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Tidak ada tujuan',
                                              style: AppTypography.textTheme.bodyMedium?.copyWith(
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    } else if (index == 1) {
                                      return GestureDetector(
                                        onTap: () => context.push('/savings/form'),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.add, size: 20),
                                          ),
                                        ),
                                      );
                                    } else {
                                      final goalIndex = index - 2;
                                      if (savingsState.isLoading) {
                                        return _SkeletonChip(isDark: isDark);
                                      }

                                      final goal = savingsState.goals[goalIndex];
                                      final goalId = goal['id'] as String;
                                      final goalName = goal['name'] as String? ?? '';
                                      final goalEmoji = goal['emojiIcon'] as String? ?? '??';
                                      
                                      final isSelected = _selectedSavingsGoalId == goalId;
                                      
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedSavingsGoalId = goalId),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.primary.withOpacity(0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                            border: Border.all(
                                              color: isSelected ? AppColors.primary : Colors.transparent,
                                              width: 1.5,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(goalEmoji, style: const TextStyle(fontSize: 16)),
                                              const SizedBox(width: 8),
                                              Text(
                                                goalName,
                                                style: AppTypography.textTheme.bodyMedium?.copyWith(
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),";
                        
        string newList = @"                        SizedBox(
                          height: 48,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: 2 + (savingsState.isLoading ? 3 : savingsState.goals.length),
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                // 1. No saving goals
                                final isSelected = _selectedSavingsGoalId == null;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSavingsGoalId = null),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        l10n.noSavingsGoals,
                                        style: AppTypography.textTheme.bodyMedium?.copyWith(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              } else if (index == 1 + (savingsState.isLoading ? 3 : savingsState.goals.length)) {
                                // 3. Button plus (Last item)
                                return GestureDetector(
                                  onTap: () => context.push('/savings/form'),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.add, size: 20),
                                    ),
                                  ),
                                );
                              } else {
                                // 2. Data saving
                                final goalIndex = index - 1;
                                if (savingsState.isLoading) {
                                  return _SkeletonChip(isDark: isDark);
                                }

                                final goal = savingsState.goals[goalIndex];
                                final goalId = goal['id'] as String;
                                final goalName = goal['name'] as String? ?? '';
                                final goalEmoji = goal['emojiIcon'] as String? ?? '??';
                                
                                final isSelected = _selectedSavingsGoalId == goalId;
                                
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedSavingsGoalId = goalId),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      border: Border.all(
                                        color: isSelected ? AppColors.primary : Colors.transparent,
                                        width: 1.5,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(goalEmoji, style: const TextStyle(fontSize: 16)),
                                        const SizedBox(width: 8),
                                        Text(
                                          goalName,
                                          style: AppTypography.textTheme.bodyMedium?.copyWith(
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? (isDark ? Colors.white : AppColors.primary) : (isDark ? Colors.white70 : Colors.black87),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),";
        content = content.Replace(oldList, newList);
        File.WriteAllText(path, content);
    }
}
