# Third-party inventory

| Item | Actual use | License / evidence |
|---|---|---|
| HarmonyOS SDK and DevEco Studio | Native ArkTS/ArkUI compilation, system APIs and inherited project template | Installed vendor SDK/tooling; governed by their supplied terms. This document does not assign an open-source license to the entire SDK. |
| `@ohos/hypium` 1.0.24 | Existing template development/test dependency | Installed `oh-package.json5` declares Apache-2.0. |
| `@ohos/hamock` 1.0.0 | Existing template mock/test development dependency | Installed `oh-package.json5` declares Apache-2.0 and carries an Apache-2.0 header. |
| SDK-bundled TypeScript compiler | Host test transpilation of actual `.ets` domain/service files | Used from the local SDK; not copied or vendored into the repository. Its distribution contains the applicable package notices. |
| Node and Java bundled with DevEco | Build and host checks | Used from their installed locations; not redistributed by this repository. |
| Starter PNGs / layered icon resources | Existing launcher/start-window artwork in AppScope and entry | Inherited from the user's DevEco-created project. A separate asset license was not found in this workspace; confirm rights before public distribution. |
| Activity copy and ArkUI/card UI code | Written/updated in this AI-assisted development run | Project ownership/license has not been declared; no project-wide license is invented here. |

Backend development adds TypeScript 5.9.3 (Apache-2.0), @types/node 24.19.1 (MIT), and transitive undici-types (MIT), verified in installed metadata/lockfile. Runtime uses Node built-ins; no Express/Google SDK is included. HarmonyOS uses a local shared HAR and native HTTP/Video.

The bundled `tventry/src/main/resources/rawfile/fallback.mp4` is an original eight-second 1280×720 cloud illustration made from programmatic shapes in this run, not Veo or stock content. This small clip is intentionally committed. It was encoded with local @ffmpeg-installer/win32-x64 4.1.0 tooling (metadata declares GPLv3); the binary and temporary inputs are ignored and not redistributed. No project-wide asset/code license is invented. Live generated media/cache remains ignored under backend/data.

The existing Hypium/hamock template test files were retained; their original sample tests are not represented as full MVP coverage. Current checks use Node built-in modules and the locally installed SDK compiler. Public dependency artifacts remain excluded from Git; `oh-package-lock.json5` preserves package versions and integrity metadata.

Official references consulted for API usage include [basic notifications](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V2/text-notification-0000001478340981-V2), [widget lifecycle](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/arkts-ui-widget-lifecycle-V5), and the actual installed API 21 declarations and DevEco widget templates. Documentation references are not claims of code or asset licensing.
