# Parent Phone UI

## Scope

This iteration changes Phone presentation and navigation only. Tablet gameplay, WorldStatus/commands, SessionBalanceEngine, BehaviorInsightEngine, interaction event semantics and persistence remain unchanged.

## Information architecture

| Tab | Content |
|---|---|
| Home | Tablet status, one contextual primary action, compact session choices, real What We Noticed statistic and today's recorded foreground minutes |
| Activities | Play/Watch/Move/Create/Calm catalog; existing Video Library and optional Phone fallback activities |
| Insights | Seven-day styles, completion/retry/feedback counts, Play/Watch/Move counts, evidence, recent Tablet outcomes and links to separate Phone journals |
| Parent | Existing profile/settings route, saved session choices, memory signals, custom sliders, Child Mode exit and technical information |

Large Home buttons for settings, video, fallback, legacy insights and parent-confirmed progress were removed from the hierarchy, not deleted. Memory/custom sliders and transport/OS-lock disclaimers moved to Parent. Detailed balance-plan strings are absent from Home. Preset buttons use compact neutral surfaces; the selected preset is subtle, while Start Child Mode / Start Session / Resume / View Summary is the strongest accent.

## Real-state rendering

State is derived from the existing polled Tablet status, never fabricated locally. Disconnected takes precedence; inactive Child Mode takes precedence over a retained paused/ended session.

| State | Actions |
|---|---|
| DISCONNECTED | Reconnect (existing poll, with automatic retries also retained) |
| CONNECTED_IDLE | Start Child Mode |
| CHILD_MODE_READY | Start Session |
| SESSION_RUNNING | Pause, Next, smaller End Session |
| SESSION_PAUSED | Resume, smaller End Session |
| SESSION_COMPLETE (ended) | View Summary, neutral Start New Session |

The ended state says **Session complete** only when total > 0 and completed == total; early ending says **Session ended**. Exit Child Mode remains in Parent. Commands use the unchanged relay room family-demo and unchanged payloads. UI acknowledgement can lag by several polling cycles; HTTP success alone is not shown as a changed Tablet state. Sending disables command buttons; failures remain visible with details in Parent.

Duration defaults to 30 minutes for new installations; existing saved selections are preserved (the test device retained 15). Settings use the existing journal, not a new store. Today's minutes sum actual result duration by category, rounded down, not allocated budget. The quick insight reports observed BUILDING completions only after at least three building outcomes; otherwise it requests more activity data. No comparison, preference or diagnosis is invented.

## Routes and limitations

Index keeps the old activities, games, settings, insights and progress routes for existing features. Four parent root screens use home, parent-activities, parent-insights and parent-controls. Old Progress remains reachable as Parent-confirmed records, without mixing it into the Tablet journal. Existing detail Back returns Home. The Activities catalog does not remotely open individual games; children choose them on Tablet, and the existing Phone fallback remains optional.

Implementation: entry/src/main/ets/pages/Index.ets and ParentDashboard.ets. Testing: TESTING.md. The development relay limitation remains documented and visible under Parent > About / Technical Information. Physical small phones, large fonts and screen readers still need human verification.
