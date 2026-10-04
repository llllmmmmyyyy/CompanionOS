# Interactive activities

Primary gameplay runs on Tablet API 21, using reusable native ArkUI scenes and the local WorldEngine. Phone retains the older five GameBoard activities only as explicit fallback. Do not confuse those older quiz-style checks with the primary world tests below.

| Mission | Actual mechanics | Observable goal / style |
|---|---|---|
| Dino Bridge Builder | Five existing stones, three draggable matching gaps; invalid drop returns, retry; all placements repair bridge and characters cross | counting/addition, BUILDING |
| Robot Memory Repair | Four physical colored panels flash a 2/3/4/5-signal sequence, input blocked during preview; wrong input/retry; correct sequence activates robot | ordered recall, MEMORY |
| Animal Rescue World | Tap an animal then a visible land/water zone; wrong placement/retry; all three animate into habitats | environmental classification, SORTING |
| Star Collector | Collect all five blue stars; amber target is invalid; repeats do not count twice; gate opens | counting/colors, COUNTING |
| Copy Pico | Animated safe tiny penguin steps or seated arm moves, ten-second foreground demonstration, More time, gated Done or Skip | child-confirmed MOVEMENT |
| Number Move | Four actual blue crystals required, amber rejected; then ten-second character demonstration and Done | counting plus child-confirmed MOVEMENT |
| Build the Rocket | Circle/triangle/rectangle drag into corresponding target positions; wrong placement retries; three fitted pieces launch rocket | spatial matching, BUILDING |
| Creative Garden | Choose palette and tap garden positions to place flowers; finish after at least one placement; no correctness judgement | open CREATING |
| Calm Sky (Breathe with the Cloud) | Watch the cloud, breathe slowly and tap gently; slow expansion/contraction, soft tap fade, optional finish; no score/accuracy | unscored EXPLORING / CALM |
| Storybook / Help the Cloud Find Home | Existing native cloud video (or selected reviewed URI), then three gentle cloud waypoints by drag or cloud-tap/target-tap; one Return to World after reaching the sky; early Skip is not completion | WATCHING, descriptive hybrid story |

Original graphics are authored vectors/native shapes, not commercial characters or stock game scenes. No Unity/Flutter/web runtime, camera or risky equipment. Lightweight native motion represents consequences, not verified real-world learning or exercise.

Raw local events include MISSION_STARTED, OBJECT_SELECTED, OBJECT_DRAG_STARTED, OBJECT_PLACED, OBJECT_PLACED_INCORRECTLY, MISSION_RETRIED, SEQUENCE_ATTEMPT, MISSION_COMPLETED, ACTIVITY_SKIPPED, NEED_MORE_TIME, FEEDBACK_SUBMITTED, VIDEO_STARTED and VIDEO_COMPLETED. Meaningless ambient/Pico taps do not become diagnostic behavior events. The Phone receives compact outcomes only.

For exact per-game played/unplayed status and the actual test inputs, see TESTING.md. A rendered scene alone is never a completed gameplay test.
