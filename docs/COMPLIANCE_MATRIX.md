# Official challenge compliance audit

Source of truth: [challenge](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/hackathon_challenge.md) and [participant setup](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/README.md), read 2026-10-04. Mandatory requirements are distinguished from recommended setup and our own device/test scope. No eligibility or jury acceptance is asserted.

## Initial audit, before modifications

| Item | Status | Actual evidence / gap |
|---|---|---|
| Selected OS | PASS | Both products runtimeOS HarmonyOS; native Stage apps |
| API >=20 | PASS | Both compatible/target 6.0.1(21) |
| API 20 minimum where applicable | UNVERIFIED | Minimum is honestly 21; no API 20 SDK/device validation; no proven API-21-only dependency claimed |
| Compile SDK | PASS | Installed SDK 6.0.1.112, ETS metadata apiVersion 21; implicit compile SDK, explicit key absent |
| Native ArkTS/ArkUI | PASS | entry/tventry/shared source and HAP builds |
| Phone target | PASS | entry profile phone / product default |
| Tablet target | PASS | tventry profile tablet / product tablet |
| Emulator validation | PASS | Prior actual API 21 HDC gameplay/control evidence in TESTING |
| HAP generation | PASS | Prior builds exist; both must be rebuilt this audit |
| Setup reproducibility | PARTIAL | Dependency/bootstrap instructions incomplete; clean source-only build not tested |
| Build reproducibility | PARTIAL | Current environment builds, fresh dependency restoration pending |
| Installation | PARTIAL | Emulator install helper; unsigned package restrictions documented |
| Launch | PASS | Existing HDC/DevEco routes and helper |
| Platform capabilities | PARTIAL | Native APIs present, dedicated evidence inventory missing |
| AI_WORKFLOW | PARTIAL | Historical disclosure exists; current status/tools/lessons need concise audit summary |
| Architecture | PARTIAL | Actual ownership described, explicit two different insight pipelines must remain truthful |
| Demo readiness | PARTIAL | Actual runtime exists; script outdated after Phone cleanup |
| Recorded demonstration | MISSING | No submission recording produced |
| Test evidence | PASS | Executed matrices distinguish checks/device evidence; new build/runtime audit pending |
| Repository safety | PASS | Ignored caches/credentials; tracked .env.example has blank keys |
| Secret scanning | PARTIAL | Initial tracked-content patterns clear; repeat entire tracked-file hygiene scan |
| Known limitations | PASS | Signing, live AI, widget hosting and physical device limits disclosed |
| Public repository | UNVERIFIED | Git origin known; public unauthenticated visibility needs verification |
| Rights / project license | PARTIAL | Dependency inventory exists; inherited assets/owner project license unresolved |
| HackYeah skills / AGENTS | UNVERIFIED | No applicable workspace/ancestor AGENTS; requested skills not found in checked user skill roots; not used or required for reproducible existing build |

## Scope decision

Retain the working API 21 template. API 20 may be feasible but was not established by lowering a declaration or checking one API. The official API-20-or-later requirement is met by 21; the where-applicable minimum-20 clause remains unverified. No fabricated dependency forces API 21. Actual API 20 support is not claimed.

Remaining deliverables are separate from implementation: record a brief demo, review rights/signing for the intended distribution, and submit via the actual competition channel. Details and final audit evidence follow after validation.

## Final audit after documentation/build validation

| Item | Final status | Evidence / boundary |
|---|---|---|
| HarmonyOS target, native ArkTS/ArkUI, Phone + Tablet | PASS | Existing Stage products/profiles unchanged; actual emulator install/launch |
| Compatible SDK | PASS for API >=20 / UNVERIFIED for API 20 | 6.0.1(21) for both; API 20 minimum not demonstrated |
| Compile SDK | PASS | Explicit compileSdkVersion absent; actual DevEco build scripts/SDK ETS metadata use 6.0.1.112 API 21; not the official newer starter's API 23 configuration |
| Target SDK / runtimeOS | PASS | Both targetSdkVersion 6.0.1(21), runtimeOS HarmonyOS |
| Fresh native HAP outputs | PASS | Optional -Clean actually executed; fresh file timestamps/hashes and installed emulator artifacts in TESTING |
| Setup/build/install/launch reproducibility | PASS in tested environment | Source-only git archive at b699764; no oh_modules/node_modules/build/local.properties; OHPM install --all + npm ci + both builds/tests succeed with installed vendor tools |
| Independent fresh Windows installation | UNVERIFIED | Existing user tool/registry/SDK caches remain required; not an OS/SDK install test |
| Platform capability evidence | PASS | PLATFORM_CAPABILITIES maps actual native APIs to source/status/limitations |
| Public source repository | PASS | Unauthenticated GitHub API metadata returned private=false for project origin |
| AI_WORKFLOW and optional product AI docs | PASS within evidenced history | Actual tools/prompt patterns/review/tests/failures/status disclosure; no invented human review/live inference |
| Architecture | PASS | Exact state/persistence/network/offline ownership and two separate insight pipelines |
| Testing | PASS within executed cases | Current 87 native host checks + clean-source backend 23; current emulator smoke plus explicitly historical complete game tests |
| Demo script/claim mapping | PASS (documentation) | 75-90 second plan, actual claims/evidence and edit limitations |
| Recorded demonstration | MISSING | Human must record/save/review/upload; script is not a recording |
| API 20 runtime, physical signing/device, widget hosting, live cloud AI | UNVERIFIED | Excluded from verified claims |
| Rights/license | PARTIAL | Dependency/original-asset inventory; no invented project license or starter rights |
| Tracked-file repository hygiene | PASS for scan scope | No recognized key/token/private-key/user-specific path/forbidden generated files found; blank env example allowed; not an exhaustive security/personal-data certification |
| Required competition-platform upload / eligibility | UNVERIFIED | Actual submission process/acceptance remains outside code execution |

Missing mandatory deliverable: recorded demonstration. Partial release readiness: unsigned packages are working in tested development emulators, but physical/release distribution is unverified. No full-compliance claim is made. The supplied official repository has no root AGENTS.md; guidance shipped inside other project templates is not silently applied to this existing non-Conductor project. Requested official skills were not found in the inspected installation roots.
