# Testing evidence

## Actual emulator follow-up — 2026-10-03

HDC connected to `127.0.0.1:5555` using DevEco's installed SDK toolchain. `param get const.ohos.apiversion` returned **21**, matching both the project's target and compatible API. The device software property reported `emulator 6.0.0.112(SP3DEVC00E112R4P11)`; this is the actual returned value, rather than an assumed marketing version. UI layout bounds were 1316×2832.

The current source was rebuilt with `scripts/build.ps1 -RunChecks`: HAP build succeeded and all 26 host checks passed again. Project signing configuration remains empty, but this development emulator accepted the exact unsigned HAP below: HDC reported `install bundle successfully` and `aa start` reported `start ability successfully`. This does not prove unsigned installation works on physical devices or validate a signed release.

| Actual device test | Result | Observed evidence |
|---|---|---|
| Home and all three activity details | Passed | Exact product/subtitle, Penguin Walk, Animal Sounds, Butterfly Stretch and their steps present in device UI dumps |
| Save parent settings | Passed | Selected age 6–8, Movement + Nature and 5 minutes; successful save message |
| Settings survive process restart | Passed | `aa force-stop` / relaunch restored age 6–8, 5 minutes and selected Movement/Nature controls |
| Demo countdown | Passed | Actual UI showed Demo Mode, `00:10`, put-down prompt, then `Time is up!` |
| Normal mode start and cancel | Passed (partial timing coverage) | Actual UI showed `NORMAL MODE • 5 minutes` and `05:00`; cancellation returned Home without changing count |
| Full three-minute normal activity | Passed | Actual countdown `03:00` → `02:07` → `00:25` → `Time is up!`; confirmation saved a `3 min` normal record, total/today 3 and Together Team badge |
| Cancellation after expiry | Passed | Confirmed cancellation dialog; Home showed no completion recorded and count remained 0 |
| Parent confirmation required | Passed | `Mark as completed` was disabled before checking the parent box |
| Repeated confirmation click | Passed for injected double-click | System UI `doubleClick` produced one record and count 1, not two; broader rapid-tap stress not performed |
| Completed records and badges | Passed | Progress displayed dated Demo record(s), parent-confirmed label, First Adventure badge and matching total |
| Records/counts survive restart | Passed | After two Demo sessions, restart restored two records; after the normal session, another restart restored total/today 3 and three records |
| Real notification permission denial | Passed | Actual OS permission dialog was denied; app showed failure message and completion still worked |
| Real foreground-end notification | Passed | After enabling the app's OS notification toggle, a foreground Demo expiry submitted a notification; actual notification center contained `CompanionOS: time is up` and the Penguin Walk text |
| Background expiry/resume | Passed for Demo case | Backgrounded by opening Settings for 12 seconds, returned to `Time is up!` and parent confirmation; no retroactive submission message; count unchanged until confirmation |
| Unconfigured AI fallback | Passed | Actual recommendation UI explicitly said no AI service was configured and labelled the offline recommendation |
| Runtime exception review | No app crash observed | Reviewed app-PID hilog; final capture had zero JSCRASH/TypeError/ReferenceError/Unhandled/Fatal-exception matches and normal Ability startup |
| Full 5/10-minute expiry variants | Not verified | Complete three-minute expiry and five-minute start/cancel tested; full five/ten-minute runs pending |
| Desktop widget host/update/tap | Not verified | Remains a launcher test; compiled widget alone is not a runtime pass |
| Real AI backend, corrupted device storage, alternate layouts | Not verified | Host mocks/logic only; no live backend or destructive device fault injection |

No application-code failure was reproduced, so no source change was made just to create a fix. Platform-tag errors from CONCUR/QoS and PARAM_WATCHER appeared in an earlier PID log; they did not terminate the app and are not described as resolved application defects. Log-buffer keyword checks cannot prove absence of every possible issue.

Local evidence is retained under ignored `artifacts/`: UI layout snapshots (`settings-saved.json`, `restart-settings.json`, `completion-disabled.json`, `completed-once.json`, `two-records-restored.json`, `notification-center.json`, `normal-countdown.json`, `background-expired-resume.json`, the `normal-three-minute-*` snapshots, `three-records-restored.json`, activity detail dumps), a reviewed emulator screenshot, and app-PID logs. Raw dumps/logs are not uploaded. No private data or existing records were deleted. The emulator was left with two labelled Demo records, one normal record, and restored age 6–8 / Movement + Nature / 5-minute settings. System notifications remain enabled after the delivery test.

### Short remaining manual checklist

| Check | Action |
|---|---|
| Additional normal durations | Disable Demo Mode and exercise complete 5/10-minute expiry when convenient; three-minute end-to-end timing already passed |
| Widget | Add Today together from the launcher's widget picker; tap to open app; complete a session and inspect count update |
| Layout | Try larger system text and a smaller phone; check scrolling and controls |
| Recording | Record the actual two-minute walkthrough from `DEMO_SCRIPT.md` |

Live AI validation requires a real backend and remains future work. Storage fault injection should use a disposable debug installation, not the retained test/family data. No reliable background alarm is claimed.

## Initial host-only build results — 2026-10-03

| Check | Actual result | Evidence boundary |
|---|---|---|
| Native API 21 ArkTS compilation and resources | Passed | Actual Hvigor `assembleHap` run; not Preview |
| HAP packaging including form extension | Passed | Unsigned HAP produced |
| Domain checks | 13 passed | Actual pure `.ets` model transpiled using the installed SDK compiler and executed on host Node |
| Service checks | 13 passed | Actual AI/notification/LocalStore modules executed with mocked HarmonyOS services |
| Device availability | `hdc list targets` returned `[Empty]` | No installable connected target available |
| Phone/emulator UI interaction | Not run | No device; no runtime pass claimed |
| System notification delivery/permission UI | Not run | Only mocked error/allow/deny paths exercised |
| Desktop widget hosting, launch and refresh | Not run | Compiled card and provider; launcher behavior unverified |
| Live AI integration | Not run | No backend or endpoint configured; mock results are not real AI output |
| Competition requirements | Not verified | No RULES/CRITERIA in the workspace |

The final build reported `BUILD SUCCESSFUL` with no ArkTS compiler errors or warnings. Signing was explicitly skipped because `signingConfigs` is empty. The only build warning is the missing signing configuration. Windows PowerShell may format native stderr warnings as `NativeCommandError` text; the build helper evaluates the actual exit code and does not confuse that text with a failed HAP build.

Artifact: `entry/build/default/outputs/default/entry-default-unsigned.hap`.
Observed size: 316,555 bytes.
Observed SHA-256: `4DF86E2E9D31DDECF69A1EE876CCD4C5250B70ABEDA528AB88659CC316622E5D`.
This fingerprint identifies the tested local artifact, not every future rebuild.

Local evidence logs: `artifacts/build.txt` and `artifacts/tests.txt` (excluded from Git). Reproduction commands are in README. The template's existing Hypium sample tests were retained but not run as MVP device tests.

## Automated coverage

Domain checks cover settings/record serialization, absent/malformed/invalid snapshots, date rollover, duplicate completion IDs, independent counters beyond the 20-record limit, all normal durations, ten-second Demo Mode, single foreground-end notification decision, cancellation, background expiry/resume, resume before deadline, interest validation and HTTPS endpoint restrictions.

Service checks cover unconfigured offline recommendation without a request, accepted mocked AI response, rejection of mismatched age/time/adult/source/interest/ID, network/status/JSON failure fallback, simulated total timeout and request destruction, HTTP initialization failure, notification denial, enabled publish, publish failure/stale session suppression, Preferences round-trip through a fresh store mock, corrupt snapshot recovery, migration of previous homepage data, and flush error propagation.

The timeout test simulates firing the configured 10,000 ms callback immediately; it is not a ten-second live network measurement. Preferences mocks test application behavior, not OS file durability. Duplicate protection is checked at the domain level and reviewed in the synchronous UI busy/phase guard; real repeated-tap behavior remains pending.

## Full device checklist (follow-up results above take precedence)

Use this checklist for broader regression coverage on an API 21+ phone/emulator. The follow-up table above identifies the cases actually executed; unlisted variants remain pending. Physical-device signing and runtime are not verified.

1. **Home:** verify exact product/subtitle, three activities and today's count. Open all three steps pages. Confirm no camera/location prompts.
2. **Settings restore:** choose age 6–8, Nature and 5 minutes; save, stop and relaunch without uninstalling/clearing data; confirm restoration. Repeat with age 4–5 and 3/10 minutes. Empty interests must not save.
3. **Normal completion:** disable Demo Mode, start a 3-minute activity, check its countdown and put-down prompt. Completion must remain unavailable until the deadline and parent checkbox. Complete once; check total/today increment by one and a dated record/badge.
4. **Demo Mode:** start the labelled ten-second mode; verify the mode label and Demo record. Demo counts deliberately contribute to badges/totals.
5. **Cancel/back:** cancel during running and after time-up. Both must leave counts unchanged. Declining cancellation must preserve the session.
6. **Repeated taps:** tap confirmation repeatedly; only one record/count increment should be saved. Return to the old screen if possible and ensure the same session cannot be saved twice.
7. **Record restore:** complete two different sessions, relaunch the app, confirm records and counters remain. The latest 20 history entries are retained while totals continue.
8. **Foreground notification:** in Parent Settings allow notifications; complete a Demo countdown while app stays foreground; inspect the actual notification center. An OS publish success does not alone establish visible delivery.
9. **Rejected notification:** deny/disable notifications, repeat; time-up and parent confirmation must still work. Review message wording and OS permission behavior.
10. **Background transitions:** background midway and return before deadline; countdown should match remaining wall time. Repeat returning after deadline; page should be ready, without a promised background/retroactive notification.
11. **Process termination:** terminate during a running session; relaunch should show saved data but not record or revive the unfinished session.
12. **Recovery/storage failure:** on a disposable debug installation, inject malformed `mvp` Preferences JSON or simulate read/write failure using the debugger. Recovery must not crash; failed save must not show success. Do not corrupt real family data.
13. **AI failure:** with an empty endpoint request a recommendation; it must say offline. On a disposable configuration, use a reachable HTTPS test endpoint returning bad JSON/503/wrong age and verify offline fallback/loading clears. A live AI pass requires an actual AI backend and separately captured evidence.
14. **Widget:** add Today together from a supporting launcher's widget picker; tap to open the app. Save settings and complete a session; inspect title/count update. Check its data date across day rollover; OS scheduling may delay refresh.
15. **Layout/accessibility:** inspect a small phone, larger text and landscape if supported; ensure scrolling and buttons remain usable. These layouts have not been visually verified.

## Known limits

- No signed HAP, physical-phone run or screen recording is available. The development emulator accepted and ran the unsigned HAP.
- Notification and widget delivery are controlled by the OS. No reliable background reminder is implemented.
- Unfinished sessions are in-memory; process kill cancels them implicitly. Wall-clock adjustment can change countdown behavior.
- Demo completions count towards totals; imported legacy totals include only reconstructible known history/counts.
- Corrupt snapshots reset to defaults; there is no backup-repair/export workflow. Uninstall or clearing app data deletes local state.
- Optional service authenticity, production authentication, privacy policy and deployment remain backend work.
- Starter artwork rights and competition compliance require review before public submission.
