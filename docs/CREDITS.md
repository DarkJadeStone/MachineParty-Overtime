# 致谢、参考与来源 / Credits

[返回首页](../README.md) · [English](../README.en.md)

Machine Party 的游戏代码、美术、音频和场景属于原作权利人。Overtime 是非官方社区修改，
需要玩家持有正版副本；不分发原版数据包、资产或完整反编译脚本。

感谢报告问题、提供复现信息与实际对局反馈的玩家。

## 1.7 参考的社区工作

- [NotAsher999 / MachineParty-Overtime](https://github.com/NotAsher999/MachineParty-Overtime)：参考本地扩席、分屏相机、角色与换装器配对、本地角色确认等问题定位和修复思路。对照提交：`638d0240989023e41ca3ec7701ea3a43d461c069`。
- [JaredMerritt / MachineParty-Overtime-English（english 分支）](https://github.com/JaredMerritt/MachineParty-Overtime-English/tree/english)：参考多语言、消息校验、投票节流和外置补丁包等方向与取舍。对照提交：`108f1899edd6d96ca528aadfd6f83f3eb9be046f`。

1.7 的代码在本项目主线中重写，没有整段合并这些 fork 的补丁；
通用短表达式和部分节点重绑定写法存在相似之处。
我们已阅读这些实现，因此不宣称严格净室开发、零派生或“完全没有改写”。
稳定席位、回合代次与单次结算、标准 ZIP 清单和可恢复写入等机制按本项目的需求实现。

MPML 备选路线使用 [MachinePartyModLoader](https://github.com/Krunk-theduck/MachinePartyModLoader) 提供的加载能力。
本项目不捆绑加载器；兼容性以其接口和双方修改的脚本为限。

自有贡献的授权见 [MIT LICENSE](../LICENSE)，不改变原游戏及其他项目的权利归属。

## English

Thanks to the original game's creators and the players who reported problems and supplied session feedback.

The local multiplayer direction was informed by NotAsher999's fork. The language, validation, voting and external-payload direction was informed by JaredMerritt's English branch, at the commits listed above. The reference scope includes specific diagnoses and repair ideas, not only broad feature requests.

Implementation was rewritten on this project's mainline rather than wholesale merging fork patches. Short general expressions and some node-rebinding idioms are similar. Because those implementations were read, this is not claimed as strict clean-room work or zero derivation.

Original game content belongs to its rights holders. Overtime is an unofficial community mod; its original contributions use the repository's MIT license. The optional MPML loader is distributed by its own project and is not bundled here.
