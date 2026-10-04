# Pico native animation system

Pico uses the existing Tablet mascot SVG separated into seven transparent vector layers. Its eyes, mouth, arms and feet articulate independently; breathing and floating are additional effects. Existing whole-Pico catalog art remains unchanged.

## Reusable architecture

- `shared/PicoMascot.ets`: `action`, `cue`, `mascotSize`, `active`, `reducedMotion` inputs. Cue retriggers a short action with the same name. Native transforms animate shoulders/feet/eyes; eat opens a mouth; celebrate raises arms, hops and shows three brief stars.
- `shared/PicoAnimationController.ets`: finite 790ms enter → outgoing pull/collapse → navigation commit at 290ms → reveal → rest. Revision tokens cancel stale callbacks. Rapid tabs keep the newest destination. Lifecycle cancellation can settle a pending destination exactly once.
- `shared/PicoTransitionOverlay.ets`: non-interactive and accessibility-hidden overlay above navigation; page/scene transforms alongside Pico.
- `shared/src/main/resources/rawfile/pico-*.svg`: body, eyes, smile, left/right arms and feet, derived from original vector primitives without redesign.

## States

| State | Character motion |
|---|---|
| idle | Small breathing/float cycle and occasional blink |
| blink | Eye closure preserving the original face |
| wave | Right arm greeting |
| hop / bounce | Short vertical hop |
| walk / run | Alternating arms/feet, horizontal motion; run adds a hop |
| pull | Reaching arms and body lean while outgoing live content translates away |
| eat | Opening mouth while Phone content collapses toward Pico |
| reveal | Arm gesture and incoming panel reveal |
| point | Arm and gaze point toward content |
| celebrate | Raised arms, hop, three short gold stars |
| gentle-error | Small questioning tilt with a friendly face |

Short actions settle after about 900ms. Idle movement only continues while active. Native easing generally uses 260–300ms, blinking 100ms. Disappearance/background/reduced motion clear timers. Celebrations do not award rewards or loop indefinitely.

## Applied events

Phone: Home → Activities uses pull; Activities → Insights uses eat; Home → Parent, Parent → Home and other major activity/status/progress/summary destinations use reveal. The selected tab background/border interpolates over 280ms. Parent accepted start commands and fallback activity start cue Pico. Saved completions celebrate only after storage success. Generation/import/loading uses a waiting walk/blink; existing failures use gentle-error; Insights with no results points toward the next action. Header Pico adds no extra Start CTA.

Tablet: ChildWorld replaces its previous single-image mascot. Child Mode/session entry, local activity choice, learning-path choice, Continue and Back to World use reveal. Success/ending celebrates; feedback gets a neutral hop regardless of whether the child liked it; retry/storage/video failures tilt gently; video waiting uses walk/blink. Pause/background freeze the character. Existing authoritative resume remains unchanged.

**Reduce mascot motion** is available in Phone Parent and on Tablet. Flags are process-local and independent per device; no persistence schema or relay payload changed. Navigation becomes immediate and the recognizable static character remains.

## Limits and implementation fallback

No captured-page snapshot or shader is used. Phone outgoing native content genuinely scales/translates before swapping; Tablet authoritative commands apply immediately and the scene receives a presentation reveal. The controller never changes sessions, records, memory sequences, paused time or garden rewards. Overlays do not intercept taps. Small foreground action cues use lightweight transforms rather than full animation clips.

No new dependency, generated/downloaded artwork, camera permission or analytics was added. Physical-device frame-rate/battery studies, child usability and destructive empty/storage-failure fixtures are pending. See [TESTING.md](TESTING.md) for measured verification.
