using System;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Threading;

static class PayloadTests
{
    static string root;
    static int failures;
    static readonly byte[] script = Encoding.UTF8.GetBytes("test compiled script bytes");
    static string ZipPath { get { return Path.Combine(root, "overtime_payload.zip"); } }
    static string Hash(byte[] bytes) { using (var h = SHA256.Create()) return BitConverter.ToString(h.ComputeHash(bytes)).Replace("-", ""); }
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); }
    static void Test(string name, Action action)
    {
        try { if (File.Exists(ZipPath)) File.Delete(ZipPath); action(); Console.WriteLine("PASS " + name); }
        catch (Exception ex) { failures++; Console.WriteLine("FAIL " + name + ": " + ex.Message); }
    }
    static string Manifest(string fileLine)
    {
        return "OVERTIME-PAYLOAD\t1\nmod_tag\tovertime-1.7-dev\ngame_version\t" + Core.GameVersion +
            "\nvanilla_sha256\t" + Core.VanillaSha + "\nvanilla_size\t" + Core.VanillaSize + "\n" + fileLine + "\n";
    }
    static string FileLine(string target, string entry, byte[] data)
    { return "file\t" + target + "\t" + entry + "\t" + data.Length + "\t" + Hash(data); }
    static string ValidManifest() { return Manifest(FileLine("res://scripts/test.gdc", "scripts/000.gdc", script)); }
    static void Entry(ZipArchive zip, string name, byte[] bytes)
    { using (var s = zip.CreateEntry(name).Open()) s.Write(bytes, 0, bytes.Length); }
    static void Zip(string manifest, Action<ZipArchive> extra)
    {
        using (var fs = File.Create(ZipPath)) using (var zip = new ZipArchive(fs, ZipArchiveMode.Create))
        {
            Entry(zip, "manifest.txt", new UTF8Encoding(false).GetBytes(manifest));
            Entry(zip, "scripts/000.gdc", script);
            if (extra != null) extra(zip);
        }
    }
    static object Load()
    {
        var method = typeof(Core).GetMethod("LoadPayload", new Type[] { typeof(string) });
        Check(method != null, "external payload loader is absent");
        try { return method.Invoke(null, new object[] { ZipPath }); }
        catch (TargetInvocationException ex) { throw ex.InnerException; }
    }
    static void Reject()
    {
        bool rejected = false;
        try { Load(); } catch (InvalidDataException) { rejected = true; } catch (FileNotFoundException) { rejected = true; }
        Check(rejected, "invalid payload was not rejected");
    }
    static string MakeInstalledFixture()
    {
        string dir = Path.Combine(root, "game-" + Guid.NewGuid().ToString("N"));
        Directory.CreateDirectory(dir);
        using (var fs = File.Create(Path.Combine(dir, Core.PckName))) using (var bw = new BinaryWriter(fs))
        {
            bw.Write(0x43504447u); bw.Write(3u); bw.Write(4u); bw.Write(5u); bw.Write(2u);
            bw.Write(0u); bw.Write(128UL); bw.Write(128UL); fs.Position = 128; bw.Write(0u); fs.SetLength(164);
        }
        using (var fs = File.Create(Path.Combine(dir, Core.ResName))) using (var bw = new BinaryWriter(fs))
        {
            bw.Write(0x3852504Du); bw.Write(1u); bw.Write(132L); bw.Write(164L);
            bw.Write(""); bw.Write(Core.GameVersion); bw.Write("overtime-1.6"); bw.Write(0);
        }
        return dir;
    }
    static void FailedInstallPreservesFiles(bool corrupt)
    {
        if (corrupt) File.WriteAllBytes(ZipPath, new byte[] { 1, 2, 3 });
        string dir = MakeInstalledFixture();
        string pck = Path.Combine(dir, Core.PckName), restore = Path.Combine(dir, Core.ResName);
        string before = Core.Sha256(pck), restoreBefore = Core.Sha256(restore);
        bool failed = false;
        try { Core.Install(dir, true, delegate(string s) { }); } catch { failed = true; }
        Check(failed, "install should reject unavailable payload even with --force");
        Check(Core.Sha256(pck) == before, "PCK was modified before payload validation");
        Check(File.Exists(restore) && Core.Sha256(restore) == restoreBefore, "restore record was changed before payload validation");
    }
    static string MakeVanillaFixture()
    {
        string dir = Path.Combine(root, "game-" + Guid.NewGuid().ToString("N")); Directory.CreateDirectory(dir);
        byte[] original = Encoding.UTF8.GetBytes("ORIGINAL");
        byte[] path = Encoding.UTF8.GetBytes("scripts/test.gdc");
        using (var fs = File.Create(Path.Combine(dir, Core.PckName))) using (var bw = new BinaryWriter(fs))
        {
            bw.Write(0x43504447u); bw.Write(3u); bw.Write(4u); bw.Write(5u); bw.Write(2u);
            bw.Write(0u); bw.Write(128UL); bw.Write(136UL); fs.Position = 128; bw.Write(original);
            bw.Write(1u); int padded = (path.Length + 3) & ~3; bw.Write((uint)padded); bw.Write(path); bw.Write(new byte[padded - path.Length]);
            bw.Write(128UL); bw.Write((ulong)original.Length); using (var md5 = MD5.Create()) bw.Write(md5.ComputeHash(original)); bw.Write(0u);
        }
        return dir;
    }
    public static int Main()
    {
        root = AppDomain.CurrentDomain.BaseDirectory;
        L.Zh = false;
        Test("missing package cannot revert installed PCK", delegate { FailedInstallPreservesFiles(false); });
        Test("corrupt package cannot revert installed PCK", delegate { FailedInstallPreservesFiles(true); });
        Test("valid external package", delegate {
            Zip(ValidManifest(), null); object snapshot = Load();
            Check((string)snapshot.GetType().GetProperty("Tag").GetValue(snapshot, null) == "overtime-1.7-dev", "wrong tag");
            Check((int)snapshot.GetType().GetProperty("Count").GetValue(snapshot, null) == 1, "wrong count");
            File.Delete(ZipPath);
            Check((string)snapshot.GetType().GetProperty("Tag").GetValue(snapshot, null) == "overtime-1.7-dev", "snapshot depends on open file");
        });
        Test("missing package", delegate { Reject(); });
        Test("game script paths containing spaces", delegate {
            Zip(ValidManifest().Replace("res://scripts/test.gdc", "res://scripts/components/character customization/customization_assigner.gdc"), null);
            Check(((Core.PayloadSnapshot)Load()).Count == 1, "legitimate original game directory was rejected");
        });
        Test("invalid ZIP", delegate { File.WriteAllText(ZipPath, "broken"); Reject(); });
        Test("hash mismatch", delegate { Zip(ValidManifest().Replace(Hash(script), new string('0', 64)), null); Reject(); });
        Test("declared length mismatch", delegate { Zip(ValidManifest().Replace("\t" + script.Length + "\t", "\t1\t"), null); Reject(); });
        Test("duplicate ZIP entry", delegate { Zip(ValidManifest(), delegate(ZipArchive z) { Entry(z, "scripts/000.gdc", script); }); Reject(); });
        Test("extra ZIP entry", delegate { Zip(ValidManifest(), delegate(ZipArchive z) { Entry(z, "extra.txt", script); }); Reject(); });
        Test("directory ZIP entry", delegate { Zip(ValidManifest(), delegate(ZipArchive z) { z.CreateEntry("scripts/"); }); Reject(); });
        Test("missing script entry", delegate { Zip(ValidManifest().Replace("scripts/000.gdc", "scripts/001.gdc"), null); Reject(); });
        Test("duplicate target path", delegate {
            Zip(Manifest(FileLine("res://scripts/test.gdc", "scripts/000.gdc", script) + "\n" + FileLine("res://scripts/test.gdc", "scripts/001.gdc", script)), delegate(ZipArchive z) { Entry(z, "scripts/001.gdc", script); }); Reject();
        });
        Test("traversal target", delegate { Zip(ValidManifest().Replace("res://scripts/test.gdc", "res://scripts/../test.gdc"), null); Reject(); });
        Test("backslash target", delegate { Zip(ValidManifest().Replace("res://scripts/test.gdc", "res://scripts\\test.gdc"), null); Reject(); });
        Test("traversal ZIP entry", delegate { Zip(ValidManifest().Replace("scripts/000.gdc", "../000.gdc"), null); Reject(); });
        Test("game metadata mismatch", delegate { Zip(ValidManifest().Replace(Core.GameVersion, "v9.9.9"), null); Reject(); });
        Test("vanilla hash mismatch", delegate { Zip(ValidManifest().Replace(Core.VanillaSha, new string('1', 64)), null); Reject(); });
        Test("vanilla size mismatch", delegate { Zip(ValidManifest().Replace(Core.VanillaSize.ToString(), "634798101"), null); Reject(); });
        Test("duplicate metadata", delegate { Zip(ValidManifest().Replace("game_version\t", "mod_tag\tovertime-1.7-dev\ngame_version\t"), null); Reject(); });
        Test("missing metadata", delegate { Zip(ValidManifest().Replace("game_version\t" + Core.GameVersion + "\n", ""), null); Reject(); });
        Test("unknown metadata", delegate { Zip(ValidManifest().Replace("game_version\t", "other\tx\ngame_version\t"), null); Reject(); });
        Test("unsafe display tag", delegate { Zip(ValidManifest().Replace("overtime-1.7-dev", "overtime-1.7\rInjected"), null); Reject(); });
        Test("manifest BOM", delegate { Zip("\uFEFF" + ValidManifest(), null); Reject(); });
        Test("manifest blank line", delegate { Zip(ValidManifest() + "\n", null); Reject(); });
        Test("ZIP size bound", delegate { using (var fs = File.Create(ZipPath)) fs.SetLength(32L * 1024 * 1024 + 1); Reject(); });
        Test("single script size bound", delegate { Zip(ValidManifest().Replace("\t" + script.Length + "\t", "\t4194305\t"), null); Reject(); });
        Test("manifest size bound", delegate { Zip(ValidManifest() + new string('x', 128 * 1024), null); Reject(); });
        Test("missing package safe display", delegate { Check(Core.ModTag() != "mp8", "unknown tag is silently advertised as mp8"); });
        Test("uninstall without package", delegate {
            string dir = MakeInstalledFixture(); Core.Uninstall(dir, delegate(string s) { });
            Check(new FileInfo(Path.Combine(dir, Core.PckName)).Length == 132, "restore did not complete");
            Check(!File.Exists(Path.Combine(dir, Core.ResName)), "restore record not removed");
        });
        Test("synthetic PCK install and missing-package uninstall roundtrip", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture(); string pck = Path.Combine(dir, Core.PckName), hash = Core.Sha256(pck);
            Core.Install(dir, true, delegate(string s) { }); Check(Core.Sha256(pck) != hash, "no patch written"); File.Delete(ZipPath);
            Core.Uninstall(dir, delegate(string s) { }); Check(Core.Sha256(pck) == hash, "roundtrip changed original bytes");
        });
        Test("missing target rejected before reverting old mod", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture(); Core.Install(dir, true, delegate(string s) { });
            string pck = Path.Combine(dir, Core.PckName), hash = Core.Sha256(pck), restore = Path.Combine(dir, Core.ResName), record = Core.Sha256(restore);
            Zip(ValidManifest().Replace("res://scripts/test.gdc", "res://scripts/missing.gdc"), null);
            bool failed = false; try { Core.Install(dir, true, delegate(string s) { }); } catch { failed = true; }
            Check(failed && Core.Sha256(pck) == hash && File.Exists(restore) && Core.Sha256(restore) == record, "target validation happened after upgrade reverted files");
        });
        Test("rejected upgrade reports the actual restored baseline in both languages", delegate {
            foreach (bool zh in new[] { false, true }) {
                L.Zh = zh;
                Zip(ValidManifest().Replace("overtime-1.7-dev", "overtime-1.6"), null);
                string dir = MakeVanillaFixture(), pck = Path.Combine(dir, Core.PckName);
                string baseline = Core.Sha256(pck);
                Core.Install(dir, true, delegate(string s) { });
                Zip(ValidManifest(), null);
                string error = "";
                try { Core.Install(dir, false, delegate(string s) { }); } catch (Exception ex) { error = ex.Message; }
                Check(error.Length > 0 && Core.Sha256(pck) == baseline && !File.Exists(Path.Combine(dir, Core.ResName)), "expected rejected upgrade to leave the original input baseline");
                Check(!error.Contains("Nothing was changed") && !error.Contains("没有动"), "upgrade message incorrectly claims the previous installation was left intact");
                Check(error.Contains(zh ? "已还原" : "reverted") && error.Contains(zh ? "未安装" : "not installed"), "upgrade message omits the actual outcome");
            }
            L.Zh = false;
        });
        Test("post-write failure restores baseline and keeps evidence", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture(); string pck = Path.Combine(dir, Core.PckName), hash = Core.Sha256(pck);
            bool failed = false; try { Core.Install(dir, true, delegate(string s) { if (s.StartsWith("[4/4]")) throw new IOException("injected post-write failure"); }); } catch { failed = true; }
            Check(failed && Core.Sha256(pck) == hash, "failed install did not restore baseline");
            Check(Directory.GetFiles(dir, Core.ResName + "*").Length > 0, "failure evidence disappeared");
        });
        Test("verification detects changed payload bytes with intact index", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture(); string pck = Path.Combine(dir, Core.PckName), hash = Core.Sha256(pck);
            bool failed = false; try { Core.Install(dir, true, delegate(string s) {
                if (s.StartsWith("[4/4]")) using (var fs = new FileStream(pck, FileMode.Open, FileAccess.ReadWrite)) { fs.Position = fs.Length - 1; fs.WriteByte(99); }
            }); } catch { failed = true; }
            Check(failed, "verification only checked the index, not installed bytes"); Check(Core.Sha256(pck) == hash, "corrupt payload was not rolled back");
        });
        Test("durable record recovers interrupted append without package", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture(); string pck = Path.Combine(dir, Core.PckName), hash = Core.Sha256(pck); long length = new FileInfo(pck).Length;
            Core.Install(dir, true, delegate(string s) { }); File.Delete(ZipPath);
            using (var fs = new FileStream(pck, FileMode.Open, FileAccess.Write)) fs.SetLength(length + script.Length / 2);
            Core.Uninstall(dir, delegate(string s) { }); Check(Core.Sha256(pck) == hash, "partial append could not be restored");
        });
        Test("missing package still identifies restorable installation", delegate {
            string dir = MakeInstalledFixture(); var state = Core.Detect(dir);
            Check(state.Kind.ToString() == "RestorableInstalled" && state.InstalledTag == "overtime-1.6" && state.CanUninstall, "missing package hid installed state");
        });
        Test("validated snapshot survives package replacement during install", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture();
            Core.Install(dir, true, delegate(string s) { if (s.StartsWith("[2/4]")) File.WriteAllText(ZipPath, "changed after validation"); });
            Check(Core.Detect(dir).InstalledTag == "overtime-1.7-dev", "install tag did not come from validated snapshot");
        });
        Test("concurrent operation on same folder is rejected", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture();
            using (var ready = new ManualResetEvent(false)) using (var release = new ManualResetEvent(false))
            {
                Exception workerError = null;
                var worker = new Thread(delegate() { try { Core.Install(dir, true, delegate(string s) { if (s.StartsWith("[3/4]")) { ready.Set(); if (!release.WaitOne(5000)) throw new Exception("test synchronization timeout"); } }); } catch(Exception ex) { workerError = ex; } });
                worker.Start(); bool blocked = false;
                try { Check(ready.WaitOne(5000), "first install never reached held operation"); try { Core.Uninstall(dir, delegate(string s) { }); } catch(IOException ex) { blocked = ex.Message.Contains("Another installer"); } }
                finally { release.Set(); worker.Join(5000); }
                Check(blocked, "second operation was not blocked by the folder mutex"); Check(workerError == null, "first install failed");
            }
        });
        Test("total expanded payload bound", delegate {
            byte[] large = new byte[4 * 1024 * 1024]; var lines = new StringBuilder(FileLine("res://scripts/test.gdc", "scripts/000.gdc", script));
            for (int i = 1; i <= 9; i++) lines.Append("\n" + FileLine("res://scripts/test" + i + ".gdc", "scripts/" + i.ToString("D3") + ".gdc", large));
            Zip(Manifest(lines.ToString()), delegate(ZipArchive z) { for(int i=1;i<=9;i++) Entry(z,"scripts/"+i.ToString("D3")+".gdc",large); }); Reject();
        });
        Test("file count bound", delegate {
            var lines = new StringBuilder(FileLine("res://scripts/test.gdc", "scripts/000.gdc", script));
            for (int i = 1; i <= 256; i++) lines.Append("\n" + FileLine("res://scripts/test" + i + ".gdc", "scripts/" + i.ToString("D3") + ".gdc", script));
            Zip(Manifest(lines.ToString()), delegate(ZipArchive z) { for(int i=1;i<=256;i++) Entry(z,"scripts/"+i.ToString("D3")+".gdc",script); }); Reject();
        });
        Test("changed baseline blocks destructive recovery", delegate {
            Zip(ValidManifest(), null); string dir = MakeVanillaFixture(); string pck = Path.Combine(dir, Core.PckName);
            Core.Install(dir, true, delegate(string s) { }); File.Delete(ZipPath);
            using (var fs = new FileStream(pck, FileMode.Open, FileAccess.Write)) { fs.Position = 128; fs.WriteByte(99); }
            string hash = Core.Sha256(pck); bool refused = false; try { Core.Uninstall(dir, delegate(string s) { }); } catch { refused = true; }
            Check(refused && Core.Sha256(pck) == hash && File.Exists(Path.Combine(dir,Core.ResName)), "mismatched base was modified or recovery evidence deleted");
        });
        Console.WriteLine("RESULT failures=" + failures);
        return failures == 0 ? 0 : 1;
    }
}
