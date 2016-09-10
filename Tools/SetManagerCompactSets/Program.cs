using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;

namespace CompactSets
{
    //"(3 items) Adds 129 Stamina Recovery",
    //"(2 items) Adds 967 Maximum Stamina",
    //"(4 items) Adds 129 Weapon Damage",
    //"(2 items) Adds 688 Weapon Critical",

    //"(2 items) Adds 129 Health Recovery",
    //"(2 items) Adds 1064 Maximum Health",
    //"(4 items) Adds 1935 Physical Resistance",
    //"(3 items) Adds 1935 Spell Resistance",

    //"(3 items) Adds 129 Magicka Recovery",
    //"(2 items) Adds 967 Maximum Magicka",
    //"(4 items) Adds 129 Spell Damage",
    //"(4 items) Adds 688 Spell Critical",

    class Program
    {
        class StatType
        {
            public char Resource;
            public float Factor;
        }
        static Dictionary<string, StatType> nameToStatType = new Dictionary<string, StatType>();

        //static readonly Regex statsRegEx = new Regex(@"Adds\s+(?<value>\d+)\s+(?<name>\w+\s+\w+)");
        static readonly Regex statsRegEx = new Regex(@"\s(?<name>(M|H|S|P|W)\w+\s+\w+)");

        static void Main(string[] args)
        {
            nameToStatType["Magicka Recovery"] = new StatType() { Resource = 'M', Factor = 1 };
            nameToStatType["Maximum Magicka"] = new StatType() { Resource = 'M', Factor = 0.3340f };
            nameToStatType["Spell Damage"] = new StatType() { Resource = 'M', Factor = 1 };
            nameToStatType["Spell Critical"] = new StatType() { Resource = 'M', Factor = 1 };
            nameToStatType["Magic Damage"] = new StatType() { Resource = 'M', Factor = 1 };
            nameToStatType["Reduce Magicka costs"] = new StatType() { Resource = 'M', Factor = 1 };
            nameToStatType["Reduce the Magicka cost"] = new StatType() { Resource = 'M', Factor = 1 };

            nameToStatType["Health Recovery"] = new StatType() { Resource = 'H', Factor = 1 };
            nameToStatType["Maximum Health"] = new StatType() { Resource = 'H', Factor = 0.3340f };
            nameToStatType["Physical Resistance"] = new StatType() { Resource = 'H', Factor = 1 };
            nameToStatType["Spell Resistance"] = new StatType() { Resource = 'H', Factor = 1 };
            nameToStatType["Healing Taken"] = new StatType() { Resource = 'H', Factor = 1 };
            nameToStatType["Reduce damage taken from"] = new StatType() { Resource = 'H', Factor = 1 };
            nameToStatType["Reduces damage from"] = new StatType() { Resource = 'H', Factor = 1 };

            nameToStatType["Stamina Recovery"] = new StatType() { Resource = 'S', Factor = 1 };
            nameToStatType["Maximum Stamina"] = new StatType() { Resource = 'S', Factor = 0.3340f };
            nameToStatType["Weapon Damage"] = new StatType() { Resource = 'S', Factor = 1 };
            nameToStatType["Weapon Critical"] = new StatType() { Resource = 'S', Factor = 1 };
            nameToStatType["Physical Penetration"] = new StatType() { Resource = 'S', Factor = 1 };
            nameToStatType["Reduces Stamina cost"] = new StatType() { Resource = 'S', Factor = 1 };
            nameToStatType["Reduces the costs of Stamina"] = new StatType() { Resource = 'S', Factor = 1 };
            nameToStatType["Reduce cost of Break Free"] = new StatType() { Resource = 'S', Factor = 1 };

            string filename = @"C:\Users\Votan.Defiant\Data\Documents\Visual Studio 2012\Projects\CompactSets\SetManager_100017.lua";
            var serializer = new System.Web.Script.Serialization.JavaScriptSerializer();
            var lines = new List<string>(System.IO.File.ReadAllLines(filename));
            lines.RemoveAt(0);
            //for (int i = 0; i < lines.Count; i++) lines[i] = new StringBuilder(lines[i].Trim()).Replace("[\"", "\"").Replace("\"] =", "\":").ToString();
            for (int i = 0; i < lines.Count; i++) lines[i] = Regex.Replace(lines[i].Trim().Replace("] =", "]:"), "\\[(?<num>\\d+)\\]", (MatchEvaluator)delegate(Match match)
            {
                return match.Groups["num"].Value;
            });
            for (int i = 0; i < lines.Count; i++) lines[i] = Regex.Replace(lines[i], @"\|c\w\w\w\w\w\w(?<num>[^\|]+)\|r", (MatchEvaluator)delegate(Match match)
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
                lua.AppendLine("local addon = SET_MANAGER");
                lua.AppendLine();
                lua.AppendLine("local C = SET_MANAGER.SetType.Craftable");
                lua.AppendLine("local M = SET_MANAGER.SetType.Monster");
                lua.AppendLine("local J = SET_MANAGER.SetType.Jevelry");
                lua.AppendLine();

                lua.AppendLine("local allSets = {");
                var stats = new Dictionary<string, int>();
                foreach (var entry in sets)
                {
                    stats.Clear();

                    var bonus = new List<string>((entry.Value["bonus"] as Dictionary<string, object>).Values.Cast<string>());

                    for (int i = 0; i < bonus.Count; i++)
                    {
                        foreach (Match m in statsRegEx.Matches(bonus[i]))
                        {
                            if (m.Success)
                            {
                                var name = m.Groups["name"].Value;
                                int value;
                                if (!stats.TryGetValue(name, out value))
                                    value = 0;
                                // A set which gives a bonus early gets a better vote for that stat
                                stats[name] = value + 1;// Int32.Parse(m.Groups["value"].Value) * 2 / (i + 2) * 4 / bonus.Count;
                            }
                        }
                    }

                    var resources = new Dictionary<char, float>();
                    resources['M'] = 1;
                    resources['H'] = 1;
                    resources['S'] = 1;

                    foreach (var stat in stats)
                    {
                        StatType statType;
                        if (nameToStatType.TryGetValue(stat.Key, out statType))
                            resources[statType.Resource] += stat.Value;// *statType.Factor;
                    }
                    entry.Value["resources"] = resources;
                }
                //var resourceMax = new Dictionary<char, float>();
                //resourceMax['M'] = 0;
                //resourceMax['H'] = 0;
                //resourceMax['S'] = 0;

                //foreach (var entry in sets)
                //{
                //    var resources = entry.Value["resources"] as Dictionary<char, float>;
                //    foreach (var resource in resources)
                //    {
                //        resourceMax[resource.Key] = Math.Max(resourceMax[resource.Key], resource.Value);
                //    }
                //}
                //foreach (var entry in sets)
                //{
                //    var resources = entry.Value["resources"] as Dictionary<char, float>;
                //    foreach (var resource in resourceMax)
                //    {
                //        resources[resource.Key] = (float)Math.Round(resources[resource.Key] * 4f / resource.Value + 1.4);
                //    }
                //}
                foreach (var entry in sets)
                {
                    var resources = entry.Value["resources"] as Dictionary<char, float>;

                    lua.Append('\t').Append('[').Append(entry.Key).Append("] = { ");
                    if (Convert.ToBoolean(entry.Value["isCraftable"]))
                        lua.Append("category = C, ");
                    else if (Convert.ToBoolean(entry.Value["isMonster"]))
                        lua.Append("category = M, ");
                    else if (Convert.ToBoolean(entry.Value["isJevelry"]))
                        lua.Append("category = J, ");

                    lua.Append("qualityM = ").Append(Math.Min(5, resources['M'])).Append(", ");
                    lua.Append("qualityH = ").Append(Math.Min(5, resources['H'])).Append(", ");
                    lua.Append("qualityS = ").Append(Math.Min(5, resources['S'])).Append(", ");

                    lua.Append("items = { ");
                    foreach (var item in (entry.Value["items"] as Dictionary<string, object>).Values)
                        lua.Append(item).Append(", ");
                    lua.Remove(lua.Length - 2, 2);
                    lua.Append(" }");
                    lua.AppendLine(" },");
                }
                lua.AppendLine("}");
                lua.AppendLine();
                lua.AppendLine("addon.allSets = allSets");
                System.IO.File.WriteAllText("Sets.lua", lua.ToString());
            }
        }
    }
}
