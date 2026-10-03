# CompanionOS

CompanionOS helps busy parents keep working while their children stay safely engaged at home.

Turn passive screen time into safe, guided activity time. Parents should not have to choose between focused work and keeping their child meaningfully engaged. CompanionOS provides a fourth option alongside constant entertainment, passive screens and unsupervised outdoor play: short, structured home activities with practical adult oversight. It does not replace appropriate adult supervision.

## The experience

- **A home designed around families:** original illustrations, a prominent Parent Work Session hero, warm category colors, tappable activity cards and Home / Activities / Progress / Parent navigation. Network/provider status is shown only where relevant.
- **Parent Work Session:** choose 15, 30, 45 or 60 planned minutes. A sequence of five-minute MOVE, LEARN, CREATE and CALM activities uses the parent's preferred types. Review before each start, take breaks, pause/resume, skip or end. Parent-confirmed activities feed the existing journal; the summary separates completed, skipped and demo activities. Planned durations are not measured developmental outcomes or a promise of continuous engagement.
- **Child profile:** ages 4-5 / 6-8, interests, preferred activity types, work-window duration, Gentle / Standard difficulty, indoor/no-jumping/low-intensity preferences. Existing 3/5/10-minute quick activities remain available. Settings and history migrate without resetting earlier records.
- **Child view and parent work view:** a large native video/instruction area with progress and minimal controls. Parent controls require a hand-off dialog, which is an accidental-tap barrier, not authentication. The compact work view shows current activity, status and remaining planned activities.
- **Content options:** Recommended chooses safe Built-in content without a network. Gemini AI, Huawei AI and My Videos remain optional sources, with parent review and safe fallback. Work-session source preference prepares each new activity; parents can change it before starting. API keys stay on the backend. Neither live cloud provider has been verified with credentials.
- **Phone first:** the complete session works on Phone alone. "Play on a larger screen" exposes existing Demo TV and independent emulator TV as optional extensions. Failed TV connections never block Phone activity or confirmation.
- **Native HarmonyOS:** ArkTS/ArkUI, Preferences persistence, foreground-end notification permission/error handling, system video picker, existing widget and optional multi-device playback. No Flutter or web runtime.

## Safety and recovery

An adult prepares a clear indoor space, stays available, reviews media and confirms completion. Younger children may need closer support. Built-in templates remain indoor, gentle and jump-free even if a safety preference is disabled. No climbing, sharp tools, risky jumps or unsupervised outdoor suggestions. The app does not monitor children through location, camera, microphone or emotion recognition.

Active work sessions checkpoint locally; after process restart they resume in a safe paused state with Built-in content and the same completion identifier. Generated/imported source selection is reviewed again, rather than silently replayed after restart. Missing/corrupt work data returns to safe defaults; previous activity records are stored separately. Reliable background alarms are not claimed.

## Environment verified during development

| Component | Observed value |
|---|---|
| Platform / module | HarmonyOS Stage model / `entry` / Phone |
| DevEco Studio | 6.0.1.251 |
| Compatible and target SDK | HarmonyOS 6.0.1, API 21 |
| Installed SDK package | 6.0.1.112 |
| Build tools | DevEco bundled Hvigor, Node 18.20.1, Java 21.0.8 |
| Git remote | https://github.com/llllmmmmyyyy/CompanionOS.git |

Phone product `default` remains minimum/target API 21. Separate product `tv` is minimum API 19, target/compiler SDK 21. Its independent HAP was installed and launched on the actual API 19 TV. `shared` is a local protocol HAR, not another project.

## Optional larger-screen demo

Backend requires Node.js 22+ (24.21.0 was available here). In Windows PowerShell inside `backend`, run `npm.cmd ci`, `npm.cmd run build`, then `npm.cmd start`. No key is needed for fallback. To enable providers, copy `.env.example` to ignored `.env`. Set `GEMINI_API_KEY` for Gemini/Veo, or `HUAWEI_MAAS_API_KEY` plus the exact enabled `HUAWEI_MAAS_MODEL` from your MaaS console. Huawei video uses the documented Wan text-to-video adapter; configure the enabled video model and explicit trusted storage hosts in `HUAWEI_VIDEO_DOWNLOAD_HOSTS`. No key goes into either app. Account/model access remains unverified. Generated footage is review-gated: inspect MP4 under backend/data/videos, then `npm.cmd run review -- <videoId>` to approve.

The helper automates builds, Windows backend start on port 18080, installation and launch: run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-emulator-demo.ps1 -Build` from this repository. Both apps connect directly to `http://10.0.2.2:18080` using emulator host-gateway networking; no HDC port forwarding is required. Policy changes apply only to that process. Emulators must already be running; override -Phone / -Tv if target IDs differ.

Exact demo sequence (the helper performs setup steps):

1. Start backend as above.
2. Ensure API 21 Phone emulator is running.
3. Ensure API 19 Huawei TV emulator is running.
4. Install TV HAP: `tventry/build/tv/outputs/default/tventry-default-unsigned.hap`.
5. Launch `com.example.companionos` / `TvAbility`; Waiting for phone appears.
6. Install Phone HAP: `entry/build/default/outputs/default/entry-default-unsigned.hap`.
7. Launch `com.example.companionos` / `EntryAbility`.
8. TV: verify `http://10.0.2.2:18080` / `family-demo`, then press Connect. Connected to Windows relay / Waiting for Phone means the server is reachable.
9. Phone: Play on TV → Connect to Emulator TV.
10. Both apps use `http://10.0.2.2:18080`, room `family-demo`; the Node server listens on Windows loopback port 18080. TV shows CONNECTED once Phone posts its heartbeat. Emulator loopback is not the host; the previous tunnel-only configuration is obsolete.
11. Use Edit age, interests and duration to save the desired age/interests/3–10 minutes.
12. Return to Play on TV, choose category and enter an educational goal.
13. Tap Create Adventure and observe Planning / Generating video progress.
14. Missing keys show Backend fallback plan. Real AI plans are labelled only after a valid provider response.
15. Start when plan/first approved clip or safe fallback is playable; Play on TV keeps Phone as controller.
16. For a short demo check Demo Mode; normal mode uses the chosen minutes.
17. Phone Pause / Resume controls actual TV video playback.
18. Next / Previous switches step and clip; scheduled steps also advance.
19. After time ends, check the parent box and Mark as completed on Phone.
20. TV celebrates; Phone saves one record. Cancel records no completion.

No-key videos are explicitly bundled fallback, not Veo output. Same-phone Demo TV remains separate and needs no backend. Both development emulators accepted unsigned HAPs; physical-device signing remains unverified. In DevEco choose product `default`, module `entry`, Phone then Run; for TV choose product `tv`, module `tventry`, TV then Run.

## Build

Open the project in DevEco Studio and build the `entry` module. The verified underlying command is:

```text
hvigorw --mode module -p product=default -p module=entry@default -p buildMode=debug assembleHap --no-daemon
```

On Windows, `scripts/build.ps1` discovers DevEco through its uninstall registry entry, uses its bundled tools, restores process environment changes, and optionally runs host checks. It does not change persistent PATH or execution policy. From the project directory:

```powershell
& ([scriptblock]::Create((Get-Content -LiteralPath ./scripts/build.ps1 -Raw))) -RunChecks
```

Output: `entry/build/default/outputs/default/entry-default-unsigned.hap`. Local build/test logs are under `artifacts/`, which is excluded from Git. HAPs, signatures, dependencies, local properties and caches are also excluded.

## Run in DevEco Studio

1. Open this `CompanionOS` folder and allow project synchronization to finish.
2. In **Tools > Device Manager**, start a HarmonyOS phone emulator supporting API 21 or later, or connect a compatible phone with developer mode and USB debugging enabled.
3. If required, open **File > Project Structure > Signing Configs**, select **Support HarmonyOS** and **Automatically generate signature**, sign in as prompted, and apply. See [Huawei's signing instructions](https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-signing-auto).
4. Select the `entry` run configuration and target device, then click **Run**.
5. In Parent Settings, enable notifications explicitly. Open an activity, select Demo Mode, start it, wait ten seconds, check the parent confirmation box and mark it completed.

The current project has no signing configuration. The verified output is **unsigned**, not a signed release. The redesigned Phone and preserved TV HAPs were built and installed; current parent-work and visual checks are listed at the top of docs/TESTING.md. The following core-flow checks are historical evidence. In the follow-up test, the API 21 development emulator accepted this unsigned HAP and ran it successfully. Home/details, settings and record persistence, Demo and full three-minute normal completion, cancellation, confirmation/double-click protection, background expiry/resume and an actual notification in the system notification center were verified. The current work flow also passed one full normal five-minute activity. Widget hosting, physical-phone installation, full ten-minute expiry and full-length work windows remain pending. See `docs/TESTING.md` for exact results.

To try the widget after installation, open the launcher's service-widget picker for CompanionOS and add **Today together**. Launcher support varies. Tap it to open the app. Counts are pushed after saves and refreshed on system widget callbacks; the widget shows its data date and does not promise instant background refresh.

## Local data and timing limits

Settings and the latest 20 records share a validated Preferences snapshot. Total and daily counts are independent of the history limit. Valid records from the previous homepage are migrated; its older discarded records cannot be reconstructed, so an imported total reflects known records/counts. Missing or invalid snapshots recover to defaults with a notice. Storage access/write failures are reported and do not claim a successful save.

An in-memory session uses a wall-clock deadline. Backgrounding clears the UI interval; returning recalculates remaining time. An activity that expires in the background becomes ready for parent confirmation on return without a retroactive notification. Process termination discards an unfinished standalone quick activity and never records it automatically. Parent Work Sessions checkpoint remaining time/step and restore paused with Built-in content. Manual clock changes can affect timing. Reliable background alarms are not implemented.

No camera, location, child account, dangerous tools or client API keys are used. Network access is used for explicitly requested optional recommendations, AI preparation, imported-video TV caching or TV relay communication. Local Built-in activities do not require network success. Local Preferences are not presented as encrypted storage.

## Evidence and submission materials

- [Testing results and pending device checks](docs/TESTING.md)
- [Architecture and data flow](docs/ARCHITECTURE.md)
- [Optional AI service contract](docs/AI_SERVICE.md)
- [Actual AI development workflow](AI_WORKFLOW.md)
- [Third-party inventory](docs/THIRD_PARTY.md)
- [Two-minute demo and recording steps](docs/DEMO_SCRIPT.md)
- [Submission checklist](docs/SUBMISSION_CHECKLIST.md)

No competition RULES or CRITERIA were found in this workspace. Competition eligibility and complete compliance are not verified. No recording or final competition submission has been produced automatically.
