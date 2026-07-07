using System;
using System.IO;
using System.Text.RegularExpressions;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\screens\transaction_form_screen.dart";
        string content = File.ReadAllText(path);
        
        // 1. Bottom Button SafeArea issue:
        // Let's replace the SafeArea on ottomNavigationBar with just InkWell and adjust padding.
        string oldBottomNav = @"      bottomNavigationBar: SafeArea(
        child: InkWell(
          onTap: _selectedCategoryId == null
              ? () => _showCategoryPickerSheet(context, isDark, categoriesAsync)
              : _isSaving ? null : _save,
          child: Container(
            width: double.infinity,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(_selectedCategoryId == null ? 0.7 : 1.0),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 24, width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    _selectedCategoryId == null ? l10n.selectCategoryAction : l10n.saveTransaction,
                    style: AppTypography.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),";
      
        string newBottomNav = @"      bottomNavigationBar: InkWell(
        onTap: _selectedCategoryId == null
            ? () => _showCategoryPickerSheet(context, isDark, categoriesAsync)
            : _isSaving ? null : _save,
        child: Container(
          width: double.infinity,
          height: 60 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: _selectedCategoryId == null ? 0.7 : 1.0),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 24, width: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Text(
                  _selectedCategoryId == null ? l10n.selectCategoryAction : l10n.saveTransaction,
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),";
        content = content.Replace(oldBottomNav, newBottomNav);
        
        // 2. Body Structure:
        // We need to change:
        // ody: SafeArea(bottom: false, child: Column(children: [ ... Top Integrated Block ... AnimatedBuilder(...) ... Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24.0), physics: const BouncingScrollPhysics(), child: Form(...) )) ])))
        // into:
        // ody: SafeArea(bottom: false, child: SingleChildScrollView(physics: const BouncingScrollPhysics(), child: Column(children: [ ... Top Integrated Block ... AnimatedBuilder(...) ... const SizedBox(height: 24), Form(...) ])))
        
        string oldBodyStart = @"      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // -- Top Integrated Block ---------------------------------------------
            Container(";
            
        string newBodyStart = @"      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // -- Top Integrated Block ---------------------------------------------
              Container(";
              
        content = content.Replace(oldBodyStart, newBodyStart);
        
        // Remove the Expanded + SingleChildScrollView wrapper around Form
        string oldFormStart = @"            // -- Scrollable Form Fields -------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                physics: const BouncingScrollPhysics(),
                child: Form(";
                
        string newFormStart = @"            // -- Form Fields -------------------------------------------
            Form(";
            
        content = content.Replace(oldFormStart, newFormStart);
        
        // Now, we need to add Padding to Form Fields.
        // Date & Time Picker:
        string oldDateRow = @"                      // -- Date & Time Picker ---------------------------------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,";
                        
        string newDateRow = @"                      const SizedBox(height: 24),
                      // -- Date & Time Picker ---------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,";
        
        content = content.Replace(oldDateRow, newDateRow);
        
        // The closing of DateRow:
        string oldDateRowEnd = @"                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),";
                      
        string newDateRowEnd = @"                            ),
                          ),
                        ],
                      ),
                      ),
                      const SizedBox(height: 24),";
                      
        content = content.Replace(oldDateRowEnd, newDateRowEnd);
        
        // Savings Goals transform removal:
        string oldTransform = @"                        Transform.translate(
                          offset: const Offset(-24, 0),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: 48,
                            child: ListView.separated(";
                            
        string newTransform = @"                        SizedBox(
                          height: 48,
                          child: ListView.separated(";
                          
        content = content.Replace(oldTransform, newTransform);
        
        string oldTransformEnd = @"                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),";
                        
        string newTransformEnd = @"                              },
                            ),
                        ),
                        const SizedBox(height: 24),";
                        
        content = content.Replace(oldTransformEnd, newTransformEnd);
        
        // Title & Notes Area padding:
        string oldTitleNotes = @"                      // -- Title & Notes Area ---------------------------------
                      AppTextField(";
                      
        string newTitleNotes = @"                      // -- Title & Notes Area ---------------------------------
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            AppTextField(";
                            
        content = content.Replace(oldTitleNotes, newTitleNotes);
        
        string oldTitleNotesEnd = @"                        hint: l10n.noteOptional,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }";
        
        string newTitleNotesEnd = @"                        hint: l10n.noteOptional,
                        maxLines: 3,
                      ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }";
        
        content = content.Replace(oldTitleNotesEnd, newTitleNotesEnd);
        
        // Locked goals area padding:
        string oldLockedGoals = @"                              Row(
                                children: [
                                  Text(
                                    l10n.selectSavingsGoal,";
        
        string newLockedGoals = @"                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Row(
                                  children: [
                                    Text(
                                      l10n.selectSavingsGoal,";
        content = content.Replace(oldLockedGoals, newLockedGoals);
        
        string oldLockedGoalsEnd = @"                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(";
                                  
        string newLockedGoalsEnd = @"                                    ),
                                  ),
                                ],
                              ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Row(
                                  children: [
                                    Container(";
        content = content.Replace(oldLockedGoalsEnd, newLockedGoalsEnd);
        
        string oldLockedGoalsBoxEnd = @"                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );";
                            
        string newLockedGoalsBoxEnd = @"                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ],
                            );";
        content = content.Replace(oldLockedGoalsBoxEnd, newLockedGoalsBoxEnd);

        File.WriteAllText(path, content);
    }
}
