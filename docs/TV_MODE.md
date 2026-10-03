# CompanionOS Phone + TV

## Content selection

Phone offers Gemini AI, Huawei AI, Built-in Video and My Video before start. Shared VideoSource carries URI/title/source through the existing protocol; the player uses only its URI regardless of origin. Older messages are converted to Built-in metadata. The original bundled MP4 is unchanged. My Video uses backend caching for separate TV, private offline playback on Phone, and explicit TV fallback when the cache is unavailable. Choosing a provider does not imply successful AI generation.

The former HDC reverse-tunnel setup was lost between runs. It is replaced by direct emulator host-gateway networking: both apps use http://10.0.2.2:18080. HDC is used only for installation/device control, not relay communication.

One repository contains `entry` (Phone), `tventry` (independent TV entry HAP), `shared` (local protocol HAR) and `backend` (Node/TypeScript relay and generation service). The existing Phone module was extended, not moved or replaced. Phone `default` minimum/target API remains 21; TV product `tv` minimum is API 19 and target/compiler SDK is 21. The TV HAP actually installed and launched on the API 19 TV. API 19 SDK is not claimed to be installed.

## Two experiences

**Demo TV Mode** is the existing landscape simulated receiver inside the Phone, using LocalDemoTvTransport without a backend. **Emulator TV Mode** launches TvAbility in tventry independently and uses EmulatorTvTransport through HTTP. It plays real video with ArkUI Video, or the small original bundled cloud clip when generated URLs are unavailable. That clip is labelled Not AI generated.

Phone owns timer, automatic steps, manual next/previous, pause, cancellation, parent-confirmed completion and Preferences history. TV has no history writes or independent completion timer. Expiry is ready, not completed; COMPLETE follows successful Phone storage. Phone process restart restores settings/history, but does not resurrect an unfinished session. TV restart restores the surviving Phone session from STATE_SYNC.

## Communication

Both emulator NetworkKit clients reach the same Windows relay over HTTP through gateway 10.0.2.2. Phone POSTs bounded full snapshots/commands; TV polls every 500 ms. Requests do not overlap, pending snapshots are coalesced and queues bounded. Relay revisions prevent reapplying unchanged state; the latest snapshot repairs missed intermediate commands. Polling is not frame-accurate video synchronization.

Windows backend: `127.0.0.1:18080`; both guests use `http://10.0.2.2:18080`, verified through real app requests, not assumed from Android behavior. Both guest route tables reported gateway 10.0.2.2; guest addresses 10.0.2.15 belong to isolated networks and are not used to address each other. Room `family-demo` is a local demo identifier, not authentication. Observed targets: Phone 5555 / API 21, TV 5557 / API 19 / type tv. Start from backend with `npm.cmd run build` then `npm.cmd start`; defaults are PORT=18080, HOST=127.0.0.1. No firewall changes or reverse tunnels are needed for this verified configuration.

TV displays Connecting..., Connected to Windows relay / Waiting for Phone, Connected / Phone online, or Connection failed with native error code/message. Endpoint and room are always visible; failed/disconnected states retain editable settings and Connect. Phone reports the failure reason. Console/hilog tags CompanionTV, CompanionPhoneTV and CompanionRelay identify endpoint, room, connection attempts, successful connections and HTTP/native errors. Logs never contain provider credentials.

Six-second heartbeat expiry marks disconnection. TV loss leaves Phone running/history intact. Phone loss pauses video, overlays Connection lost and retains last safe state without completing it. Reconnection restores title, phase, step and media from full state. Foreground polling restarts on foreground; reliable background delivery is not promised.

## TV playback

The 16:9 screen has safe margins, a dominant video surface, large instruction, step progress and small timer. Sources are approved cached HTTPS/backend URLs or the bundled rawfile. Session/step/source changes recreate the surface. PAUSE/RESUME call VideoController; NEXT/PREVIOUS switch clips; CANCEL/COMPLETE stop activity playback. Short clips loop for the step duration. Video failure switches to a static safe visual and reports VIDEO_FAILED; history remains on Phone. Video: PLAYING/PAUSED reflects actual player callbacks.

Connection states: OFFLINE, WAITING, CONNECTING, CONNECTED, DISCONNECTED, ERROR. Presentation covers waiting, buffering, playing, paused, parent-confirmation ready, completed, cancelled and disconnected. No camera, microphone or emotion monitoring.

HarmonyDistributedTvTransport remains a future physical-channel boundary. NearbyTv performs authorized DeviceManager lookup/permission handling; physical pairing and distributed TV communication remain unimplemented/unverified. Working emulator transport does not use distributed APIs.

See [protocol](TV_PROTOCOL.md), [AI architecture](AI_ARCHITECTURE.md) and [test evidence](TESTING.md).
