using System;
using System.IO;
using System.Text.RegularExpressions;
using System.Collections.Generic;

public class Program {
    public static void Main() {
        string logPath = @"C:\Users\User\.gemini\antigravity\brain\4febdf42-b85a-43d7-9725-9f7235f24ba6\.system_generated\logs\transcript.jsonl";
        var lines = new Dictionary<int, string>();
        foreach (var line in File.ReadLines(logPath)) {
            if (line.Contains("\"type\":\"VIEW_FILE\"") || line.Contains("\"type\":\"TOOL_CALL_RESPONSE\"")) {
                if (line.Contains("transaction_form_screen.dart")) {
                    var match = Regex.Match(line, "\"content\":\"(.*?)\"");
                    if (!match.Success) match = Regex.Match(line, "\"output\":\"(.*?)\"");
                    if (match.Success) {
                        string output = Regex.Unescape(match.Groups[1].Value);
                        foreach (Match m in Regex.Matches(output, @"^(\d+):\s(.*)$", RegexOptions.Multiline)) {
                            lines[int.Parse(m.Groups[1].Value)] = m.Groups[2].Value;
                        }
                    }
                }
            }
        }
        
        int max = 0;
        foreach (var k in lines.Keys) if (k > max) max = k;
        
        using (var w = new StreamWriter("recovered.dart")) {
            for (int i=1; i<=max; i++) {
                if (lines.ContainsKey(i)) w.WriteLine(lines[i]);
                else w.WriteLine("// MISSING LINE " + i);
            }
        }
        Console.WriteLine("Recovered " + max + " lines.");
    }
}
