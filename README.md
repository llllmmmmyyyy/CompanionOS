# CompanionOS

Small activities. Meaningful family moments.

CompanionOS is a native HarmonyOS phone MVP for short, adult-accompanied family activities. It encourages families to put the screen down and play together, then lets a parent confirm the shared moment. The core works offline without an account or AI key.

## Implemented experience

- **Home:** Penguin Walk, Animal Sounds, Butterfly Stretch, today's completion count, interest matches, settings and progress.
- **Parent Settings:** ages 4–5 or 6–8, Movement / Sounds / Nature interests, 3 / 5 / 10 minutes, persistent local settings.
- **Activity:** age guidance, curated steps, adult accompaniment, start, countdown, cancellation and parent confirmation. Normal mode uses the selected duration; clearly labelled Demo Mode uses ten seconds.
- **Progress:** recent completions, local date/time, total count and badges at 1, 3 and 10 completions. Demo completions are labelled and included in totals.
- **HarmonyOS capabilities:** Preferences persistence, real foreground-end notification calls with permission/error handling, and a 2×2 desktop widget with an app launch link.
- **Optional AI:** configurable HTTPS recommendation endpoint, validation, loading state, ten-second timeout and offline fallback. No backend exists in this workspace and no live AI connection has been verified. A service may recommend only a supported activity matching parent settings; steps remain curated offline content.

## Environment verified during development

| Component | Observed value |
|---|---|
| Platform / module | HarmonyOS Stage model / `entry` / Phone |
| DevEco Studio | 6.0.1.251 |
| Compatible and target SDK | HarmonyOS 6.0.1, API 21 |
| Installed SDK package | 6.0.1.112 |
| Build tools | DevEco bundled Hvigor, Node 18.20.1, Java 21.0.8 |
| Git remote | https://github.com/llllmmmmyyyy/CompanionOS.git |

The existing SDK and build configuration are preserved. The separate competition CLI setup is not required for this project's native build.

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

The current project has no signing configuration. The verified output is **unsigned**, not an installation-ready signed release. No device or emulator was connected during this development run; UI, notification delivery and widget hosting remain device verification tasks.

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
