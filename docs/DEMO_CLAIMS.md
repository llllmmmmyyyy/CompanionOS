# Demo claim verification

VERIFIED means supported within the named emulator/host scope, not production, physical-device or human-child validation. TESTING.md contains historical dates and this audit's current smoke test. Steps refer to DEMO_SCRIPT.md.

| Claim | Implementation evidence | Test evidence | Demo step | Status |
|---|---|---|---|---|
| Distinct native Phone parent and Tablet child apps | entry/src/main/ets/pages/ParentDashboard.ets and tventry/src/main/ets/pages/ChildWorld.ets; two device profiles | Actual API 21 installation/launch | 1-4 | VERIFIED |
| Phone activates Child Mode | Existing ENTER_CHILD_MODE through ParentDashboard/WorldEngine | Actual Phone command and Tablet world acknowledgement | 3-4 | VERIFIED |
| Original animated 2D world/Pico reaction | ChildWorld.ets, native shapes and authored rawfile assets | Actual tap reaction/screenshot in prior world test | 4 | VERIFIED |
| Balanced bounded sessions | SessionBalanceEngine.ets, shared/ChildWorldModel.ets | Pure category allocation tests and genuine five-mission completion | 5 | VERIFIED |
| Dino Bridge is playable, including retry and environment change | WorldEngine.act, ChildWorld.stones/drag | Actual invalid drop, retry, three drags and crossing on API 21 Tablet | 6-9 | VERIFIED |
| Robot sequence can be played | WorldEngine memory transitions/native panels | Actual two-signal preview/ordered input/retry | 10 | VERIFIED (2 signals; not all longer variants) |
| Movement is child-confirmed | WorldEngine movement timer and Done | Actual Copy Pico timer/Done, background pause | 11 | VERIFIED (self-report, not physical exercise validation) |
| Native built-in video returns to world | ChildWorld Video/onFinish and committed MP4 | Actual native playback/finish in finite adventure | 12 | VERIFIED |
| Remote Pause/Resume changes Tablet state | Existing compact command protocol | Actual pause overlay and resume through Phone | 13-15 | VERIFIED |
| Adventure can genuinely finish 5/5 | WorldEngine.next/finish, Phone status | Full native Bridge/Memory/Move/Garden/Video completion | 16 | VERIFIED |
| Progress persists without missed-day punishment | WorldStore results/days/decorations | Actual force-stop restore; pure date/dedup checks | 17 | VERIFIED within tested cases |
| Phone insights are based on recorded outcomes | ParentDashboard recent/styleEvidence | Actual saved results, What We Noticed and evidence views | 18-20 | VERIFIED (descriptive, not causal preference proof) |
| Detailed raw world events stay local | WorldStore and compact world-relay payload | Actual HTTP tests reject oversized/malformed payloads; protocol never streams raw events | 18-20 | VERIFIED by code/tests |
| Real notifications exist in Phone fallback | Notifications.ets | Prior notification-center delivery and denial | Optional extra | VERIFIED historically; not the Tablet mission demo |
| System video picker/import exists | UserVideoStore.ets | Prior actual MP4 import/metadata/restart | Optional extra | VERIFIED historically |
| Credentialed Gemini/Huawei AI generates content | backend provider adapters | Mock provider tests only, no live credential test | Exclude | NOT VERIFIED |
| Desktop widget works on launcher | TodayFormAbility/TodayCard | Build only, hosting not tested | Exclude | NOT VERIFIED |
| Production distributed-device / OS kiosk / reliable background reminders | Not implemented | None | Exclude | UNSUPPORTED |
| Signed release / physical device / API 20 run | No signed release or API 20/physical test | API 21 unsigned emulators only | Exclude | NOT VERIFIED |
| Child learning benefit or clinical measurement | No study/clinical model | None | Exclude | UNSUPPORTED |

The Windows transport is development/demo Phone-Tablet transport. No prerecorded mock UI may be presented as a live game. The actual judged recording remains MISSING until a human saves/reviews/uploads it.
