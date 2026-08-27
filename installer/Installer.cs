// Machine Party 8 人 mod —— 安装器 / 启动器
//
// 同一份源码编出两个 exe（见 tools\build_installer.ps1）：
//   mp8_install.exe    控制台版，命令行参数齐全
//   mp8_launcher.exe   窗口版（/define:GUI /target:winexe），双击即用
// 补丁字节码全部**内嵌**，两个都不需要装任何运行库、不需要下别的工具。
//
// 它不含、也不分发任何游戏原始资产：内嵌的只有 mod 自己改过的那些 .gdc。
//
// ── 还原是怎么做到只存几 KB 的 ───────────────────────────────────────
// 打补丁的做法是「把新内容追加到 PCK 末尾 + 把索引里那一条指过去」，
// **原文件的字节一个都没被覆盖**，还老老实实躺在包中间。
// 所以还原不需要 605 MB 的整包备份，只要把索引那几个字段写回去、
// 再把文件截断回原长度就行 —— 备份文件因此只有几 KB，
// 而且还原完可以直接算 SHA256 跟原版指纹比对，**能证明是逐字节精确的**。
// （旧版本那种 605 MB 整包备份仍然认，见 TryLegacyBackup。）

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.RegularExpressions;
using Microsoft.Win32;
#if GUI
using System.Drawing;
using System.Threading;
using System.Windows.Forms;
#endif

// ═════════════════════════════════════════════════════════════════════════
// 双语文案
// ═════════════════════════════════════════════════════════════════════════
static class L
{
    public static bool Zh = true;

    public static void Auto()
    {
        try { Zh = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "zh"; }
        catch { Zh = true; }
    }

    // 中英文就近写在调用处，不搞 key 表 —— 文案改动时不会漏掉另一边
    public static string T(string zh, string en) { return Zh ? zh : en; }
}

// ═════════════════════════════════════════════════════════════════════════
// 核心逻辑（控制台版与窗口版共用）
// ═════════════════════════════════════════════════════════════════════════
static class Core
{
    // ── 本 mod 支持的游戏版本（原版 PCK 的指纹）────────────────────────
    // 换游戏版本必须同时更新这三行，否则会把新版本的包按旧补丁打坏。
    public const string GameVersion = "v2.1.2";
    public const string VanillaSha  = "326CC3988D3AC554D1F288BED89B1F89D450F78EC9D4470F88558975753DFA8E";
    public const long   VanillaSize = 634798100L;

    // ── 安装器自己的发布号（与 mod 版本是两件事）────────────────────────
    // ModTag()（来自 network_manager.gd 的 MP8_VERSION_TAG）= 打进 pck 的 mod 版本，
    //   它决定谁能跟谁联机，一改就是所有人都得重装；
    // ReleaseNum = 这个 exe 自己的发布号，不进 pck、不进联机握手串，只是标识。
    // 1.3.1 就是「只修安装器」的一次发布：mod 仍是 overtime-1.3，pck 字节一个没变，
    // 已装 1.3 的人不用动，1.3 与 1.3.1 的人照样同房。
    // 它同时决定 dist\ 下的输出目录名与发布包名（见 tools\build_installer.ps1），
    // 免得重建时把已经发出去的 dist\overtime-1.3\ 连 zip 一起覆盖掉。
    public const string ReleaseNum = "1.4";

    public const string AppId   = "4108000";
    public const string GameRel = @"steamapps\common\party project\Machine Party_Windows";
    public const string PckName = "Machine Party.pck";
    public const string BakName = "Machine Party.pck.vanilla";   // 旧版整包备份（仍兼容）
    public const string ResName    = "overtime_restore.dat";           // 小体积还原数据
    // 0.9 之前叫 mp8_restore.dat。已经装过旧版的机器上还是那个名字，
    // 所以读的时候两个名字都认，写只写新名。
    public const string OldResName = "mp8_restore.dat";

    // 现场已有的还原数据在哪（新名优先）。没有就返回空串。
    public static string FindRes(string gameDir)
    {
        string a = Path.Combine(gameDir, ResName);
        if (File.Exists(a)) return a;
        string b = Path.Combine(gameDir, OldResName);
        if (File.Exists(b)) return b;
        return "";
    }

    const uint  ResMagic  = 0x3852504Du;   // "MP8R"
    const uint  ResFormat = 1u;

    // ── 日志 ───────────────────────────────────────────────────────────
    static readonly List<string> logBuf = new List<string>();
    public static string LogPath
    {
        get { return Path.Combine(Path.GetTempPath(), "overtime_install.log"); }
    }

    public static void Log(string s)
    {
        logBuf.Add(DateTime.Now.ToString("HH:mm:ss") + "  " + s);
    }

    public static void FlushLog()
    {
        // 缓冲空就别写：否则每按一次「安装日志」都往文件里插一个空段落头
        if (logBuf.Count == 0) return;
        try
        {
            var sb = new StringBuilder();
            sb.AppendLine("──── " + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") +
                          "  mod " + ModTag() + "  安装器 " + ReleaseNum +
                          "  游戏 " + GameVersion + " ────");
            foreach (string s in logBuf) sb.AppendLine(s);
            File.AppendAllText(LogPath, sb.ToString(), Encoding.UTF8);
            // 写出去就清掉。1.3 少了这一句：「安装日志」按钮 flush 一次、关窗再
            // flush 一次，同一批行被原样写进文件两遍 —— 玩家看到的是一整屏
            // 完全相同的行，反倒以为自己的日志坏了。
            logBuf.Clear();
        }
        catch { }
    }

    // ── 找游戏：注册表拿 Steam 根目录 → libraryfolders.vdf 拿所有库盘 ──
    // 返回**所有**命中的副本：有人装了多份（多库盘、家庭共享），
    // 只取第一个会打错包，让上层去问用户。
    public static List<string> FindGameDirs()
    {
        var roots = new List<string>();
        foreach (var pair in new[] {
            new[] { @"Software\Valve\Steam", "SteamPath" },
            new[] { @"SOFTWARE\WOW6432Node\Valve\Steam", "InstallPath" } })
        {
            foreach (var hive in new[] { Registry.CurrentUser, Registry.LocalMachine })
            {
                try
                {
                    using (var k = hive.OpenSubKey(pair[0]))
                    {
                        if (k == null) continue;
                        var v = k.GetValue(pair[1]) as string;
                        if (!string.IsNullOrEmpty(v)) roots.Add(v.Replace('/', '\\'));
                    }
                }
                catch { }
            }
        }

        var dirs = new List<string>(roots);
        foreach (string r in roots)
        {
            string vdf = Path.Combine(r, @"steamapps\libraryfolders.vdf");
            if (!File.Exists(vdf)) continue;
            try
            {
                foreach (Match m in Regex.Matches(File.ReadAllText(vdf), "\"path\"\\s+\"([^\"]+)\""))
                    dirs.Add(m.Groups[1].Value.Replace("\\\\", "\\"));
            }
            catch { }
        }

        var found = new List<string>();
        foreach (string d in dirs)
        {
            try
            {
                string cand = Path.Combine(d, GameRel);
                if (!File.Exists(Path.Combine(cand, PckName))) continue;
                string full = Path.GetFullPath(cand);
                bool dup = false;
                foreach (string f in found)
                    if (string.Equals(f, full, StringComparison.OrdinalIgnoreCase)) dup = true;
                if (!dup) found.Add(full);
            }
            catch { }
        }
        return found;
    }

    // ── 「现在能不能动这个包」───────────────────────────────────────────
    //
    // 1.3 之前这里只问一句：进程列表里有没有叫 "Machine Party" 的进程。
    // 那个判据错在只比名字 —— 不看路径、不看是不是当前选中的这个游戏目录。
    // 线上真出了事：有玩家机器上常驻一个同名进程（退不干净的僵尸、崩溃后被
    // WerFault 挂住、或者别处一个同名 exe），于是被永久拦在门外，重启电脑、
    // 重装游戏全都没用 —— 这两样都动不了「进程叫什么名字」这件事 ——
    // 而弹窗一个线索都不给。
    //
    // 现在拆成两条判据，各管一段：
    //   ① pck 能不能用 FileShare.None 独占打开 —— 权威。直接问文件系统
    //      「有没有人占着这个文件」，管它进程叫什么名字；
    //   ② 同名进程**且**其 exe 路径就落在这个游戏目录里 —— 补 ① 的漏：
    //      Godot 的 FileAccessPack 是「读一个资源开一次句柄」，游戏停在主菜单
    //      发呆时可能一个 pck 句柄都不持有，那时 ① 探不出来。
    // 路径拿不到、或路径在别处的同名进程一律**不拦**，只记进日志 ——
    // 那正是 1.3 把玩家锁死的那一支。

    public sealed class Holder
    {
        public int    Pid;
        public string ExePath = "";   // 取不到就是空串（权限 / 位数不匹配）
        public bool   InGameDir;      // 路径确认落在当前这个游戏目录里
    }

    // 同名进程一览。只用来解释「为什么拦你」，不单独作为判据。
    public static List<Holder> FindGameProcesses(string gameDir)
    {
        var list = new List<Holder>();
        string root = "";
        try { root = Path.GetFullPath(gameDir).TrimEnd('\\') + "\\"; }
        catch { }

        Process[] ps;
        try { ps = Process.GetProcessesByName("Machine Party"); }
        catch { return list; }

        foreach (var p in ps)
        {
            var h = new Holder();
            try { h.Pid = p.Id; } catch { h.Pid = -1; }
            // MainModule 会因为权限或 32/64 位不匹配抛异常。抛了就当路径未知，
            // 而路径未知**不拦人**（见上面那段）。
            try { h.ExePath = p.MainModule.FileName; } catch { h.ExePath = ""; }
            h.InGameDir = root.Length > 0 && h.ExePath.Length > 0 &&
                          h.ExePath.StartsWith(root, StringComparison.OrdinalIgnoreCase);
            list.Add(h);
            try { p.Dispose(); } catch { }
        }
        return list;
    }

    // 能动 → 返回 null；不能动 → 返回该原样显示给玩家的原因。
    public static string BusyReason(string gameDir)
    {
        // ② 先查进程：命中时这条的文案比 ① 有用得多（能指名道姓报 PID 和路径）
        var mine = new List<Holder>();
        foreach (var h in FindGameProcesses(gameDir))
        {
            if (h.InGameDir) mine.Add(h);
            else Log(string.Format("同名进程，不拦（路径{0}）：PID {1}  {2}",
                                   h.ExePath.Length == 0 ? "取不到" : "不在本目录",
                                   h.Pid, h.ExePath.Length == 0 ? "-" : h.ExePath));
        }
        if (mine.Count > 0)
        {
            var sb = new StringBuilder();
            sb.Append(L.T("游戏正在运行，先完全退出。\n\n占用它的进程：\n",
                          "The game is running. Fully exit it first.\n\nProcesses:\n"));
            foreach (var h in mine)
            {
                sb.AppendLine("    PID " + h.Pid + "    " + h.ExePath);
                Log("拦下：PID " + h.Pid + "  " + h.ExePath);
            }
            sb.Append(L.T("\n窗口已经关了还报这个，就是进程没退干净：\n" +
                          "任务管理器 →「详细信息」→ 找到上面这个 PID → 结束任务。",
                          "\nIf the window is already closed, the process did not exit:\n" +
                          "Task Manager -> Details -> find that PID -> End task."));
            return sb.ToString();
        }

        // ① 再问文件系统。杀软扫描、Steam 校验会瞬时占一下，给几次重试再判死。
        string pck = Path.Combine(gameDir, PckName);
        if (!File.Exists(pck)) return null;      // 包都不在，让后面的流程去报这个错
        for (int i = 0; i < 5; i++)
        {
            try
            {
                using (new FileStream(pck, FileMode.Open, FileAccess.ReadWrite, FileShare.None)) { }
                return null;
            }
            catch (UnauthorizedAccessException)
            {
                // 权限不是占用，交给 PreflightWritable 去报 —— 它那条文案更准
                return null;
            }
            catch (IOException) { }
            // using System.Threading 只在 GUI 分支里，控制台版编不到，这里写全名
            if (i < 4) System.Threading.Thread.Sleep(200);
        }
        Log("pck 独占打开失败：" + pck);
        return L.T(
            "数据包正被占用，现在动不了。\n\n" +
            "常见原因：游戏没退干净；Steam 正在更新或校验这个游戏；杀毒软件正在扫描它。\n" +
            "处理：完全退出游戏和 Steam，等几秒再试；仍然不行就重启一次电脑再来。",
            "The PCK is locked by another process.\n\n" +
            "Usual causes: the game did not exit cleanly; Steam is updating or verifying it; " +
            "an antivirus is scanning it.\n" +
            "Fix: fully exit the game and Steam, wait a few seconds, then retry; reboot if it persists.");
    }

    public static string ModTag()
    {
        try
        {
            using (var s = Assembly.GetExecutingAssembly().GetManifestResourceStream("mp8.version"))
                if (s != null) using (var r = new StreamReader(s)) return r.ReadToEnd().Trim();
        }
        catch { }
        return "mp8";
    }

    public static string Sha256(string path)
    {
        using (var sha = SHA256.Create())
        using (var fs = File.OpenRead(path))
            return BitConverter.ToString(sha.ComputeHash(fs)).Replace("-", "");
    }

    // ═══════════════════════════════════════════════════════════════════
    // PCK 结构
    // ═══════════════════════════════════════════════════════════════════
    //
    // Godot 4.5 的 PCK（格式版本 3）布局 —— 拿原装包实测出来的，不是抄文档：
    //
    //   +0   "GDPC"
    //   +4   格式版本 = 3
    //   +8   +12  +16   引擎版本 4 / 5 / 2
    //   +20  pack_flags（位 0 = 目录加密，位 1 = 偏移相对 file_base）
    //   +24  file_base (u64) = 128 ← 文件数据从这里开始
    //   +32  dir_offset(u64)       ← **索引在文件末尾**（Godot 4.4+ 改的，不在开头）
    //   …    保留区，到 128 为止
    //   128  文件数据……
    //   dir_offset:  u32 文件数，然后每条：
    //                u32 路径长(补零对齐) + 路径 + u64 偏移 + u64 大小 + md5[16] + u32 标志

    public class PckEntry
    {
        public long   FieldPos;   // 索引里「偏移」字段的绝对位置，后面三项紧随其后
        public ulong  Offset;
        public ulong  Size;
        public byte[] Md5;
    }

    public class PckIndex
    {
        public ulong FileBase;
        public bool  RelBase;
        public Dictionary<string, PckEntry> Entries = new Dictionary<string, PckEntry>();
    }

    public static PckIndex ReadIndex(FileStream fs)
    {
        var br = new BinaryReader(fs);
        fs.Position = 0;

        if (br.ReadUInt32() != 0x43504447u)
            throw new Exception(L.T("不是 PCK 文件（缺 GDPC 标记）", "Not a PCK file (missing GDPC magic)"));
        uint ver = br.ReadUInt32();
        if (ver != 3)
            throw new Exception(L.T("PCK 格式版本是 " + ver + "，本程序只认 3（Godot 4.4+）",
                                    "PCK format version is " + ver + ", this tool only supports 3 (Godot 4.4+)"));
        br.ReadUInt32(); br.ReadUInt32(); br.ReadUInt32();
        uint packFlags = br.ReadUInt32();
        if ((packFlags & 1) != 0)
            throw new Exception(L.T("这个 PCK 的目录是加密的，改不了", "This PCK has an encrypted directory"));

        var idx = new PckIndex();
        idx.FileBase = br.ReadUInt64();
        ulong dirOffset = br.ReadUInt64();
        idx.RelBase = (packFlags & 2) != 0;

        fs.Position = (long)dirOffset;
        uint count = br.ReadUInt32();
        for (uint i = 0; i < count; i++)
        {
            uint plen = br.ReadUInt32();
            string path = Encoding.UTF8.GetString(br.ReadBytes((int)plen)).TrimEnd('\0');
            var e = new PckEntry();
            e.FieldPos = fs.Position;
            e.Offset = br.ReadUInt64();
            e.Size   = br.ReadUInt64();
            e.Md5    = br.ReadBytes(16);
            br.ReadUInt32();                       // 标志
            idx.Entries[path] = e;
        }
        return idx;
    }

    // 内嵌资源：mp8.manifest 一行 "<序号>|<res:// 路径>"，内容在 mp8.<序号>
    public static SortedDictionary<string, byte[]> LoadEmbedded()
    {
        var asm = Assembly.GetExecutingAssembly();
        // ⚠️ 用 SortedDictionary 而不是 Dictionary：写入顺序决定追加顺序，
        //    进而决定产物字节。定死顺序才能「同样的输入产出同样的包」。
        var map = new SortedDictionary<string, byte[]>(StringComparer.Ordinal);

        string manifest;
        using (var s = asm.GetManifestResourceStream("mp8.manifest"))
        {
            if (s == null)
                throw new Exception(L.T("这个 exe 里没有内嵌补丁（打包时漏了）",
                                        "This exe has no embedded patches (packaging error)"));
            using (var r = new StreamReader(s, Encoding.UTF8)) manifest = r.ReadToEnd();
        }

        foreach (string raw in manifest.Split('\n'))
        {
            string line = raw.Trim();
            if (line.Length == 0 || line.StartsWith("#")) continue;
            int bar = line.IndexOf('|');
            if (bar < 0) throw new Exception("bad manifest line: " + line);
            string id = line.Substring(0, bar);
            string path = line.Substring(bar + 1).Trim();
            if (path.StartsWith("res://")) path = path.Substring(6);   // PCK 索引里不带 res://

            using (var s = asm.GetManifestResourceStream("mp8." + id))
            {
                if (s == null) throw new Exception("missing embedded patch: mp8." + id);
                var buf = new byte[s.Length];
                int off = 0;
                while (off < buf.Length) off += s.Read(buf, off, buf.Length - off);
                map[path] = buf;
            }
        }
        return map;
    }

    static byte[] Md5Of(byte[] data)
    {
        using (var md5 = MD5.Create()) return md5.ComputeHash(data);
    }

    static bool SameBytes(byte[] a, byte[] b)
    {
        if (a == null || b == null || a.Length != b.Length) return false;
        for (int i = 0; i < a.Length; i++) if (a[i] != b[i]) return false;
        return true;
    }

    // ═══════════════════════════════════════════════════════════════════
    // 当前状态
    // ═══════════════════════════════════════════════════════════════════
    public enum Kind { Missing, Vanilla, OursInstalled, OldVersion, Unknown }

    public class State
    {
        public string GameDir;
        public string PckPath;
        public Kind   Kind = Kind.Missing;
        public long   Length;
        public bool   HasRestore;
        public bool   HasLegacy;
        public string InstalledTag = "";   // 还原数据里记的 mod 版本
        public string Note = "";

        public bool CanUninstall { get { return HasRestore || HasLegacy; } }
    }

    public static State Detect(string gameDir)
    {
        var st = new State();
        st.GameDir = gameDir;
        st.PckPath = Path.Combine(gameDir, PckName);
        if (!File.Exists(st.PckPath)) return st;

        st.Length     = new FileInfo(st.PckPath).Length;
        string resPath = FindRes(gameDir);
        st.HasRestore = (resPath.Length > 0);
        st.HasLegacy  = File.Exists(Path.Combine(gameDir, BakName));

        if (st.HasRestore)
        {
            try { st.InstalledTag = ReadRestore(resPath).ModTag; }
            catch { }
        }

        try
        {
            var patches = LoadEmbedded();
            using (var fs = new FileStream(st.PckPath, FileMode.Open, FileAccess.Read))
            {
                var idx = ReadIndex(fs);

                // 判「装的是不是我们这一版」：不算整包哈希（635 MB 要十几秒），
                // 只比索引里记的 md5 与内嵌补丁的 md5 —— 一样就是我们写进去的。
                int hit = 0, total = 0;
                bool allPresent = true;
                foreach (var kv in patches)
                {
                    total++;
                    PckEntry e;
                    if (!idx.Entries.TryGetValue(kv.Key, out e)) { allPresent = false; continue; }
                    if (SameBytes(e.Md5, Md5Of(kv.Value))) hit++;
                }

                if (!allPresent)
                {
                    st.Kind = Kind.Unknown;
                    st.Note = L.T("这个包里找不到本 mod 要改的文件 —— 游戏版本多半不是 " + GameVersion,
                                  "Files this mod patches are absent — the game is probably not " + GameVersion);
                }
                else if (hit == total)   st.Kind = Kind.OursInstalled;
                else if (st.InstalledTag.Length > 0 && st.InstalledTag != ModTag())
                {
                    // 🩸 装着**别的版本**的 MP8。不这么判的话会掉进下面那条
                    //    "只有 N/47 个补丁在位、上次安装可能失败了" —— 既吓人又是错的，
                    //    而升级恰恰是最常见的路径（每次发新版所有老用户都会走到这里）。
                    st.Kind = Kind.OldVersion;
                    st.Note = L.T("装的是 Overtime " + st.InstalledTag + "，本程序是 " + ModTag() + "。直接装即可升级。",
                                  "Overtime " + st.InstalledTag + " is installed; this program is " + ModTag() + ". Installing upgrades it.");
                }
                else if (hit > 0)
                {
                    st.Kind = Kind.Unknown;
                    st.Note = L.T("只有 " + hit + "/" + total + " 个补丁在位 —— 上次安装可能中途失败了",
                                  "Only " + hit + "/" + total + " patches present — a previous install may have failed");
                }
                else if (st.Length == VanillaSize) st.Kind = Kind.Vanilla;
                else
                {
                    st.Kind = Kind.Unknown;
                    st.Note = L.T("既不是原版也不是本 mod（装过别的 mod？游戏更新了？）",
                                  "Neither vanilla nor this mod (another mod? game updated?)");
                }
            }
        }
        catch (Exception ex)
        {
            st.Kind = Kind.Unknown;
            st.Note = ex.Message;
        }
        return st;
    }

    // ═══════════════════════════════════════════════════════════════════
    // 还原数据（几 KB）
    // ═══════════════════════════════════════════════════════════════════
    class RestoreData
    {
        public long   OrigLength;      // 打补丁之前的文件长度
        public long   PatchedLength;   // 打完之后的文件长度
        public string BaseSha;         // 打补丁之前那份包的指纹；没校验过则为空
        public string GameVer;
        public string ModTag;
        public Dictionary<string, PckEntry> Orig = new Dictionary<string, PckEntry>();
        // 我们写进去的值。还原之前拿它跟现场比对，确认「这份包正是我改过的那一份」。
        public Dictionary<string, PckEntry> Made = new Dictionary<string, PckEntry>();
    }

    static void WriteRestore(string path, RestoreData d)
    {
        using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write))
        using (var bw = new BinaryWriter(fs, Encoding.UTF8))
        {
            bw.Write(ResMagic);
            bw.Write(ResFormat);
            bw.Write(d.OrigLength);
            bw.Write(d.PatchedLength);
            bw.Write(d.BaseSha == null ? "" : d.BaseSha);
            bw.Write(d.GameVer);
            bw.Write(d.ModTag);
            bw.Write(d.Orig.Count);
            foreach (var kv in d.Orig)
            {
                var made = d.Made[kv.Key];
                bw.Write(kv.Key);
                bw.Write(kv.Value.Offset); bw.Write(kv.Value.Size); bw.Write(kv.Value.Md5);
                bw.Write(made.Offset);     bw.Write(made.Size);     bw.Write(made.Md5);
            }
        }
    }

    static RestoreData ReadRestore(string path)
    {
        using (var fs = new FileStream(path, FileMode.Open, FileAccess.Read))
        using (var br = new BinaryReader(fs, Encoding.UTF8))
        {
            if (br.ReadUInt32() != ResMagic)
                throw new Exception(L.T("还原数据文件损坏（标记不对）", "Restore data corrupt (bad magic)"));
            uint fmt = br.ReadUInt32();
            if (fmt != ResFormat)
                throw new Exception(L.T("还原数据的格式版本是 " + fmt + "，本程序不认",
                                        "Restore data format " + fmt + " is not supported"));
            var d = new RestoreData();
            d.OrigLength    = br.ReadInt64();
            d.PatchedLength = br.ReadInt64();
            d.BaseSha       = br.ReadString();
            d.GameVer       = br.ReadString();
            d.ModTag        = br.ReadString();
            int n = br.ReadInt32();
            for (int i = 0; i < n; i++)
            {
                string p = br.ReadString();
                var o = new PckEntry();
                o.Offset = br.ReadUInt64(); o.Size = br.ReadUInt64(); o.Md5 = br.ReadBytes(16);
                var m = new PckEntry();
                m.Offset = br.ReadUInt64(); m.Size = br.ReadUInt64(); m.Md5 = br.ReadBytes(16);
                d.Orig[p] = o;
                d.Made[p] = m;
            }
            return d;
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 打补丁 / 还原
    // ═══════════════════════════════════════════════════════════════════
    //
    // 改法：**追加 + 改索引**，不重写整个包。
    //   1. 新内容写到文件末尾（索引后面也无所谓 —— 引擎只按索引里的偏移去 seek）；
    //   2. 把那一条索引的 偏移/大小/md5 原地改掉。
    // 于是 635 MB 的包只写进去 ~640 KB，秒级完成。
    static int PatchPck(string pckPath, SortedDictionary<string, byte[]> patches, RestoreData rec)
    {
        int replaced = 0;
        using (var fs = new FileStream(pckPath, FileMode.Open, FileAccess.ReadWrite))
        {
            var idx = ReadIndex(fs);
            var bw = new BinaryWriter(fs);

            var missing = new List<string>();
            foreach (var kv in patches) if (!idx.Entries.ContainsKey(kv.Key)) missing.Add(kv.Key);
            if (missing.Count > 0)
                throw new Exception(L.T("这些补丁在游戏包里找不到对应文件（游戏版本不对？）：\n  ",
                                        "These patches have no counterpart in the game (wrong version?):\n  ")
                                    + string.Join("\n  ", missing.ToArray()));

            // 先把「改之前的索引字段」原样记下来 —— 这就是还原的全部所需
            rec.OrigLength = fs.Length;
            foreach (var kv in patches)
            {
                var e = idx.Entries[kv.Key];
                var copy = new PckEntry();
                copy.Offset = e.Offset; copy.Size = e.Size; copy.Md5 = e.Md5;
                rec.Orig[kv.Key] = copy;
            }

            foreach (var kv in patches)      // SortedDictionary：顺序确定，产物可复现
            {
                byte[] data = kv.Value;
                fs.Position = fs.Length;
                long at = fs.Position;
                bw.Write(data);

                ulong stored = idx.RelBase ? (ulong)at - idx.FileBase : (ulong)at;
                byte[] md5 = Md5Of(data);
                fs.Position = idx.Entries[kv.Key].FieldPos;
                bw.Write(stored);
                bw.Write((ulong)data.Length);
                bw.Write(md5);

                var made = new PckEntry();
                made.Offset = stored; made.Size = (ulong)data.Length; made.Md5 = md5;
                rec.Made[kv.Key] = made;
                replaced++;
            }
            bw.Flush();
            rec.PatchedLength = fs.Length;
        }
        return replaced;
    }

    // 「现在这份包，正是我当初改过的那一份吗？」
    //
    // 🩸 这道闸门不能省。还原的做法是把索引字段写回记录下来的旧值 + 截断到旧长度 ——
    //    一旦文件已经不是当初那份（最常见：**Steam 更新了游戏**，或用户点了
    //    「验证游戏文件的完整性」），把旧偏移写进新包的索引就是**当场写坏它**。
    //    所以还原之前必须逐条证明现场与记录一致。
    static bool RestoreApplies(string pckPath, RestoreData d, out string why)
    {
        why = null;
        try
        {
            var fi = new FileInfo(pckPath);
            if (fi.Length != d.PatchedLength)
            {
                why = L.T("数据包长度变了（记录 " + d.PatchedLength.ToString("N0") +
                          "，现在 " + fi.Length.ToString("N0") + "）",
                          "PCK length changed (recorded " + d.PatchedLength.ToString("N0") +
                          ", now " + fi.Length.ToString("N0") + ")");
                return false;
            }

            using (var fs = new FileStream(pckPath, FileMode.Open, FileAccess.Read))
            {
                var idx = ReadIndex(fs);
                foreach (var kv in d.Made)
                {
                    PckEntry cur;
                    if (!idx.Entries.TryGetValue(kv.Key, out cur))
                    {
                        why = L.T("数据包里已经没有 " + kv.Key, "The PCK no longer contains " + kv.Key);
                        return false;
                    }
                    if (cur.Offset != kv.Value.Offset || cur.Size != kv.Value.Size ||
                        !SameBytes(cur.Md5, kv.Value.Md5))
                    {
                        why = L.T("索引对不上（" + kv.Key + "）", "Index mismatch (" + kv.Key + ")");
                        return false;
                    }
                }
            }
            return true;
        }
        catch (Exception ex) { why = ex.Message; return false; }
    }

    // 打完之后把索引重新读一遍，核对每条的 md5 都是我们刚写的那份。
    // 便宜的保险：写了一半断电/磁盘满，这里就能当场发现。
    static void VerifyPatched(string pckPath, SortedDictionary<string, byte[]> patches)
    {
        using (var fs = new FileStream(pckPath, FileMode.Open, FileAccess.Read))
        {
            var idx = ReadIndex(fs);
            var bad = new List<string>();
            foreach (var kv in patches)
            {
                PckEntry e;
                if (!idx.Entries.TryGetValue(kv.Key, out e)) { bad.Add(kv.Key); continue; }
                if (!SameBytes(e.Md5, Md5Of(kv.Value))) bad.Add(kv.Key);
                if (e.Size != (ulong)kv.Value.Length) bad.Add(kv.Key);
            }
            if (bad.Count > 0)
                throw new Exception(L.T("写入自检没过（" + bad.Count + " 条对不上）",
                                        "Post-write verification failed (" + bad.Count + " entries)"));
        }
    }

    // 还原：把索引字段写回去 + 截断掉我们追加的那一段。
    // 原文件的字节从来没被覆盖过，所以这样就是**逐字节**回到打补丁之前。
    static void ApplyRestore(string pckPath, RestoreData d)
    {
        string why;
        if (!RestoreApplies(pckPath, d, out why))
            throw new Exception(L.T(
                "还原数据跟当前的游戏数据包对不上，**没有动你的文件**。\n  " + why + "\n" +
                "多半是 Steam 更新了游戏，或者你点过「验证游戏文件的完整性」——\n" +
                "那样游戏已经是原版了，把 " + ResName + " 删掉即可。",
                "The restore data does not match the current PCK. Nothing was changed.\n  " + why + "\n" +
                "Most likely Steam updated the game, or you ran \"Verify integrity of game files\" —\n" +
                "in that case the game is already vanilla; just delete " + ResName + "."));

        using (var fs = new FileStream(pckPath, FileMode.Open, FileAccess.ReadWrite))
        {
            var idx = ReadIndex(fs);
            var bw = new BinaryWriter(fs);
            foreach (var kv in d.Orig)
            {
                var e = idx.Entries[kv.Key];       // RestoreApplies 已保证存在
                fs.Position = e.FieldPos;
                bw.Write(kv.Value.Offset);
                bw.Write(kv.Value.Size);
                bw.Write(kv.Value.Md5);
            }
            bw.Flush();
            fs.SetLength(d.OrigLength);      // 砍掉追加的那一段
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // 对外动作
    // ═══════════════════════════════════════════════════════════════════
    public static void Install(string gameDir, bool force, Action<string> say)
    {
        string live = Path.Combine(gameDir, PckName);
        string res  = Path.Combine(gameDir, ResName);   // 写：永远用新名
        string cur  = FindRes(gameDir);                 // 读：现场那个（可能是旧名）
        string bak  = Path.Combine(gameDir, BakName);

        PreflightWritable(gameDir, live);

        // 已经装过 → 先原样还原回去，再从干净的包重打。
        // 不这么做的话补丁会一层层叠上去，包越来越大。
        if (cur.Length > 0)
        {
            RestoreData old = null;
            string why = null;
            try { old = ReadRestore(cur); } catch (Exception ex) { why = ex.Message; }

            if (old != null && RestoreApplies(live, old, out why))
            {
                say(L.T("[1/4] 先还原上一次的安装…", "[1/4] Reverting the previous install first..."));
                ApplyRestore(live, old);
                File.Delete(cur);
            }
            else
            {
                // 现场跟记录对不上（Steam 更新、或用户点过「验证游戏文件的完整性」）。
                // 拿它去改包会写坏文件，所以只忽略、不使用；
                // 当前这份包到底能不能装，交给下面那道原版校验判。
                say(L.T("[1/4] 上次的还原数据跟当前数据包对不上，已忽略（" + why + "）",
                        "[1/4] Stale restore data ignored (" + why + ")"));
            }
        }
        else if (File.Exists(bak))
        {
            // 旧版的 605 MB 整包备份：**必须验哈希**。
            // 🩸 老版本安装器在这里只判存在、不验内容 —— 游戏更新之后重装，
            //    会把旧版本的数据包盖到新游戏上。这条就是修那个 bug。
            say(L.T("[1/4] 发现旧版整包备份，校验中（约十几秒）…",
                    "[1/4] Found a legacy full backup, verifying (~15s)..."));
            string bs = Sha256(bak);
            if (bs != VanillaSha)
                throw new Exception(L.T(
                    "旧版备份 " + BakName + " 不是本 mod 认识的原版，**没有动你的文件**。\n" +
                    "  多半是游戏更新过、而那份备份还是旧版本的。\n" +
                    "  处理：把它删掉，然后用 Steam「验证游戏文件的完整性」拿回当前版本的原版。",
                    "Legacy backup " + BakName + " is not the vanilla build this mod knows. Nothing was changed.\n" +
                    "  Most likely the game updated while that backup is from an older version.\n" +
                    "  Fix: delete it, then use Steam's \"Verify integrity of game files\"."));
            File.Copy(bak, live, true);
            say(L.T("      ✓ 已从旧备份还原到原版", "      OK, restored to vanilla from the legacy backup"));
        }

        // 现在这份包应该是干净原版了，验一下
        say(L.T("[2/4] 校验当前数据包是不是原版（约十几秒）…",
                "[2/4] Verifying the current PCK is vanilla (~15s)..."));
        long sz = new FileInfo(live).Length;
        string sha = Sha256(live);
        bool verified = (sha == VanillaSha);

        if (!verified)
        {
            if (!force)
                throw new Exception(L.T(
                    "当前数据包跟本 mod 认识的原版对不上，**没有动它**。\n" +
                    "  期望：" + VanillaSha + "（" + GameVersion + "，" + VanillaSize.ToString("N0") + " 字节）\n" +
                    "  实际：" + sha + "（" + sz.ToString("N0") + " 字节）\n" +
                    "常见原因：\n" +
                    "  1. 游戏更新了 —— 要等 mod 出适配新版本的版本，硬装会坏；\n" +
                    "  2. 已经装过别的 mod。\n" +
                    "补救：Steam → 右键游戏 → 属性 → 已安装的文件 → 验证游戏文件的完整性。\n" +
                    "确定要继续可以加 --force。",
                    "The current PCK does not match the vanilla build this mod knows. Nothing was changed.\n" +
                    "  Expected: " + VanillaSha + " (" + GameVersion + ", " + VanillaSize.ToString("N0") + " bytes)\n" +
                    "  Actual:   " + sha + " (" + sz.ToString("N0") + " bytes)\n" +
                    "Common causes:\n" +
                    "  1. The game was updated — wait for a mod build that targets it;\n" +
                    "  2. Another mod is already installed.\n" +
                    "Fix: Steam -> right click the game -> Properties -> Installed Files -> Verify integrity.\n" +
                    "Use --force to proceed anyway."));
            say(L.T("      ⚠ 校验没过，但你加了 --force，继续。",
                    "      WARNING: verification failed but --force was given, continuing."));
        }
        else say(L.T("      ✓ 是原版 " + GameVersion, "      OK, vanilla " + GameVersion));

        var patches = LoadEmbedded();
        say(L.T("[3/4] 写入 " + patches.Count + " 个补丁…",
                "[3/4] Writing " + patches.Count + " patches..."));

        var rec = new RestoreData();
        rec.BaseSha = verified ? VanillaSha : null;   // 没验过就不承诺还原后等于原版
        rec.GameVer = GameVersion;
        rec.ModTag  = ModTag();

        var sw = Stopwatch.StartNew();
        int n = PatchPck(live, patches, rec);
        sw.Stop();

        // 还原数据必须在打完之后落盘：中途失败的话文件里没有半份还原数据，
        // 重跑一次会当成「没装过」，从原包重打，天然自洽。
        WriteRestore(res, rec);

        say(L.T("[4/4] 写入自检…", "[4/4] Verifying what was written..."));
        VerifyPatched(live, patches);

        say("");
        say(L.T("✓ 装好了：" + n + " 个文件已替换，用时 " + sw.Elapsed.TotalSeconds.ToString("0.0") + " 秒",
                "Done: " + n + " files replaced in " + sw.Elapsed.TotalSeconds.ToString("0.0") + "s"));

        if (File.Exists(bak))
            say(L.T("提示：现在还原只需要 " + ResName + "（几 KB），那份 605 MB 的 " + BakName + " 可以删了。",
                    "Note: reverting now only needs " + ResName + " (a few KB); the 605 MB " + BakName + " can be deleted."));
    }

    public static void Uninstall(string gameDir, Action<string> say)
    {
        string live = Path.Combine(gameDir, PckName);
        string res  = FindRes(gameDir);                // 可能是旧名 mp8_restore.dat
        string bak  = Path.Combine(gameDir, BakName);

        PreflightWritable(gameDir, live);

        string stale = null;
        if (res.Length > 0)
        {
            RestoreData d = null;
            try { d = ReadRestore(res); } catch (Exception ex) { stale = ex.Message; }

            // 对不上就别硬来 —— 下面还有整包备份那条路，实在不行让 Steam 修
            if (d != null && !RestoreApplies(live, d, out stale)) d = null;

            if (d != null)
            {
                say(L.T("正在还原原版…", "Restoring vanilla..."));
                ApplyRestore(live, d);

                if (!string.IsNullOrEmpty(d.BaseSha))
                {
                    say(L.T("校验还原结果（约十几秒）…", "Verifying the restored file (~15s)..."));
                    string sha = Sha256(live);
                    if (sha != d.BaseSha)
                        throw new Exception(L.T(
                            "还原完的数据包跟原版指纹对不上：\n  期望 " + d.BaseSha + "\n  实际 " + sha +
                            "\n用 Steam「验证游戏文件的完整性」可以拿回原版。",
                            "The restored PCK does not match the vanilla fingerprint:\n  expected " + d.BaseSha +
                            "\n  actual   " + sha + "\nUse Steam's \"Verify integrity of game files\" to recover."));
                    say(L.T("      ✓ 逐字节等于原版 " + GameVersion,
                            "      OK, byte-for-byte identical to vanilla " + GameVersion));
                }
                File.Delete(res);
                say("");
                say(L.T("✓ 已还原成原版，现在可以跟没装 mod 的朋友一起玩了。",
                        "Reverted to vanilla. You can play with unmodded friends now."));
                return;
            }
        }

        if (File.Exists(bak))
        {
            say(L.T("用旧版整包备份还原，先校验（约十几秒）…",
                    "Restoring from the legacy full backup, verifying first (~15s)..."));
            if (Sha256(bak) != VanillaSha)
                throw new Exception(L.T(
                    "旧版备份不是本 mod 认识的原版，**没有动你的文件**。\n" +
                    "用 Steam「验证游戏文件的完整性」拿回原版。",
                    "The legacy backup is not the vanilla build this mod knows. Nothing was changed.\n" +
                    "Use Steam's \"Verify integrity of game files\"."));
            File.Copy(bak, live, true);
            say("");
            say(L.T("✓ 已还原成原版。", "Reverted to vanilla."));
            return;
        }

        // 走到这儿没有可用的还原手段。先看看是不是根本不用还原 ——
        // 用户点过 Steam「验证游戏文件的完整性」之后就是这个状态：包已经是原版，
        // 只剩一个用不上的 mp8_restore.dat。这种情况该报喜，不该报错。
        var now = Detect(gameDir);
        if (now.Kind == Kind.Vanilla)
        {
            if (res.Length > 0) { try { File.Delete(res); } catch { } }
            say(L.T("✓ 当前已经是原版了，不用还原（顺手清掉了用不上的还原数据）。",
                    "Already vanilla, nothing to revert (removed the stale restore data)."));
            return;
        }

        throw new Exception(L.T(
            "没有可用的还原手段 —— 没法自己还原。\n" +
            (stale != null ? "  还原数据用不了：" + stale + "\n" : "  找不到还原数据（" + ResName + "），也没有旧版备份。\n") +
            "补救：Steam → 右键游戏 → 属性 → 已安装的文件 → 验证游戏文件的完整性，\n" +
            "Steam 会重新下载原版（约 600 MB）。",
            "No usable way to revert.\n" +
            (stale != null ? "  Restore data unusable: " + stale + "\n" : "  No restore data (" + ResName + ") and no legacy backup.\n") +
            "Fix: Steam -> right click the game -> Properties -> Installed Files -> Verify integrity of game files."));
    }

    // 写得进去吗、地方够吗 —— 提前问清楚，别写到一半才炸
    static void PreflightWritable(string gameDir, string live)
    {
        try
        {
            using (var fs = new FileStream(live, FileMode.Open, FileAccess.ReadWrite)) { }
        }
        catch (UnauthorizedAccessException)
        {
            throw new Exception(L.T(
                "没有写入权限：" + gameDir + "\n" +
                "游戏装在受保护的目录里（比如 Program Files）。\n" +
                "处理：右键本程序 →「以管理员身份运行」。",
                "No write permission: " + gameDir + "\n" +
                "The game lives in a protected folder (e.g. Program Files).\n" +
                "Fix: right click this program -> Run as administrator."));
        }
        catch (IOException)
        {
            throw new Exception(L.T(
                "数据包被占用，动不了。\n" +
                "处理：完全退出游戏；Steam 若正在更新或校验这个游戏，等它做完；必要时退出 Steam。",
                "The PCK is locked by another process.\n" +
                "Fix: fully exit the game; if Steam is updating or validating it, wait; exit Steam if needed."));
        }

        try
        {
            var drive = new DriveInfo(Path.GetPathRoot(Path.GetFullPath(gameDir)));
            // 追加量 ~1 MB，留 200 MB 余量足够；旧版整包备份那条路才需要 605 MB
            if (drive.AvailableFreeSpace < 200L * 1024 * 1024)
                throw new Exception(L.T(
                    "磁盘剩余空间不足 200 MB（" + drive.Name + "），先腾点地方再来。",
                    "Less than 200 MB free on " + drive.Name + ". Free up some space first."));
        }
        catch (Exception ex)
        {
            if (ex.Message.StartsWith("磁盘") || ex.Message.StartsWith("Less than")) throw;
            // 取不到盘符信息就算了，不因为查不了空间而拦住安装
        }
    }

    // 免费声明。放在 Core 里，保证控制台版与窗口版一字不差。
    // 起因：社区里有人把同类 mod 闭源收费卖，本 mod 是免费替代品。
    public static string FreeNotice()
    {
        return L.T("本 mod 完全免费。如果你为它花过钱，说明你被骗了。",
                   "This mod is completely FREE. If you paid for it, you were scammed.");
    }

    public static void OpenSteamValidate()
    {
        try { Process.Start("steam://validate/" + AppId); } catch { }
    }

    // ── 游戏自己的日志目录（Godot 写的，不是本安装器写的那份）────────────────
    //
    // 排 mod 的 bug 要的是这一份。T45 那次碎骨者黑屏就卡在拿不到房主机器上的
    // godot.log —— 让每个玩家都能两下点开自己的日志目录，就是为了堵这个缺口。
    //
    // ⚠️⚠️ 这里**刻意只开文件夹，不复制、不打包、不上传**，这条别改：
    //   本 exe 未签名，而「读用户目录下的文件 → 打包 → 往外发」正是 infostealer
    //   的行为签名。只调 explorer 打开一个目录，杀软画像一点不动。
    //   **本文件至今零网络调用（grep 不到 System.Net / HttpClient / Socket），
    //   别在这里开第一处。** 用户自己把文件拖出来即可。
    //
    // /select 会顺带把 godot.log 选中：目录里还躺着几个轮换的 godot<日期>.log，
    // 不指一下用户不知道该拿哪个（而且 godot.log 才是当前这次的）。
    // 文件不在就退回只开目录；目录也不在（游戏还没启动过）就返回 false，由界面提示。
    public static string GameLogDir
    {
        get
        {
            return Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                @"Godot\app_userdata\Machine Party\logs");
        }
    }

    public static bool OpenGameLogFolder()
    {
        try
        {
            string dir = GameLogDir;
            string cur = Path.Combine(dir, "godot.log");

            if (File.Exists(cur))
            {
                Process.Start("explorer.exe", "/select,\"" + cur + "\"");
                return true;
            }
            if (Directory.Exists(dir))
            {
                Process.Start("explorer.exe", "\"" + dir + "\"");
                return true;
            }
            return false;
        }
        catch { return false; }
    }

    public static void LaunchGame()
    {
        try { Process.Start("steam://rungameid/" + AppId); } catch { }
    }
}

#if !GUI
// ═════════════════════════════════════════════════════════════════════════
// 控制台版
// ═════════════════════════════════════════════════════════════════════════
static class Installer
{
    static bool pause = true;

    static int Main(string[] args)
    {
        L.Auto();

        bool uninstall = false, force = false, status = false, validate = false;
        string gameDir = null;

        for (int i = 0; i < args.Length; i++)
        {
            string a = args[i].ToLowerInvariant();
            if (a == "--uninstall" || a == "-u") uninstall = true;
            else if (a == "--status" || a == "-s") status = true;
            else if (a == "--force") force = true;
            else if (a == "--validate") validate = true;
            else if (a == "--no-pause") pause = false;
            else if (a == "--lang" && i + 1 < args.Length) L.Zh = (args[++i].ToLowerInvariant() == "zh");
            else if ((a == "--game" || a == "-g") && i + 1 < args.Length) gameDir = args[++i];
            else if (a == "--help" || a == "-h" || a == "/?") { Usage(); return 0; }
            else { Console.WriteLine("unknown argument: " + args[i]); Usage(); return Done(2); }
        }

        try { Console.OutputEncoding = Encoding.UTF8; } catch { }
        Line(L.T("Machine Party-Overtime（8 人联机 + 全面重平衡）",
                 "Machine Party-Overtime - 8 players & rebalance"), ConsoleColor.Green);
        Console.WriteLine(L.T("适用游戏版本：", "Target game version: ") + Core.GameVersion +
                          L.T("        mod 版本：", "        mod version: ") + Core.ModTag() +
                          L.T("        安装器：", "        installer: ") + Core.ReleaseNum);
        Console.WriteLine();

        try
        {
            if (validate) { Core.OpenSteamValidate(); Console.WriteLine(L.T("已请求 Steam 校验游戏文件。", "Asked Steam to verify game files.")); return Done(0); }

            if (gameDir == null) gameDir = PickGameDir();
            if (gameDir == null || !File.Exists(Path.Combine(gameDir, Core.PckName)))
                return Fail(L.T(
                    "没找到 Machine Party 的安装目录。\n用 --game 手动指定，例如：\n" +
                    "  mp8_install.exe --game \"D:\\Steam\\" + Core.GameRel + "\"\n" +
                    "（Steam 里右键游戏 → 管理 → 浏览本地文件，打开的就是那个目录）",
                    "Could not find the Machine Party install folder.\nSpecify it with --game, e.g.\n" +
                    "  mp8_install.exe --game \"D:\\Steam\\" + Core.GameRel + "\"\n" +
                    "(In Steam: right click the game -> Manage -> Browse local files.)"));

            Console.WriteLine(L.T("游戏目录：", "Game folder: ") + gameDir);
            Core.Log("gameDir=" + gameDir);
            Console.WriteLine();

            if (status) { PrintStatus(gameDir); return Done(0); }

            string busy = Core.BusyReason(gameDir);
            if (busy != null) return Fail(busy);

            if (uninstall) Core.Uninstall(gameDir, Say);
            else           Core.Install(gameDir, force, Say);

            if (!uninstall)
            {
                Console.WriteLine();
                Warn(L.T("接下来：", "Next:"));
                Console.WriteLine(L.T(
                    "  · 从 Steam 正常启动游戏，主菜单右下角版本号带 +" + Core.ModTag() + " 就是装上了。",
                    "  - Launch the game from Steam; the version in the bottom right of the main menu ends with +" + Core.ModTag() + "."));
                Console.WriteLine(L.T(
                    "  · **一起玩的人必须都装同一版**：版本对不上会被房主直接拒绝进房。",
                    "  - EVERYONE in the lobby must install the SAME version, or the host will refuse them."));
                Console.WriteLine(L.T(
                    "  · 想回原版：本程序加 --uninstall 参数再跑一次。",
                    "  - To revert: run this program again with --uninstall."));
                Console.WriteLine();
                Warn(L.T("⚠ Steam 更新游戏、或点了「验证游戏文件的完整性」，都会把 mod 冲掉；重跑本程序即可。",
                         "Steam updating the game (or verifying its files) removes the mod; just run this again."));

                // 免费声明放在最后一行 —— 装完之后视线停在这里
                Console.WriteLine();
                Line(Core.FreeNotice(), ConsoleColor.Red);
            }
            return Done(0);
        }
        catch (Exception ex)
        {
            Core.Log("ERROR " + ex);
            return Fail(ex.Message + L.T(
                "\n\n（完整日志：" + Core.LogPath + "）",
                "\n\n(Full log: " + Core.LogPath + ")"));
        }
    }

    // 找到多份就让用户挑，别默默用第一个
    static string PickGameDir()
    {
        var dirs = Core.FindGameDirs();
        if (dirs.Count == 0) return null;
        if (dirs.Count == 1) return dirs[0];

        Warn(L.T("找到 " + dirs.Count + " 份游戏安装，选一个：",
                 "Found " + dirs.Count + " installs, pick one:"));
        for (int i = 0; i < dirs.Count; i++) Console.WriteLine("  " + (i + 1) + ") " + dirs[i]);
        Console.Write(L.T("输入序号：", "Number: "));
        string s = Console.ReadLine();
        int n;
        if (int.TryParse(s == null ? "" : s.Trim(), out n) && n >= 1 && n <= dirs.Count) return dirs[n - 1];
        return null;
    }

    static void PrintStatus(string gameDir)
    {
        var st = Core.Detect(gameDir);
        Console.WriteLine(L.T("数据包：", "PCK:      ") + st.PckPath);
        Console.WriteLine(L.T("大小：  ", "Size:     ") + st.Length.ToString("N0"));
        switch (st.Kind)
        {
            case Core.Kind.Vanilla:
                Line(L.T("状态：  原版（没装 mod）", "State:    vanilla (mod not installed)"), ConsoleColor.Gray); break;
            case Core.Kind.OursInstalled:
                Line(L.T("状态：  已装 Overtime " + Core.ModTag(), "State:    Overtime " + Core.ModTag() + " installed"), ConsoleColor.Green); break;
            case Core.Kind.OldVersion:
                Line(L.T("状态：  已装 Overtime " + st.InstalledTag + "（旧版，本程序是 " + Core.ModTag() + "）",
                         "State:    Overtime " + st.InstalledTag + " installed (this program is " + Core.ModTag() + ")"), ConsoleColor.Yellow);
                Console.WriteLine(L.T("        直接运行本程序即可升级。", "        Just run this program to upgrade."));
                break;
            case Core.Kind.Missing:
                Line(L.T("状态：  找不到数据包", "State:    PCK not found"), ConsoleColor.Red); break;
            default:
                Line(L.T("状态：  认不出来", "State:    unrecognised"), ConsoleColor.Yellow);
                if (st.Note.Length > 0) Console.WriteLine("        " + st.Note);
                break;
        }
        Console.WriteLine(L.T("还原数据：", "Restore:  ") + (st.HasRestore ? Path.GetFileName(Core.FindRes(gameDir)) : "-"));
        Console.WriteLine(L.T("旧版备份：", "Legacy:   ") + (st.HasLegacy ? Core.BakName + " (605 MB)" : "-"));
        Console.WriteLine(L.T("日志：  ", "Log:      ") + Core.LogPath);
    }

    static void Say(string s) { Console.WriteLine(s); Core.Log(s); }

    static void Line(string s, ConsoleColor c)
    {
        var old = Console.ForegroundColor; Console.ForegroundColor = c;
        Console.WriteLine(s); Console.ForegroundColor = old;
        Core.Log(s);
    }
    static void Warn(string s) { Line(s, ConsoleColor.Yellow); }

    static int Fail(string msg)
    {
        Console.WriteLine();
        Line("X " + msg, ConsoleColor.Red);
        return Done(1);
    }

    // 双击运行时窗口会一闪而过，所以停一下让人看得见结果
    static int Done(int code)
    {
        Core.FlushLog();
        if (pause && !Console.IsOutputRedirected)
        {
            Console.WriteLine();
            Console.WriteLine(L.T("（按任意键关闭）", "(press any key to close)"));
            try { Console.ReadKey(true); } catch { }
        }
        return code;
    }

    static void Usage()
    {
        Console.WriteLine();
        Console.WriteLine(L.T("用法：", "Usage:"));
        Console.WriteLine(L.T("  mp8_install.exe                 安装（自动找 Steam 里的游戏）",
                              "  mp8_install.exe                 install (auto-detects the game)"));
        Console.WriteLine(L.T("  mp8_install.exe --uninstall     还原成原版",
                              "  mp8_install.exe --uninstall     revert to vanilla"));
        Console.WriteLine(L.T("  mp8_install.exe --status        只看当前状态，不改任何东西",
                              "  mp8_install.exe --status        show current state, change nothing"));
        Console.WriteLine(L.T("  mp8_install.exe --game \"<目录>\"  手动指定游戏目录",
                              "  mp8_install.exe --game \"<dir>\"   set the game folder manually"));
        Console.WriteLine(L.T("  mp8_install.exe --validate      让 Steam 校验游戏文件（拿回原版）",
                              "  mp8_install.exe --validate      ask Steam to verify game files"));
        Console.WriteLine(L.T("  mp8_install.exe --lang en|zh    界面语言",
                              "  mp8_install.exe --lang en|zh    interface language"));
        Console.WriteLine(L.T("  mp8_install.exe --force         跳过原版校验（后果自负）",
                              "  mp8_install.exe --force         skip the vanilla check (at your own risk)"));
    }
}
#endif

#if GUI
// ═════════════════════════════════════════════════════════════════════════
// 窗口版：一个开关在「原版 ⇄ MP8」之间切
//
// 为什么值得做：本 mod 最大的体验代价是「装了就不能跟没装的朋友玩」
// （版本握手是故意这么设计的）。既然还原只要写几 KB，切换就该是一秒钟一个按钮的事。
//
// 界面刻意用固定浅色配色，不跟随系统深色模式 —— WinForms 没有原生深色支持，
// 半吊子跟随只会做出黑底黑字。
// ═════════════════════════════════════════════════════════════════════════
static class Launcher
{
    [STAThread]
    static void Main()
    {
        L.Auto();
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        Application.Run(new MainForm());
    }
}

class MainForm : Form
{
    // ── 配色 ────────────────────────────────────────────────────────────
    static readonly Color Ink      = Color.FromArgb( 24,  26,  33);
    static readonly Color InkSub   = Color.FromArgb(150, 156, 168);
    static readonly Color Muted    = Color.FromArgb(110, 118, 132);
    static readonly Color CardBg   = Color.FromArgb(246, 247, 249);
    static readonly Color CardLine = Color.FromArgb(226, 229, 234);
    static readonly Color Amber    = Color.FromArgb(202, 138,   4);
    static readonly Color AmberHot = Color.FromArgb(170, 116,   3);
    static readonly Color Slate    = Color.FromArgb( 71,  85, 105);
    static readonly Color SlateHot = Color.FromArgb( 51,  65,  85);
    static readonly Color Ghost    = Color.FromArgb(238, 240, 244);
    static readonly Color GhostHot = Color.FromArgb(226, 229, 234);
    static readonly Color Good     = Color.FromArgb( 22, 143,  74);
    static readonly Color Bad      = Color.FromArgb(185,  28,  28);
    static readonly Color Caution  = Color.FromArgb(180,  83,   9);
    static readonly Color FreeBg   = Color.FromArgb(254, 237, 237);
    static readonly Color FreeLine = Color.FromArgb(246, 203, 203);

    ComboBox dirBox;
    Label    stateLabel, noteLabel;
    Panel    accentBar;
    Button   toggleBtn, launchBtn, validateBtn, logBtn, gameLogBtn;
    Core.State st;
    bool busy;

    static Font F(float size, FontStyle style)
    {
        // Segoe UI 在 Win10/11 一定有，中文会自动回退到微软雅黑
        return new Font("Segoe UI", size, style);
    }

    static Button FlatBtn(string text, Color bg, Color hover, Color fg, float size, FontStyle fs)
    {
        var b = new Button();
        b.Text = text;
        b.FlatStyle = FlatStyle.Flat;
        b.FlatAppearance.BorderSize = 0;
        b.FlatAppearance.MouseOverBackColor = hover;
        b.FlatAppearance.MouseDownBackColor = hover;
        b.BackColor = bg;
        b.ForeColor = fg;
        b.Font = F(size, fs);
        b.Cursor = Cursors.Hand;
        b.UseVisualStyleBackColor = false;
        return b;
    }

    public MainForm()
    {
        Text = "Machine Party-Overtime";   // 品牌名，两种语言下一致
        FormBorderStyle = FormBorderStyle.FixedSingle;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        ClientSize = new Size(580, 430);
        BackColor = Color.White;
        Font = F(9f, FontStyle.Regular);

        // ── 顶栏 ───────────────────────────────────────────────────────
        var header = new Panel();
        header.SetBounds(0, 0, 580, 78);
        header.BackColor = Ink;
        Controls.Add(header);

        var title = new Label();
        title.Text = "Overtime";
        title.Font = F(15f, FontStyle.Bold);
        title.ForeColor = Color.White;
        title.AutoSize = false;
        title.SetBounds(24, 14, 320, 30);
        header.Controls.Add(title);

        var sub = new Label();
        sub.Text = L.T("Machine Party　·　人数上限 4 → 8", "Machine Party  ·  8 players & rebalance");
        sub.Font = F(8.5f, FontStyle.Regular);
        sub.ForeColor = InkSub;
        sub.AutoSize = false;
        sub.SetBounds(26, 46, 340, 20);
        header.Controls.Add(sub);

        var ver = new Label();
        // 三行：mod 版本 / 安装器发布号 / 游戏版本。安装器那行是给排障用的 ——
        // 只修安装器的发布（如 1.3.1）ModTag() 不变，没有这一行就分不出玩家手上
        // 是修好的那版还是出事的那版，而我们能拿到的往往只有一张截图。
        ver.Text = Core.ModTag() + "\n"
                 + L.T("安装器 ", "installer ") + Core.ReleaseNum + "\n"
                 + L.T("游戏 ", "game ") + Core.GameVersion;
        ver.Font = F(8.5f, FontStyle.Regular);
        ver.ForeColor = InkSub;
        ver.TextAlign = ContentAlignment.MiddleRight;
        ver.AutoSize = false;
        ver.SetBounds(370, 14, 186, 52);   // 三行；顶栏高 78，到 66 为止还有余量
        header.Controls.Add(ver);

        // ── 游戏目录 ───────────────────────────────────────────────────
        var dirLab = new Label();
        dirLab.Text = L.T("游戏目录", "Game folder");
        dirLab.ForeColor = Muted;
        dirLab.AutoSize = false;
        dirLab.SetBounds(26, 94, 300, 18);
        Controls.Add(dirLab);

        dirBox = new ComboBox();
        dirBox.DropDownStyle = ComboBoxStyle.DropDownList;
        dirBox.FlatStyle = FlatStyle.Flat;
        dirBox.SetBounds(26, 114, 428, 24);
        dirBox.SelectedIndexChanged += delegate { Refresh2(); };
        Controls.Add(dirBox);

        var browse = FlatBtn(L.T("浏览…", "Browse"), Ghost, GhostHot, Ink, 9f, FontStyle.Regular);
        browse.SetBounds(462, 113, 92, 26);
        browse.Click += delegate { Browse(); };
        Controls.Add(browse);

        // ── 状态卡片 ───────────────────────────────────────────────────
        var card = new Panel();
        card.SetBounds(26, 152, 528, 92);
        card.BackColor = CardBg;
        card.BorderStyle = BorderStyle.FixedSingle;
        Controls.Add(card);

        accentBar = new Panel();
        accentBar.Dock = DockStyle.Left;
        accentBar.Width = 4;
        accentBar.BackColor = CardLine;
        card.Controls.Add(accentBar);

        stateLabel = new Label();
        stateLabel.Font = F(12f, FontStyle.Bold);
        stateLabel.AutoSize = false;
        stateLabel.SetBounds(20, 13, 490, 26);
        card.Controls.Add(stateLabel);

        noteLabel = new Label();
        noteLabel.ForeColor = Muted;
        noteLabel.Font = F(8.5f, FontStyle.Regular);
        noteLabel.AutoSize = false;
        noteLabel.SetBounds(22, 42, 492, 44);
        card.Controls.Add(noteLabel);

        // ── 动作按钮 ───────────────────────────────────────────────────
        toggleBtn = FlatBtn("", Amber, AmberHot, Color.White, 11f, FontStyle.Bold);
        toggleBtn.SetBounds(26, 260, 268, 48);
        toggleBtn.Click += delegate { Toggle(); };
        Controls.Add(toggleBtn);

        // 比主按钮更深一档：主按钮（琥珀/石板）→ 启动游戏（近黑）→ Steam 修复（浅灰），
        // 三级色阶把「这次该点哪个」一眼分开。同色会让主次失效（第一版就是这样）。
        launchBtn = FlatBtn(L.T("启动游戏", "Play"), Ink, Color.FromArgb(44, 47, 58), Color.White, 10f, FontStyle.Regular);
        launchBtn.SetBounds(306, 260, 122, 48);
        launchBtn.Click += delegate { Core.LaunchGame(); };
        Controls.Add(launchBtn);

        validateBtn = FlatBtn(L.T("Steam 修复", "Steam repair"), Ghost, GhostHot, Ink, 9f, FontStyle.Regular);
        validateBtn.SetBounds(440, 260, 114, 48);
        validateBtn.Click += delegate { Core.OpenSteamValidate(); };
        Controls.Add(validateBtn);

        // 两个日志入口，一个是安装器自己的、一个是游戏的 —— 标签必须分得开。
        // 原来只有一个叫「打开日志」，加了第二个之后那个名字就有歧义了，一并改掉。
        logBtn = FlatBtn(L.T("安装日志", "Install log"), Color.White, Ghost, Muted, 8.5f, FontStyle.Regular);
        logBtn.SetBounds(24, 318, 100, 24);
        logBtn.Click += delegate {
            try { Core.FlushLog(); Process.Start("notepad.exe", Core.LogPath); } catch { }
        };
        Controls.Add(logBtn);

        // 报 bug 时要交的是这一份。见 Core.OpenGameLogFolder() 上那段说明：
        // 只开文件夹，不复制不上传。
        gameLogBtn = FlatBtn(L.T("游戏日志", "Game log"), Color.White, Ghost, Muted, 8.5f, FontStyle.Regular);
        gameLogBtn.SetBounds(132, 318, 116, 24);
        gameLogBtn.Click += delegate {
            if (Core.OpenGameLogFolder()) return;
            MessageBox.Show(this,
                L.T("还没有游戏日志 —— 游戏至少要启动过一次。\n\n目录：\n",
                    "No game logs yet — launch the game at least once.\n\nFolder:\n")
                + Core.GameLogDir,
                "Machine Party-Overtime",
                MessageBoxButtons.OK, MessageBoxIcon.Information);
        };
        Controls.Add(gameLogBtn);

        // ── 免费声明（红色，常驻）──────────────────────────────────────
        // 社区里有人把同类 mod 闭源收费卖，这条得让人一眼看见。
        var freeBand = new Panel();
        freeBand.SetBounds(0, 354, 580, 76);
        freeBand.BackColor = FreeBg;
        Controls.Add(freeBand);

        var freeLine = new Panel();
        freeLine.Dock = DockStyle.Top;
        freeLine.Height = 1;
        freeLine.BackColor = FreeLine;
        freeBand.Controls.Add(freeLine);

        var free = new Label();
        free.Text = Core.FreeNotice();
        free.Font = F(10.5f, FontStyle.Bold);
        free.ForeColor = Bad;
        free.TextAlign = ContentAlignment.MiddleCenter;
        free.AutoSize = false;
        free.SetBounds(16, 10, 548, 56);
        freeBand.Controls.Add(free);

        // 只探测、不操作就关窗的情况下，缓冲里的日志得有人写出去
        FormClosed += delegate { Core.FlushLog(); };

        foreach (string d in Core.FindGameDirs()) dirBox.Items.Add(d);
        // 给 SelectedIndex 赋值会触发 SelectedIndexChanged → Refresh2()，
        // 所以只有「一个目录都没找到」时才需要自己补一次。1.3 是两边都调，
        // 于是每开一次启动器就往日志里记两行一模一样的 detect。
        if (dirBox.Items.Count > 0) dirBox.SelectedIndex = 0;
        else Refresh2();

        // 开局别让焦点落在下拉框上：DropDownList 一旦获得焦点，选中项会整行刷成
        // 系统高亮蓝，界面第一眼就被那条蓝杠抢走。焦点给主按钮，顺便回车即可执行。
        ActiveControl = toggleBtn;
    }

    string Dir { get { return dirBox.SelectedItem == null ? null : dirBox.SelectedItem.ToString(); } }

    void Browse()
    {
        var fd = new FolderBrowserDialog();
        fd.Description = L.T("选中 Machine Party_Windows 这个目录（里面有 Machine Party.pck）",
                             "Pick the Machine Party_Windows folder (it contains Machine Party.pck)");
        if (fd.ShowDialog() != DialogResult.OK) return;
        if (!File.Exists(Path.Combine(fd.SelectedPath, Core.PckName)))
        {
            MessageBox.Show(L.T("这个目录里没有 " + Core.PckName + "。", "No " + Core.PckName + " in that folder."),
                            Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        int i = dirBox.Items.Add(fd.SelectedPath);
        dirBox.SelectedIndex = i;
    }

    void SetState(string text, Color color, string note)
    {
        stateLabel.Text = text;
        stateLabel.ForeColor = color;
        accentBar.BackColor = color;
        noteLabel.Text = note;
    }

    void Refresh2()
    {
        if (busy) return;
        if (Dir == null)
        {
            SetState(L.T("没找到游戏", "Game not found"), Bad,
                     L.T("用「浏览…」手动指定游戏目录（Steam 里右键游戏 → 管理 → 浏览本地文件）。",
                         "Use Browse to pick the game folder (Steam: right click the game -> Manage -> Browse local files)."));
            toggleBtn.Enabled = false;
            toggleBtn.Text = L.T("启用 Overtime", "Enable Overtime");
            toggleBtn.BackColor = Ghost;
            toggleBtn.ForeColor = Muted;
            return;
        }

        st = Core.Detect(Dir);
        // 控制台版不发给玩家了，所以日志是唯一的诊断通道 ——
        // 每次探测都记一行，「打开日志」在还没装任何东西时也有内容可看。
        Core.Log(string.Format("detect: {0} | tag={1} | len={2} | restore={3} | legacy={4} | {5}",
            st.Kind, (st.InstalledTag.Length > 0 ? st.InstalledTag : "-"),
            st.Length, st.HasRestore, st.HasLegacy, Dir));
        toggleBtn.Enabled = true;
        toggleBtn.ForeColor = Color.White;

        switch (st.Kind)
        {
            case Core.Kind.OursInstalled:
                SetState(L.T("Overtime 已启用", "Overtime enabled"), Good,
                         L.T("主菜单右下角的版本号会带 +" + Core.ModTag() + "。\n" +
                             "一起玩的人必须装同一版，否则会被房主拒绝进房。",
                             "The main menu version ends with +" + Core.ModTag() + ".\n" +
                             "Everyone in the lobby needs this same version, or the host will refuse them."));
                toggleBtn.Text = L.T("切回原版", "Switch to vanilla");
                toggleBtn.BackColor = Slate;
                toggleBtn.FlatAppearance.MouseOverBackColor = SlateHot;
                break;

            case Core.Kind.OldVersion:
                SetState(L.T("已装 Overtime " + st.InstalledTag + "（旧版）", "Overtime " + st.InstalledTag + " installed (outdated)"), Caution,
                         L.T("本程序是 " + Core.ModTag() + "。点下面的按钮升级（会先还原再装新版）。"
                             + "一起玩的人都要升到同一版，否则互相进不了房。",
                             "This program is " + Core.ModTag() + ". The button below upgrades it "
                             + "(revert, then install). Everyone you play with needs the same version."));
                toggleBtn.Text = L.T("升级到 " + Core.ModTag(), "Upgrade to " + Core.ModTag());
                toggleBtn.BackColor = Amber;
                toggleBtn.FlatAppearance.MouseOverBackColor = AmberHot;
                break;

            case Core.Kind.Vanilla:
                SetState(L.T("当前是原版", "Currently vanilla"), Slate,
                         L.T("点下面的按钮启用 Overtime。随时可以再切回来。",
                             "Press the button below to enable Overtime. You can switch back at any time."));
                toggleBtn.Text = L.T("启用 Overtime", "Enable Overtime");
                toggleBtn.BackColor = Amber;
                toggleBtn.FlatAppearance.MouseOverBackColor = AmberHot;
                break;

            case Core.Kind.Missing:
                SetState(L.T("找不到数据包", "PCK not found"), Bad, st.Note);
                toggleBtn.Enabled = false;
                toggleBtn.BackColor = Ghost;
                toggleBtn.ForeColor = Muted;
                break;

            default:
                SetState(L.T("认不出当前的游戏数据", "Unrecognised game data"), Caution,
                         st.Note.Length > 0 ? st.Note
                                            : L.T("既不是原版，也不是本 mod。", "Neither vanilla nor this mod."));
                if (st.CanUninstall)
                {
                    toggleBtn.Text = L.T("切回原版", "Switch to vanilla");
                    toggleBtn.BackColor = Slate;
                    toggleBtn.FlatAppearance.MouseOverBackColor = SlateHot;
                }
                else
                {
                    toggleBtn.Text = L.T("启用 Overtime", "Enable Overtime");
                    toggleBtn.BackColor = Amber;
                    toggleBtn.FlatAppearance.MouseOverBackColor = AmberHot;
                }
                break;
        }
    }

    void Toggle()
    {
        if (Dir == null) return;
        // 别叫 busy：MainForm 已经有个 bool busy 字段（「处理中」标志），
        // 局部同名会把它遮住，后面那句 busy = true 就直接编译不过。
        string blocked = Core.BusyReason(Dir);
        if (blocked != null)
        {
            // 拦下的理由（PID / 路径）刚写进缓冲，立刻落盘 —— 玩家点「安装日志」
            // 时得看得见，否则又是一份只有 detect、看不出所以然的日志。
            Core.FlushLog();
            MessageBox.Show(blocked, Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }

        // OldVersion 走安装（Install 会先用还原数据回到原版再打新补丁），不是卸载
        bool remove = (st.Kind == Core.Kind.OursInstalled) || (st.Kind == Core.Kind.Unknown && st.CanUninstall);
        string dir = Dir;

        busy = true;
        toggleBtn.Enabled = false; launchBtn.Enabled = false; dirBox.Enabled = false;
        SetState(L.T("处理中…", "Working..."), Caution, "");

        // 校验哈希要十几秒，不能卡死界面
        var th = new Thread(delegate ()
        {
            string err = null;
            try
            {
                Action<string> say = delegate (string s)
                {
                    Core.Log(s);
                    try { BeginInvoke((Action)delegate { noteLabel.Text = s; }); } catch { }
                };
                if (remove) Core.Uninstall(dir, say);
                else        Core.Install(dir, false, say);
            }
            catch (Exception ex) { Core.Log("ERROR " + ex); err = ex.Message; }

            Core.FlushLog();
            try
            {
                BeginInvoke((Action)delegate
                {
                    busy = false;
                    launchBtn.Enabled = true;
                    dirBox.Enabled = true;
                    Refresh2();
                    if (err != null)
                        MessageBox.Show(err, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
                });
            }
            catch { }
        });
        th.IsBackground = true;
        th.Start();
    }
}
#endif
