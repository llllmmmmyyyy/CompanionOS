# CompanionOS

Small activities. Meaningful family moments.

**Help parents understand their child better through natural interaction behavior.**

CompanionOS separates the child and parent experiences across HarmonyOS devices. The Tablet is the child's interactive learning world, while the Phone acts as the parent's control and insight dashboard.

CompanionOS uses an engaging 2D child world to generate meaningful, natural interaction data. These observable patterns help parents understand which activity formats, challenges and learning experiences engage their child most effectively.

## Current product

- **Tablet:** original Pico companion, visual world hub, draggable Dino Bridge and Rocket, flashing Robot Memory, Animal Rescue, Star Collector, Copy Pico and Number Move, Creative Garden, Calm Sky and native storybook video. Children give optional feedback on the Tablet and can finish a normal adventure without using the Phone.
- **Phone:** live Tablet status, in-app Child Mode entry/exit, start/pause/resume/next/end controls, 15/30/45/60-minute configuration, balance presets, 2-5 memory signals, locally saved Tablet history, interaction styles, descriptive Parent Insights and evidence.
- **Finite Daily Adventure:** Help Dino Get Home follows the balanced category plan. Completing every mission adds a persistent garden decoration once per day. Skipped/incomplete adventures do not grant that day's reward. Missed days never remove progress. The session window is a maximum foreground budget; short missions may finish earlier. Planned minutes are not measured engagement or exercise.
- **Local first:** detailed object/sequence/mission events stay on Tablet. Phone receives compact states and outcomes, not a live feed of raw taps. Both journals use bounded, double-bank chunked HarmonyOS Preferences. Disconnecting the parent does not stop a safe current mission.
- **Retained fallback:** original Penguin Walk, Animal Sounds, Butterfly Stretch, Phone-only Work Session, parent confirmation, local history, BehaviorInsightEngine, Adventure Journey, notifications and widget code remain. Tablet child-completed summaries and parent-confirmed Phone records are clearly separate journals.
- **Video remains:** Built-in Video, Gemini AI, Huawei AI and My Video use the existing adult-reviewed provider/import flow. Home's Video library opens that flow. The world storybook plays a reviewed source already projected by the legacy receiver when available; otherwise it plays an original Built-in clip. Live cloud generation is not credential-verified. No provider key belongs in either HAP.

An adult remains nearby and available. Activities avoid jumping, climbing, sharp tools and outdoor tasks. Movement is child-confirmed, never sensor verified. There is no camera/microphone/location monitoring, clinical assessment, OS kiosk or device lock.

## Environment and actual transport

Native Stage ArkTS / ArkUI V1; existing configuration retained. Installed DevEco Studio 6.0.1.251, SDK 6.0.1.112, compatible/target API 21. `entry` uses product `default` / Phone; `tventry` uses product `tablet` / Tablet; `shared` is the reusable HAR. The old `Tv` file names are retained for compatibility.

Both emulator guests use **http://10.0.2.2:18080**, room **family-demo**. Windows runs the CompanionOS Node backend/relay on loopback port 18080. Guest 127.0.0.1 points to that guest, so it cannot connect two emulators. This is an HTTP polling development relay, not production HarmonyOS distributed-device transport. Raw child event logs are not sent to cloud AI.

```text
Phone parent dashboard ----> Windows Node relay :18080 <---- Tablet child world
       compact journal          compact sync only             raw local journal
```

## Build and run on Windows

The backend requires Node.js 22+ (tested with 24.21). The build script discovers DevEco's bundled Node/Java/Hvigor/SDK without changing project SDK or signing settings.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -RunChecks
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Module tventry
cd backend
npm ci
npm test
npm start
```

Keep the backend terminal open. With both API 21 emulators already running, a separate terminal at the project root can install and launch the built packages:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-emulator-demo.ps1
```

The helper preserves an existing healthy listener. After changing backend source, restart the owned `npm start` process so new routes take effect. Start Child Mode on Phone, then Start Tablet session. For independent exploration, the Tablet also has Open Pico world locally.

In DevEco Studio, open this repository, select `entry` / product `default` / Phone API 21 and Run. For the child app, select `tventry` / product `tablet` / Tablet API 21 and Run. Do not convert the project or select a TV API 19 target. Start the Windows backend separately for two-device control; local Tablet exploration and Phone fallback do not require cloud credentials.

## Artifacts and verification

- Phone: `entry/build/default/outputs/default/entry-default-unsigned.hap`
- Tablet: `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`

Signing configuration is still empty. These are unsigned development HAPs accepted by the two tested API 21 emulators, not signed physical-device/release packages. In DevEco, use **File > Project Structure > Project > Signing Configs** to configure Automatic Signing/login if needed for your device. Keep credentials and generated signing files outside Git.

Both native builds and 110 automated checks passed. The six core games were actually played on Tablet API 21; remote controls, a finite five-mission Daily Adventure, background pause, restart, evidence and relay-loss recovery were observed. See [TESTING](docs/TESTING.md) for exact evidence and limits. Build success is never described as physical-device testing. Widget hosting, real cloud credentials, physical-device signing, large-font/accessibility speech and full real-time 15/30/45/60-minute windows remain outside the verified scope. Current emulator journals contain development test interactions, not research with children.

## Submission materials

[Architecture](docs/ARCHITECTURE.md), [Child Mode](docs/CHILD_MODE.md), [Interactive activities](docs/INTERACTIVE_ACTIVITIES.md), [Insights](docs/ACTIVITY_INSIGHTS.md), [Demo script](docs/DEMO_SCRIPT.md), [Score readiness](docs/SCORE_READINESS.md), [Submission checklist](docs/SUBMISSION_CHECKLIST.md), [Third party](docs/THIRD_PARTY.md), [AI workflow](AI_WORKFLOW.md).

No competition RULES/CRITERIA file was available in this workspace. These materials describe implementation and evidence, not verified eligibility, judging compliance or a guaranteed score. Recording is still a human deliverable; follow the concrete steps in DEMO_SCRIPT.
