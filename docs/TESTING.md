# Testing evidence

## Current API 21 Tablet companion - 2026-10-03

**Targets:** primary Phone entry/default remains compatible/target API 21; secondary tventry/tablet is compatible/target API 21 and deviceTypes tablet. Shared HAR supports phone/tablet. No current product requires API 19. HDC queried Phone API 21/phone and MatePad Pro 11 API 21/tablet; Windows emulator process arguments identify MatePad Pro 11. The Tablet system reports generic model emulator; the emulator profile, not a physical device, supplies the model name.

**Build/checks passed:** final native Phone and Tablet unsigned HAPs built and installed. 47 ArkTS checks and 18 backend tests passed (65 total); cloud HTTP remains mocked. Phone SHA-256 `6799EA6EB10AF5ECB5FFD8D5754738E03DF493AD9D42E4361E0F2AAF2A9F17D9`; Tablet SHA-256 `3C1B434D5CDAAED0EB43E9183E460C014AD98209289FE8B8AAE263E11ECF80F0`. Outputs: entry/build/default/outputs/default/entry-default-unsigned.hap and tventry/build/tablet/outputs/default/tventry-default-unsigned.hap. No signing or physical-device validation.

| Actual current emulator check | Result |
|---|---|
| Phone launch/work plan/activity | Passed: Home -> thirty-minute six-entry plan -> Penguin Walk -> normal 05:00 child view. |
| Tablet launch/connect | Passed: updated helper installs/launches both; Tablet connects to Windows relay at 10.0.2.2:18080 / family-demo, then Phone connects to Emulator Tablet; both report Connected. |
| START | Passed: Tablet native bundled content, Penguin Walk/instruction, Step 1/3 and Video PLAYING observed. |
| PAUSE/RESUME | Passed: Phone commands switch actual Tablet state/video PLAYING -> PAUSED -> PLAYING with synchronized remaining time. |
| NEXT | Passed: Tablet becomes Step 2/3, displaying gentle flipper instruction while video remains PLAYING. |
| CANCEL / end | Passed: final Phone End Session produced actual Tablet CANCELLED / 0:00; Phone summary showed 0 confirmed and 6 skipped. |
| Reconnect / journal | Passed: restarted Tablet and explicit Phone reconnect restored CONNECTED, native LEARN video PLAYING and Step 2; after end, journal retained total 11 and prior Demo/non-Demo records. No new completion was recorded by cancel/skip. |
| Change/skip | Passed: first entry is skipped and next LEARN preview opens; receiver becomes WAITING for the new reviewed activity, not a false completion. |
| Landscape content/layout | Passed for observed 2560x1600 emulator screenshot: native content, title, two-line instruction and progress fit without major clipping. Portrait/larger text not tested. |
| Tablet unavailable | Passed: force-stopped Tablet while Phone normal LEARN activity continued at 04:52 with local video/instructions. |
| Phone restart recovery | Passed: force-stop/relaunch then final-HAP installation retains work checkpoint; explicit restored notice, Paused status and 25 remaining planned minutes / 0 confirmed. Resume returns to native child view. |

Captured Phone/Tablet app logs contained no Uncaught/JsError/Error-name/FATAL signatures; receiver logs showed actual disconnect/heartbeat expiry and later CONNECTED. This is bounded captured-log evidence. Final HAP manifests were inspected for minimum/target/device values.

**Automation findings:** several navigation attempts searched for a Home button after recovery had already opened the work-status screen. These attempts were aborted; actual layout inspection identified the correct Resume/Open child view route. They are not reported as successful tests. Root npm test failed because this native project has no root package.json; backend npm.cmd test then passed from backend. Build reports absent signing and platform throw warnings. Initial product-switch build also reported local HAR metadata warning; both compilations completed and the final Phone rebuild did not repeat that warning.

**Preserved historical evidence:** old API 19 TV tests below are deprecated target evidence only, not proof of current Tablet support. Earlier actual My Video import, profile/history restore, no-key AI fallback and notifications were not all repeated in this focused target conversion. Interrupted prior refinement's Demo confirmation and pause/resume/early-end checks remain documented in its own section.

**Not verified:** physical Phone/Tablet, live cloud generation, production distributed-device deployment, full elapsed work windows, widget hosting, portrait/formal accessibility and recording. Validated on HarmonyOS Phone and Tablet emulators. The relay is a development/demo HTTP transport with explicit Phone fallback. API target adjustment is not a full competition compliance certificate.


## Historical pre-Tablet evaluation refinement - 2026-10-03

This section distinguishes checks performed in this refinement from historical sections below. The user supplied evaluation weights; the public organizer tasks page returned a loading placeholder, so official partner criteria/compliance remain unverified.

**Passed builds:** Phone and TV native unsigned HAPs rebuilt with existing DevEco SDK/API configuration. Phone SHA-256 `75D102345949D92B53313A9BB16C76763CC662B6F19027F7896568EED63F9A68`; TV SHA-256 `2EC037E6F20B8B606C594052DA22268FFFBD3FE8EF1AC405CF85DB810919846D`. Both installed successfully on the existing Phone API 21 / TV API 19 emulators. Warnings about potentially throwing platform APIs and absent signing remain; no physical device was used.

**Passed host checks:** all 47 ArkTS checks (14 domain, 7 work/profile, 13 mocked services, 7 TV, 6 emulator/protocol) and 18 backend checks passed, total 65. The new work check verifies the exact default thirty-minute category sequence, invalid-duration normalization and restricted preferred types. Cloud tests use injected HTTP, not live provider success.

**Actual Phone observations this iteration:** Home displays the new proposition. Thirty-minute setup renders MOVE 5 / LEARN 10 / CREATE 10 / CALM 5; a screenshot was visually inspected. Preparation starts Penguin Walk with Why this activity and age/adult notices. Labelled ten-second Demo start reached the child player and foreground expiry reported a submitted system notification. Parent confirmation advanced to Animal Number Adventure / LEARN; force-stop/relaunch retained the active work plan and exposed Return to work session. The notification center was not reinspected at this point. Recovered work view showed 25 planned minutes and 1/6 confirmed. The second entry normal timer paused at 04:55 and resumed at 04:54; early end showed one confirmed Demo and five skipped. No thirty-minute real-time completion claim.

**Audit:** tracked-file scan found no common API/private-key token patterns, tracked secret env files/signing/generated packages/dependency directories, or broken local Markdown links. This bounded scan is not proof that arbitrary secret formats cannot exist. Only blank-key backend/.env.example is tracked. Existing .gitignore already covers env/signing/local paths, artifacts, dependencies and build output; no unrelated change was needed.

**Historical emulator evidence retained, not repeated wholesale:** native My Video picker/private persistence, Gemini/Huawei no-key fallbacks, actual TV controls/outage continuation, profile restore, notification-center inspection and full normal five-minute activity are documented below. Current TV HAP installation/launch is a smoke check, not a repetition of every transport case.

**Not verified:** physical devices, live cloud success, complete elapsed work windows, widget hosting, formal accessibility, actual recording and final organizer eligibility/submission. No new third-party assets/dependencies. The 90-second script explicitly captions an edited completed-Demo summary; a continuously filmed early end is labelled Work Session Ended.


## Parent work sessions and visual refinement - 2026-10-03

This section covers the current product refinement. The emulator's local record clock crossed into 2026-10-04 during testing; dates shown in device records are retained as observed. Later sections are historical evidence, not a blanket claim that every old test was repeated.

**Environment:** existing native Phone API 21 and TV API 19 emulators, DevEco 6.0.1.251 / SDK 6.0.1.112. No AGENTS.md or competition RULES/CRITERIA were found. No applicable development skill required a different workflow. No framework, signing profile, target SDK, runtime dependencies or relay architecture was replaced.

**Build and delivery:** Phone and TV unsigned HAP builds passed and both were installed on the running development emulators. Final Phone SHA-256 `597AE4F83BDADBC58604BEBC454F156A930E475A77362B7DE15E0FC4E618866F`; TV SHA-256 `D8D59288DFBEB6770033BBA48122A944921F0D4094E7557EEEE1089851D50202`. Actual paths: `entry/build/default/outputs/default/entry-default-unsigned.hap` and `tventry/build/tv/outputs/default/tventry-default-unsigned.hap`. Signing is still unconfigured; builds report caught-platform-API/signing warnings. This is not a signed release or physical-device verification.

**Host checks:** 46 actual-ArkTS checks passed (14 original domain, 6 new work/profile, 13 mocked services, 7 TV and 6 emulator). Existing backend `npm.cmd test` also passed all 18 tests. The six work checks cover legacy profile migration, preference serialization, 15/30/45/60 plans and type constraints, sequencing/skips, duplicate record IDs, honest summary/demo minutes, early end and corrupt/restart checkpoints. These checks are separate from device testing; cloud calls use injected responses.

| Device check | Actual result / bounded scope |
|---|---|
| Home and discovery | Passed: original hero/character/category SVGs visibly render on the 1316x2832 Phone. Four bottom tabs, scrolling, CREATE filter and tappable Imagine a Tiny World/Penguin cards were exercised. Screenshot inspection found category ellipsis, fixed by explicit compact padding; later screenshot shows all labels in full. |
| Parent profile restart | Passed: saved age 6-8, five-minute quick duration, 45-minute work preference and Standard difficulty; force-stop/relaunch retained the profile. The work hero showed 45 min and activity preview showed ages 6-8. Test selections were later returned to the original three-minute quick duration and default 30-minute/Gentle work profile; age/interests and existing records were retained. Safety/type serialization and invalid profile checks passed on host; not every switch combination was tapped on-device. |
| 15-minute work plan / full sequence | Passed in labelled Demo Mode: three five-minute planned entries were each run with a ten-second countdown and parent confirmation. Sequence MOVE -> LEARN -> CREATE reached Work Session Complete, 15 minutes planned, 3 confirmed, 0 skipped. Demo category-minute totals correctly remained zero. This is NOT fifteen elapsed minutes. |
| Duplicate confirmation / original history | Passed: actual first completion doubleClick produced one record; final total changed 6 -> 9 after three distinct demo confirmations. Original six records were retained. |
| Full normal five-minute work activity | Passed with actual unshortened foreground countdown: 05:00 -> automatic Step 3/3 / 00:50 -> ready and parent confirmation. The later early-end summary showed 15 minutes planned, 1 confirmed, 5 planned minutes MOVE, 2 skipped. Final HAP install/restart retained this non-Demo five-minute record, total 10 and the same summary. This does not imply full fifteen-minute completion. |
| 30-minute normal plan | Passed for six-entry preparation, normal five-minute activity start, parent hand-off, pause, parent work view, force-stop/relaunch safely paused, resume, skip and early end. It showed 25 remaining planned minutes after skipping the first entry and finally 30 minutes planned / 0 confirmed / 6 skipped. Full thirty-minute elapsed completion was not tested. |
| Child view | Passed visually: large native video, current instruction, step progress, countdown and a single parent-control entry. Parent controls open a hand-off dialog; this is not a secure PIN or identity check. |
| Content sources | Passed for real Gemini/Huawei no-key backend requests and labelled Built-in fallback, Built-in selection and saved My Video selection. Live cloud generation remains unverified. Switching My Video exposed a stale builder title, fixed with a direct state binding; later actual preview shows My family video. On the delivered category-bound HAP, selecting LEARN/Animal Sounds and Gemini produced a real no-key Space Counting Mission fallback labelled LEARN / ages 6-8 / 3 min, matching the selected category and restored quick duration. |
| System video import | Passed: native PhotoViewPicker selected the existing original eight-second clip, explicit system Done returned success, private-copy metadata retained title and duration. No new external/user media was fetched. |
| Phone-only | Passed: all three 15-plan Demo activities completed before TV connection; the 30-plan pause/recovery/skip/end also used Phone alone. |
| Optional TV / imported media | Passed: explicit TV receiver Connect and Phone Connect to Emulator TV reached Connected through 10.0.2.2:18080 / family-demo. Native TV displayed My Video gateway URL, PAUSED / Video: PAUSED; resume/next worked. Force-stopping TV left Phone video/instructions/countdown running; cancelling did not create a record. |
| Same-phone Demo TV | Passed on final HAP: Animal Sounds -> Play on a larger screen -> Demo TV Mode -> View Demo TV opened the retained local illustration/player, then returned/relaunched Home. The local view explicitly labelled video unavailable; this is not a separate-TV connection or generated-video claim. |
| Notification | Actual activity-end UI reported a submitted system notification during the work Demo. Notification-center inspection is historical in sections below and was not repeated at this point. Reliable background notification is not claimed. |
| Journal / recovery | Passed: new source-labelled Demo records coexist with older records after restarts. Work checkpoints use stable entry IDs, remaining time, step and demo; resumed source becomes Built-in with an explicit notice. Corrupt/missing checkpoints are host-tested safe defaults. Only the latest work summary is retained. |

**Intermediate findings resolved:** missing Phone fallback resource initially failed compilation, fixed by copying the original TV MP4 unchanged (both SHA-256 `13CDE1CFB76B486249352E25B5E460C77B8032224E75196C39F1AEFA85177F01`). Initial Unicode text passed through a Windows shell became question marks; replaced with plain English punctuation and checked in actual UI. Category labels and changed-content heading were corrected from device evidence. Home filters now reset on all routes back Home. Optional TV includes Continue on phone (actual failed-receiver -> Phone start/cancel passed); active-activity Back returns to the child flow. Home after filtered cancellation showed all five activities again.

**Still unverified:** full 15/30/45/60 elapsed work windows; all multi-step source-preference combinations; live Gemini/Huawei accounts; signed physical devices; larger system text, smaller Phone widths, landscape and formal accessibility audit; widget hosting; recording and complete competition compliance. Imported/generated content still requires adult review. Built-in activities remain indoor/gentle/jump-free regardless of relaxed preference flags. Work restart restores paused Built-in content, not arbitrary unreviewed AI/video replay. Uninstall/clear-data deletes local state.

**Minimal human review:** use the new home on the existing emulator; try a complete normal work window with an adult nearby, review the independent-activity wording for your child's needs, inspect larger-font layout, and record the 90-second script in DEMO_SCRIPT.md. Live keys/signing are separate and do not block local use.

Scoped captured Phone logs contained no Uncaught/FATAL/JsError/Error-name crash signatures. Intentional connection failures remain diagnostic evidence, not hidden successes. Local screenshots/layout/logs are ignored under artifacts/work-*. They are actual local evidence and are not uploaded as user/device data.


## Direct emulator relay routing — 2026-10-03

This historical network fix established the preserved direct gateway route; the current product refinement is documented above.

Diagnosis on the running Windows machine found no listener on port 18080. An older Node backend was listening on 127.0.0.1:8787, and both HDC forwarding lists were empty. The HTTP relay is the CompanionOS backend (`backend/dist/server.js`), not a Phone TCP server. Guest loopback therefore reached neither Windows nor the other emulator. Both guests report eth0 10.0.2.15 with gateway 10.0.2.2; those identical guest addresses belong to separate virtual networks.

The corrected topology is Phone and TV → `http://10.0.2.2:18080` → Windows Node relay bound to `127.0.0.1:18080`, using room `family-demo`. Windows loopback binding is intentional; guest loopback is not used. No firewall modification or HDC reverse tunnel was required.

| Actual check | Result |
|---|---|
| Final unsigned builds | Passed: Phone API 21 and TV minimum API 19 / compiler API 21. Both HAPs installed on the existing running emulators. |
| Host tests | Passed: 40 ArkTS checks and 18 backend tests. These are separate from device evidence. |
| Startup helper | Passed: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/run-emulator-demo.ps1` compiled and started the stopped Windows backend, installed and launched both apps. |
| TV Connect, then Phone Connect to Emulator TV | Passed: TV Connecting → waiting for Phone → CONNECTED; Phone Connection: Connected. Actual UI shows gateway endpoint and family-demo. Both HDC forwarding lists remained empty. |
| START / PAUSE / RESUME / NEXT / CANCEL | Passed on both emulators through the direct gateway route: native TV Video PLAYING → PAUSED → PLAYING; step advances to 2/3; confirmed cancellation produces CANCELLED and leaves completed count unchanged. |
| Relay unavailable / recovery | Passed: deliberately stopping the owned 18080 backend produced visible `Connection failed: Error 2300028: Timeout was reached`; Connect remained available. Restarting the backend and connecting both clients restored CONNECTED. |
| Logs | Actual TV logs contain connection attempt, endpoint, room, CONNECTING, WAITING and CONNECTED. Network failures include native error codes in the UI and request/status diagnostics. |
| Physical TV / other emulator network configurations | Not verified. 10.0.2.2 was verified on these two running DevEco emulators, not assumed universal. |

Final HAP paths: `entry/build/default/outputs/default/entry-default-unsigned.hap` (SHA-256 `9D12C3E4D1B93A6586B51F8B82B51C33B694C18CEA567286911A2A24D6DA97C8`) and `tventry/build/tv/outputs/default/tventry-default-unsigned.hap` (SHA-256 `D097AAF69519ECF84192FA0C232F386B577C38B33A32522766890AD0D5B90773`). Signing remains unconfigured. An intermediate ArkTS misplaced-import error was fixed before these successful builds.

Ignored local evidence includes `artifacts/relay-final-*.json`, `artifacts/relay-tv-stopped.json`, `artifacts/relay-final-tv-hilog.txt` and `artifacts/network-final-*-build.txt`. This targeted change does not revalidate unrelated AI providers, physical devices or release signing.

## Integrated backend, TV and content sources — 2026-10-03

This historical integrated stage used HDC reverse routing. The direct gateway correction and current build hashes are documented above.

**Build:** Phone API 21 and TV minimum API 19 / compiler API 21 unsigned HAPs built with installed DevEco 6.0.1.251 / SDK 6.0.1.112. Phone SHA-256 `0EEF8A476859D17A3195232031B75F892023FF6FD03F59C5A63755E72E5FBC51`; TV SHA-256 `55B348D3F56CE0BC24C8CAAE8E0CC29F5D38E90E1BDBFB35759FC889FF661F87`. Actual paths: `entry/build/default/outputs/default/entry-default-unsigned.hap` and `tventry/build/tv/outputs/default/tventry-default-unsigned.hap`. Signing remains unconfigured; both development emulators accepted installation and launched the respective abilities. This does not verify physical installation or a signed release.

**Host tests:** 39 actual-ArkTS logic checks (14 domain, 13 mocked services, 7 TV/mock-plan, 5 emulator protocol/client) and 18 backend tests passed. `scripts/build.ps1 -RunChecks` and `npm.cmd test` in backend were actually executed. Backend tests include actual ephemeral local HTTP endpoints but mocked cloud responses/media bytes: Gemini reuse, Huawei REST/task shapes, missing models/keys, provider failure, strict safety/duration validation, retries, review-gated cache/ranges, progressive generation, redirects without secret forwarding, imports and all four source types with every transport command. These tests are not live provider or device claims.

| Actual device / integration check | Result and scope |
|---|---|
| HDC detection / compatibility | Passed: Phone 5555 API 21; independent TV 5557 reports tv/API 19. Both are running emulators, not physical devices. |
| Phone-to-TV connection | Passed using real loopback backend/HDC reverse routes: Phone Connected; TV receiver heartbeat and full state observed. Startup helper installed/launched both. |
| Video-first TV / native bundled MP4 | Passed: 3840×2160 16:9 TV screenshot inspected; actual Video PLAYING/PAUSED callbacks and VIDEO_READY feedback. Original non-AI cloud clip preserved. |
| Normal timer and controls | Passed in integrated stage: real 5-minute start/pause/resume/next/previous; full wall-clock 3-minute Dino fallback expiry reached parent confirmation, TV Step 3/3. |
| Disconnect/reconnect | Passed: TV force-stop for seven seconds produced Phone Disconnected while countdown continued; receiver restart restored full state. |
| Completion / double-click | Passed integrated stage: required parent checkbox; doubleClick produced one 3-minute record, total 4→5; TV completion celebration. |
| Real system notification | Passed integrated stage: actual Dino foreground-end notification inspected in notification center. Reliable background notification is not claimed. |
| Video failure | Passed on actual TV with explicit HTTP 404 fixture: VIDEO_FAILED / safe static FALLBACK; no record created. This was injected test media, not a provider result. |
| Same-phone Demo / original activities | Passed integrated stage: IMAGINE ten-second expiry, original Penguin 3-minute start/cancel with total unchanged. |
| Four content cards / both provider failure UI | Passed on latest Phone: real GEMINI and HUAWEI requests to no-key backend returned Built-in/offline labels and offered the other provider/Built-in. No cloud call succeeded or was attempted. |
| Missing saved video | Passed latest Phone: My Video with no private copy offered import or Built-in; app remained usable. |
| System picker / real import | Passed latest Phone: selected the project's original eight-second MP4 in PhotoViewPicker, copied private file, extracted duration and displayed saved title/8 seconds. No broad gallery permission requested. |
| Imported-video restart | Passed latest Phone: force-stop/relaunch retained saved clip/title/duration and My Video selection succeeded; existing settings age 6–8 / 3 minutes and five old records retained. |
| Imported Phone/TV controls and cancellation | Passed latest devices: USER_VIDEO cached URI arrived through real relay; TV showed My Video / Video: PAUSED; normal 02:59 paused, next/previous/resume worked; explicit dialog cancellation returned Home with count five. |
| Imported Demo completion / duplicate click | Passed latest Phone: actual ten-second expiry, parent checkbox and doubleClick produced one My family video / My Video Demo record; total five→six. Older Dino record defaulted to CompanionOS Built-in. |
| Latest record restart / fallback heading | Passed: final Phone restart displayed count six and saved age/time; repeated Gemini failure displayed the refreshed Dino Movement Adventure heading. |
| Four-source actual TV control fixtures | Passed on TV for GEMINI_AI, HUAWEI_AI, BUILT_IN and USER_VIDEO: START actual PLAYING callback, PAUSE actual PAUSED, NEXT/PREVIOUS displayed step, RESUME PLAYING, CANCEL and COMPLETE states. Fixtures explicitly said Playback fixture - NOT AI output and used the original clip/cached import. This proves shared player/transport behavior, not live AI generation. No Phone completion was written by fixtures. |
| Heading update | Fixed after device observation: direct Text binding refreshes changed activity title; My family video title observed after import. |
| Live Gemini/Veo / Huawei MaaS | Unverified: no provider credentials configured. Existing Gemini client and second Huawei client compile and pass injected HTTP tests; no claim of generated cloud footage. |
| Latest runtime log review / final state | No app JS exception/fatal signature found in captured Phone and TV process hilog. Final backend rebuilt/restarted; Phone returned Home with six completions and Connected to Emulator TV, receiver waiting. Expected AV decoder errors from the deliberate earlier 404 fixture are not treated as app crashes. |
| Widget / physical devices / signing | Unverified: widget hosting/tap/update, physical Phone/TV pairing and signed distribution still pending. |
| Full 5/10-minute expiry variants | Unverified on device; selected time arithmetic covered by host checks. |

Initial failed build checks were fixed (SDK lifecycle spelling), then successfully rebuilt. npm.ps1 was blocked by existing PowerShell policy, so npm.cmd was used without changing system policy. HDC media import initially failed for temporary path access and relative/forward-slash Windows paths; the API 21 media-FUSE route and Windows-native resolved source path successfully imported only the project's clip. These intermediate failures are not counted as passes.

Remaining manual checks: configure backend credentials only if live AI is desired; review real generated clips before child playback, test actual provider billing/model access and result-storage allowlist. Run complete 5/10-minute sessions and add/tap the widget. Sign and test physical devices. Recording remains manual; follow DEMO_SCRIPT.md. No RULES/CRITERIA file was found, so full contest compliance remains unassessed.

## Companion TV extension — 2026-10-03

Final API 21 build succeeded with `scripts/build.ps1 -RunChecks`; **33 host checks passed** (13 domain, 13 mocked services, 7 TV/AI checks). The exact unsigned HAP SHA-256 is `918BF1F0A7AC741F3BC192917EDE9FE16317BA49DB97E024675413C4C3A36810`, at `entry/build/default/outputs/default/entry-default-unsigned.hap`. Signing remains unconfigured. HDC installed this HAP successfully on the existing `127.0.0.1:5555` emulator; its API property returned 21. Another emulator was visible at 5557 but was not used.

| Test | Result / evidence |
|---|---|
| Existing settings and history after update | Passed on emulator: age 6–8, 5 minutes, original three completions preserved |
| Demo TV connection / mock selection | Passed on emulator: Connected, locally labelled Demo; MOVE, CALM and LEARN selected |
| Normal phone countdown and pause | Passed on emulator for 5-minute start: 04:59 froze while paused; elapsed wall time did not exhaust it |
| Landscape TV pause and placeholder | Passed on emulator: 2832×1316 screenshot inspected; Paused, 04:59, Step 1/3, local video-unavailable illustration visible |
| Return to controller, resume, next step | Passed on emulator: restored portrait controls, countdown continued, Step 2/3 instruction appeared |
| Disconnect fallback / cancel | Passed on emulator: phone continued at 04:56 after disconnect; cancellation confirmed; count stayed 3 |
| Ten-second Demo and TV expiry celebration | Passed on emulator: LEARN reached Time is up; local player showed star celebration, 00:00 and parent-confirmation prompt |
| Parent confirmation / double click | Passed on emulator: confirmation box required; injected doubleClick saved one Space Counting Mission record; total/today became 4 |
| Restart restore | Passed on emulator: force-stop/relaunch restored age/duration and total 4; new mock record and old Penguin Walk record visible |
| Runtime crash review | No app JS exception/fatal signature found in captured process hilog; AceScrollable HandleCrashTop/Bottom are scroll diagnostics, not evidence of an application crash |
| Four mock categories / all durations / malformed plans | Passed in host checks: deterministic MOVE/LEARN/IMAGINE/CALM, 3/5/10 duration sums, absent-video fallback metadata, invalid request/URL rejected |
| Transport command forwarding | Passed in host checks: local events and real adapter delegation using an injected mock channel; no real remote transport tested |
| Old stored records migration / duplicates | Existing service/domain checks passed; version-1 TV and old records coexist after serialization; emulator retained old data |
| Full three-minute countdown | Existing version was actually tested below; this extension's pause-aware 3-minute behavior passed simulated-clock host checks. A full wall-clock three-minute run was not repeated this round |
| Real TV, streaming video, provider failure, Gemini/Veo | Not verified / not implemented end to end: no TV receiver/channel, live provider or streamed media in this version |
| Real notification regression this round | Existing emulator verification is documented below; not separately rechecked in this TV extension round |

The local Demo is real ArkUI running on the Phone emulator, not a test on actual TV hardware. Local placeholder rendering was verified; this does not constitute a streamed-video error test. Host mocks are not platform/device evidence. Permission-denied/unavailable discovery is handled in code; real nearby-device discovery remains unverified. Earlier sections describe earlier versions and their own results.

### Remaining manual checks

- Select IMAGINE in Demo TV Mode and review the story with an adult for age suitability.
- Run a complete normal three-minute activity in this version; pause, wait and resume before confirming.
- Check notification permission grant/denial and notification center again for the TV flow.
- With compatible TV hardware and a implemented receiver/channel, verify pairing, ordered commands, real disconnection/reconnect and video failure. These cannot be tested by the local phone Demo.

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
