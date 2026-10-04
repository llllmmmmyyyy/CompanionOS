# CompanionOS

Small activities. Meaningful family moments.

Pico has a reusable native layered mascot system on Phone and Tablet: articulated greetings/blinks, page pull/collapse/reveal, activity entry and bounded completion celebrations. **Reduce mascot motion** is available in Parent and on Tablet. See [implementation](docs/PICO_ANIMATION.md) and [actual verification](docs/TESTING.md).

## Problem

Parents need a clear way to guide bounded screen-based activities and understand observable play patterns, without surveillance or diagnostic labels. Children need interaction, movement, creativity and a calm ending rather than an endless video feed. An adult remains nearby and available; this is not a replacement for supervision.

## Solution

CompanionOS separates the child and parent experiences across HarmonyOS devices. The Tablet provides an engaging interactive world for the child, while the Phone acts as the parent's control and insight dashboard.

**The tablet engages the child. The phone helps the parent understand the child.** Insights describe recorded activities and explicit feedback, not ability, IQ, attention measurement or diagnosis. Educational effectiveness has not been studied.

## Product Architecture

**PHONE = Parent Control + Insights**: Home, Activities, Insights and Parent; contextual remote controls, a compact saved-session summary, history and evidence. Duration/preset grids and advanced settings are kept in Parent.

**TABLET = Child Interactive World**: original Pico character, native 2D scenes, locally owned gameplay, video, movement and feedback.

```text
Phone parent controls <-> Windows Node demo relay <-> Tablet child world
compact local journal       compact sync only         detailed local journal
```

Detailed events remain Tablet-local. The relay is a development/demo Phone-Tablet transport, not production HarmonyOS distributed-device technology. See [architecture](docs/ARCHITECTURE.md) and [Phone navigation](docs/PARENT_PHONE_UI.md).

## Core Experience

- **WATCH:** native built-in storybook video; optional adult-reviewed AI/imported content.
- **PLAY:** draggable Dino Bridge/Rocket, Robot Memory, Animal Rescue and Star Collector.
- **MOVE:** Copy Pico and Number Move; gentle child-confirmed movement, no camera verification.
- **CREATE:** freely place colored flowers in Creative Garden.
- **CALM:** comfortable cloud interaction and a bounded ending.

Daily Adventure uses protected learning/movement/creative/calm allocations. Short missions may finish before the maximum 15/30/45/60-minute foreground window. Completing all missions rewards a persistent daily garden gift; skipping does not fake completion. No endless auto-start, purchases or streak punishment.

## Requirements

- Windows 64-bit, PowerShell, Git.
- DevEco Studio **6.0.1.251** and installed HarmonyOS SDK **6.0.1.112 / API 21** (tested configuration).
- Both products declare minimum compatible and target **6.0.1(21)**, runtimeOS **HarmonyOS**. `compileSdkVersion` is not explicitly set; the effective build uses the installed API 21 SDK. This is not an API 20 compatibility claim.
- DevEco's bundled Node/Java/Hvigor/OHPM build tools; build helper discovers installation via Windows registry.
- System **Node.js >=22**, npm for the relay (tested Node 24.21.0). DevEco's older bundled Node is for native builds, not the backend.
- Phone and Tablet **API 21+** emulators; tested Mate70Pro and MatePadPro11 API 21. Untested higher versions are not certified.
- Python is **not required** to build/run; it was used during development. Optional video re-authoring needs local FFmpeg; committed original assets are sufficient for normal builds.

No cloud credentials, Conductor or DevEco CLI installation is required for the existing build scripts. The official newer starter setup is a recommendation; this existing compatible toolchain is retained.

## Repository Structure

| Path | Purpose |
|---|---|
| entry/ | Native Phone app, product default |
| tventry/ | Native Tablet app, product tablet; legacy Tv filenames retained |
| shared/ | Local native HAR, pure gameplay/protocol/HTTP components |
| backend/ | Node provider adapters, review/import routes and Windows demo relay |
| scripts/ | Native builds, actual-source host tests, deployment and hygiene scan |
| docs/ | Architecture, evidence, privacy, demo and submission audit |
| AI_WORKFLOW.md | Actual AI-assisted development disclosure |

## Setup

1. Clone this repository and open its root in DevEco Studio. Complete initial setup, install SDK API 21 through SDK Manager and allow project dependency synchronization. Keep the existing products/configuration.
2. For command-line dependency restoration, run the following from the repository root. The tool path below is the default Windows installation; if you installed elsewhere, set `$studio` to that installation directory. The build helper itself discovers that path automatically.

```powershell
$studio = Join-Path $env:ProgramFiles 'Huawei\DevEco Studio'
& "$studio\tools\ohpm\bin\ohpm.bat" install --all
```

3. Install backend dependencies using system Node >=22:

```powershell
cd backend
npm.cmd ci
npm.cmd run build
cd ..
```

No `.env` is needed for the offline demonstration. `backend/.env.example` has blank key fields; real keys belong only in an ignored backend environment, never in HAPs or Git. Do not import private family media for the judging recording.

## Build

From the repository root, using the existing DevEco SDK:

Phone:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Clean -RunChecks
```

Tablet:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build.ps1 -Clean -Module tventry
```

`-Clean` regenerates packages; omit it for incremental builds. `-RunChecks` currently runs 114 host checks against actual ArkTS logic/services and Pico choreography, with platform/cloud mocks explicitly separated from runtime evidence. Scripts change environment variables only for their process. They need normal write access to DevEco/Hvigor's user caches. They do not configure signing or change persistent execution policy.

Backend checks:

```powershell
cd backend
npm.cmd test
cd ..
node scripts/audit-repository.cjs
```

The backend has 23 tests. The hygiene scan reports paths/rule names without printing secret values; it is a pattern-based check, not proof that every possible secret or personal datum is absent.

## Run

Create/start one Phone and one Tablet API 21 emulator in DevEco's Device Manager. No need to recreate already running devices. Use HDC `list targets` to identify their IDs; default tested IDs are `127.0.0.1:5555` and `127.0.0.1:5557` (HDC IDs, not app relay endpoints).

Start the Windows relay in one terminal:

```powershell
cd backend
npm.cmd start
```

In a separate terminal at the repository root, install and launch both built HAPs:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/run-emulator-demo.ps1
```

For different device IDs pass `-Phone <hdc-id> -Tablet <hdc-id>`. The helper checks API/device profiles and preserves a healthy existing backend. It needs system Node >=22. Neither successful installation nor launch alone proves the control connection; check Home's Tablet Connected state and exercise a command.

In DevEco Studio select **entry / product default / Phone** and Run; select **tventry / product tablet / Tablet** and Run for the child app. Tablet **Open Pico world locally** and optional Phone activities work offline; two-device remote controls need the relay. Do not select the obsolete TV API 19 target.

The tested emulators accept unsigned development HAPs. For devices requiring signing, use **File > Project Structure > Project > Signing Configs** and configure the applicable automatic/manual signing. Account access, device registration and release signing are not completed by this project; keep signing credentials outside Git. Other emulator images may reject unsigned packages.

## Demo Configuration

Both guest applications use **http://10.0.2.2:18080**, session **family-demo**. Windows relay listens on **127.0.0.1:18080**. Guest 127.0.0.1 is the guest itself and cannot connect different emulators. No HDC reverse tunnel is needed in the tested DevEco emulator setup. Other networking environments are unverified.

Phone Parent: choose memory **2 lights**, **Balanced / 15 min**, then return Home for a finite five-mission recording. Fresh installs default to 30 minutes; saved choices are preserved. Exit Child Mode in Parent if needed, then Home > Start Child Mode > Start Session. Child may choose Dino Forest before the first learning interaction. Follow [75-90 second demo](docs/DEMO_SCRIPT.md); label time edits and development history honestly.

## Generated HAP Files

- Phone: `entry/build/default/outputs/default/entry-default-unsigned.hap`
- Tablet: `tventry/build/tablet/outputs/default/tventry-default-unsigned.hap`

Both paths are checked after the current audit build; hashes and generation/runtime evidence are recorded in [TESTING](docs/TESTING.md). HAPs and logs are ignored rather than committed. These are development artifacts, not signed physical-device releases.

## Platform Capabilities

Verified native ArkUI interaction, HAP/device profiles, lifecycle recovery, Preferences persistence and native Video are documented in [PLATFORM_CAPABILITIES](docs/PLATFORM_CAPABILITIES.md). Earlier actual Phone NotificationKit/system media picker evidence is separately dated in TESTING. Widget code is compiled but hosting is unverified. The application-level relay is not represented as a production distributed API.

## AI Usage

[AI_WORKFLOW](AI_WORKFLOW.md) discloses actual Codex-assisted requirements, implementation, debugging, review and validation. [AI architecture](docs/AI_ARCHITECTURE.md) and [AI service](docs/AI_SERVICE.md) document optional inference/data handling. Built-in activity/video is **FALLBACK**; cloud provider tests are **MOCKED / SIMULATED**; credentialed Gemini/Veo and Huawei MaaS generation is **NOT VERIFIED**. No product cloud path is marked REAL API VERIFIED. Local deterministic summary recommendations are rules, not model inference.

## Testing

See [executed test matrices](docs/TESTING.md) and [demo claim evidence](docs/DEMO_CLAIMS.md). Source-only archive reproduction restores OHPM/npm dependencies and builds both modules without project caches/local.properties; it still uses the installed vendor SDK and user tool caches. This is not a fresh-OS setup or bit-for-bit reproducible-package claim. Emulator test history contains development interactions, not child research.

## Known Limitations

API 20 runtime compatibility; release signing/physical devices; widget hosting; live cloud generation; authenticated/encrypted production transport; full long-window/age/preset combinations; accessibility/usability and educational effectiveness remain unverified. There is no OS kiosk lock or reliable background reminder. Project-wide license/inherited starter-asset rights require owner review. Recorded demo and final competition-platform upload are not yet done.

## Privacy / Safety

Raw child interaction events stay locally on Tablet; compact results reach the Windows relay and Phone. No child camera/microphone monitoring, location, emotion recognition or diagnosis. Movement is child-confirmed; an adult supervises indoor gentle activities. Optional imported/generated media has a separate network/review flow. See [PRIVACY_AND_SAFETY](docs/PRIVACY_AND_SAFETY.md).

## Challenge Alignment

Primary: **Human-Centric Technology**, through responsible family activity, education and bounded screen use. Secondary: **Intelligent Experiences**, limited to explainable rule personalization and optional unverified AI adapters. No 3D/spatial or clinical claim.

The [official challenge](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/hackathon_challenge.md) and [setup guide](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/README.md) were read for this audit. [COMPLIANCE_MATRIX](docs/COMPLIANCE_MATRIX.md), [SCORE_READINESS](docs/SCORE_READINESS.md) and [SUBMISSION_CHECKLIST](docs/SUBMISSION_CHECKLIST.md) distinguish satisfied, partial, missing and unverified items. No numeric self-score or full compliance assertion.
