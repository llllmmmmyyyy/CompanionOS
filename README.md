# CompanionOS

**Don't just limit screen time. Transform it.**

CompanionOS turns passive screen time into structured activity time while parents focus. An adult remains nearby and available.

Turn passive screen time into safe, guided activity time. Parents should not have to choose between focused work and keeping their child meaningfully engaged. CompanionOS provides a fourth option alongside constant entertainment, passive screens and unsupervised outdoor play: short, structured home activities with practical adult oversight. It does not replace appropriate adult supervision.

## What it does and why it exists

A parent needs thirty minutes to work; their child is bored at home. With all four types selected, the default plan offers Move 5, Learn 10, Create 10 and Calm 5 minutes, split into six short activities. Every activity is reviewed and confirmed by an adult. This complements supervision rather than replacing it.

## The experience

- **A home designed around families:** original illustrations, a prominent Parent Work Session hero, warm category colors, tappable activity cards and Home / Activities / Progress / Parent navigation. Network/provider status is shown only where relevant.
- **Parent Work Session:** choose 15, 30, 45 or 60 planned minutes. A sequence of five-minute MOVE, LEARN, CREATE and CALM activities uses the parent's preferred types. Review before each start, take breaks, pause/resume, skip or end. Parent-confirmed activities feed the existing journal; the summary separates completed, skipped and demo activities. Planned durations are not measured developmental outcomes or a promise of continuous engagement.
- **Child profile:** ages 4-5 / 6-8, interests, preferred activity types, work-window duration, Gentle / Standard difficulty, indoor/no-jumping/low-intensity preferences. Existing 3/5/10-minute quick activities remain available. Settings and history migrate without resetting earlier records.
- **Child view and parent work view:** a large native video/instruction area with progress and minimal controls. Parent controls require a hand-off dialog, which is an accidental-tap barrier, not authentication. The compact work view shows current activity, status and remaining planned activities.
- **Content options:** Recommended chooses safe Built-in content without a network. Gemini AI, Huawei AI and My Videos remain optional sources, with parent review and safe fallback. Work-session source preference prepares each new activity; parents can change it before starting. API keys stay on the backend. Neither live cloud provider has been verified with credentials.
- **Phone first:** the complete session works on Phone alone. "Play on Large Screen" exposes existing Demo Large Screen and independent emulator Large Screen as optional extensions. Failed Large Screen connections never block Phone activity or confirmation.
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

Phone product `default` remains minimum/target API 21. Separate product `tablet` is minimum/target API 21 and supports tablet devices. Its retained tventry module is the Large-Screen companion. `shared` is a local protocol HAR, not another project.

## Optional larger-screen demo

Backend requires Node.js 22+ (24.21.0 was available here). In Windows PowerShell inside `backend`, run `npm.cmd ci`, `npm.cmd run build`, then `npm.cmd start`. No key is needed for fallback. To enable providers, copy `.env.example` to ignored `.env`. Set `GEMINI_API_KEY` for Gemini/Veo, or `HUAWEI_MAAS_API_KEY` plus the exact enabled `HUAWEI_MAAS_MODEL` from your MaaS console. Huawei video uses the documented Wan text-to-video adapter; configure the enabled video model and explicit trusted storage hosts in `HUAWEI_VIDEO_DOWNLOAD_HOSTS`. No key goes into either app. Account/model access remains unverified. Generated footage is review-gated: inspect MP4 under backend/data/videos, then `npm.cmd run review -- <videoId>` to approve.

The helper automates builds, Windows backend start on port 18080, installation and launch: run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-emulator-demo.ps1 -Build` from this repository. Both apps connect directly to `http://10.0.2.2:18080` using emulator host-gateway networking; no HDC port forwarding is required. Policy changes apply only to that process. Emulators must already be running; override -Phone / -Tablet if target IDs differ.

Exact demo sequence (the helper performs setup steps):

1. Start backend as above.
2. Ensure API 21 Phone emulator is running.
3. Ensure API 21 MatePad Pro 11 emulator is running.
4. Install Large Screen HAP: `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`.
5. Launch `com.example.companionos` / `TvAbility`; Waiting for phone appears.
6. Install Phone HAP: `entry/build/default/outputs/default/entry-default-unsigned.hap`.
7. Launch `com.example.companionos` / `EntryAbility`.
8. Large Screen: verify `http://10.0.2.2:18080` / `family-demo`, then press Connect. Connected to Windows relay / Waiting for Phone means the server is reachable.
9. Phone: Play on Large Screen → Connect to Emulator Tablet.
10. Both apps use `http://10.0.2.2:18080`, room `family-demo`; the Node server listens on Windows loopback port 18080. Large Screen shows CONNECTED once Phone posts its heartbeat. Emulator loopback is not the host; the previous tunnel-only configuration is obsolete.
11. Use Edit age, interests and duration to save the desired age/interests/3–10 minutes.
12. Return to Play on Large Screen, choose category and enter an educational goal.
13. Tap Create Adventure and observe Planning / Generating video progress.
14. Missing keys show Backend fallback plan. Real AI plans are labelled only after a valid provider response.
15. Start when plan/first approved clip or safe fallback is playable; Play on Large Screen keeps Phone as controller.
16. For a short demo check Demo Mode; normal mode uses the chosen minutes.
17. Phone Pause / Resume controls actual Large Screen video playback.
18. Next / Previous switches step and clip; scheduled steps also advance.
19. After time ends, check the parent box and Mark as completed on Phone.
20. Large Screen celebrates; Phone saves one record. Cancel records no completion.

No-key videos are explicitly bundled fallback, not Veo output. Same-phone Demo Large Screen remains separate and needs no backend. Both development emulators accepted unsigned HAPs; physical-device signing remains unverified. In DevEco choose product `default`, module `entry`, Phone then Run; for Large Screen choose product `tablet`, module `tventry`, Large Screen then Run.

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

The current project has no signing configuration. The verified output is **unsigned**, not a signed release. The redesigned Phone and preserved Large Screen HAPs were built and installed; current parent-work and visual checks are listed at the top of docs/TESTING.md. The following core-flow checks are historical evidence. In the follow-up test, the API 21 development emulator accepted this unsigned HAP and ran it successfully. Home/details, settings and record persistence, Demo and full three-minute normal completion, cancellation, confirmation/double-click protection, background expiry/resume and an actual notification in the system notification center were verified. The current work flow also passed one full normal five-minute activity. Widget hosting, physical-phone installation, full ten-minute expiry and full-length work windows remain pending. See `docs/TESTING.md` for exact results.

To try the widget after installation, open the launcher's service-widget picker for CompanionOS and add **Today together**. Launcher support varies. Tap it to open the app. Counts are pushed after saves and refreshed on system widget callbacks; the widget shows its data date and does not promise instant background refresh.

## Local data and timing limits

Settings and the latest 20 records share a validated Preferences snapshot. Total and daily counts are independent of the history limit. Valid records from the previous homepage are migrated; its older discarded records cannot be reconstructed, so an imported total reflects known records/counts. Missing or invalid snapshots recover to defaults with a notice. Storage access/write failures are reported and do not claim a successful save.

An in-memory session uses a wall-clock deadline. Backgrounding clears the UI interval; returning recalculates remaining time. An activity that expires in the background becomes ready for parent confirmation on return without a retroactive notification. Process termination discards an unfinished standalone quick activity and never records it automatically. Parent Work Sessions checkpoint remaining time/step and restore paused with Built-in content. Manual clock changes can affect timing. Reliable background alarms are not implemented.

No camera, location, child account, dangerous tools or client API keys are used. Network access is used for explicitly requested optional recommendations, AI preparation, imported-video Large Screen caching or Large Screen relay communication. Local Built-in activities do not require network success. Local Preferences are not presented as encrypted storage.

## Evidence and submission materials

- [Testing results and pending device checks](docs/TESTING.md)
- [Architecture and data flow](docs/ARCHITECTURE.md)
- [Optional AI service contract](docs/AI_SERVICE.md)
- [Actual AI development workflow](AI_WORKFLOW.md)
- [Third-party inventory](docs/THIRD_PARTY.md)
- [90-second demo and recording steps](docs/DEMO_SCRIPT.md)
- [Submission checklist](docs/SUBMISSION_CHECKLIST.md)
- [Evaluation evidence](docs/SCORE_READINESS.md)
- [Presentation outline](docs/PRESENTATION.md)

No competition RULES or CRITERIA were found in this workspace. Competition eligibility and complete compliance are not verified. No recording or final competition submission has been produced automatically.

## Why HarmonyOS?

CompanionOS uses HarmonyOS as the foundation for a family-device experience across Phone and larger displays. The native Stage-model ArkTS/ArkUI application uses:

| Implemented capability | Actual API / component |
|---|---|
| Lifecycle-aware foreground timing | UIAbility onForeground/onBackground, AppStorage, wall-clock ActivitySession |
| Settings, history and paused work recovery | preferences from @kit.ArkData; LocalStore and WorkStore |
| Foreground activity-end notifications | notificationManager from @kit.NotificationKit; permission rejection and publish failure handled |
| Parent-owned video import | photoAccessHelper.PhotoViewPicker, fileIo private copy, media.AVMetadataExtractor |
| Native playback | ArkUI Video / VideoController on Phone and Tablet |
| Larger-display experience | Separate tventry HAP and shared validated protocol through the optional Windows HTTP relay |
| Service widget | @kit.FormKit provider and launch action; implemented/built, hosting not verified |

Validated on HarmonyOS Phone and Tablet emulators. The relay is an application-level HTTP channel, not a claim of verified native distributed playback or physical-device validation.

## Architecture

Phone owns profiles, timers and confirmation records. An optional Node backend handles provider adapters, approved media and transient Large Screen rooms. Large Screen receives validated frames and never writes the Phone journal. See [architecture](docs/ARCHITECTURE.md), [AI](docs/AI_ARCHITECTURE.md) and [Large Screen](docs/TV_MODE.md).

## Requirements, test and HAP output

DevEco Studio 6.0.1.251 with SDK 6.0.1.112/API 21 was used. Phone needs API 21+; Large Screen needs API 21+ with compiler API 21. Backend is optional for Built-in Phone sessions and requires Node 22+ (24.21.0 tested). From repository root:

```powershell
& ([scriptblock]::Create((Get-Content -LiteralPath ./scripts/build.ps1 -Raw))) -RunChecks
& ([scriptblock]::Create((Get-Content -LiteralPath ./scripts/build.ps1 -Raw))) -Module tventry
Push-Location backend
npm.cmd ci
npm.cmd test
npm.cmd start
Pop-Location
```

The last command keeps the optional backend running until Ctrl+C. Default PORT=18080, HOST=127.0.0.1; both emulators use http://10.0.2.2:18080 / family-demo. All supported configuration names, with blank secrets, are in [backend/.env.example](backend/.env.example): GEMINI_API_KEY, HUAWEI_MAAS_API_KEY, HUAWEI_MAAS_MODEL, HUAWEI_MAAS_VIDEO_MODEL, HUAWEI_VIDEO_DOWNLOAD_HOSTS, GEMINI_MODEL, VEO_MODEL, PORT, HOST and REQUIRE_VIDEO_REVIEW. Never put credentials in either HAP.

Phone output: entry/build/default/outputs/default/entry-default-unsigned.hap. Large Screen output: tventry/build/tablet/outputs/default/tventry-default-unsigned.hap. Generated HAPs are ignored rather than committed.

## Known limitations and AI

Real Gemini/Veo and Huawei cloud success is NOT VERIFIED; provider HTTP tests are MOCKED and actual no-key fallback is emulator tested. My Video requires adult review; missing media leaves Built-in instructions usable. Large Screen is OPTIONAL and Phone continues without it. Full work-window elapsed runs, physical devices, signed release, widget hosting, formal accessibility and family usability studies remain pending. Demo minute totals exclude accelerated activities. Notifications are foreground-only; reliable background reminders are not implemented.

## Built during HackYeah 2026

The repository records development on 2026-10-03: the Phone application, redesigned UI, Parent Work Session, expanded child profile, sequencing/recovery, content-source system, Gemini and Huawei adapters, My Video import, Large Screen module, emulator relay fixes, tests and English documentation. This is an implementation record, not independent certification that every change occurred inside the official permitted competition window.

Pre-existing foundations include the DevEco Stage template and build toolchain, Node/TypeScript libraries and the earlier CompanionOS implementation preserved by this refinement. Original SVG illustrations were authored with Codex; the existing original bundled clip was reused. Inventory: [THIRD_PARTY](docs/THIRD_PARTY.md). ChatGPT, Gemini and Huawei were not used as additional coding agents in this iteration.

## Evaluation evidence

[Score readiness](docs/SCORE_READINESS.md) maps concrete evidence to the six evaluation areas supplied in the user's brief, without invented scores. The official [HackYeah tasks page](https://hackyeah.pl/tasks-prizes) returned only a loading placeholder during this audit; the quoted partner weights and full rules could not be independently verified. Final eligibility, timing, licenses and submission requirements need organizer confirmation.

## Large-Screen Companion

Primary: HarmonyOS Phone API 21 (`entry`, product `default`). Optional: HarmonyOS Tablet API 21 (`tventry`, product `tablet`). The former TV/API 19 product is no longer configured as a current target. Internal TvAbility/TvReceiver/protocol names remain for compatibility, not as a claim of current TV support.

Phone remains the authoritative controller of START / PAUSE / RESUME / NEXT / CANCEL, activity time and history. Tablet is a child-facing video/instruction display. Both guests use the existing http://10.0.2.2:18080 relay and family-demo room. This development/demo HTTP channel is not production distributed-device deployment. Failure always allows continuing on Phone.

In DevEco choose product tablet, module tventry and the MatePad Pro 11 / HarmonyOS 6.0.1 / API 21 emulator. Phone uses default / entry. Build with scripts/build.ps1 -Module tventry; output tventry/build/tablet/outputs/default/tventry-default-unsigned.hap. The helper accepts -Tablet <HDC target> (legacy -Tv is an alias). Refer to [Large-Screen mode](docs/TV_MODE.md) and the latest [actual tests](docs/TESTING.md).
