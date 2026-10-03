# Two-minute demo

Use a phone/emulator on API 21+, a signed debug build, and clearly labelled Demo Mode. This script describes a planned walkthrough; no video has been recorded automatically.

| Time | Action | English narration |
|---|---|---|
| 0:00–0:15 | Show Home and the three cards | “CompanionOS turns small activities into meaningful family moments. The three adventures work offline, with a parent beside the child.” |
| 0:15–0:35 | Open Parent Settings; choose age 6–8, Movement, and 3 minutes; save | “Parents choose an age group, interests and duration. Settings are saved locally. No child account, camera or location is needed.” |
| 0:35–0:55 | Open Penguin Walk and show its steps | “Each activity has simple steps, age guidance and an adult accompaniment reminder. The aim is to leave the screen and play together.” |
| 0:55–1:15 | Enable Demo Mode and start; wait ten seconds | “For this demonstration, Demo Mode shortens the countdown to ten seconds. Normal mode runs for the parent's selected three, five or ten minutes.” |
| 1:15–1:35 | Show time-up; check parent confirmation; mark completed; show Progress | “A foreground activity can submit a real system notification when allowed. Notification failure never blocks completion. Only the parent confirms the shared activity. One session produces one record.” |
| 1:35–1:50 | Show total, date, badge; return Home and request recommendation with empty endpoint | “Progress stays on this device. With no AI service configured, recommendations are honestly labelled offline. A future trusted service can recommend only one of these curated activities.” |
| 1:50–2:00 | Show the desktop widget if verified; otherwise finish on Home | “Our native widget offers today's activity and count, and opens the app. CompanionOS helps families spend more time together, away from the screen.” |

If notification delivery or widget hosting has not been verified, say “implemented, awaiting device verification” and show the in-app state instead of staging a fake notification/card. Do not describe a preset as live AI output or claim reliable background reminders.

## Record the walkthrough

1. Run the signed app using the README instructions and complete the device checks in `TESTING.md` first.
2. On the phone/emulator, open its quick settings and start **Screen recording**, or use an already available desktop recording tool to capture the emulator window. Record without private notifications or account information on screen.
3. Follow the timeline above. Keep Demo Mode visible. Use the actual parent confirmation and actual saved record; do not overlay fabricated UI or results.
4. Stop recording at about two minutes. Play the whole file back to check readable text, timing and audio. If the recorder has no microphone option, record narration separately or use accurate English subtitles.
5. Save the real recording as `CompanionOS-demo.mp4` outside tracked source/cache folders, then upload it through the competition's actual submission channel once that channel and its limits are known.

The video's path, duration and completion status should be entered in `SUBMISSION_CHECKLIST.md` only after the file exists and has been reviewed. No recorder was launched and no recording is claimed in this run.
