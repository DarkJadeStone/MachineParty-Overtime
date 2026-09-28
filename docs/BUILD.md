# 自己编译 Overtime 1.7

公开仓库只提供相对正版 v2.1.2 脚本的差异补丁。先从自己的正版副本恢复原始脚本，
再应用补丁；公开树生成时会验证每个补丁都能重建出与开发工作区逐字节相同的文件。
补丁数量以 VERSION.txt 与构建输出为准。

## 前置

- Windows、PowerShell 5.1、Git。
- 正版 Machine Party v2.1.2，原始 PCK 的 SHA-256：
  `326CC3988D3AC554D1F288BED89B1F89D450F78EC9D4470F88558975753DFA8E`。
- GDRE Tools v2.6.4，完整解压到 `tools/gdre/`，保留 `gdre_tools.exe`、`gdre_tools.pck`
  及随包 DLL，不能只复制 exe。不同反编译器版本可能产生不同源码。
- .NET Framework 4 编译器，构建脚本使用
  `C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe`，
  并引用系统的 IO.Compression、WinForms 等程序集。
- Godot 编辑器版用于解析探针及 MPML 打包。本机验证版本为 4.7.2；
  游戏补丁字节码仍由 GDRE 以 **4.5.2** 格式生成。

## 安装器构建

```powershell
tools\gdre\gdre_tools.exe --headless --recover="<游戏目录>\Machine Party.pck" --output="src"
powershell -File tools\apply_patches.ps1
powershell -File tools\build.ps1 -CompileOnly
powershell -File tools\build_installer.ps1
```

`-CompileOnly` 只生成 `patch_gdc/`，不会安装或改动游戏 PCK。
不要公开 `src/`、`patch/` 或原版资源。

安装器默认输出 `dist/overtime-<mod版本>-launcher-<程序版本>/`：

| 文件 | 用途 |
| --- | --- |
| overtime_launcher.exe | 普通用户权限的窗口程序，支持中英文 |
| overtime_install.exe | 同一核心实现的命令行程序 |
| overtime_payload.zip | 外置补丁清单及编译后脚本，必须与所用 exe 放在一起 |
| BUILDINFO.json | 源文件、字节码、程序及补丁包哈希和构建参数记录 |
| SHA256SUMS.txt | 两个程序和补丁包的 SHA-256 |
| Machine-Party-Overtime-<版本>.zip | 玩家包：窗口程序、补丁包、说明和校验记录 |
| Machine-Party-Overtime-<版本>-CLI.zip | 对应命令行包 |

程序不再嵌入 Mod 版本与字节码。缓存键包含源码、manifest、编译器、显式引用程序集和实际编译参数。
构建从暂存快照编译；检查输入未变化、补丁包已验证后，才原子发布缓存目录。
缓存完整时，仅补丁变化会复用相同的程序文件。清空缓存或换机器后，旧版 csc 重编的 exe
不保证逐字节相同；不能把本地缓存复用称为跨机器可重复构建。
正式发行应保存一份经过核验、签名和时间戳处理的程序产物，后续 Mod 更新复用那份产物。
当前开发候选尚未签名，也没有完成上述正式发行流程。
`-ForceRebuild` 跳过缓存读取，但不替换已有的有效缓存；其新编 exe 的哈希可能不同。
`-Out` 必须为空目录或匹配本版本的候选目录；遇到无关文件、链接目录或候选哈希不符会拒绝覆盖。

补丁 ZIP 的条目顺序和时间固定。清单记录每个资源路径、大小及 SHA-256。
构建拒绝缺失或早于源码的字节码，并通过真实 CLI 的 `--verify-package` 验证候选包。
记录的源文件和字节码哈希用于追溯内容，不代替对编译器或构建环境的信任。
单个 exe 不是完整发行包。

```powershell
powershell -File tools\test_installer_payload.ps1
powershell -File tools\test_installer_build.ps1
powershell -File tools\test_installer_distribution.ps1 -Directory "<上面的输出目录>"
```

测试覆盖坏包拒绝、安装/还原、写入失败回滚、GUI 后台检测和构建期间输入变化。正式发布前还需在目标 Windows
环境实际下载、解压、安装与还原，并运行完整多人回归。
构建 MPML 后可为发行检查追加 `-MpmlDirectory "<overtime文件夹>"`，逐项核对两条路线的字节码一致。

## 运行时解析检查

```powershell
powershell -File tools\parsecheck.ps1 -Godot "D:\Godot\godot.exe" -Pck "<测试用已打补丁的 PCK>"
```

该探针不启动完整游戏，不能替代真实多人测试。未实例化的 autoload、Steam 扩展和重复类身份
会产生噪音；输出会列出无法判定的脚本。给它旧 PCK 时，新方法依赖也可能无法解析。
构建成功仅说明字节码生成成功，不代表关卡运行正确。

## MPML 备选包

这是另一条安装路线：先还原原版 PCK，再使用独立安装的兼容 MPML。
不要叠加 PCK 安装器与 MPML 覆盖包。项目不分发加载器本身。

保留一份原版数据包为 `game_test/Machine Party.pck.orig` 后运行：

```powershell
powershell -File tools\build_mpml_mod.ps1 -Godot "D:\Godot\godot.exe"
```

包内包含 `mod.json`、独立适配层 `main.gd`、原始脚本 MD5 清单和覆盖 ZIP。
加载前先验证覆盖 ZIP 的大小与 SHA-256，再验证原游戏文件，最后挂载。
这是内容一致性检查，不是签名认证。
MPML 构建失败应保留上一份完整输出；构建路径与日志以脚本输出为准。
`-Out` 指定模组目录，例如 `dist/mpml/overtime`；外层发行 ZIP、构建锁与临时目录位于其父目录。
建议每个候选使用独立父目录。重建前会核对已有外层 ZIP 与所选模组目录逐文件一致，
拒绝覆盖同名无关 ZIP 或含无关文件的目录。

## 发布检查

当前 1.7 程序**未签名，未取得 Defender 检测通过结论**。构建不会禁用防护、添加排除项或申请管理员权限。
代码签名及时间戳应使用项目合法持有的证书，由发布环境执行；签名之后必须重新计算校验记录并打包，
再对最终下载文件测试。不能把签名前的哈希用于签名后的 exe。

保留固定项目名与发布者信息。发生具名病毒误报时，将最终文件和检测名称提交微软复核；
SmartScreen 的下载/应用信誉提示另行记录，不能把两者混成同一个问题。
不要通过改名、加壳、加密载荷或要求玩家关闭防护处理误报。

## 可选的展示素材重建

展示图片的可编辑 SVG 和导出 PNG 位于 `images/`。可选素材工具为 `tools/build_branding.ps1`
（Windows 的 Impact / Microsoft YaHei / Consolas 字体）与 `tools/render_branding.cjs`（Node.js + sharp）。
普通源码编译使用已经提供的图片，不需要安装这些额外素材依赖。

## 常见错误

- 字节码过期：先跑 `build.ps1 -CompileOnly`；不要手动修改时间戳绕过检查。
- 补丁打不上：核对游戏、GDRE 版本和 LF 行尾；`apply_patches.ps1` 已关闭 Git 自动行尾转换。
- 脚本基名冲突：GDRE 输出不保留目录，同名会覆盖；构建会拒绝，先解决冲突。
- 缺少补丁包：完整解压 ZIP，不能只下载或复制 exe。
- 生成公开树时输出目录已存在：用新的 `-Out` 路径。工具不会删除现有 Git 仓库或覆盖其工作。
