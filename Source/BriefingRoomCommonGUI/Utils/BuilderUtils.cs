using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading.Tasks;
using BriefingRoom4DCS.Template;
using Microsoft.AspNetCore.Components.Forms;

namespace BriefingRoom4DCS.GUI.Utils
{
    internal class BuilderUtils
    {
        internal static async Task<IEnumerable<Country>> SearchCountry(string searchText) => await Typeahead.SearchEnum<Country>(searchText);

        internal static async Task<IEnumerable<DatabaseEntryInfo>> SearchAircraft(string searchText) => await Typeahead.SearchDB(DatabaseEntryType.UnitFlyableAircraft, searchText);
        internal static string GetAircraftDisplayName(string id) => Typeahead.GetDBDisplayName(DatabaseEntryType.UnitFlyableAircraft, id);

        internal static async Task<IEnumerable<DatabaseEntryInfo>> SearchObjectiveType(string searchText) => await Typeahead.SearchDB(DatabaseEntryType.ObjectiveTask, searchText);
        internal static string GetObjectiveTypeDisplayName(string id) => Typeahead.GetDBDisplayName(DatabaseEntryType.ObjectiveTask, id);

        internal static string GetObjectiveTargetDisplayName(string id) => Typeahead.GetDBDisplayName(DatabaseEntryType.ObjectiveTarget, id);

        internal static async Task<IEnumerable<DatabaseEntryInfo>> SearchCoalition(string searchText) => await Typeahead.SearchDB(DatabaseEntryType.Coalition, searchText);

        internal static string GetCoalitionDisplayName(string id) => Typeahead.GetDBDisplayName(DatabaseEntryType.Coalition, id);

        internal static async Task<MissionTemplate> LoadTemplateFile(InputFileChangeEventArgs e, MissionTemplate Template)
        {
            var targetFile = e.File.OpenReadStream(BriefingRoom.MAXFILESIZE);
            var data = "";
            if (e.File.Name.EndsWith(".miz"))
            {
                using var ms = new MemoryStream();
                await targetFile.CopyToAsync(ms);
                using var zip = new ZipArchive(ms);
                if (!zip.Entries.Any(entry => entry.Name == "template.brt"))
                    throw new Exception("Template File not found within mission");
                targetFile.Close();
                using var reader = new StreamReader(zip.Entries.First(entry => entry.Name == "template.brt").Open());
                data = await reader.ReadToEndAsync();
            }
            else
            {
                using var reader = new StreamReader(targetFile);
                data = await reader.ReadToEndAsync();
            }
            Template.LoadFromString(data);
            return Template;
        }

        internal static void SetTemplateHints(Dictionary<string, double[]> result, ref MissionTemplate Template)
        {
            Template.CarrierHints = new Dictionary<string, double[]>();
            foreach (var kv in result)
            {
                switch (true)
                {
                    case true when kv.Key.StartsWith("OBJECTIVE"):
                        var obj = Template.Objectives.Find(x => x.Alias == kv.Key.Replace("OBJECTIVE_", ""));
                        obj.CoordinateHint = kv.Value;
                        break;
                    case true when kv.Key.StartsWith("CARRIER"):
                        Template.CarrierHints.Add(kv.Key.Replace("CARRIER_", ""), kv.Value);
                        break;
                    case true when kv.Key.StartsWith("FOB"):
                        Template.CarrierHints.Add(kv.Key, kv.Value);
                        break;
                    default:
                        throw new Exception($"Can't process hint key {kv.Key}");
                }
            }
        }

        internal static Dictionary<string, double[]> LoadHints(ref MissionTemplate Template)
        {
            var hints = new Dictionary<string, double[]>();
            foreach (var obj in Template.Objectives)
            {
                hints.Add($"OBJECTIVE_{obj.Alias}", obj.CoordinateHint);
            }
            foreach (var key in Template.CarrierHints.Keys)
            {
                if (key.StartsWith("fob"))
                    hints.Add(key, Template.CarrierHints[key]);
                else
                    hints.Add($"CARRIER_{key}", Template.CarrierHints[key]);
            }
            return hints;
        }
    }
}