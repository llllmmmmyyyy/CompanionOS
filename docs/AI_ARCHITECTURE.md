# AI activity and video architecture

## Implemented now

`AiActivityService.generateActivityPlan(ActivityPlanRequest)` returns an `ActivityPlan` containing title, theme, structured steps and video prompts. `MockAiActivityService` deterministically chooses safe curated content for MOVE, LEARN, IMAGINE or CALM. It validates the supported age group and duration. UI labels these plans **Mock plan**, never real AI. Converted activities expose category, duration, theme, educationalGoal, detailed `activitySteps`, videoSegments and generatedByAI. Existing `steps: string[]` stays as a compatible phone presentation; `activitySteps` is the structured step contract. Completion schema version 1 is unchanged.

No Gemini/Veo credentials, backend implementation or generated videos are present. The existing optional recommendation endpoint remains separate from activity-plan generation. Client validation catches malformed step durations, unsupported sources and non-HTTPS video references; this is structural validation, not a complete content moderation system.

## Future server pipeline

Phone → authenticated HTTPS backend → Gemini structured plan → server safety review → Veo short segments → private cached assets / expiring HTTPS URLs → phone or TV receiver. Secrets belong only in server environment variables. Never put provider keys in ArkTS, preferences, URLs, documentation or the public repository. Use server rate limits, bounded timeouts, request size limits and minimal child information. No names, camera, microphone, location or monitoring data are required.

The backend must validate age, duration, adult accompaniment and safety before returning `source: "ai"`. Reject invalid output and use the curated mock/offline catalog. Cache plans/assets using a safe request/version key, apply retention limits, and return an asset expiry. A receiver should preload the next approved clip with a bounded timeout, never block the activity clock waiting for video, and switch to the local illustration on failure. The current player always uses this illustration; streaming is future work.

### Example future request

```json
{
  "childAge": "4–5",
  "interest": "Movement",
  "category": "MOVE",
  "durationMinutes": 3,
  "educationalGoal": "Count five gentle movements together"
}
```

### Example future response (illustrative, not a live response)

```json
{
  "source": "ai",
  "title": "Dino Movement Adventure",
  "theme": "Friendly dinosaurs",
  "adultAccompanied": true,
  "steps": [
    {"instruction":"Sit or stand comfortably beside your parent.","durationSeconds":60,"learningGoal":"Prepare a safe space","videoUrl":"","fallbackVisual":"Friendly dinosaurs"},
    {"instruction":"Count five tiny steps or gentle hand movements together.","durationSeconds":60,"learningGoal":"Count to five","videoUrl":"","fallbackVisual":"Friendly dinosaurs"},
    {"instruction":"Rest and share your favorite movement.","durationSeconds":60,"learningGoal":"Reflect together","videoUrl":"","fallbackVisual":"Soft clouds"}
  ],
  "videoPrompts": ["A friendly illustrated dinosaur takes tiny gentle steps in a clear peaceful space. Static camera, soft lighting, no flashing or danger."]
}
```

An empty video URL explicitly means local fallback; no invented asset URL is presented as playable.

### Sample Veo prompt

“A short gentle illustration of a friendly dinosaur slowly moving its hands in a peaceful clearing. Soft colors, steady camera, age appropriate for children 4–8. No predators, violence, frightening sounds, flashing/strobe lighting, jumping, climbing or dangerous objects. Include a quiet rest moment. Do not display text instructions; the application supplies approved instructions.”

## Safety review requirements

Use simple age-appropriate language and one instruction at a time. Avoid dangerous movements, violence, frightening imagery, flashing/strobe visuals, breath holding and unsafe physical challenges. Include seated alternatives, adult accompaniment, breaks and permission to stop. Enforce limits on clip duration, playback volume, activity duration and output size. Independently inspect generated videos; a safe prompt does not guarantee a safe result. Never implement camera or microphone monitoring for this MVP.

Provider integration should follow the current official [Gemini API documentation](https://ai.google.dev/gemini-api/docs) and [Veo video generation documentation](https://ai.google.dev/gemini-api/docs/video). Model availability, quota, cost and content review require verification when a real backend is added.
