# Implemented platform capability evidence

This inventory covers real native APIs. Verification is scoped to API 21 development emulators; historical runtime evidence is identified rather than presented as a new test. Build-only implementation is not runtime PASS.

| Capability | Source files | API / module | Device | Verification / demo evidence | Limitation |
|---|---|---|---|---|---|
| Native pages, interaction and animation | entry/src/main/ets/pages/Index.ets, ParentDashboard.ets; tventry/src/main/ets/pages/ChildWorld.ets | ArkUI Stack, PanGesture, animation, component state, accessibility labels | Phone + Tablet API 21 | Actual installed emulator taps/pans, bridge changes, memory panels and remote controls in TESTING | No physical usability or screen-reader certification |
| Native HAP packages and device profiles | build-profile.json5; entry and tventry src/main/module.json5 | Stage UIAbility; Phone/default and Tablet/tablet | Both API 21 | Both HAP builds and HDC installations | Unsigned development HAPs; physical/release signing pending |
| Lifecycle and landscape window | entry/ets/entryability/EntryAbility.ets and tventry/ets/entryability/TvAbility.ets (under src/main); ChildWorld.ets | AbilityKit UIAbility foreground/background; ArkUI window orientation | Both API 21 | Restart/background pause and Tablet landscape observed | No guaranteed background timers or OS kiosk |
| Durable local settings/results | entry/src/main/ets/services/{LocalStore,ParentWorldStore,BehaviorStore,JourneyStore}.ets; tventry/src/main/ets/services/WorldStore.ets | ArkData preferences; double-bank chunked JSON | Both API 21 | Actual settings/result/world-gift restart recovery; mocked malformed/write-failure tests | Bounded histories; corruption fault injection on device not performed |
| Foreground activity notification | entry/src/main/ets/services/Notifications.ets, pages/Index.ets | NotificationKit notificationManager permission request and publish | Phone API 21 | Prior actual denial and notification-center delivery documented in TESTING | Phone fallback foreground expiry only; not Tablet mission notification or reliable background reminder |
| User-selected video import | entry/src/main/ets/services/UserVideoStore.ets | MediaLibraryKit PhotoViewPicker; CoreFileKit fileIo; MediaKit AVMetadataExtractor | Phone API 21 | Earlier real system MP4 picker/import/title/duration/restart evidence in TESTING | Parent-selected files only; no broad library permission; user must check video rights and suitability |
| Native video playback | Index.ets, ChildWorld.ets, TvHome.ets | ArkUI Video, VideoController; MediaKit metadata for import | Both API 21 | Actual bundled video/onFinish return and legacy projection tests | No credentialed provider result verified; imported media is optional |
| Development/demo Phone-Tablet transport | ParentDashboard.ets, ChildWorld.ets; shared/Network.ets; backend/src/world-relay.ts | NetworkKit HTTP polling + Windows Node relay | Both API 21 | Actual commands/results, disconnect/recovery/dedup | Not production distributed-device functionality; no auth/TLS; Windows loopback and emulator gateway only |
| Desktop form/widget | entry/src/main/ets/widget/pages/TodayCard.ets; entry/src/main/ets/widget/TodayFormAbility.ets | FormKit formProvider and native form profile | Phone | Implemented and compiled only; exact paths are inventoried in architecture/testing | Hosting/tap/update NOT RUN; not a verified demo capability |

At least one verified native capability is demonstrated without relying on the unverified widget or cloud AI.

## Permission inventory

Phone requests INTERNET for optional backend/demo HTTP and DISTRIBUTED_DATASYNC for the separately user-triggered NearbyTv authorized-device discovery path (DistributedServiceKit). That discovery code is implemented but native discovery/pairing is NOT VERIFIED and provides no production receiver transport; it is excluded from verified demo claims. Tablet requests INTERNET for compact demo synchronization/video. No camera, microphone or location permissions are requested. PhotoViewPicker grants selected-item access rather than broad library monitoring.
