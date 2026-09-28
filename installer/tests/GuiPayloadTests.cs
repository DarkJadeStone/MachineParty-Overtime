using System;
using System.Collections.Generic;
using System.Drawing;
using System.Diagnostics;
using System.IO;
using System.Threading;
using System.Windows.Forms;

static class GuiPayloadTests
{
    static void Check(bool ok, string message) { if (!ok) throw new Exception(message); }
    static void PumpUntil(Func<bool> done, string label = "completion")
    {
        var timer = Stopwatch.StartNew();
        while (!done()) {
            Application.DoEvents();
            if (timer.ElapsedMilliseconds > 5000) throw new Exception("GUI test timed out: " + label);
            Thread.Sleep(1);
        }
    }
    static void ShowOffscreen(Form form)
    {
        form.ShowInTaskbar = false;
        form.StartPosition = FormStartPosition.Manual;
        form.Location = new Point(-32000, -32000);
        form.Show();
    }
    static void BackgroundDetection()
    {
        int calls = 0, uiThread = Thread.CurrentThread.ManagedThreadId;
        bool workerThread = true;
        using (var first = new ManualResetEvent(false))
        using (var latest = new ManualResetEvent(false))
        using (var form = new MainForm(new[] { "FIRST", "MIDDLE", "LATEST" }, "FIRST", delegate(string dir) {
            workerThread &= Thread.CurrentThread.ManagedThreadId != uiThread;
            Interlocked.Increment(ref calls);
            if (!(dir == "FIRST" ? first : latest).WaitOne(5000)) throw new Exception("detect test timeout");
            return new Core.State { GameDir = dir, Kind = Core.Kind.Vanilla, PayloadTag = dir, PayloadCount = 1 };
        })) {
            ShowOffscreen(form);
            PumpUntil(delegate { return calls == 1; }, "first worker");
            var launch = Find(form, "launch-game");
            var toggle = Find(form, "toggle-install");
            Check(!launch.Enabled && !toggle.Enabled, "actions enabled while file detection is pending");
            bool heartbeat = false;
            form.BeginInvoke((Action)delegate { heartbeat = true; });
            PumpUntil(delegate { return heartbeat; }, "heartbeat");
            var dirs = (ComboBox)Find(form, "game-directory");
            dirs.SelectedItem = "MIDDLE";
            dirs.SelectedItem = "LATEST";
            Check(calls == 1, "directory changes started concurrent PCK hashes");
            first.Set();
            PumpUntil(delegate { return calls == 2; }, "latest worker");
            Check(!launch.Enabled && !toggle.Enabled, "stale result enabled operations for the new directory");
            latest.Set();
            PumpUntil(delegate { return launch.Enabled; }, "latest result");
            Check(workerThread && calls == 2, "detection was not off-thread / requests were not coalesced");
            Check(toggle.Enabled && Find(form, "payload-info").Text.Contains("LATEST"), "latest directory result was not displayed");
            form.Close();
        }
        using (var release = new ManualResetEvent(false))
        using (var started = new ManualResetEvent(false))
        using (var finished = new ManualResetEvent(false))
        using (var form = new MainForm(new[] { "SLOW" }, "SLOW", delegate(string dir) {
            started.Set();
            release.WaitOne(5000);
            finished.Set();
            return new Core.State { GameDir = dir };
        })) {
            ShowOffscreen(form);
            PumpUntil(delegate { return started.WaitOne(0); }, "close test worker start");
            form.Close();
            Check(!form.Visible, "read-only detection prevented closing the window");
            release.Set();
            PumpUntil(delegate { return finished.WaitOne(0); }, "closed worker completion");
            Application.DoEvents();
        }
        Console.WriteLine("PASS GUI background detection: responsive UI, disabled actions, coalescing, stale results, close during read");
    }
    static Control Find(Control parent, string name)
    {
        if (parent.Name == name) return parent;
        foreach (Control child in parent.Controls) { Control found = Find(child, name); if (found != null) return found; }
        return null;
    }
    [STAThread]
    public static int Main()
    {
        try { return Run(); }
        catch (Exception ex) { Console.WriteLine("FAIL GUI: " + ex.Message); return 1; }
    }
    static int Run()
    {
        Application.EnableVisualStyles();
        foreach (bool zh in new[] { false, true })
        {
            L.Zh = zh;
            var constructor = typeof(MainForm).GetConstructor(new Type[] { typeof(IEnumerable<string>), typeof(string) });
            if (constructor == null) throw new Exception("GUI cannot accept a selected game-directory list");
            using (var form = (MainForm)constructor.Invoke(new object[] { new List<string>(), null }))
            {
                Control language = Find(form, "language-switch"), payload = Find(form, "payload-info");
                if (language == null || payload == null || !payload.Text.Contains("overtime_payload.zip")) throw new Exception("Missing-package GUI guidance or language control absent");
                if (language.Text != (zh ? "English" : "简体中文")) throw new Exception("Language switch label is wrong");
                ShowOffscreen(form);
                PumpUntil(delegate { return Find(form, "launch-game").Enabled; });
                Check(payload.Text.Contains("overtime_payload.zip") && !Find(form, "toggle-install").Enabled, "missing payload guidance was not applied after detection");
                using (var bitmap = new Bitmap(form.Width, form.Height))
                { form.DrawToBitmap(bitmap, new Rectangle(0, 0, bitmap.Width, bitmap.Height)); bitmap.Save(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, zh ? "gui-zh.png" : "gui-en.png")); }
                ((Button)language).PerformClick();
                if (!form.LanguageChanged || L.Zh == zh) throw new Exception("Language switch did not request the translated form");
            }
        }
        Console.WriteLine("PASS GUI missing-package guidance and language choices (EN/ZH)");
        BackgroundDetection();
        return 0;
    }
}
