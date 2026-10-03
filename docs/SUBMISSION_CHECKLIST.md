# Submission checklist

This checklist reports implementation and observed evidence. It is not a competition compliance certificate.

| Deliverable / requirement | Status | Evidence or next action |
|---|---|---|
| Native HarmonyOS Phone project, API 20+ | Implemented and built | Existing Stage-mode template; compatible/target API 21 |
| Four clear page states | Implemented and built | Home, Parent Settings, Activity, Progress in `Index.ets` |
| Offline curated activities | Implemented and built | Penguin Walk, Animal Sounds, Butterfly Stretch |
| Settings and records persistence | Implemented; host mocks passed | Actual device restart/durability checks pending |
| Countdown, cancellation, duplicate protection | Implemented; host logic passed | Normal timing/UI interaction on a device pending |
| Real notification API | Implemented and built; mocks passed | Device permission, delivery and failure checks pending |
| Desktop widget and launch action | Implemented and built | Launcher addition, tap and update checks pending |
| AI adapter and honest offline fallback | Implemented; mocks passed | No live AI backend or provider connection verified |
| Source and English docs | Prepared and committed by development stages | Repository: https://github.com/llllmmmmyyyy/CompanionOS |
| Native HAP | Unsigned artifact built | `entry/build/default/outputs/default/entry-default-unsigned.hap`; sign before installation/distribution |
| Signed installation-ready HAP | Pending | Configure debug/release signing as appropriate in DevEco; never commit credentials |
| Two-minute recording | Pending | Follow `DEMO_SCRIPT.md`; no video has been generated |
| Third-party rights | Partially inventoried | Development dependency licenses confirmed; inherited starter artwork rights need review |
| HackYeah RULES / CRITERIA | Not available in workspace | Obtain actual published rules and assess required platform capabilities, licenses, deliverables and eligibility |
| Final competition upload | Not performed | Verify real submission channel/deadline and upload actual reviewed deliverables |

No background alarm reliability, live AI connection, device pass, recording or final competition acceptance is claimed. Building or Previewing is not device verification. See `TESTING.md` for the exact boundary of automated evidence.
