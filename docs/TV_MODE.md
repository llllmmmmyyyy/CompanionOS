# Large-Screen Companion (Tablet API 21)

This replaces the former API 19 TV target. Filename and internal TvAbility/TvReceiver/TvMessage identifiers are retained to avoid breaking imports/protocols. Historical TV testing remains labelled in TESTING.md, not part of the current formal target.

## Targets

Primary Phone: entry / product default / compatible and target API 21 / phone. Optional companion: tventry / product tablet / compatible and target API 21 / tablet. Shared HAR supports phone/tablet. Reused Hvigor module tasks remain stage-mode; no new project or media/transport framework.

## Data and control

Phone owns settings, timers, parent confirmation and journal. START/PAUSE/RESUME/NEXT/CANCEL use the unchanged validated shared protocol, transient Windows backend relay and family-demo room. Both emulator guests connect to http://10.0.2.2:18080. TV-style wire routes/feedback fields remain internal compatibility names. Connection errors are visible; Phone offers Continue on phone. Native distributed-device deployment is not claimed.

## UI

TvHome remains native ArkUI/Video with VideoController. Landscape is requested through the existing Window API. Video/content fills the flexible central area; title, instruction and progress stay readable. Connection endpoint/room are shown for setup/failure rather than dominating active playback. Reduced margins and bounded text improve Tablet fit; Connect has a 48vp touch target. Portrait/formal accessibility require separate verification.

## Build/run

From repository root use scripts/build.ps1 -Module tventry through the scriptblock command in README. Output: tventry/build/tablet/outputs/default/tventry-default-unsigned.hap. Select tablet / tventry / MatePad Pro 11 API 21 in DevEco. Launch retained TvAbility. Connect receiver, then on Phone select Play on Large Screen -> Connect to Emulator Tablet. Same-phone Demo Large Screen is separate from the actual Tablet.

Backend: cd backend; npm.cmd ci; npm.cmd run build; npm.cmd start. Node 22+ required, no key needed for relay/Built-in. Guest loopback is not used to reach Windows. scripts/run-emulator-demo.ps1 -Tablet <target> automates setup and preserves -Tv alias for old scripts.

## Evidence and limits

See the latest TESTING.md section for actual current build/device results. Historical API 19 TV success does not prove Tablet success. Unsigned development HAPs, emulators, optional media review and foreground notifications are not a physical-device/production claim. No live cloud success is implied.
