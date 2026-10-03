# Current official submission checklist

Source: [official challenge](https://github.com/onirodeveloper/hackyeah2026-challenge/blob/main/hackathon_challenge.md), read 2026-10-04. No eligibility/acceptance or numeric score is asserted. COMPLIANCE_MATRIX holds the full audit.

| Deliverable / condition | Status | Evidence / remaining action |
|---|---|---|
| Public source repository | PASS | Unauthenticated GitHub metadata returned private=false for llllmmmmyyyy/CompanionOS |
| Native HarmonyOS target / API >=20 | PASS | Stage ArkTS/ArkUI; actual compatible/target/effective compile API 21 |
| Minimum API 20 where applicable | UNVERIFIED | Minimum remains 21; API 20 SDK/runtime not tested; no fabricated API-21-only reason |
| Functional emulator app | PASS | Real API 21 Phone/Tablet HDC install, launch, gameplay/control evidence |
| Working HAPs | PASS (development emulator scope) | Fresh Phone/Tablet artifacts in README/TESTING; unsigned and accepted by tested emulators |
| Signed physical/release distribution | UNVERIFIED | Actual device/account/signing required if intended distribution needs it |
| Reproducible setup/build/install/launch | PASS within existing Windows SDK scope | Source-only OHPM/npm restoration; both builds/tests; README commands; fresh OS installation NOT RUN |
| Brief recorded demo | MISSING | Record real sequence using DEMO_SCRIPT; no saved recording or final upload produced |
| Architecture / implementation description | PASS | ARCHITECTURE distinguishes Tablet raw-event and Phone fallback insight pipelines |
| AI development disclosure | PASS within known history | AI_WORKFLOW records actual Codex prompts/work, tests/mocks/failures and unavailable skills |
| Optional product AI documentation | PASS (documentation) | AI_WORKFLOW / AI_ARCHITECTURE / AI_SERVICE; live providers NOT VERIFIED |
| Real platform capability | PASS | Native lifecycle, Preferences, ArkUI gestures/Video; dated notification/picker evidence |
| Widget hosting / production distributed transport | UNVERIFIED / not implemented | Excluded from verified demo claim; development relay explicitly labelled |
| Privacy / safety inventory | PASS (implementation inventory) | Local-first/no monitoring/descriptive rules; security/legal/child-usability certification not claimed |
| License / inherited starter rights | PARTIAL | THIRD_PARTY inventory exists; owner must resolve project license and inherited asset rights |
| Secret / tracked-output hygiene | PASS for executed scan scope | Ignore rules + tracked-file pattern scan; no blanket security certification |
| Competition platform upload / eligibility | UNVERIFIED | Human must verify real channel/eligibility and upload reviewed artifacts/recording |

Minimal remaining submission work: save/review the 75-90 second recording; resolve rights and intended signing/distribution; upload actual source link, HAP(s), recording and English documentation through the real competition channel. Do not claim all mandatory deliverables are complete while the recording is missing.
