# Native Pico animation verification - 2026-10-04

## Build and host checks

Phone and Tablet clean builds passed with the configured HarmonyOS 6.0.1/API 21 SDK. Both API 21 emulators were detected through HDC, and both final unsigned HAPs installed and launched. The user's existing local Phone debug signing configuration also produced a signed Phone HAP; that signing material/configuration was not committed. Tablet still has no signing configuration. Installation tests used unsigned development packages, not a signed physical-device release.

`scripts/build.ps1 -Module entry -Clean -RunChecks` completed all **114 host checks**: domain 14, work 17, parent summary 14, games/journey 10, world 21, Pico scheduler 6, mocked services 18, TV/AI 7, emulator protocol/client 7. The scheduler checks navigation once, latest-tab wins, lifecycle cancellation, post-swap cancellation, immediate reduced motion and supported actions. Existing host protocol loaders now explicitly stub native UI exports; these are not UI-rendering tests.

Final installed unsigned artifacts:

- `entry/build/default/outputs/default/entry-default-unsigned.hap`: SHA-256 `F3537818A229BE075E72884EF573EC1DF7D15A86010DE6EF27160EA964BDADFE`.
- `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`: SHA-256 `359379EF100B264242D3EF2BAFF85C91DBC32B7D95EDC11E37B8050A08C25DC4`.

## Native checks

| Check | Actual result |
|---|---|
| Phone Home, Activities, Insights, Parent | Passed: all destinations displayed existing content with a layered Pico header and selected tab indicator. Native logs captured enter/out/in/reveal/rest stages, including pull for Activities and eat for Insights. An in-flight overlay was captured, not only a static final page. |
| Parent settings reachable | Passed: Child & Safety Settings opened the existing age/interests/duration page; session duration, presets, custom balance, memory, Exit Child Mode and technical information remained available. |
| Phone reduced motion | Passed: native toggle reported checked=true; Home navigation worked; toggled off afterwards. Flag is process-local. |
| Tablet reduced motion | Passed: native toggle reported checked=true and was restored off. |
| Start Session | Passed: actual Phone button sent the existing START_SESSION command; Tablet entered a planned adventure and Phone showed running counters. No protocol/backend change. |
| Pause/resume with Robot Memory | Passed: Phone Pause displayed one Tablet pause overlay with Skip absent; Phone Resume returned to input safely. Memory completed with three correct inputs and zero retries. |
| Completion celebration | Passed: native capture shows articulated raised arms and gold stars beside Robot. Continue produced one stable-ID completed record and the Phone count increased from 54 to 55. Checking the ID in the actual relay journal found one occurrence. |
| Bounded ending / Home Base | Passed: ending the test session showed the existing healthy ending/Back to World; returning preserved the one garden gift and saved completion count. An unfinished next mission was explicitly ended, not counted as completed. |
| Restart preservation | Passed: after installing/restarting final packages, Phone still showed 55 completed activities and Tablet 55 discoveries/one garden gift. No app data was cleared. |
| Final-package repeat | Passed: final HAPs ran another separate session, Phone Pause → Tablet Resume Adventure → three correct memory inputs → celebration → Okay feedback/hop → Continue. The new stable ID occurred once, with three attempts/zero retries and feedback=okay; Phone count rose 55 → 56. End/Back to World retained one garden gift and 56 discoveries. These are two separate test sessions, not duplicate records. |
| Foreground/layout | Passed for tested layouts: first Phone viewport retained Today's Activity above navigation; overlays use no hit testing. No ReferenceError/TypeError/SyntaxError/FATAL matched the inspected native logs. |

Native evidence is local and ignored under `artifacts/pico-*`: layouts, screenshots and filtered motion logs. Initial automation briefly saw the launcher before the app returned to foreground; that initial capture was not called a Home pass. A preset was found changed during automation and restored to the original 30 min / More Movement selection without resetting custom rules or journals. The existing relay already owned port 18080; a redundant startup returned EADDRINUSE and was not reported as a successful server start.

## Remaining verification limits

Native testing is a focused emulator regression, not proof of every screen/animation on every device. Physical-device FPS/battery, large-font/small-screen accessibility and a child usability study remain unverified. Empty/error states are implemented but destructive empty-journal/storage-failure scenarios were not injected into retained data. Background animation cancellation is covered by deterministic scheduler checks; every possible native background race has not been exhaustively tested. No snapshot capture or shader mask is used; live content transforms provide the reusable pull/eat/reveal illusion. No new full 15/30/45/60-minute timing or AI-provider validation is claimed. See [PICO_ANIMATION.md](PICO_ANIMATION.md).

# Interactive cloud Storybook verification - 2026-10-04

Correction scope: **Storybook/WATCH in Home Base**, not Calm Sky. Previously native video completion directly marked Storybook success; child could only watch and return/skip. Now Help the Cloud Find Home keeps the existing eight-second cloud clip, automatically replaces the player with three native sky waypoints, accepts drag or cloud-tap/next-glow-tap, then shows The cloud found its home! and one Return to World. Gentle misplaced drags return without wrong/failure screens, attempt scores or retry counts. No new schema, Phone logic, Insights, relay or SessionBalanceEngine change; Calm Sky and other game branches are untouched.

Final clean Tablet build: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Module tventry -Clean`, BUILD SUCCESSFUL, exit 0, API 21. Installed/launched without removing journal data. Output `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`, SHA256 `4E409062C2603CC2C2518E6D662D65C4A3C33B5860677582F4D97DE9669F99D3`. Existing signing/exception warnings remain; unsigned emulator development output, not a signed release. A normal incremental build initially reused an older external shared-model cache; the clean build included the current model and pause/video guard, and the installed clean HAP was used for final Daily testing. The requested post-test build also finished BUILD SUCCESSFUL with exit 0 and the identical SHA256, so the final output matches the installed/tested HAP.

| Check | Actual verification | Status |
|---|---|---|
| Video preservation | API 21 Storybook screenshot/layout showed native player resource://RAWFILE/fallback.mp4 and 00:08 duration; cloud story clip actually played | PASS |
| Automatic transition | Native video end replaced player with Can you help the cloud find the sky? and a large interactive cloud/path; no Return press needed first | PASS |
| Wrong drag | Actual drag from Story cloud directly to waypoint 3 at first step returned cloud, showed The glowing path will guide our cloud and stayed interactive | PASS |
| Drag and fallback tap | Native drag to waypoint 1, tap cloud then waypoint 2, drag to sky waypoint 3 all moved the cloud; screenshots show brighter sun and cloud joining the sky | PASS |
| Completion UX | The cloud found its home! / Thanks for helping, explorer; one Return to World, no score/failure/leaderboard/retry UI | PASS |
| Independent return | Return to World opened Home Base and produced one WATCHING/CALM result, completed, 0 attempts, 0 retries | PASS |
| Skip | Actually skipped during video and separately after video in input; Return to World returned hub and both outcomes stayed skipped, not completed | PASS |
| Final clean HAP Daily flow | Genuine bridge placements, memory sequence, foreground movement + Done, garden planting + Done, native video and all three cloud drags completed | PASS |
| No video-only completion | Final Daily after video before interaction was 4/5, active and not ended; only interaction + explicit Return advanced to 5/5 ending | PASS |
| Duplicate Return | Two native Return clicks at the same button coordinates; final Daily had exactly one completed Storybook mission result, total 5/5 | PASS |
| Existing ending/hub | Final healthy bounded ending and Back to World worked; existing daily gift retained, not re-awarded | PASS |
| Model tests | 21 world checks passed: four new Storybook rules cover video gating/three steps/gentle miss/dedup, skips/reload/paused progress, paused-video-end race and intermediate Daily slot return; 17 existing checks retained | PASS |
| Logs | Captured final Tablet process log had zero Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches | PASS within captured scope |
| Physical Tablet / child pacing study / selected remote URI / native restart during story | Not exercised in this task. Reload/pause semantics were host-tested; 20–40 seconds is a pacing target, not an enforced deadline or usability finding | NOT RUN on device |

Event scope: existing MISSION_STARTED, native VIDEO_STARTED, one phase-guarded VIDEO_COMPLETED, OBJECT_DRAG_STARTED, three successful OBJECT_PLACED, and one final completed/skipped outcome. Tap arming and gentle misses emit no per-touch/psychological event. Raw events remain Tablet-local; existing relay carries compact WATCHING outcome only. Story duration includes video plus interaction and is not a passive-watch-only or psychological measurement. Shared phase/progress/selected fields preserve existing storage schema; no artificial completion rows were injected.

Evidence is ignored under artifacts/story-cloud-* (screenshots/layouts, actual compact outcomes, host tests, clean build/runtime logs). Test setup used unchanged existing relay command endpoints. Balanced 15-minute Daily command reused the actual SessionBalanceEngine/worldSlots plan from earlier verified harness with a fresh ID; saved parent settings were not changed. Full standalone and Skip checks used the prior build with the same story transition; final clean package also includes a native-video-start pause guard and received the full Daily and duplicate-return checks. No unrelated Phone/backend system was rebuilt.

# Calm Sky wording and gentle tap verification - 2026-10-04

This is a small Tablet UX consistency change, not a new game. No "Help the cloud find home" or other cloud drag-home instruction was found in the current inspected scene/model/demo copy. Old child title was Calm Sky; prompt was "Breathe comfortably with the cloud. Tap gently, with no score."; completion used the generic "Our world changed because of you!". New child title: **Breathe with the Cloud**. Story: "Pico found a sleepy cloud. Let's help it relax." Instruction: "Watch the cloud. Breathe slowly, then tap it gently." Completion: "Nice and calm." The safety reminder retains comfortable breaths, no holding and no score.

The existing 4-second breathing scale animation, cloud tap counter, optional Done/Skip, activity completion and progression remain. A soft 900ms opacity change uses the existing counter as visual tap feedback; no new score, retry, challenge, reward, timer, data field or psychological metric was added. World/record name Calm Sky is retained; the new title is child-facing. Phone/relay/Insights/persistence/session architecture were not changed or rebuilt.

Tablet build command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Module tventry`. The tested API 21 package was installed/launched without deleting data; build exited 0 with BUILD SUCCESSFUL. Output `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`, SHA256 `0DD8E585235B52B2BDF3974B36FCEFCCC12022733C4F582E754CB49FCF2F861A`. It is unsigned development output with the existing signing/exception warnings, not a signed release. The required post-verification Tablet build also finished BUILD SUCCESSFUL with exit 0 and the same SHA256, so its artifact is identical to the installed/tested HAP.

| Check | Actual verification | Status |
|---|---|---|
| Clear Calm instructions | Actual Tablet API 21 opened Calm Sky from Home Base; screenshot/layout showed one Breathe with the Cloud title, Watch/Breathe/Tap instruction, sleepy-cloud story and no-score safety text | PASS |
| Gentle cloud tap response | Actual HDC tap and before/after screenshots show soft cloud tint change; the same interior screenshot pixel changed RGB 255/255/255 → 251/253/250. Existing slow scale motion retained | PASS within captured visual evidence |
| Calm completion | Done exploring displayed Nice and calm; no score, correct/wrong, failure, drag target or retry state appeared | PASS |
| Data semantics | Calm outcome remained EXPLORING / CALM, completed, 0 attempts, 0 retries; no new field/event or emotional inference | PASS |
| Continue progression | Continue adventure returned to Home Base after the independent Calm activity | PASS |
| Daily Adventure regression | Actual native bridge placements, memory signals, foreground movement + Done, garden planting + Done, built-in story/video completion; all 5/5 complete, healthy ending and Back to World worked | PASS |
| Existing host rules | All 17 world rule checks passed through installed SDK compiler, including unscored calm, daily dedup/progression and pause/resume | PASS |
| Runtime log | Tablet process log had zero Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches | PASS within captured scope |
| Physical Tablet / accessibility / child comprehension study | Not performed | NOT RUN |

First Phone navigation attempts encountered its separately restored fallback work screen and were interrupted, not marked passes. Test setup used the existing unchanged relay command endpoint for end/re-entry and START_SESSION. The 15-minute Balanced regression command was generated from actual SessionBalanceEngine + worldSlots using the installed SDK compiler; it did not modify saved 60-minute Custom settings. All recorded completions came from native Tablet interactions, not injected result rows. Existing already-successful story state was preserved as an outcome when ending that prior session. Current-day garden gift was already earned and stayed 1; no second gift was claimed. Evidence stays ignored under artifacts/calm-copy-*; temporary test harness was removed. No new wording-mirror test was added for this reversible UI edit.

# Tablet local Resume Adventure fix - 2026-10-04

Scope: ChildWorld's local pause/resume button and paused presentation only. The old control was disabled whenever connected; its disconnected handler merely changed a flag. The new Resume Adventure constructs RESUME_SESSION and invokes the same extracted applyCommand handler used for received Phone commands: WorldEngine.command, active callback, persistence, video handling and existing state sync. The Tablet is already the session-state authority. No Phone, backend, shared command transition or protocol change was made.

Tablet final build: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Module tventry`; BUILD SUCCESSFUL, exit 0, API 21. Final HAP `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`, SHA256 `6FEA616AAF968A70369815F481871F97FE3A663D0F29B34464C52F76F7912CD0`. Installed/launched on the existing Tablet API 21 without removing storage. It remains unsigned development output; signing and existing exception warnings remain.

| Check | Actual verification | Status |
|---|---|---|
| Shared resume semantics | 17 world host checks passed, including added preview/input RESUME_SESSION test, replay safety, unchanged progress/results/retries and ten-minute paused-time exclusion | PASS |
| Phone Pause → Tablet resume | Real Phone Pause while Robot Memory was previewing, followed by real Tablet Resume Adventure; overlay disappeared and Phone displayed Robot task with running Pause/Next/End controls | PASS |
| Paused UI | Real paused layout: exactly one Adventure paused text and one Resume Adventure, zero Skip buttons; path/feedback/continuation controls hidden | PASS |
| Pause budget | Real relay remaining held at 1796 seconds across an additional eight-second paused wait, beyond native inspection time | PASS |
| Memory preview | Paused preview safely resumed and reached input with 0/2 lights; host test separately proves preview restarts its sequence safely | PASS |
| Partial memory input | Tapped Blue, Phone Pause, Tablet Resume: 1/2 progress persisted; Red completed Robot without repeating the first answer | PASS |
| No extra retry/completion | Resume itself added no outcomes; actual completed memory mission had exactly one stable-ID result, 2 attempts and 0 retries | PASS |
| Final HAP spot check | After hiding resume for ended sessions, rebuilt/reinstalled and repeated connected Phone Pause → Tablet Resume; no new outcome on resume and Phone running | PASS |
| Ended while paused | Final HAP Phone Pause then End Session showed ending without dead resume button/pause overlay | PASS |
| Runtime logs | Final Tablet process log had zero Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches | PASS within captured scope |
| Video-specific local resume / disconnected resume / physical Tablet | Same handler retains video controller resume branch, but these variants were not exercised in this narrow runtime test | NOT RUN |

Native memory completion tests ran on the first build with the same handler; final build added only the ended-overlay visibility guard and received the separate native spot check above. Existing 30-minute Custom settings and journal were retained. Test sessions were explicitly ended from Phone; those unfinished outcomes remain skipped rather than claimed as successful. Ignored artifacts/tablet-resume-* contain real layouts/screenshots, pause snapshot and build/runtime logs. No unrelated broad backend/Phone suite was rerun.

# Local Parent Insight Summary verification - 2026-10-04

ParentInsightSummaryEngine is a new read-only deterministic layer on the retained BehaviorInsightEngine metrics. It summarizes validated, deduplicated saved Tablet outcomes; temporary mission-level metric adapter events are neither persisted nor uploaded. Home shows one seven-day sentence; Insights offers up to three observations, one balanced suggestion, Today/7/30 controls, expandable evidence and optional structured metrics/history.

Final Phone build: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Module entry`, BUILD SUCCESSFUL, exit 0, API 21. Output `entry/build/default/outputs/default/entry-default-unsigned.hap`, SHA256 `5F4F8175E0452A854CE67221438DD3D4ED7C9478C6C31834179EC0D42B8FC64A`. Final HAP was installed and launched on the existing Phone API 21 without deleting data. Existing warning/signing limitations remain; this is an unsigned emulator development package. Tablet was unchanged and not rebuilt in this stage.

| Check | Actual verification | Status |
|---|---|---|
| Summary rules | 14 new SDK-transpiled host tests: building, memory retries, format comparison without selection claim, insufficient data, conflicting signals, sparse all-completed groups, no completions, one category, movement, positive feedback, exact source/evidence matching, prohibited language, balance protection, windows/deduplication | PASS |
| Existing BehaviorInsightEngine / balance regression | `scripts/test-work.cjs`: all 17 existing work/behavior/balance checks passed; original engine unchanged | PASS |
| Home summary | Actual Phone API 21 layout shows one Story completion observation and View Insights, without raw metrics in What We Noticed | PASS |
| Summary-first Insights | Final HAP real screenshot/layout shows Story observation, building Loved it observation, balanced suggestion and evidence button above optional Recent patterns | PASS |
| Actual evidence | Real saved emulator journal has 45 outcomes. Storybook 4/4 completed; building 4 Loved it out of 5 explicit responses (overall building completion 7/16). The engine and Phone correctly report Story completion and building feedback, not a fabricated building-completion advantage | PASS |
| Expand/collapse | Real taps on Why am I seeing this? and Hide summary evidence reveal matching Story titles/dates/mission IDs and 4/4 count, scroll to building feedback and suggestion evidence, then return to compact summary; explicit feedback denominator is displayed separately | PASS |
| Time windows | Real Today / 30 days / 7 days taps change the selected window label. Synthetic boundary tests separately prove older/future records are excluded; this current demo journal shares the same day | PASS |
| Optional structured metrics | Recent patterns tap reveals retained per-style counts and evidence links after the summary | PASS |
| No duplicate or changed outcomes | Full serialized relay outcome array remained identical before/after summary navigation and final HAP reinstall; 45 records, completed session still 5/5 | PASS |
| Local/no cloud dependency | Source inspection: summarizer imports only local metric model and existing protocol types/validation; no HTTP/provider calls, keys, mutable store or command API. Host engine runs with unavailable Network mock. Existing local Windows compact relay is unchanged | PASS by code/host verification; not a packet-capture claim |
| Runtime log | Final Phone process log had no Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches | PASS within captured scope |
| Insufficient-data UI on cleared device | Engine output tested with fewer than three outcomes (no suggestion/evidence); saved emulator history was deliberately preserved, so empty-journal native UI was not exercised | NOT RUN on device |
| Physical-device accessibility / five-second comprehension | No physical device or parent usability study was run | NOT RUN |

Evidence remains ignored in artifacts/parent-summary-* (source snapshot, host output, layouts, screenshots, build/log files). Test fixtures are synthetic unit inputs; the on-device journal is real development/demo interaction history, not a recruited child study. New tests are included in `scripts/build.ps1 -RunChecks`. Broader unrelated backend/game tests were not rerun. Actual rules/limitations are in ACTIVITY_INSIGHTS.md; historical results below retain their original scope.

# Tablet Daily Adventure return verification - 2026-10-04

The bounded ending now includes an immediately available **Back to World** button. Returning changes the scene to Home Base and saves/syncs it; it retains ended/session identity, slots, results, daily completion and decorations. Completed-session portal taps cannot restart the zero-budget adventure. A parent can explicitly start a separate session through the existing controls.

Build commands: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Module tventry` and `-Module entry`. Both finished BUILD SUCCESSFUL with exit 0 using API 21. Existing exception-handling warnings and absent-signing warnings remain. Tablet unsigned HAP: `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`, SHA256 `C4F959843F0FE4C5BD79C4CA11F36646113B55FA7A64A4B14EB44154F9D97255`. Phone regression HAP SHA256: `F623106A47A113E5B12A07D5F0C63997D0930A378BA7AA66163BCFC241AED104`. Unsigned development packages are not signed releases.

| Check | Actual verification | Status |
|---|---|---|
| Complete final activity | Existing Tablet API 21: Phone started 15-minute Balanced session; actual bridge placements, two memory signals, foreground movement + Done, garden planting + Done and final story completed; Continue adventure produced healthy completion screen | PASS |
| Clear completion action | Real ending screenshot/layout shows visible Back to World under family-break text | PASS |
| Return to World | Real HDC tap opened Home Base, with no activity automatically started | PASS |
| Progress preservation | Discoveries remained 29 and existing garden gifts remained 1 before/after return and Tablet process restart. This date already had a daily gift; a second same-day gift was not expected | PASS |
| No duplicate completion | Relay had 45 records before and after return, portal tap, polling and restart; session identity stayed the same and completion remained 5/5 | PASS |
| Phone completed state | Phone API 21 displayed Session complete / 5 of 5 before and after return; actual View Summary tap opened Activity Insights | PASS |
| Persisted return | Force-stop/relaunch Tablet preserved Home Base, ended state, 5/5 and reward | PASS |
| Rule regression | 16 world checks passed using installed SDK TypeScript compiler, including repeated return, ticking, serialization/reload, unchanged results/events/days/reward and incomplete ending without reward | PASS |
| Runtime log | Post-restart Tablet app-PID log contained no Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches; scope is that captured process only | PASS within scope |
| Physical Tablet / screen reader / other sizes | Not exercised in this change | NOT RUN |

Evidence is ignored under artifacts/back-world-*: ending/hub screenshots, native layouts, before/after relay snapshots and runtime log. Phone duration was restored to its original 30 min / Balanced after the test. Historical results below retain their original scope; backend broad suites were not rerun for this native navigation change.

# Compact Parent Home verification - 2026-10-04

Phone-only presentation changes: sessionOptions is rendered only in Parent, actual saved duration/preset summary lives in the status card, insights and Today follow directly, spacing is reduced, and the Home-only decorative footer is omitted. No balance/insight/transport/storage/Tablet game logic changed.

Phone build command: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1`; final BUILD SUCCESSFUL, process exit 0. Final unsigned development HAP: `entry/build/default/outputs/default/entry-default-unsigned.hap`, SHA256 `0790C2B63B9459AFDA2C05473817CC7832D0E09C7FD1C295AE484CBA99A5CC2A`. Actually installed/launched on existing Phone API 21, connected to existing Tablet API 21. Tablet was not modified/rebuilt for this change. Existing broad host/backend suites were not rerun for this UI-only change; older results below are historical.

| Check | Target/API | Actual verification | Status |
|---|---|---|---|
| Home configuration removal | Phone/21 | Final layout has zero duration/preset grid buttons; real 30 min / Balanced summary present | PASS |
| Single Start Session | Phone + Tablet/21 | Final ready layout counted exactly one Button labelled Start Session; no second start CTA in that state | PASS |
| Primary Start Session | Both/21 | Actual tap opened Tablet Bridge, Phone showed 30-minute maximum and 0/9; End still worked | PASS |
| Change settings navigation | Phone/21 | Home link opened Parent on initial and final HAP | PASS |
| Saved summary | Phone/21 | Changed to 15 min/More Learning; Home showed those values; restored original 30/Balanced | PASS |
| Retained Parent controls | Phone/21 | Four duration buttons/four presets, memory 2-5, Custom, Exit and technical info visible; Custom opened saved 35/30/30 sliders | PASS |
| Child & Safety Settings | Phone/21 | Renamed entry opened unchanged profile route with saved interests/age/duration/category controls | PASS |
| Insight/Today hierarchy | Phone/21 | Actual screenshots show What We Noticed immediately below status/action card, Today below insight | PASS |
| Today not covered by navigation | Phone/21 | Final ready screenshot shows full card; View history bottom=2146px, navigation Home column starts=2538px on 1316x2832 display | PASS |
| App log | Phone/21 | Current app-PID log had zero Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches | PASS within captured scope |
| Small physical screens / large fonts / screen readers | Physical Phone | Not run; vertical scrolling remains available above navigation | NOT RUN |

Evidence stays ignored under artifacts/: home-summary-build-final.txt, home-summary-final-ready.jpeg/json, home-summary-final-parent/running layouts, home-summary-changed/custom/child-safety layouts and home-summary-runtime.txt. These are HDC runtime touches/screenshots, not a human usability study. Test sessions were intentionally ended and are not falsely marked complete.

---

# Official submission audit validation - 2026-10-04

This audit adds documentation and build/hygiene tooling, not product features. App source, Tablet gameplay, protocol and persistence schemas are unchanged. Older statements about unavailable competition rules describe their original sessions; the official challenge/README have now been read and mapped in COMPLIANCE_MATRIX.

## Fresh builds and source-only reproducibility

Source-only `git archive` at **b699764** was expanded to an ignored isolated directory. Before restoration it had no oh_modules, node_modules, build outputs or local.properties. DevEco OHPM `install --all` restored native dependencies; system Node `npm ci` restored backend dependencies. Both source-only HAP builds succeeded; 87 native host checks and 23 backend tests passed. This uses existing installed DevEco/SDK/registry/user tool caches, not a fresh Windows/SDK installation. Byte-identical packages were not asserted; generated metadata/path differences are possible.

The current working project was then built with the new optional **-Clean** flag for both modules; both reported BUILD SUCCESSFUL and new output file timestamps. Compiler exception-handling/signing warnings remain nonfatal. No SDK/signing configuration was changed. Current 87 native checks passed again; count 87+23 = **110 distinct automated checks**, not a doubled count for repeated runs.

| Artifact | Current checked output | SHA256 |
|---|---|---|
| Phone unsigned HAP | entry/build/default/outputs/default/entry-default-unsigned.hap | 64FE75CE3EE5D8C2FFC09D4FAC34A9BCF4D737C5B6F4520B8956E509D9F42822 |
| Tablet unsigned HAP | tventry/build/tablet/outputs/default/tventry-default-unsigned.hap | 17C1408B310651A0B7F784A4143BB7B1E2154A99AE1AA15211ED7A22BC26E962 |

Final incremental-command verification exposed a PowerShell single-element splat issue in the new helper. It was corrected with an explicit string[] task array; Phone and Tablet incremental scripts then both returned exit code 0 and BUILD SUCCESSFUL. Those builds repackaged unchanged app sources; the final hashes above replace the earlier clean-build hashes (Phone 29BEE49B..., Tablet 2D6E047B...). The final packages were reinstalled and launch/connection/start/pause/resume/next/end smoke was repeated. Full Bridge/Memory/control/disconnect evidence below was executed on the preceding clean packages of identical app source, not claimed as a second gameplay replay.

Both freshly generated packages were actually installed and launched through HDC on API 21 Phone 127.0.0.1:5555 and Tablet 127.0.0.1:5557. These are HDC IDs, not relay endpoints. Runtime uses guest gateway http://10.0.2.2:18080, family-demo and the existing Windows backend. No signed release/physical-device installation is claimed.

## Required-path evidence matrix

PASS is scoped to executed current or explicitly historical tests. All gameplay source is unchanged by this audit; historical evidence is retained rather than claimed as replayed today.

| Test | Target | API | Steps / evidence scope | Expected | Actual | Status |
|---|---|---|---|---|---|---|
| Phone launch | Phone | 21 | Current fresh HAP install, force-stop/start, layout | Parent dashboard loads | Connected dashboard and saved insight counts | PASS |
| Tablet launch / Child Mode | Tablet | 21 | Current fresh HAP install/start; Phone mode toggle | Native world visible | Pico hub/scene, saved discoveries and garden gift | PASS |
| Tablet connection | Both | 21 | Existing relay, inspect Phone and Tablet | Real Connected state | Phone Connected, Tablet Parent connected | PASS |
| Start / Exit Child Mode | Both | 21 | Current Parent Exit; Home Start; wait actual state | Correct inactive/active world status | Ready/Start Child Mode -> Active/Start Session | PASS |
| Start Session | Both | 21 | Current Home Start Session, saved 30-minute balanced settings | Tablet receives planned session | Bridge mission, 30 min maximum, 0/9 | PASS |
| Pause | Both | 21 | Current Phone Pause | Tablet pause overlay and Resume-only context | Both showed Adventure paused | PASS |
| Resume | Both | 21 | Current Phone Resume | Tablet resumes; contextual controls return | Pause/Next/End returned | PASS |
| Next | Both | 21 | Current Phone Next after two genuine completed games | Advance with skipped outcome | Copy Pico -> Garden; count stayed 2/9 | PASS |
| End | Both | 21 | Current End Session | Safe ending, not all-completed claim | Session ended, 2/9; Summary/New Session | PASS |
| Parent Insights / evidence | Phone | 21 | Current View Summary and Why am I seeing this? | Actual outcome/retry/feedback evidence | Bridge/Memory rows and recorded per-result evidence visible | PASS |
| Session/activity history | Phone | 21 | Current saved summaries/legacy record view; prior history scroll | Preserve separate histories | Actual compact counts; old parent journal total 20/today 14 retained | PASS |
| Pico/world interaction | Tablet | 21 | Prior recorded world test below | Tap reaction/original scene | Actual reaction and screenshots recorded; not rerun in this audit | PASS (prior scope) |
| Dino Bridge Builder | Tablet | 21 | Current invalid stone-to-Pico drag, Try again, three correct drags | Retry then environmental success | Native retry, crossing/completion, Loved it; one new outcome | PASS |
| Robot Memory Repair | Tablet | 21 | Current preview, Blue then Red, Continue | Restore robot and save outcome | Completed; Phone reached 2/9 | PASS (two signals) |
| Animal Rescue | Tablet | 21 | Prior actual wrong/correct habitat sequence below | Correct placement after retry | Native three-animal completion after hit-test fix; not rerun here | PASS (prior scope) |
| Movement | Tablet | 21 | Prior full Copy Pico/Number Move; current Copy Pico open | Timer/child confirmation, no surveillance | Prior true Done completion; current timer displayed then intentionally skipped by Next | PASS (prior completion; current open/skip) |
| Educational/native video | Tablet | 21 | Prior finite adventure and counting clip tests below | Video plays and returns on finish | Actual playback/onFinish recorded; not rerun here | PASS (prior scope) |
| Child feedback | Tablet / Phone | 21 | Current Loved it after Bridge, then sync | Optional feedback attached to same outcome | Phone evidence showed liked, attempts=4/retries=1 | PASS |
| Daily Adventure complete | Both | 21 | Previous UI refinement's genuine five-mission chain | Natural 5/5 and persistent reward | 5/5 recorded; today's smoke intentionally ended 2/9, not a completion pass | PASS (prior scope) |
| Progress persistence | Both | 21 | Current app restart; inspect summaries/gift; prior settings/custom restart | Existing journal survives | Tablet discoveries/gift and Phone insights/20 old completions retained | PASS within observed data |
| Phone -> Tablet commands | Both | 21 | Current seven controls above | Actual Tablet acknowledgement | Mode/mission/pause/ending matched | PASS |
| Tablet -> Phone results | Both | 21 | Current Bridge/Memory complete | Compact counts update | Phone 2/9; actual feedback/evidence updated | PASS |
| Disconnect | Both | 21 | Current force-stop Tablet, wait heartbeat expiry | Phone shows disconnected | Reconnect-only state; no stale session controls | PASS |
| Reconnect | Both | 21 | Current Tablet relaunch, wait status | Connected and saved results restored | Connected, retained ended session | PASS |
| Duplicate completion prevention | Both / host | 21 | Current periodic sync/relaunch; prior repeat-click and host checks | Stable IDs/counts | 36 results/36 unique before and after relaunch; no extra records | PASS in tested scope |
| Phone HAP | Build | 21 | Current -Clean -RunChecks | Fresh package and checks | BUILD SUCCESSFUL, 87 host checks | PASS |
| Tablet HAP | Build | 21 | Current -Clean -Module tventry | Fresh package | BUILD SUCCESSFUL | PASS |
| Runtime crash signatures | Phone | 21 | Current app-PID hilog after paths | No uncaught failures | Zero Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled matches | PASS within captured log |
| API 20 / physical signing / live AI / widget hosting / full long windows / accessibility study | Untested targets | 20 or physical | Not performed | Requires additional environment/review | No evidence produced | NOT RUN |
| Recorded submission demonstration | Windows | N/A | Script prepared, no recording UI driven | Saved/reviewed video | Not produced | NOT RUN |

Evidence stays ignored under artifacts/: compliance-phone/tablet-final.txt, clean-audit-*-build logs, clean-audit-source backend restoration/tests, compliance-deploy.txt, compliance-*.json/jpeg layouts/screens and compliance-phone-runtime.txt. At the disconnect/reconnect check there were 36 bounded outcomes, including intentional skips (the later final-package smoke added further intentional test skips); these are not real child-study data. The actual 30-minute maximum window was not allowed to fully elapse.

## Repository/reproduction review

Unauthenticated GitHub metadata returned private=false for the source repository. `.gitignore` excludes keys/env/signing files, local config, dependencies, artifacts/caches and HAPs; committed blank backend/.env.example and required authored demo assets remain. The tracked-file scan prints only paths/rule names and currently finds no recognized secrets/user-specific absolute paths/forbidden outputs. This is not an exhaustive history/security or personal-data audit.

README referenced source paths, four navigation entry points, dependencies, build/install/start commands and actual HAP paths were checked. Vendor tool installation and physical signing are documented prerequisites, not hidden configuration. Missing submission recording, rights/license decisions and final platform upload remain visible in SUBMISSION_CHECKLIST.

---

# Parent Phone UI verification - 2026-10-04

This iteration changed only Phone UI/navigation. Tablet sources, backend protocol, persisted schemas and balance/insight engines were not modified. Actual HDC UITest touch input, UI layouts, screenshots and live relay state were used on the already running API 21 Phone and Tablet emulators. This is executed emulator runtime verification, not a human usability study.

Phone build: `powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -RunChecks` built successfully and passed **87** existing domain/work/game/world/service/transport checks. Backend tests were not rerun for this UI-only change; older 110-check evidence below belongs to the previous iteration. Subsequent UI corrections were rebuilt successfully. Final Phone artifact was installed and launched:

`entry/build/default/outputs/default/entry-default-unsigned.hap`

SHA256: `A373579F950BFD931524389AC42015D039D66E7818AFD43679577E0CC97A5388`.

Unsigned development package; emulator installation succeeded. No signing or SDK changes. Tablet package/code was retained, not rebuilt for this task.

| Test | Target / API | Steps | Expected | Actual | Status |
|---|---|---|---|---|---|
| Phone launch / clean Home | Phone / 21 | Install current HAP, launch, inspect layout/screenshot | Status and contextual CTA; no large legacy entry stack or technical panel | Header/status/compact choices/real insight/today; duplicate header and clipped preset text corrected | PASS |
| Disconnected | Phone + Tablet / 21 | Force-stop Tablet; wait heartbeat expiry | Reconnect only, no session controls | Disconnected, unavailable Child Mode, Reconnect | PASS |
| Reconnect | Both / 21 | Tap Reconnect; restart existing Tablet app | Real Connected state returns | Connected status restored from Tablet | PASS |
| Connected, Child Mode inactive | Both / 21 | Parent > Exit Child Mode, then Home | Start Child Mode only | Child Mode Ready; Start Child Mode; no Pause/Resume/Next/End | PASS |
| Child Mode active | Both / 21 | Home > Start Child Mode, await poll | Start Session only | Ready for today's adventure; Start Session | PASS |
| Session running | Both / 21 | Start Session | Current mission/time/count; Pause/Next/End only | Actual Robot/Bridge missions and 0/5; no Start/Resume/Exit controls | PASS |
| Session paused | Both / 21 | Pause, wait for Tablet state | Adventure paused; Resume/End only | Correct paused card and controls | PASS |
| Resume / Next | Both / 21 | Resume, then Next | Return to running; Tablet advances mission | Pause/Next returned; Robot moved to Bridge, skip remained a skip | PASS |
| Early End | Both / 21 | End Session before completion | Summary/new-session actions; no false completion wording | Final HAP says Session ended, 0/5; View Summary and Start New Session | PASS |
| Natural completion | Both / 21 | Final HAP > Start New Session; actually play Bridge, Memory, child-confirmed movement, Garden, native video; Continue after each | Completed status, 5/5 and summary action | Session complete, 5/5, View Summary; no fake Next-to-complete test | PASS |
| Summary / evidence | Phone / 21 | View Summary, Why am I seeing this? | Dedicated Insights and actual result evidence | Saved completion/skips, attempts/retries/duration/feedback visible | PASS |
| Four navigation tabs | Phone / 21 | Tap Home, Activities, Insights, Parent | Dedicated content and selected tab | All four opened; old Progress route preserved separately | PASS |
| Video and settings retained | Phone / 21 | Activities > Open Video Library; Parent > Parent Settings | Existing content/profile routes still open | Existing video/game page and saved Movement/Nature profile opened | PASS |
| Runtime logs | Phone / 21 | Inspect current app-PID hilog after navigation | No uncaught app errors | Zero matches for Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled | PASS |
| Human usability / small physical device / accessibility | Physical Phone | Adult usability, large fonts, screen reader | Readable/usable | Not performed | NOT RUN |

Local evidence is intentionally ignored under artifacts/: parent-cleanup-home-final.jpeg, parent-cleanup-completed.jpeg; parent-cleanup-running/paused/next/ended/disconnected/reconnected/inactive/activities/insights/parent/evidence/settings layouts; daily mission layouts and parent-cleanup-runtime.txt. Test records are development inputs, not data from children. The 15-minute adventure is a maximum window; the genuine short missions completed sooner. One locked-emulator UITest attempt was interrupted, unlocked and repeated; it is not a PASS. Polling acknowledgement is asynchronous: wait for the actual state rather than assuming an immediate button tap changed Tablet state.

---

# Current Tablet-child / Phone-parent verification

Development session: 2026-10-03; emulator local clocks displayed 2026-10-04. Current evidence supersedes older architectural descriptions below; historical tests are retained and are not reclassified as new world tests.

## Environment and test method

Actual native ArkTS/ArkUI project, existing compatible/target API 21 products and empty signing configuration. Installed DevEco Studio 6.0.1.251 / SDK 6.0.1.112. HDC detected Phone 127.0.0.1:5555 and Tablet 127.0.0.1:5557; both returned API 21 and the deployment helper checked Phone/Tablet device types. Both unsigned HAPs were actually installed and launched. UI gameplay was driven with HDC UITest real touches/pans, checked with layouts, screenshots, relay outcomes and app logs. This is emulator runtime testing, not Preview, physical-device testing or a study involving children.

## Actual Tablet gameplay results

| Core mission | Required explicit status | Actual observed interaction |
|---|---|---|
| Dino Bridge Builder | IMPLEMENTED AND PLAYED ON TABLET | Dragged a stone to Pico (invalid), Try again, dragged all three stones into their targets, bridge repaired and characters crossed, Loved it/Just right, one completion saved |
| Robot Memory Repair | IMPLEMENTED AND PLAYED ON TABLET | Screenshot showed Blue light glowing during preview; native panel group disabled while previewing. Red first was invalid, retry, Blue then Red activated Robot; Loved it/Tricky saved. Longer sequences have pure-rule coverage, not an exhaustive native playthrough |
| Animal Rescue World | IMPLEMENTED AND PLAYED ON TABLET | Dolphin to Land rejected; retry and Water; Lion to Land; Whale to Water; visible relocation and completion. A placed-animal hit-test bug was fixed and the new HAP passed the previously blocked final habitat tap |
| Star Collector | IMPLEMENTED AND PLAYED ON TABLET | Amber star rejected, retry, all five actual blue stars collected; gate changed and completion saved |
| Copy Pico | IMPLEMENTED AND PLAYED ON TABLET | Animated character/10-second display, Done initially gated, More time restarted interval, waited and tapped Done, child-confirmed result saved |
| Number Move | IMPLEMENTED AND PLAYED ON TABLET | Amber crystal rejected, retry, four blue crystals collected, actual transition to 10-second marching demonstration, waited then Done and saved |

Additional runtime passes: Rocket wrong-shape target/retry/three correct drags/launch; Garden three actual flower placements and finish without correctness scoring; Calm cloud touch/finish without scoring; Storybook native original counting video played (app log confirmed native start), ended and returned to the world, then Continue saved WATCHING result. No live Gemini/Huawei generated video was claimed.

Pico tap reaction and remote ENTER_CHILD_MODE were actually observed, with Phone showing ACTIVE and Tablet world replacing the technical receiver screen. Original SVG scenes were visually inspected. Full animation-frame timing, child usability, screen-reader speech and accessibility certification remain unverified.

## Actual compact synchronization and disconnect

Stopped only the owned Windows Node relay while Tablet Rocket was active. The Tablet showed Parent connection paused, accepted three local drags and completed/saved the mission. Restarted the relay, observed automatic reconnect, and recovered 14 summary records with 14 unique IDs. Repeated synchronization preserved that count. Raw object logs were absent from the Phone relay response.

Phone actually showed six completed core activities in Tablet history, actual attempts/retries/durations/feedback and sample-protected style counts in Parent Insights. Initial evidence-button content was below the viewport; a dedicated evidence view was added for immediate inspection. Interrupted drag automation used an incorrect temporary coordinate parser and also created skipped outcomes; those are retained as test records, not counted as successful games or real child preferences. The corrected parser drove the passing bridge test.

## Final installed-HAP control, ending and recovery checks

**Passed actual remote controls:** EXIT_CHILD_MODE made Phone INACTIVE and returned Tablet to the receiver screen; ENTER_CHILD_MODE restored the child world. START_SESSION created a 30-minute-budget, nine-mission balanced story. PAUSE_SESSION showed Adventure paused and the budget stayed exactly 1769 seconds across the check; RESUME_SESSION continued. NEXT_ACTIVITY skipped the current Bridge and opened Robot Memory; END_SESSION showed the child-safe ending and Phone Session ended / 0:00. These are observed Tablet reactions, not HTTP-only success claims.

**Passed finite Daily Adventure:** selected Balanced / 15 min; child chose Robot then returned to Forest before their first attempt, without touching Phone for gameplay. Completed Bridge, Memory, real Copy Pico timer/Done, Garden and native allocated video. Five genuine completed results matched five planned missions. Tablet displayed Today's Adventure Complete and one garden gift; Phone showed 5/5 and Session ended. It finished earlier than the maximum window; fifteen real minutes did not elapse. No Skip/Next was used to simulate completion in this adventure.

**Passed persistence/evidence:** force-stopped and relaunched both apps. Tablet retained the completion ending, 16 completed discoveries and one garden gift. Phone retained all 21 summaries (16 completed), selected 15-minute window and Custom configuration. Actually moved the Custom MOVE slider from 20% to 35%; after restart it still displayed 35%, LEARN 30%, passive 30%. Returned to Balanced afterward. The dedicated evidence view displayed individual Bridge/Rocket completed/skipped outcomes, actual attempts/retries/seconds and explicit feedback. Earlier Phone Progress retained total 20 / today 14, and profile retained selected Movement/Nature; Tablet summaries did not inflate that parent-confirmed journal.

**Passed final background/Skip behavior:** installed the final Tablet HAP, opened Copy Pico, sent the Tablet to its launcher for twelve seconds and resumed the app. It showed Adventure paused and still ten movement seconds; no background movement was invented. Parent Resume then a real foreground interval enabled Done. A second Copy mission used Skip and Not for me; its synchronized result was completed=false, skipped=true, feedback=disliked and movementConfirmed=false. Final relay contained 23 records, 23 unique IDs, 17 completed; both apps were left connected with Child Mode active at the hub and one persisted gift.

**Runtime:** captured Phone and Tablet app-PID logs after restart had zero matches for Uncaught/JsError/FATAL/TypeError/ReferenceError/Unhandled. The final Tablet background/Skip UI flow also completed without a process crash. Expected handled network errors occurred during the deliberate relay outage. One temporary automation attempt to tap Balanced while it was above the viewport failed; scrolling to the top and repeating succeeded. No app bug or successful native test is inferred from that helper failure.

## Final build/check artifacts

- Phone native build succeeded; SHA-256 `DE161A3E9BDB1B33BE3A5DEB8F70B3CBD325DD2CC794994005E581E27EF0D842`.
- Tablet native build succeeded; SHA-256 `30CBB042827D37FFC0A27405A776725B1C52A89BF17F1F9ABE8D2BBC828051D4`.
- Paths: `entry/build/default/outputs/default/entry-default-unsigned.hap`, `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`.
- **87 host checks passed**: domain 14, Work/balance/insights 17, fallback games/Journey 10, Tablet world 14, mocked platform/storage 18, TV/AI 7, emulator clients 7.
- **23 backend checks passed**, including actual local HTTP compact commands, malformed input and 300-result synchronization. **110 automated checks total**, zero failed in the final suites. Cloud HTTP is mocked where explicitly labelled.
- Both unsigned HAPs were installed and launched on the actual API 21 emulators. No signed physical-device/release artifact was generated. Build logs/screenshots/raw runtime captures stay ignored under artifacts and are not uploaded with child/test journals.

## Short human follow-up checklist

| Not verified | Minimum follow-up |
|---|---|
| Physical devices/signing | Configure appropriate signing and use a reachable, secured production transport; emulator 10.0.2.2 is not a physical-device endpoint |
| Full runtime variants | Run 15/30/45/60 real-time windows, other presets/ages, native 4/5-signal memory and 5/10-minute legacy expiry variants |
| Accessibility | Inspect speech/focus, large fonts, smaller Tablet/Phone sizes and reduced-motion behavior |
| Live providers/widget | Use owner-controlled backend credentials and review a real result; host the FormKit widget separately |
| Submission recording/rules | Record actual interactions via DEMO_SCRIPT, review starter-asset rights and obtain the competition's actual RULES/CRITERIA |

## Automated checks and limitations

Current suites cover domain/settings/journal, balanced plans and passive caps, descriptive behavior/sample safeguards, all fallback games, all world transitions including 2/3/4/5 memory signals, finite/deduplicated progress, style recommendation safeguards, chunked stores/failed flush/corrupt nested data, notification authorization/failures, old relay and new compact HTTP endpoints. Large 300-result actual HTTP synchronization is covered. Platform and cloud-service mocks are separate from device tests.

The temporary root npm invocation failed because the ArkTS root has no package.json; rerunning npm test in backend passed. Native compile errors discovered during conversion were fixed before successful builds. Signing/throw-analysis warnings remain; unsigned emulator acceptance is not a signed release claim.

Not verified: physical Phone/Tablet installation, credentialed Gemini/Huawei success, FormKit hosting, reliable background notifications, full wall-clock 15/30/45/60 windows and every preset/age/video combination, 4/5-signal native playthrough, large-font/smaller-device layout, screen-reader/reduced-motion behavior, release performance/security or educational effectiveness. No RULES/CRITERIA file was found, so competition compliance/score is not certified.

## Retained earlier evidence

### Testing evidence

## Homepage UI and accessibility polish - 2026-10-03

Scope is Phone presentation only: existing session/provider/recovery/history/notification models and Phone/Tablet transport/configuration remain unchanged. Reused original SVGs; no new runtime dependency or asset generation.

**Passed builds/checks:** Phone and Tablet native unsigned HAPs rebuilt with existing API 21 configuration. Phone SHA-256 `66C6769E423644982D3CCBF79136FDCB4C580590E27C3B456020B5802D337256`; Tablet SHA-256 `D36258D502B456CAA01C0F595F5BEE6484DACD2ED03617301A2B84C0B870C519`. Paths: entry/build/default/outputs/default/entry-default-unsigned.hap and tventry/build/tablet/outputs/default/tventry-default-unsigned.hap. All 47 ArkTS checks and 18 backend checks passed, total 65. Mocked services/cloud HTTP are separate from actual device evidence. Existing throw/signing warnings remain; not a signed release.

**Actual Phone API 21 observations:** installed the new HAP without clearing data. Captured and visually inspected 1316x2832 initial/one-scroll screenshots: first viewport includes hero/CTA, all four categories and the first recommendation's title; one normal swipe exposes both recommended cards and Today's progress/counts/bar. Bottom navigation labels fit, selected tab has tinted fill/border/bold label. CREATE discovery screenshot shows Imagine a Tiny World fully readable. No major observed overlaps or clipped buttons/category/navigation text at this tested viewport. Content cut by the viewport edge scrolls normally; this is not hidden overflow.

**Navigation/regression:** tapped MOVE, LEARN, CREATE and CALM from Home; correct catalog filters rendered. Parent settings retained age/interests/type values; Progress retained total 11 and prior Demo/normal records. Hero CTA opened work setup; 15/30/45/60 buttons displayed respective planned category totals and fifteen-minute preparation opened Why this activity/age/adult notices. Actual no-key Gemini request returned visible Built-in fallback. These are selection/start-path checks, not full elapsed work-window tests.

**Current content/Tablet regression:** actual Gemini and Huawei no-key requests both produced clear Built-in fallback notices. Saved My Video restored the original eight-second My family video with a Not AI generated label; Built-in selection restored Penguin Walk and no-AI notice. Play on Large Screen connected to the existing API 21 Tablet receiver through the unchanged gateway/room. Phone started a normal five-minute work entry and its controls changed actual Tablet Video PLAYING -> PAUSED -> PLAYING with synchronized countdown. Tablet source/UI code was unchanged; the new Tablet package was built, while this regression used the previously installed unchanged receiver.

**Current completion/recovery:** skipped the first normal entry without saving a completion; the second LEARN entry ran in labelled ten-second Demo Mode. Foreground expiry reported system notification submission (notification-center content was not reinspected). Parent confirmation advanced to CREATE. After force-stop/relaunch, Return to work session showed the retained next entry, five remaining planned minutes and 1/3 confirmed. Early end/journal retained earlier records and the single new Demo record, total 11 -> 12 / today 5 -> 6. A final restart left the Phone on the polished Home. Captured app logs contained no Uncaught/JsError/Error-name/FATAL signatures. Full real-time windows and every provider combination were not repeated.

**Color/touch audit:** computed 18 explicitly sampled homepage text/background combinations using sRGB relative luminance; ratios 5.66:1 to 11.08:1. Primary white-on-green 5.66:1; category label pairs 6.53:1 or higher. This is a bounded color check, not a full WCAG certification. Navigation surface reduced from 76 to 60vp while each item retains a 52vp target; primary button 50vp and category cards at least 90vp. States use icon/text/fill/border, not color alone. Grouped descriptions explicitly identify review-before-start and selected navigation. Screen-reader speech/focus order were not tested.

**Feedback:** 120ms touch-scale feedback is implemented on hero/category/activity cards; primary button uses native state effect; navigation highlight transition is 120ms and badge progress 160ms. Actual taps/routes passed, but animation-frame timing and reduced-motion behavior were not instrumented. Today count and existing Family Explorer badge threshold are real data; no activity/learning minutes or supervision-reduction claim is introduced.

**Remaining visual/accessibility checks:** alternate smaller logical Phone sizes, enlarged system fonts, dark-mode transition, portrait/landscape variants, screen-reader focus/speech and formal accessibility audit are not verified. Observed screenshot readability does not substitute for these checks. Human check: increase system font size, browse Home/Activities/Progress/Parent, ensure every target remains reachable by scrolling and exercise screen reader. Physical-device/cloud/full-window checks retain their earlier limits.


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

- No signed release, physical-phone run or screen recording is available. The development emulator accepted the unsigned HAP; the latest local Phone configuration additionally builds a signed debug artifact, as recorded above.
- Notification and widget delivery are controlled by the OS. No reliable background reminder is implemented.
- Unfinished sessions are in-memory; process kill cancels them implicitly. Wall-clock adjustment can change countdown behavior.
- Demo completions count towards totals; imported legacy totals include only reconstructible known history/counts.
- Corrupt snapshots reset to defaults; there is no backup-repair/export workflow. Uninstall or clearing app data deletes local state.
- Optional service authenticity, production authentication, privacy policy and deployment remain backend work.
- Starter artwork rights and competition compliance require review before public submission.
