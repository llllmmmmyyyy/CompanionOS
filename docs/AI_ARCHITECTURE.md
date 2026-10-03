# Backend activity and video architecture

## Product role: optional activity preparation

AI is an optional source within parent work sessions and quick activities, not the homepage headline. Recommended uses deterministic safe Built-in templates. Work setup offers Recommended / Built-in / Huawei AI / Gemini AI / My Videos, and each activity remains reviewable before start. Gemini/Huawei still use the existing validated backend; failures return labelled fallback, not fabricated AI success. My Videos retains the system picker, private Phone copy and optional relay cache.

Work activities use five-minute category requests with the child's age, interests and learning goal. Age adapts counting instructions; local difficulty adjusts safe creative templates. Safety preferences never relax existing AI validation or adult-support requirements; the cloud adapters keep their stricter existing safety contract. The app does not claim that these preference flags are remotely enforced as additional provider parameters. Keys and media review policy remain backend-only.

## Four content sources

Activity offers **Choose Activity Content**: Gemini AI, Huawei AI, Built-in Video, My Video. Shared `ActivityContentSource` and `VideoSource` describe origin. Activity/session retain source, video/private path and provider/generation identity; history retains source. Old version-1 records without source default to BUILT_IN without losing existing records.

`AiActivityProvider.generateActivity` and `VideoGenerationProvider.generateVideo` separate planning and media. GeminiActivityProvider/GeminiVideoProvider adapt the preserved GoogleProvider. HuaweiMaaSActivityProvider uses MaaS V2 chat; HuaweiMaaSVideoProvider uses Wan text-to-video creation and polling. ProviderAdapter connects both pairs to the SAME ActivityJobs validation/retry/cache/review pipeline. Failure offers another provider or Built-in; no automatic paid provider switching occurs.

The normalized public plan uses title, theme, educationalGoal, and steps with id, instruction, durationSeconds, learningGoal, videoUrl and videoPrompt. The original internal `veoPrompt` compatibility field stays behind the backend boundary. Source labels reflect validated AI plans; failed/unavailable providers return explicitly labelled built-in content. Generated video availability remains separate.

Built-in keeps original activities and the bundled MP4 unchanged, with zero AI calls. My Video invokes PhotoViewPicker for one video, validates MP4/40 MiB, obtains duration through AVMetadataExtractor, and saves one private copy plus Preferences metadata. No broad gallery, camera or microphone permission is requested. An adult chooses and reviews the content. Missing files offer Built-in. Phone can play privately offline; separate TV receives a cached `/videos/:hash` URI via bounded binary POST /media/import. No private path is transmitted. If caching fails, TV uses explicitly labelled Built-in fallback. Thumbnails and full library management are absent.

TV consumes only VideoSource through common transport/player, with no provider API or response parsing. All controls remain Phone-owned. Both keys are blank in `.env.example`; `.env`, generated media and dependencies are ignored.

Huawei prerequisites: enabled chat/video models and trusted output-storage hosts. No live Huawei/Gemini/Veo generation was verified. Contracts checked: [MaaS V2 chat](https://support.huaweicloud.com/model-call-maas/model-call-019.html), [Wan text-to-video](https://support.huaweicloud.com/model-call-maas/model-call-070.html), [task polling](https://support.huaweicloud.com/model-call-maas/model-call-025.html). Mocked REST tests do not prove account/model availability.

## Implemented versus verified

Node.js 22+ / TypeScript uses built-in HTTP and fetch; no Express or provider SDK. Real Google REST paths are implemented with configurable defaults `gemini-2.5-flash` and `veo-3.1-generate-preview`. No key was configured, so no live Gemini/Veo request was attempted. Provider tests inject mocked HTTP. The real backend, Phone and independent TV were exercised with honest no-key fallback and a bundled non-AI MP4.

## Flow

Phone POSTs age group, interests, category, learning goal and duration. Backend creates a bounded job, requests strict Gemini JSON, validates schema, duration and safety patterns, retries once on invalid/error output, then returns an AI plan or deterministic `source: fallback` plan. Offline MockAiActivityService remains available when the backend itself fails. Existing recommendation endpoint remains separate.

An AI plan queues one eight-second 16:9 720p Veo clip per step. States: QUEUED, GENERATING, READY, FAILED. Operations poll every ten seconds with a twelve-minute deadline; downloads are bounded to 40 MiB. Segments generate sequentially, permitting PLAYABLE after the first clip or safe fallback while later generation continues. Phone polls asynchronously and keeps checking late readiness/review for its active AI plan. Ungenerated/failed/unreviewed steps use fallback without freezing the activity.

TV receives approved URLs plus Phone snapshots, never provider secrets. Clips loop for the step duration; scheduled/manual next and previous switch the surface. Fallback is an original bundled calm cloud MP4, visibly Not AI generated; playback error uses a static safe visual. Video end never writes completion.

## Endpoints

| Endpoint | Purpose |
|---|---|
| GET /health | Readiness/protocol version |
| POST /activities/generate | Validate request, return HTTP 202 activity job/ID |
| GET /activities/:id/status | Progress, source, plan and segments |
| GET /activities/:id | Same complete job representation |
| GET /videos/:videoId | Approved stored MP4 with byte ranges |
| POST /tv/rooms/:room/phone | Validated authoritative command/full state |
| GET /tv/rooms/:room/state | Snapshot/heartbeats; receiver=true registers TV |
| POST /tv/rooms/:room/feedback | VIDEO_READY/VIDEO_BUFFERING/VIDEO_FAILED feedback |
| POST /tv/rooms/:room/disconnect | Explicit disconnect |

Windows listens on http://127.0.0.1:18080; BOTH emulator apps use the verified host-gateway endpoint http://10.0.2.2:18080, without HDC reverse forwarding. Cached video URLs use that same gateway. Clients also accept HTTPS bases; other public cleartext bases are rejected. Legacy explicit loopback parsing remains for old tunnel fixtures, but is not the active/default transport. The development relay has no production authentication. Cloud deployment requires authentication/TLS/rate limits.

### Example request

```json
{"childAge":"4–5","interests":["Movement"],"activityCategory":"MOVE","educationalGoal":"Count five together","durationMinutes":3}
```

### Illustrative Gemini result, not a live response

```json
{"title":"Dino Number Adventure","theme":"Friendly dinosaurs","educationalGoal":"Count five together","steps":[
  {"id":"step-1","instruction":"Sit comfortably beside your parent.","durationSeconds":60,"learningGoal":"Prepare together","veoPrompt":"A friendly dinosaur sits calmly."},
  {"id":"step-2","instruction":"Count five gentle hand movements together.","durationSeconds":60,"learningGoal":"Count to five","veoPrompt":"A friendly dinosaur moves its hands gently."},
  {"id":"step-3","instruction":"Rest and share how you feel.","durationSeconds":60,"learningGoal":"Reflect","veoPrompt":"A friendly dinosaur rests near soft clouds."}
]}
```

Job wrappers add id/state/source/message/segments. Empty videoUrl explicitly means fallback. No fabricated playable URL is returned. Plan metadata maps to existing Activity without changing completion schema version 1.

## Cache/review

Keys hash activity/request ID, step ID, prompt, model, aspect/resolution and safety version. Ignored backend/data/videos stores MP4 and JSON metadata. Matching generated cache is reused; failed calls do not become READY. Metadata records model, generation time and review. In-memory jobs/relay rooms are transient; backend restart requires Phone resynchronization. Cloud storage, retention/quota and persisted job recovery remain future work.

Generated clips require adult review by default. Inspect the stored MP4 then run `npm run review -- <videoId>` in backend. This records approval; it does not inspect/moderate automatically. Status refreshes approvals and the active Phone picks up approved URLs. Fallback order: approved matching generated cache, bundled calm clip, static visual on playback error. REQUIRE_VIDEO_REVIEW=false is an explicit developer override, used only with mocked byte fixtures in tests, never with live child-facing output in this run.

## Security/safety

Only backend reads GEMINI_API_KEY from environment/ignored .env; .env.example is empty. Auth uses headers, not client URLs. Keys/provider response bodies are not logged. Downloads restrict redirects and never forward keys to storage hosts. Requests/jobs/rooms are bounded. No names, camera, microphone, location or emotion analysis are collected. Local settings/history remain on Phone; minimal generation inputs are sent on user action.

Controlled prompts require adult accompaniment, seated alternatives, rest, simple age-appropriate language; exclude dangerous movement/climbing, violence/weapons, frightening imagery, risky challenges and flashing/strobe. Validation checks 3–6 unique steps, exact duration and selected unsafe patterns. This is not complete moderation; review generated clips before children see them. Physical signing/transport, real quota/cost/model access and production hardening are unverified.

Sample Veo framing: “Gentle friendly illustrated dinosaur moving its hands, steady camera, soft colors, 16:9. Adult accompanied, include rest. No dangerous movement, climbing, weapons, violence, frightening imagery or flashing/strobe.” Official references: [structured JSON](https://ai.google.dev/gemini-api/docs/generate-content/structured-output?hl=en), [Veo 3.1](https://ai.google.dev/gemini-api/docs/veo?hl=en). Real credential verification is still required.
