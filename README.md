# CompanionOS

Small activities. Meaningful family moments.

CompanionOS is a native HarmonyOS phone MVP for short, adult-accompanied family activities. It encourages families to put the screen down and play together, then lets a parent confirm the shared moment. The core works offline without an account or AI key.

## Implemented experience

- **Choose Activity Content:** Gemini AI, Huawei AI, Built-in Video and My Video share the existing Phone session/history and TV player. Gemini is preserved; Huawei MaaS is a second backend adapter. Both need backend-only credentials and remain unverified against live APIs. Built-in requires no AI call. My Video uses the system picker, a private persistent MP4 copy and optional backend caching for TV; offline Phone playback is supported.

- **Companion TV Mode:** same-phone Demo TV plus independent `tventry` on API 19 TV. Phone-owned timer/pause/resume/next/previous/cancel/completion, HTTP relay and reconnect synchronization. See [TV mode](docs/TV_MODE.md).
- **Generation backend:** Node/TypeScript, real Gemini structured-plan and Veo 3.1 REST paths, validation/retry, asynchronous segments, reviewed disk cache and safe no-key fallback. No live provider call was attempted this run. TV plays a labelled original bundled fallback MP4 when generated clips are unavailable. See [AI architecture](docs/AI_ARCHITECTURE.md).

- **Home:** Penguin Walk, Animal Sounds, Butterfly Stretch, today's completion count, interest matches, settings and progress.
- **Parent Settings:** ages 4–5 or 6–8, Movement / Sounds / Nature interests, 3 / 5 / 10 minutes, persistent local settings.
- **Activity:** age guidance, curated steps, adult accompaniment, start, countdown, cancellation and parent confirmation. Normal mode uses the selected duration; clearly labelled Demo Mode uses ten seconds.
- **Progress:** recent completions, local date/time, total count and badges at 1, 3 and 10 completions. Demo completions are labelled and included in totals.
- **HarmonyOS capabilities:** Preferences persistence, real foreground-end notification calls with permission/error handling, and a 2×2 desktop widget with an app launch link.
- **Optional recommendation service:** configurable HTTPS endpoint, validation, ten-second timeout and offline fallback. This older catalog recommendation adapter is separate from the new generation backend. No live provider connection has been verified.

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

## Phone + TV hackathon demo

Backend requires Node.js 22+ (24.21.0 was available here). In Windows PowerShell inside `backend`, run `npm.cmd ci`, `npm.cmd run build`, then `npm.cmd start`. No key is needed for fallback. To enable providers, copy `.env.example` to ignored `.env`. Set `GEMINI_API_KEY` for Gemini/Veo, or `HUAWEI_MAAS_API_KEY` plus the exact enabled `HUAWEI_MAAS_MODEL` from your MaaS console. Huawei video uses the documented Wan text-to-video adapter; configure the enabled video model and explicit trusted storage hosts in `HUAWEI_VIDEO_DOWNLOAD_HOSTS`. No key goes into either app. Account/model access remains unverified. Generated footage is review-gated: inspect MP4 under backend/data/videos, then `npm.cmd run review -- <videoId>` to approve.

The helper automates builds, backend start, port forwarding, installation and launch: run `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-emulator-demo.ps1 -Build` from this repository. Policy changes apply only to that process. Emulators must already be running; override -Phone / -Tv if target IDs differ. No need to recreate running emulators.

Exact demo sequence (the helper performs setup steps):

1. Start backend as above.
2. Ensure API 21 Phone emulator is running.
3. Ensure API 19 Huawei TV emulator is running.
4. Install TV HAP: `tventry/build/tv/outputs/default/tventry-default-unsigned.hap`.
5. Launch `com.example.companionos` / `TvAbility`; Waiting for phone appears.
6. Install Phone HAP: `entry/build/default/outputs/default/entry-default-unsigned.hap`.
7. Launch `com.example.companionos` / `EntryAbility`.
8. For each device forward `rport tcp:18080 tcp:8787` through HDC.
9. Phone: Play on TV → Connect to Emulator TV.
10. Both apps use `http://127.0.0.1:18080`, room `family-demo`; host listens on `127.0.0.1:8787`.
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

The current project has no signing configuration. The verified output is **unsigned**, not a signed release. In the follow-up test, the API 21 development emulator accepted this unsigned HAP and ran it successfully. Home/details, settings and record persistence, Demo and full three-minute normal completion, cancellation, confirmation/double-click protection, background expiry/resume and an actual notification in the system notification center were verified. Widget hosting, physical-phone installation and full 5/10-minute expiry variants remain pending. See `docs/TESTING.md` for exact results.

To try the widget after installation, open the launcher's service-widget picker for CompanionOS and add **Today together**. Launcher support varies. Tap it to open the app. Counts are pushed after saves and refreshed on system widget callbacks; the widget shows its data date and does not promise instant background refresh.

## Local data and timing limits

Settings and the latest 20 records share a validated Preferences snapshot. Total and daily counts are independent of the history limit. Valid records from the previous homepage are migrated; its older discarded records cannot be reconstructed, so an imported total reflects known records/counts. Missing or invalid snapshots recover to defaults with a notice. Storage access/write failures are reported and do not claim a successful save.

An in-memory session uses a wall-clock deadline. Backgrounding clears the UI interval; returning recalculates remaining time. An activity that expires in the background becomes ready for parent confirmation on return without a retroactive notification. Process termination discards the unfinished session and never records it automatically. Manual clock changes can affect timing. Reliable background alarms are not implemented.

No camera, location, child account, dangerous tools or client API keys are used. Network access is used only when a parent configures a service and requests a recommendation. Local Preferences are not presented as encrypted storage.

## Evidence and submission materials

- [Testing results and pending device checks](docs/TESTING.md)
- [Architecture and data flow](docs/ARCHITECTURE.md)
- [Optional AI service contract](docs/AI_SERVICE.md)
- [Actual AI development workflow](AI_WORKFLOW.md)
- [Third-party inventory](docs/THIRD_PARTY.md)
- [Two-minute demo and recording steps](docs/DEMO_SCRIPT.md)
- [Submission checklist](docs/SUBMISSION_CHECKLIST.md)

No competition RULES or CRITERIA were found in this workspace. Competition eligibility and complete compliance are not verified. No recording or final competition submission has been produced automatically.
