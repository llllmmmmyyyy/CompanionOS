<!-- Internal TV/protocol identifiers retained; current companion is Tablet API 21. -->
# Protocol version 1

New senders also include `content: VideoSource` with sourceType GEMINI_AI/HUAWEI_AI/BUILT_IN/USER_VIDEO, URI, title, activityId and optional provider. URI/activityId must match the compatibility snapshot fields; private paths are rejected. Old messages without content are normalized to BUILT_IN. The Tablet player consumes content.uri, while the former videoSource field continues to describe delivery/cache state rather than content provenance. This compatible extension does not require a provider-specific player.

Shared ArkTS HAR contains TvMessage, parser, types, URL validation and bounded HTTP requests. Node relay validates the same wire contract; malformed/unknown messages cannot change Phone history.

```json
{"protocolVersion":1,"type":"START","sessionId":"session-123","activityId":"dino-move","title":"Dino Adventure","stepIndex":0,"totalSteps":3,"instruction":"Count five gentle movements.","videoUrl":"","videoSource":"FALLBACK","visual":"Friendly dinosaurs","phase":"running","remaining":180}
```

All fields required. Limits: 16 KiB message, 100-char session ID, 80-char activity ID/title, 400-char instruction, 100-char visual, 1000-char URL, 1–10 steps, valid zero-based step and 0–600 remaining seconds. Version must be 1. Media permits HTTPS or exact emulator gateway videos route; private file paths/credentials are rejected. Empty URL selects bundled fallback.

Types: PING, HELLO, STATE_SYNC, START, PAUSE, RESUME, NEXT_STEP, PREVIOUS_STEP, CANCEL, COMPLETE, VIDEO_READY, VIDEO_BUFFERING, VIDEO_FAILED. Phases: idle/running/paused/ready/completed/cancelled. Sources: FALLBACK/LOCAL/REMOTE_CACHED/REMOTE_STREAM. Actual generated URLs arrive as REMOTE_CACHED; receiver chooses its local rawfile fallback.

Commands carry full snapshots, repairing coalesced/missed intermediate commands. Relay assigns room revisions. Tablet polling and Phone posts provide six-second heartbeat expiry. Video feedback never overwrites Phone session/phase. COMPLETE means parent confirmation and successful Phone storage, not video/countdown end. Tablet never writes history. Room family-demo is not production authentication; both emulators connect directly to the Windows relay through http://10.0.2.2:18080. No HDC reverse forwarding is required.
