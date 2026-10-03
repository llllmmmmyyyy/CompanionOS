# AI development workflow

## Parent work sessions and visual redesign - 2026-10-03

The user requested a substantial visual/product refinement of the existing native app: busy parents, structured indoor activities, optional content sources and optional TV. The Codex coding assistant directly edited ArkTS models, persistence and UI, authored original SVG illustrations, reused the existing bundled video unchanged, and added host checks for planning/migration/recovery. No external artwork, new dependencies, extra agents or live cloud credentials were used. Existing history, notification adapters, providers, picker and relay were retained. Actual build/device outcomes and remaining human checks are in docs/TESTING.md.

## Emulator relay communication fix — 2026-10-03

The user requested diagnosis and an actual Phone/TV connection fix without unrelated feature changes. The coding assistant inspected existing HTTP relay clients, Windows listeners and both running emulator routes. It found no 18080 listener and no reverse tunnels, replaced guest-loopback defaults with the actually verified 10.0.2.2 gateway, standardized the backend on port 18080, added visible connection/error diagnostics and updated the startup helper. No additional agents, generated assets or live AI-provider calls were used.

Both native apps were built and installed. Actual device checks covered connection, player/control changes, relay outage and recovery; the startup command was executed. Host checks passed separately (40 ArkTS, 18 backend). See docs/TESTING.md for bounded evidence and remaining physical-device/signing limitations. No keys or local artifacts are committed.

## Multi-provider content extension — 2026-10-03

The user asked the same coding assistant to preserve Gemini/videos and add Huawei MaaS, original Built-in and system-imported My Video within the existing session/history/TV architecture. No additional agents or image generation were used. The assistant directly edited the repository, consulted installed API 21 declarations and official Huawei MaaS/OpenHarmony media-tool documents, built unsigned Phone/TV HAPs and executed host/device checks. Work from the preceding integrated TV/backend stage was preserved.

Actual changes: shared content enum/VideoSource, legacy record defaults, backend provider interfaces/adapters, normalized public plan, both blank backend environment keys, safe provider selection/fallback, PhotoViewPicker/private copy/duration persistence, bounded MP4 cache import, and provider-independent TV playback. A device-observed stale heading was fixed by binding Text directly; an SDK lifecycle spelling error was corrected from onDisappear to onDisAppear. Windows npm.cmd and native resolved HDC paths were used after execution-policy/path errors. Media-test import used API 21 media FUSE with the project’s own clip; mediatool temporary-path access was denied.

Neither live Gemini/Veo nor Huawei generation has been verified. HTTP provider tests use injected mocks; fallback uses the actual local backend. Human review remains necessary for actual generated/imported child-facing footage, physical devices/signing, launcher widget and competition rules. Exact device evidence and remaining checks are in docs/TESTING.md.

## Integrated Phone + TV + backend extension — 2026-10-03

OpenAI Codex was the coding assistant/agent used. The user requested one repository preserving Phone functionality, API 19 independent TV HAP, video-first UI, emulator transport, secure real Gemini/Veo code paths, build/test evidence and Git upload. No additional coding agents or live Gemini/Veo content generation were used.

Decisions: keep Phone API 21, add TV minimum API 19 using installed SDK 21, share a protocol HAR, use HTTP + HDC reverse forwarding rather than emulator distributed APIs, and retain Phone-authoritative history. Node built-in HTTP/fetch avoids runtime packages. Official provider documentation informed REST implementation; mock HTTP tests are clearly distinguished from real backend/emulator checks. An original bundled cloud clip was created with ignored local FFmpeg tooling and is explicitly not AI output.

Corrected failures: ArkTS constructor parameter properties were replaced with explicit fields; TV output path uses product tv; Windows test-loader paths were normalized; an incorrect test-tool package name returned 404 before the correct package was installed; bundled video resume was fixed and actual player callbacks verified. Human review remains needed for child suitability, real generated video, physical transport/signing and provider access. No credentials were present or requested. TESTING.md records actual results and limitations.

## Companion TV extension — 2026-10-03

The user supplied a detailed Companion TV Mode prompt requesting minimal API 21 changes, local and distributed transport boundaries, four activity categories, mock AI plans, future Gemini/Veo design, build checks and a Git upload. OpenAI Codex implemented the changes directly, inspected installed SDK declarations, built with DevEco tools, executed actual-model host checks and operated the existing emulator via HDC. No Gemini/Veo request or provider credential was used. Documentation separates working Local Demo from the unimplemented real TV channel/receiver. Human review remains necessary for child suitability, real TV hardware and future generated media.

## Scope of this development run

The user asked the OpenAI Codex assistant to operate directly on the existing HarmonyOS project, complete an offline parent-child activity MVP, keep the Phone/API 20+ template, validate available builds, document actual evidence in English, and commit/push meaningful stages. The user authorized repository uploads and supplied a Git identity in an earlier turn. No API key was requested.

This document records the work performed in this conversation. It does not invent an earlier team history, external model evaluation or competition approval.

## Actual use of AI

Codex inspected the project, local SDK declarations, installed DevEco templates, Git state and remote; implemented ArkTS models, page states, Preferences migration and validation, deadline-based sessions, notification handling, widget code and an optional HTTPS recommendation client; wrote and ran host checks; built the actual HAP; and prepared these documents. No image generator, cloud AI backend or autonomous sub-agent was used for this development run.

Main user instructions were to preserve existing work and SDK configuration, keep activities available offline, distinguish real service output from presets, handle background transitions honestly, avoid secrets in the app/repository, and report actual verification rather than equating compilation with device execution.

## Review and iteration performed

- Confirmed Stage-mode ArkTS/ArkUI, Phone, API 21 and a clean starting Git state.
- Found no applicable project/ancestor `AGENTS.md`, no installed native HarmonyOS development skill and no workspace RULES/CRITERIA. Available skills were assessed; website, image and pet workflows do not apply.
- Preserved the three named activities and replaced the immediate-completion shortcut with timed sessions and parent confirmation.
- Added host checks for session transitions, duplicate IDs, settings/records serialization, malformed data, daily rollover and bounded history.
- Exercised the actual service modules with mocked HTTP, Preferences and notification APIs, including rejection, timeout and failure paths.
- Fixed a notification slot enum mismatch exposed by the API 21 compiler, supplied the widget LocalStorage entry parameter, and handled Preferences calls explicitly to eliminate ArkTS warnings.
- Added a Windows build helper; corrected native-stderr handling without changing user/machine execution policy.
- Built native HAPs and pushed the core and platform stages to the authorized repository. Build artifacts and local logs stay outside Git.

## In-app AI status

There is no reusable backend in this workspace. The app defaults to curated **Offline activity** content. A parent can configure a trusted HTTPS recommendation service. Only a validated response labelled `source: "ai"` is displayed as an AI service recommendation. The client cannot independently prove which model a server used. No real endpoint, provider call, model quality or real recommendation has been verified. Mock responses used in tests are not production AI output.

## Human verification still required

A later user-triggered follow-up connected to an actual API 21 phone emulator over HDC, rebuilt/installed/launched the unsigned HAP and used system UI injection plus layout dumps to verify Home/details, settings/records after force-stop, Demo completion, cancellation, double-click protection, notification denial/actual notification-center delivery, and background expiry/resume. App-PID logs and a screenshot were reviewed. The exact tested variants and remaining gaps are in `docs/TESTING.md`; this is emulator evidence, not a physical-phone or live AI pass.

Complete the remaining checklist in `docs/TESTING.md`, especially full 5/10-minute expiry variants, desktop widget launch/update, alternate layouts and physical-phone behavior when needed. The follow-up also ran and confirmed a full three-minute normal activity, with its normal record, total 3 and Together Team badge restored after restart. Record the two-minute walkthrough using `docs/DEMO_SCRIPT.md`. Obtain actual competition rules, review asset rights and sign the final distribution artifact before submission. Corrupted-data behavior is still host-tested only; use a disposable installation for device fault injection.
