# Descriptive parent insights

The Parent Dashboard consumes **Tablet compact outcomes**, not a stream of raw child clicks. The Tablet raw journal remains local. ParentWorldStore persists up to 300 summaries; stable mission IDs prevent reconnect/replay duplicates. Phone-only BehaviorInsightEngine and its existing Today/7/30-day views remain available and use their separately labelled Phone raw events.

Tablet summaries contain mission ID/session, actual title/style/category, completed or skipped, attempts/retries, foreground duration, optional feedback/difficulty and child-confirmed movement. Unknown/not-provided feedback remains unknown. Child completion is not labelled as parent confirmation. Foreground time is not sensor-verified exercise, clinical attention or a developmental score.

Styles: BUILDING, MEMORY, SORTING, COUNTING, EXPLORING, CREATING, MOVEMENT, WATCHING. These describe interaction formats, never personalities.

Home shows one plain-language observation from the default seven-day window. The full Insights view starts with up to three observations and one optional next-experience suggestion, with Today/7 days/30 days controls. Structured metrics and retained history are secondary, behind Recent patterns. Play/Watch/Move counts are not a preference ratio of offered choices; the app does not fabricate an offer denominator.

Why am I seeing this opens recorded per-mission evidence: outcome, attempts, retries, foreground duration and optional feedback. A retry can reflect experimentation; it is not automatically a deficit. Comparing formats needs comparable sample sizes and context. No IQ, ADHD, anxiety, intelligence or clinical attention inference is made.

Recommendations use at least three recent outcomes per eligible LEARN game. Completion/skip and explicit liked/disliked feedback affect the next suggested mission. Three or more explicit memory difficulty responses with a majority Tricky can reduce the sequence to two signals. Parents can select 2-5 signals. SessionBalanceEngine still protects MOVE/LEARN/CREATE/CALM and passive-video limits; recommendations cannot turn the plan into only a preferred game or passive video.

Local development-emulator records are test inputs, not observations from a recruited child. This implementation has no evidence of educational effectiveness or validated psychometric properties. No raw behavior journal is uploaded to Gemini/Huawei. Parents should interpret patterns descriptively and with their own context.

## ParentInsightSummaryEngine

Data flow: saved Tablet compact outcomes → temporary mission-level start/outcome adapter → **BehaviorInsightEngine.metrics** → **ParentInsightSummaryEngine** → parent-language observation/suggestion → exact outcome evidence. The existing BehaviorInsightEngine is retained. The adapter uses each stable mission ID once, not its multi-mission session ID; it never persists invented interaction events. Only known outcomes are in this denominator; unfinished starts are unknown. Windows exclude future timestamps, invalid records, duplicates and older outcomes; Today follows the Phone local calendar, 7/30 days are rolling windows.

This is **local, deterministic, descriptive, non-clinical and evidence-backed**. No model, API key or network call is needed to summarize saved data. Existing compact-outcome sync to the Windows demo relay is unchanged; raw child click/event journals remain on Tablet. The summarizer does not invoke Gemini/Huawei/provider adapters. Optional future model phrasing is not implemented.

| Rule | Required evidence | Parent wording |
|---|---|---|
| Completion | At least 3 outcomes in a style and at least 75% completed; highest rate wins, ties prefer larger sample then fixed style order | Building/Memory/Movement/etc. activities were usually completed in this period |
| Memory retry | At least 3 memory outcomes, at least half with recorded retries | Memory missions often needed another try |
| Format completion | At least 3 play and 3 story outcomes, play completion rate at least 25 percentage points higher | Recorded play activities were completed more consistently than stories |
| Positive feedback | At least 3 explicit responses in a style, at least 75% Loved it; most positive responses wins | Building/etc. activities often received Loved it feedback |
| Mixed/sparse | No qualifying pattern; report only factual completion variation, no completions, or too few group outcomes | Activity completion varied in this period / No activities were recorded as completed / Too few outcomes for a group pattern |

Priority is qualifying completion, memory retries, format completion, then feedback; only the first three observations are delivered. Each observation and the suggestion carries its own source rows, threshold explanation, recorded completion/skip/retry counts and per-mission title/date/outcome/feedback/ID. Why am I seeing this? expands/collapses this evidence. Structured per-style evidence remains available separately. Evidence may reflect development/demo interactions and must not be presented as a child study.

Overall window sample labels: fewer than 3 outcomes **NOT ENOUGH DATA**, 3–5 **EARLY PATTERN**, 6+ **RECENT PATTERN**. These are sample-count labels, not statistical confidence or educational effectiveness. Individual rules still need their own minimum group/feedback samples. Fewer than 3 overall outcomes yields only: "Complete a few more adventures to start seeing reliable activity patterns." No observation claim, suggestion or evidence is forced.

Suggestions are read-only: qualifying memory retries suggest trying a shorter sequence together; otherwise qualifying completion can retain a familiar/building activity; mixed outcomes suggest a familiar experience without a preference claim. Every suggestion explicitly retains learning, movement, creating and calm time. The summary never mutates settings, invokes START_SESSION or bypasses SessionBalanceEngine. Existing recommendations and parent controls remain separate.

Stored outcomes do not include offered-choice sets, memory sequence length, planned per-mission minutes, repeat-interest or prior difficulty context. Therefore the engine does **not** claim interactive play was chosen over video, longer memory caused retries, short movement outperformed longer movement or an improvement trend. It uses recorded completion, skip, attempts/retries, style/category and explicit feedback where sufficient. Foreground duration/difficulty feedback remain accessible as recorded detail but are not promoted to unsupported causal summaries. Output sentences come from fixed observable-behavior templates, never child titles/free-form cloud text or psychological labels.

Actual existing demo journal: Storybook 4/4 completed; building feedback 4 Loved it out of 5 explicit responses. These produce "Story activities were usually completed in this period" and "Building activities often received Loved it feedback", not a fabricated building-completion advantage (building was 7/16). See TESTING.md for the real API 21 check and synthetic edge-case tests.