# Evidence-backed Parent Insight Summary - 2026-10-04

Codex read the user's attached request and added ParentInsightSummaryEngine above the retained BehaviorInsightEngine. It maps stable Tablet mission outcomes to existing completion/skip metrics and generates bounded local templates, source evidence and an optional category-preserving suggestion. Home and Insights now lead with plain language; structured metrics remain accessible. No cloud model, key, new dependency or child-study data was introduced.

Actual verification: 14 new deterministic edge-case/evidence/wording/window/balance checks and 17 existing work/behavior checks, API 21 Phone builds, final HAP install/relaunch, real saved 45-outcome journal comparison, Home/full summary/evidence/metrics and time-window touches, screenshot review and runtime log inspection. A sparse all-completed fallback was corrected after review and rebuilt. Native empty-journal testing and human comprehension/accessibility review remain pending; the existing journal was preserved. See docs/TESTING.md for results and package hash.

# Safe Daily Adventure return - 2026-10-04

Codex directly implemented the user's request for Back to World at the bounded Tablet ending. The guarded navigation transition preserves completion/session metadata and rewards, persists and synchronizes the hub scene, and prevents completed-session portals from clearing the ended flag. No new activity, replay CTA, dependency, asset or continuation pressure was added. Existing parent controls remain available.

Actual work: two targeted world-state regression checks (16 total passed), Tablet and Phone API 21 builds, real HDC completion of five activities, ending/hub screenshot review, Phone completed count and View Summary verification, relay record-count comparison and Tablet restart persistence check. Physical-device accessibility/usability remains a human review task. See docs/TESTING.md for exact scope and unsigned HAP hashes.

# Compact Parent Home refinement - 2026-10-04

Codex applied the user instruction to remove duplicate duration/preset grids from Home without deleting settings. Home now displays the actual saved duration/preset and a Parent navigation link; insights follow the primary status/action card, then Today. Parent's existing profile route is relabelled Child & Safety Settings. No new models, transport, persistence, Tablet gameplay, balance rules, dependency or asset was introduced.

Codex built the Phone HAP, installed it on API 21 Phone, inspected screenshots/layouts, opened Parent/custom/profile settings, changed duration/preset and observed Home's real summary, restored original 30/Balanced selection, and exercised Start Session against the real connected Tablet. A final build omitted Home's decorative footer and was reinstalled for final layout/control verification. These are real emulator touches, not human usability research. Existing broad host/backend checks were not rerun for this presentation-only change. See TESTING.md for actual package/test scope.

# Official submission disclosure audit - 2026-10-04

This summary is current; historical entries below retain their original dates and narrower verification scope. Source: the official HackYeah challenge and participant README, read directly for this audit. No artificial project history or human review is invented.

## Actual development tools

OpenAI Codex directly operated shell/file/build/HDC tools and read public official documentation with the available browser tool. The exact underlying model version is not captured in the project history and is not guessed. Separate ChatGPT sessions, Gemini or Huawei coding agents, external MCP servers and Conductor execution are not evidenced in this development run. Gemini/Veo and Huawei MaaS are optional product adapters, not development-agent usage. No image generator was used for the authored vector assets.

The user named conductor-dev, ohos-app-dev, hmos-arkui-develop-skill, hmos-arkui-scenario-development, hmos-arkui-mvvm-pattern and hmos-arkts-knowledge-retriever. No matching installed SKILL.md was found in the checked Codex/agents/Claude/OpenCode/Gemini skill roots; no applicable project/ancestor AGENTS.md exists. They were not used or retroactively attributed. Some broader user-directory listing was denied by sandbox; named candidate skill roots were still checked. The existing build works without those optional agent tools. No fresh scaffold, framework conversion or Conductor migration was performed.

## Workflow and representative prompt patterns

| Stage | Actual instruction pattern / work | Output and review/validation |
|---|---|---|
| Ideation / requirements | "Preserve the existing project; offline family activities; Phone parent / Tablet child; no diagnosis" | Product scope translated into native states and bounded sessions; no user-study evidence claimed |
| Architecture | "Keep detailed inputs on Tablet; send compact commands/results; preserve existing history" | Local WorldEngine/WorldStore and separate summary insights, existing fallback engine retained; code/protocol reviewed by Codex |
| Implementation | "Edit files directly, keep SDK/template, do not expose keys" | ArkTS UI/models/stores, original SVGs and English materials; generated code compiled, not accepted solely from model output |
| Debugging | "Use actual SDK/HDC; fix compile/runtime errors" | Notification enum/compiler fixes, persistence chunking, gesture hit-test fix, emulator gateway correction; failed attempts recorded historically |
| Testing | "Do not treat Preview/build as device verification" | Actual-source host tests plus explicitly mocked platform/cloud services; real HDC emulator touch/pan/layout/log checks separately labelled |
| Review | "Only stage related files; keep user work; check secrets and limitations" | Diff/path/secret-pattern review by Codex; no independent human source/child-suitability review asserted |
| Validation | "Build both HAPs; verify actual output; commit/push only after checks" | Real native artifacts and emulator installs; source-only OHPM/npm restoration and rebuild; documented remaining gaps |
| Current audit | "Use official requirements; evidence matrix; no major new features" | COMPLIANCE_MATRIX, capability/demo/privacy/readiness docs; optional clean-build flag and tracked-file hygiene tool |

Human/manual review remaining: source suitability, actual rights/license, parental/child usability, accessibility, signing and the saved final recording. User-provided environment/login confirmations are not substitutes for those reviews.

## Product AI status

| Component | Status | Inference/data flow and evidence |
|---|---|---|
| Cloud Gemini/Veo generation | NOT VERIFIED | Configured backend REST adapters; parent constraints/goal -> provider -> schema/safety validation -> generated-video review/cache -> child playback; no credentialed success |
| Huawei MaaS generation | NOT VERIFIED | Same bounded/reviewed flow; configured model/download host must match real account access; no live account test |
| Provider HTTP handling / malformed output | MOCKED / SIMULATED | Host/backend tests inject HTTP responses for errors/timeouts/parsing/review; not model quality evidence |
| Built-in activities/video and no-key failure recovery | FALLBACK | Curated local native games/clips remain available; actual fallback/local backend evidence exists |
| Local mission recommendation / Parent Insights | Deterministic rules, not model inference | Compact observed outcome/feedback aggregation; no raw world events sent to providers, no clinical score |
| REAL API VERIFIED cloud product path | None | Real local Node HTTP transport was tested; it is not proof of real AI inference |

Representative configuration is backend/.env.example with blank keys. Do not publish private endpoints, real imported videos, prompts containing identities or credentials. Vendor retention/terms and generated-content safety require real deployment review. See AI_ARCHITECTURE.md, AI_SERVICE.md and PRIVACY_AND_SAFETY.md.

## Failures, limitations and lessons

Actual unsuccessful approaches included guest loopback for cross-emulator transport, an SDK notification enum mismatch, a placed-animal hit target, temporary UITest coordinate/lock-screen problems and shell encoding of UI punctuation. Corrected builds/runtime checks followed; those failed attempts are not reported as PASS. This audit's source archive was created before attempting to use it as a working directory after the initial nonexistent-directory invocation failed; final restoration/build succeeded. A final incremental-build check exposed single-element PowerShell splatting in the new clean-build helper; an explicit string[] array fixed it, and both incremental commands were rerun successfully. A tracked-file scan initially misread blank example keys across newlines; limiting whitespace to spaces/tabs corrected that false positive.

Lessons: inspect installed SDK declarations before selecting APIs; use the host gateway for guest communication; keep child authority and journals local; treat callback/HTTP success separately from actual device acknowledgement; preserve explicit sample limits; document generated output, mocks and genuine runtime evidence separately. No guarantee of complete secret detection, educational benefit, cloud correctness, API 20 or production release readiness follows from these tests.

---

# Parent Phone UI refinement - 2026-10-04

Codex directly refactored only Phone presentation/navigation. The user asked to remove Home clutter, retain existing functionality, use Home / Activities / Insights / Parent and show only actions matching real Tablet state. No additional coding agents or art models were used.

Generated changes: contextual UI state derivation from existing WorldStatus, compact cards, real-data summaries, dedicated content/insight/settings entry points and route callbacks. Existing transport, storage, balance/insight algorithms and all Tablet gameplay were left unchanged. Codex inspected diffs, built the native Phone HAP and drove actual HDC emulator touches; this is not human usability research.

Review exposed a duplicate header, truncated preset labels and shell-encoding punctuation errors; these were corrected and rebuilt. Premature End originally read "Session complete"; the final UI distinguishes "Session ended" from all-missions-completed. One UITest attempt met the emulator lock screen and was interrupted, unlocked and repeated; it is not counted as a passing test. The initial sandboxed build lacked write access to the existing user Hvigor cache; the authorized build was rerun with that access.

Existing product AI verification statuses are unchanged. No keys, live provider verification or child research were added. Remaining human checks: small physical phones, large fonts/screen readers and parental usability. See TESTING.md for executed runtime results.

# Current AI-assisted refinement - 2026-10-03

Tool: Codex coding assistant, directly editing the existing native project. No additional coding agent, external art model, child research, cloud credential or commercial asset was used in this iteration.

Actual user instructions progressed from balance/local behavior insights, to playable games/Daily Adventure, to a Tablet-primary 2D world connected to a Phone parent dashboard. The implementation preserved API 21 products, original fallback/providers/persistence/notifications. Raw inputs were moved to Tablet-local world authority; compact command/state/result endpoints were added to the existing Windows relay.

Codex authored original SVG/native graphics, a local counting clip generation script, pure world/game/balance rules, chunked journal adapters, Phone controls/evidence and English documentation. Actual HDC touch/drag tests and screenshots exposed a placed-animal hit-target issue; the fixed HAP was reinstalled and the test repeated. A temporary UI test helper coordinate parser and compilation mistakes were corrected; their failed attempts are not counted as passed tests. A root npm test invocation had no package.json; the successful backend command was rerun from backend.

Automated tests use actual pure ArkTS transitions plus mocked platform/cloud HTTP. Those mocks are not a claim of credentialed Gemini/Huawei success. HDC installation/runtime evidence is separately documented in TESTING.md. No signing configuration was invented or credential supplied.

Human follow-up: review child suitability with adult supervision, screen-reader/reduced-motion/large-font behavior, physical-device signing and installation, actual competition rules and starter-asset rights; record the demonstration using DEMO_SCRIPT. Emulator test inputs are not real child-study evidence.

## Earlier retained workflow notes

### AI development workflow

## Homepage UI/accessibility polish - 2026-10-03

Prompt: improve homepage hierarchy, readable contrast, warm primary action, compact category/activity cards, progress and bottom navigation while preserving all session/provider/history/Tablet behavior. Codex edited only Phone presentation builders and shared page spacing/navigation styling, reused existing original SVG assets, and added semantic grouped labels. No additional agent, cloud credential, dependency, generated asset or architecture change.

The progress card reuses actual today/total counts and the existing ten-completion Family Explorer threshold. It does not invent active minutes or imply reduced adult supervision. Eighteen sampled foreground/background color pairs were computed with relative luminance (minimum 5.66:1); this is bounded color evidence, not a formal WCAG or screen-reader pass. Actual initial/one-scroll screenshots, navigation and existing regression checks are recorded separately in TESTING.md. Large-font and small physical-screen checks require additional testing.

## API 21 Tablet companion adaptation - 2026-10-03

User prompt: replace the API 19 TV-focused secondary target with a MatePad Pro 11 API 21 Large-Screen companion, preserve Phone API 21 and existing media/session/relay architecture, validate actual devices and document limits. Codex inspected actual product/module declarations and HDC properties, reused tventry/TvAbility/TvReceiver, renamed only the secondary build product to tablet and changed minimum/device declarations. Internal protocol names/routes remain compatible. No extra coding agents, assets, dependencies or cloud credentials.

The prior interrupted evaluation refinement is retained in the same worktree. Its actual pause/resume and early-end checks also finished: thirty-minute plan, one confirmed Demo activity and five skipped; normal second entry paused/resumed before early end. New Tablet results belong to the latest TESTING section, not old TV evidence. A misplaced root npm test command failed (no root package.json); rerunning inside backend passed. No persistent execution policy, Phone SDK, signing configuration or transport topology was changed.

## Final evaluation refinement - 2026-10-03

IMPLEMENTED: Codex directly refined the existing native UI/model, added a balanced default thirty-minute plan with illustrated category totals, normalized invalid duration inputs and updated English submission materials. Prompt: optimize originality, usefulness, reliability, HarmonyOS evidence, 90-second demonstration and reproducibility without unrelated features or architecture replacement.

ACTUALLY TESTED: current results are recorded in the top section of TESTING.md. MOCKED: provider HTTP and platform service injections in host tests. NOT VERIFIED: live Gemini/Huawei success, physical devices, full work windows and official partner rule compliance. OPTIONAL: backend AI, My Video and TV; Built-in Phone works without them.

AI tools: OpenAI Codex was the coding assistant. No separate ChatGPT session, Gemini coding agent or Huawei coding tool was used. Gemini/Huawei application adapters were preserved, not claimed as successful live generation. SVG assets are prior original Codex-authored graphics; no new raster generation or third-party assets were introduced.

Workflow: inspect clean Git/SDK and preserved implementation; improve bounded plan/model and UI; rerun native builds and all host tests; install on connected emulators; capture layout evidence; audit tracked files/docs; commit and push. A direct PowerShell helper import was blocked by execution policy; loading its trusted local contents as a scriptblock avoided persistent policy changes. Public organizer tasks returned a loading placeholder, so supplied weights remain attributed to the user brief. A 90-second completed-summary demonstration uses a visibly labelled separately recorded accelerated segment rather than falsely implying real-time completion.

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

Historical initial stage: no reusable backend existed then. The current repository includes the optional multi-provider backend described above. The app defaults to curated **Offline activity** content. A parent can configure a trusted HTTPS recommendation service. Only a validated response labelled `source: "ai"` is displayed as an AI service recommendation. The client cannot independently prove which model a server used. No real endpoint, provider call, model quality or real recommendation has been verified. Mock responses used in tests are not production AI output.

## Human verification still required

A later user-triggered follow-up connected to an actual API 21 phone emulator over HDC, rebuilt/installed/launched the unsigned HAP and used system UI injection plus layout dumps to verify Home/details, settings/records after force-stop, Demo completion, cancellation, double-click protection, notification denial/actual notification-center delivery, and background expiry/resume. App-PID logs and a screenshot were reviewed. The exact tested variants and remaining gaps are in `docs/TESTING.md`; this is emulator evidence, not a physical-phone or live AI pass.

Complete the remaining checklist in `docs/TESTING.md`, especially full ten-minute expiry and complete work-window variants, desktop widget launch/update, alternate layouts and physical-phone behavior when needed. The follow-up also ran and confirmed a full three-minute normal activity, with its normal record, total 3 and Together Team badge restored after restart. Record the current 90-second Phone/Tablet walkthrough using `docs/DEMO_SCRIPT.md`. Obtain actual competition rules, review asset rights and sign the final distribution artifact before submission. Corrupted-data behavior is still host-tested only; use a disposable installation for device fault injection.
