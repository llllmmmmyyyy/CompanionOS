# Submission checklist

This checklist reports implementation and observed evidence. It is not a competition compliance certificate.

| Deliverable / requirement | Status | Evidence or next action |
|---|---|---|
| Illustrated Phone experience | Implemented and emulator inspected | Original hero/category SVGs, four-tab navigation, activity cards; larger-font/smaller-phone review remains pending |
| Parent Work Session / profile | Implemented and emulator tested | 15-minute plan completed with labelled Demo activities; 30-minute plan pause/restart/resume/skip/end; see TESTING for exact limits |
| Independent TV + relay backend | Built and emulator tested | TV minimum API 19, Phone API 21; real video playback, controls, reconnect and notification observed |
| Four content sources | Implemented | Gemini preserved, Huawei adapters, unchanged Built-in, real system MP4 import/title/duration/restart; see latest TESTING evidence |
| Live Gemini/Veo and Huawei generation | Unverified | Backend-only credentials/model access required; cloud HTTP tests are mocks |
| Native HarmonyOS Phone project, API 20+ | Implemented and built | Existing Stage-mode template; compatible/target API 21 |
| Four clear page states | Implemented and built | Home, Parent Settings, Activity, Progress in `Index.ets` |
| Offline curated activities | Implemented and built | Penguin Walk, Animal Sounds, Butterfly Stretch |
| Settings and records persistence | Emulator restart checks passed | Saved settings and three records (two Demo, one normal) restored after force-stop/relaunch |
| Countdown, cancellation, duplicate protection | Emulator checks passed for tested cases | Demo and full normal 3-minute completion, normal 5-minute start/cancel, confirmation double-click; full 5/10-minute expiry variants pending |
| Real notification API | Emulator denial and actual foreground delivery passed | Actual notification-center content inspected; reliable background reminders not implemented |
| Desktop widget and launch action | Implemented and built | Launcher addition, tap and update checks pending |
| AI adapter and honest offline fallback | Implemented; mocks passed | No live AI backend or provider connection verified |
| Source and English docs | Prepared and committed by development stages | Repository: https://github.com/llllmmmmyyyy/CompanionOS |
| Native HAP | Unsigned artifact built | `entry/build/default/outputs/default/entry-default-unsigned.hap`; sign before installation/distribution |
| Signed installation-ready HAP | Pending | Configure debug/release signing as appropriate in DevEco; never commit credentials |
| Two-minute recording | Pending | Follow `DEMO_SCRIPT.md`; no video has been generated |
| Third-party rights | Partially inventoried | Development dependency licenses confirmed; inherited starter artwork rights need review |
| HackYeah RULES / CRITERIA | Not available in workspace | Obtain actual published rules and assess required platform capabilities, licenses, deliverables and eligibility |
| Final competition upload | Not performed | Verify real submission channel/deadline and upload actual reviewed deliverables |

No background alarm reliability, live AI connection, untested device cases, recording or final competition acceptance is claimed. Actual API 21 emulator tests are recorded in `TESTING.md`; building or Previewing alone is not device verification. The development emulator accepted the unsigned HAP, but a signed release and physical-phone installation remain unverified.
