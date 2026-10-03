# CompanionOS — HackYeah offline demo

这是 DevEco Studio 原生 Stage 模式 ArkTS / ArkUI 工程。保持现有 HarmonyOS 6.0.1（API 21）配置，不依赖网络或 AI 接口。

## 已实现

- 英文首页标题：CompanionOS。
- 简介：Small activities. Meaningful family moments.
- 三个活动：Penguin Walk（5 分钟）、Animal Sounds（3 分钟）、Butterfly Stretch（3 分钟）。
- 活动详情：建议时长、亲子活动步骤。
- 点击 `Explore activity` 查看简单步骤；时长为建议值，没有强制倒计时。
- 家长点击 `Mark as completed` 确认完成。保存过程中禁止重复提交。
- 保存成功后返回首页、显示完成提示并更新 `Completed today`。
- 今日次数按设备本地日期统计，独立保存，不受最近 30 条历史记录上限影响；跨日归零。
- 使用设备本地 Preferences 保存最近 30 条记录，重启后保留；卸载或清除应用数据会删除记录。
- 查看步骤后直接返回不增加完成次数。
- 家长确认是 Demo 的手动确认流程，不涉及账号或身份验证。

## 在 DevEco Studio 中运行

1. 打开当前 `CompanionOS` 文件夹，等待工程同步完成。
2. 工程使用 HarmonyOS 6.0.1 / API 21；确认 SDK Manager 中对应 SDK 已安装。
3. 打开 `Tools > Device Manager`，启动支持 API 21 或更高版本的 HarmonyOS 手机模拟器；也可连接开启开发者模式和 USB 调试的兼容真机。
4. 如果提示需要签名，打开 `File > Project Structure > Signing Configs`，选择 `Support HarmonyOS` 和 `Automatically generate signature`，按提示登录华为账号，然后应用设置。
   官方说明：https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-signing-auto
5. 顶部运行配置选择 `entry`，设备列表选择已启动的模拟器或真机，点击绿色 Run 按钮。

## 验证状态

本机使用 DevEco Studio 自带 Node、Java、Hvigor 和 API 21 SDK 执行了：

```text
hvigorw --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap --no-daemon
```

结果：`BUILD SUCCESSFUL`，ArkTS 编译及 HAP 打包通过。当前工程 `signingConfigs` 为空，构建跳过签名，输出为未签名 HAP。未改动 SDK、构建配置或签名配置。

`hdc list targets` 返回 `[Empty]`。没有连接中的设备或模拟器，因此尚未执行设备上的点击测试或重启持久化测试。编译通过不代表设备交互已经验证。

## 运行后检查

1. 打开 `Completion history`，首次运行应显示空记录提示。
2. 返回首页，依次查看三个活动的步骤和时长。
3. 首次运行首页应显示 `Completed today: 0`。点击任一活动查看步骤。
4. 家长点击 `Mark as completed` 后应返回首页，今日次数变为 1。
5. 再完成一个活动，次数应变为 2；历史记录中最新一条在顶部。
6. 关闭并重新打开应用，今日次数和记录应保留。测试时避免卸载应用或清除应用数据。
7. 查看步骤后点击 `Back`，不应增加次数；重复完成同一活动算新的一次。
8. 设备本地日期进入下一天时，今日次数应归零，历史记录仍保留。

主要代码：`entry/src/main/ets/pages/Index.ets`。活动数据、页面状态和记录保存都在此文件中，便于下一阶段继续开发。
