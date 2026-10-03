# CompanionOS Phone + TV

## Content selection

Phone offers Gemini AI, Huawei AI, Built-in Video and My Video before start. Shared VideoSource carries URI/title/source through the existing protocol; the player uses only its URI regardless of origin. Older messages are converted to Built-in metadata. The original bundled MP4 is unchanged. My Video uses backend caching for separate TV, private offline playback on Phone, and explicit TV fallback when the cache is unavailable. Choosing a provider does not imply successful AI generation.

HDC sometimes omits the TV same-port reverse forward from `fport ls` although its listener works. The helper reports this case and requires actual app connection verification; an exit code alone is not considered success.

One repository contains `entry` (Phone), `tventry` (independent TV entry HAP), `shared` (local protocol HAR) and `backend` (Node/TypeScript relay and generation service). The existing Phone module was extended, not moved or replaced. Phone `default` minimum/target API remains 21; TV product `tv` minimum is API 19 and target/compiler SDK is 21. The TV HAP actually installed and launched on the API 19 TV. API 19 SDK is not claimed to be installed.

## Two experiences

**Demo TV Mode** is the existing landscape simulated receiver inside the Phone, using LocalDemoTvTransport without a backend. **Emulator TV Mode** launches TvAbility in tventry independently and uses EmulatorTvTransport through HTTP. It plays real video with ArkUI Video, or the small original bundled cloud clip when generated URLs are unavailable. That clip is labelled Not AI generated.

Phone owns timer, automatic steps, manual next/previous, pause, cancellation, parent-confirmed completion and Preferences history. TV has no history writes or independent completion timer. Expiry is ready, not completed; COMPLETE follows successful Phone storage. Phone process restart restores settings/history, but does not resurrect an unfinished session. TV restart restores the surviving Phone session from STATE_SYNC.

## Communication

HTTP was chosen because both emulator NetworkKit clients and HDC reverse forwarding were available and actually tested. Phone POSTs bounded full snapshots/commands; TV polls every 500 ms. Requests do not overlap, pending snapshots are coalesced and queues bounded. Relay revisions prevent reapplying unchanged state; the latest snapshot repairs missed intermediate commands. Polling is not frame-accurate video synchronization.

Host backend: `127.0.0.1:8787`. Each emulator uses `127.0.0.1:18080`, forwarded with `hdc -t <target> rport tcp:18080 tcp:8787`. Room `family-demo` is a local demo identifier, not authentication. Observed targets: Phone 5555 / API 21, TV 5557 / API 19 / type tv. Server binds loopback by default; public deployment needs authentication, TLS and authorization.

Six-second heartbeat expiry marks disconnection. TV loss leaves Phone running/history intact. Phone loss pauses video, overlays Connection lost and retains last safe state without completing it. Reconnection restores title, phase, step and media from full state. Foreground polling restarts on foreground; reliable background delivery is not promised.

## TV playback

The 16:9 screen has safe margins, a dominant video surface, large instruction, step progress and small timer. Sources are approved cached HTTPS/backend URLs or the bundled rawfile. Session/step/source changes recreate the surface. PAUSE/RESUME call VideoController; NEXT/PREVIOUS switch clips; CANCEL/COMPLETE stop activity playback. Short clips loop for the step duration. Video failure switches to a static safe visual and reports VIDEO_FAILED; history remains on Phone. Video: PLAYING/PAUSED reflects actual player callbacks.

Connection states: OFFLINE, WAITING, CONNECTING, CONNECTED, DISCONNECTED, ERROR. Presentation covers waiting, buffering, playing, paused, parent-confirmation ready, completed, cancelled and disconnected. No camera, microphone or emotion monitoring.

HarmonyDistributedTvTransport remains a future physical-channel boundary. NearbyTv performs authorized DeviceManager lookup/permission handling; physical pairing and distributed TV communication remain unimplemented/unverified. Working emulator transport does not use distributed APIs.

See [protocol](TV_PROTOCOL.md), [AI architecture](AI_ARCHITECTURE.md) and [test evidence](TESTING.md).
