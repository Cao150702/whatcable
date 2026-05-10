# 已知线缆

通过应用内"报告此线缆"流程报告给 WhatCable 的 USB-C 线缆工作列表。这是未来信任信号和库存工作的记忆辅助工具，从 GitHub 上已关闭的 [`cable-report`](https://github.com/darrylmorley/whatcable/issues?q=label%3Acable-report) issue 中播种。

完整报告（包含报告者注释、日期和分类回复）位于 issue 跟踪器上。此文件保留了 e-marker 指纹的精简、去重视图。下方的供应商名称来自捆绑的 USB-IF 列表（随 WhatCable v0.8.1 及更高版本提供），而不是来自报告构建时显示的任何名称。

## 此文件存在的原因

WhatCable 的 [issue 模板](../.github/ISSUE_TEMPLATE/cable-report.yml) 说明了目标：已知良好和假冒 USB-C 线缆指纹的公共数据库。线缆信任信号工作（参见 `planning/cable-trust-signals.md`）最终将使用此文件的精选子集。目前它是一个扁平的手动维护的 markdown 表格；一旦消费者存在，格式可能会更改。

## 表格

| 品牌 / 型号上下文 | VID | PID | 供应商 (USB-IF) | XID | 速度 | 功率 | 类型 | 来源 |
|---|---|---|---|---|---|---|---|---|
| UGOURD TB5/USB4 线缆，AliExpress（无 USB-IF 认证） | `0x0138` | `0x0310` | 未注册 | 无 | USB4 Gen 4 (80 Gbps) | 5 A / 50 V (250 W) | 被动 | [#71](https://github.com/darrylmorley/whatcable/issues/71) |
| UGREEN Revodok Max 213 (U710) 扩展坞捆绑，外壳标记为 TB4 | `0x0522` | `0x0A06` | ACON, Advanced-Connectek, Inc. | `0x939` | USB4 Gen 3 (20 / 40 Gbps) | 5 A / 20 V (100 W) | 被动 | [#84](https://github.com/darrylmorley/whatcable/issues/84) |
| Anker 333 USB-C 3.3 英尺尼龙 | `0x201C` | `0x0000` | Hongkong Freeport Electronics Co., Limited | 无 | USB 2.0 (480 Mbps) | 5 A / 20 V (100 W) | 被动 | [#60](https://github.com/darrylmorley/whatcable/issues/60) |
| Monoprice Essentials USB-C 10 Gbps 0.5 m | `0x2095` | `0x004F` | CE LINK LIMITED | 无 | USB 3.2 Gen 2 (10 Gbps) | 5 A / 20 V (100 W) | 被动 | [#48](https://github.com/darrylmorley/whatcable/issues/48) |
| delock TB3 品牌线缆 | `0x20C2` | `0x0005` | Sumitomo Electric Ind., Ltd., Optical Comm. R&D Lab | 无 | USB 3.2 Gen 2 (10 Gbps) | 5 A / 20 V (100 W) | 被动 | [#44](https://github.com/darrylmorley/whatcable/issues/44) |
| CalDigit TS4 扩展坞捆绑线缆（可能） | `0x2B1D` | `0x1512` | Lintes Technology Co., Ltd. | 无 | USB4 Gen 3 (20 / 40 Gbps) | 5 A / 20 V (100 W) | 被动 | [#62](https://github.com/darrylmorley/whatcable/issues/62) |
| Dbilida TB4 品牌 240 W 线缆，Amazon（无 USB-IF 认证） | `0x2E99` | `0x0000` | Hynetek Semiconductor Co., Ltd | 无 | USB4 Gen 3 (20 / 40 Gbps) | 5 A / 50 V (250 W) | 被动 | [#49](https://github.com/darrylmorley/whatcable/issues/49) |
| acasis TBU405M1 外壳捆绑线缆 | `0x315C` | `0x0000` | Chengdu Convenientpower Semiconductor Co., LTD | 无 | USB4 Gen 3 (20 / 40 Gbps) | 5 A / 20 V (100 W) | 被动 | [#45](https://github.com/darrylmorley/whatcable/issues/45) |
| CUKTECH No.6 140 W（存在 e-marker 但 VID/PID/速度全部为零） | `0x0000` | `0x0000` | （已清零） | 无 | （未公布） | （未公布） | 被动 | [#61](https://github.com/darrylmorley/whatcable/issues/61) |

按 VID 排序。清零的指纹条目停放在底部，因为它是无身份的。

## 值得为信任信号工作标记的模式

九份报告中有三份显示了计划的线缆信任信号启发式应该捕捉的模式：

1. **营销主张超过 e-marker 能力。** #49 (Dbilida) 作为"Thunderbolt 4 / 40 Gbps / 240 W"销售，但 e-marker 报告被动 USB4 Gen 3，无 USB-IF 认证。线缆可能承载宣传的数据速率，但没有认证支持该主张。
2. **真正的未注册 VID，无 XID。** #71 (UGOURD AliExpress) 从未注册的 VID 报告 80 Gbps USB4 Gen 4，零 XID。可能是真正的硅片，但仅从 e-marker 无法验证。
3. **清零的身份字段。** #61 (CUKTECH No.6) 有一个存在的 e-marker，但报告 `0x0000` 作为 VID、PID，无速度。今天已被信任信号标记；报告确认该模式是真实的，而不是解析器错误。

其他六份报告描述了 e-marker 与其营销匹配的线缆。

## 添加新条目

当新的 cable-report issue 到达并且你已经分类 + 关闭它时，工作流是：

```bash
swift scripts/sync-cable-reports.swift     # 从 gh 拉取行
swift scripts/render-known-cables.swift    # 重建 docs/cables.html
```

同步脚本通过 `gh` 读取每个已关闭的 `cable-report` issue，解析 e-marker 指纹表，从捆绑的 TSV 查找规范的 USB-IF 供应商名称，并重写上面的表格块。现有行的"品牌 / 型号上下文"单元格通过 issue 编号保留；全新的行以 `(needs review)` 作为占位符着陆。

运行同步后：

1. 查看仍显示 `(needs review)` 的任何行。打开源 issue，阅读报告者的"故事"注释，并将占位符替换为涵盖品牌和购买上下文的单行短语。去掉 Amazon 会员链接、完整产品标题和任何读作个人上下文的内容。
2. 如果报告显示信任信号模式（营销 / e-marker 不匹配、未注册的 VID + 无认证、清零字段、不可能的 PDO），请在上面的模式部分添加项目符号。
3. 如果你再次编辑 markdown，请重新运行渲染器。
4. 一起提交 `data/known-cables.md` 和 `docs/cables.html`。

如果你需要手动修复行（例如供应商名称 TSV 条目在上游错误），请直接编辑 `data/known-cables.md`。只要它们位于"品牌 / 型号上下文"列中，同步脚本就会保留你的编辑。其他列在下次同步时被重写，因此结构更改需要进入脚本或底层 issue 正文。

此文件不捆绑到应用中。它是人类参考。当信任信号或库存功能在运行时需要此数据时，我们将那时将其形式化。
