# 1.7 验证范围与已知限制

[返回首页](../README.md) · [English](#english)

对应标签 `overtime-1.7`，游戏基线 v2.1.2，安装器版本 1.7.0。
以下是发布准备期间的检查范围，不将隔离测试等同于完整真人对局。

## 已检查

- 70 份脚本按游戏的 4.5.2 字节码格式编译，安装器与 MPML 的逐资源 SHA-256 一致。
- 原版场景数据检查：大厅模型/换装控件配对，以及灯光、相机、墙壁贴花等 11 项渲染层契约。
- 分屏隔离矩阵 2,163 项；Compatibility / Forward+ 各 36 项实际小场景渲染与缩放鼠标检查。
- 投票生命周期 46 项、版本/语言/开发门禁 30 项、外观与选择控件 36 项、MPML 完整性 16 项。
- 本地席位、退座/重入、手柄确认、计分和指定 RPC 的回归。
- 安装器核心 42 项，以及中英文 GUI、慢检测、切换目录、关闭窗口和升级失败状态提示。
- 构建缓存的参数变化、构建中源码变化与无关输出保护；MPML 构建失败保留旧输出。
- 原版 PCK 临时副本的安装/还原，以及缺补丁包时的卸载；还原 SHA-256 与支持的原版一致。
- 公开差异补丁往返重建，以及从公开源树重新编译后的 payload 内容一致性。

隔离网络测试替代了传输边界，GPU 检查使用构造的小场景，SceneState 检查不实例化完整游戏。
它们分别证明相应逻辑、渲染契约或数据关系，不能覆盖所有实际游戏组合。

## 尚待实机确认

1. 5–8 个真实输入设备的完整对局；任意键鼠席位、控制器拔插、角色轮换和重入。
2. 1080p/1440p 分屏文字与操作可读性，以及完整游戏帧时间。
3. Steam 多人的实际时序，包括加载中掉线、正常结算与投票倒计时同时结束。
4. PCK/MPML 混合安装路线的真实联机，和其他修改相同脚本的 Mod 的兼容性。
5. 渐变纹理首次生成耗时、缓存占用、远处纹理接缝和卸载后的外观回退。
6. 在更新且启用 Defender 的环境中对最终下载文件进行检测、安装与卸载验收。

此前报告的 **“1.6、五人、残骸平台结束黑屏”** 没有玩家现场日志。
代码中明确的投票生命周期缺陷已经修复，但原始黑屏根因尚未确认。
请勿将“改进重开流程”理解成已证明消除了那次黑屏的根因。

## 解析与构建工具的边界

解析探针可以挂载原版 PCK 与候选 overlay；可判定范围未发现作用域错误。
原始 reload 仍可能因 Steam 依赖、匿名脚本/全局类身份等条件失败。
编译成功、隔离用例通过或作用域检查通过，都不等于“所有场景零错误”。

程序未签名，尚无有效 Defender 通过结论。参见 [告警说明](SAFETY.md)。
复用已保存的相同 exe 可以保持文件身份；清空缓存或换机器重新编译不保证相同二进制。

## English

The 1.7 preparation checks cover 70 compiled scripts, installer/MPML payload parity, retail scene data, 2,163 isolated viewport checks, 36 rendered checks per GPU backend, voting/language/appearance/MPML regressions, and installer recovery on a copy of the original PCK. Public diff roundtrips and rebuilding from the public source tree are also checked.

Network fixtures replace transport boundaries. GPU tests use constructed scenes. SceneState inspection does not instantiate the full game. These checks do not prove a complete multiplayer session works in every configuration.

Full sessions with 5–8 physical inputs, Steam network timing, mixed installation routes and conflicting mods remain for in-game acceptance. Suit generation cost, cache use and visual behavior across all game scenes also need evaluation.

The reported five-player 1.6 end-of-round black screen has no confirmed root cause. The corrected restart lifecycle should not be presented as proof that the original report is resolved.

The binaries are unsigned; no valid Defender-pass result is available. Compiler success and file hashes are not security certifications.
