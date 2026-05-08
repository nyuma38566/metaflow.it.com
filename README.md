# MetaFlow Trade Kit

一个轻量的静态资源仓库，包含：

- `MetaTrade` 客户端安装包下载入口
- 两份示例交易策略脚本
- 经纪商筛选和落地使用说明

## 文件结构

- `index.html`：单页展示页
- `styles.css`：页面样式
- `downloads/metatrade.exe`：可下载客户端资源
- `strategies/EMA_Cross_ATR_Filter.mq5`：EMA 趋势跟随示例
- `strategies/RSI_Session_Reversion.mq4`：RSI 回归示例

## 下载资源

- 文件：`downloads/metatrade.exe`
- SHA-256：`ebff20de90a5483980415df177832b151e89f40a87e3b186adac6b2edaf7a379`

## 使用说明

1. 打开 `index.html` 可直接查看页面和下载入口。
2. 将 `strategies/` 下的脚本导入 MetaTrader 编辑器后再进行参数调整。
3. 上线真实账户前，先在模拟账户和历史回测环境验证。

## 备注

仓库内的策略脚本仅作示例用途，不构成投资建议。不同经纪商的点差、最小止损距离、杠杆和成交模型会直接影响策略结果。
