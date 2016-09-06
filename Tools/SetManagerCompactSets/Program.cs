using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace CompactSets
{
    class Program
    {
        static void Main(string[] args)
        {
            string filename = @"\\TRANTOR\MyDocuments\Elder Scrolls Online\liveeu\SavedVariables\SetManager.lua";
            var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var lines = new List<string>(System.IO.File.ReadAllLines(filename));
            lines.RemoveAt(0);
            //for (int i = 0; i < lines.Count; i++) lines[i] = new StringBuilder(lines[i].Trim()).Replace("[\"", "\"").Replace("\"] =", "\":").ToString();
            for (int i = 0; i < lines.Count; i++) lines[i] = Regex.Replace(lines[i].Trim().Replace("] =", "]:"), "\\[(?<num>\\d+)\\]", (MatchEvaluator)delegate(Match match)
            {
                return match.Groups["num"].Value;
            });
            for (int i = 0; i < lines.Count; i++) lines[i] = Regex.Replace(lines[i], "\\[(?<str>\\\"[^\\\"]+\\\")\\]", (MatchEvaluator)delegate(Match match)
            {
                return match.Groups["str"].Value;
            });
            var json = String.Join("", lines).Replace(",}", "}");
            var data = serializer.Deserialize<Dictionary<string, object>>(json);
            data = data["Default"] as Dictionary<string, object>;
            foreach (var item in data.Values)
            {
                data = item as Dictionary<string, object>;
                break;
            }
            data = data["$AccountWide"] as Dictionary<string, object>;
            data = data["all"] as Dictionary<string, object>;
            var sets = new SortedDictionary<int, Dictionary<string, object>>();
            foreach (var entry in data)
            {
                sets[Int32.Parse(entry.Key)] = entry.Value as Dictionary<string, object>;
            }
            if (sets.Count > 0)
            {
                var lua = new StringBuilder(512 * 1024);
                lua.AppendLine("local allSets = {");
                foreach (var entry in sets)
                {
                    lua.Append('\t').Append('[').Append(entry.Key).Append("] = { ");
                    lua.Append("isCraftable = ").Append(entry.Value["isCraftable"].ToString().ToLower()).Append(", ");
                    lua.Append("isJevelry = ").Append(entry.Value["isJevelry"].ToString().ToLower()).Append(", ");
                    lua.Append("isMonster = ").Append(entry.Value["isMonster"].ToString().ToLower()).Append(", ");
                    lua.Append("items = { ");
                    foreach (var item in (entry.Value["items"] as Dictionary<string, object>).Values)
                        lua.Append(item).Append(", ");
                    lua.Remove(lua.Length - 2, 2);
                    lua.Append(" }");
                    lua.AppendLine(" },");
                }
                lua.AppendLine("}");
                lua.AppendLine();
                lua.AppendLine("SET_MANAGER.allSets = allSets");
                System.IO.File.WriteAllText("Sets.lua", lua.ToString());
            }
        }
    }
}
