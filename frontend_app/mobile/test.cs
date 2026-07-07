using System;
using System.IO;

public class Program {
    public static void Main() {
        string path = @"d:\Nadhif_A.W\MY_PROJECT\cuan_buddy\frontend_app\mobile\lib\features\transactions\presentation\widgets\amount_calculator_sheet.dart";
        string content = File.ReadAllText(path);
        
        string oldEnd = @"      }).toList(),
            ),
      ),
    );";
        string newEnd = @"      }).toList(),
            );
          },
        ),
      ),
    ],
  ),
      ),
    );";
        
        // Actually, let's just do a clean replace using git checkout, and apply it properly!
    }
}
