import { dayKey } from './Companion';
export const EVENT_TYPES: string[] = ['ACTIVITY_STARTED', 'ACTIVITY_COMPLETED', 'ACTIVITY_SKIPPED', 'ANSWER_SELECTED', 'ANSWER_CORRECT', 'ANSWER_INCORRECT', 'RETRY', 'NEED_MORE_TIME', 'PAUSE', 'RESUME', 'HINT_USED', 'ACTIVITY_REPEATED', 'FEEDBACK_SUBMITTED', 'MOVEMENT_CONFIRMED'];
export class ChildInteractionEvent {
  eventId: string = ''; sessionId: string = ''; activityId: string = ''; activityCategory: string = '';
  activityMode: string = 'GUIDED_OFFSCREEN'; gameType: string = ''; timestamp: number = 0;
  eventType: string = ''; attemptNumber: number = 0; elapsedSeconds: number = -1;
  difficulty: string = 'Gentle'; contentSource: string = 'BUILT_IN'; demo: boolean = false; selectedAnswer: string = ''; plannedMinutes: number = 0;
  feedback: string = ''; difficultyFeedback: string = ''; repeatFeedback: string = '';
}
export class BehaviorData { version: number = 1; events: ChildInteractionEvent[] = []; }
export function parseBehavior(raw: string): BehaviorData {
  try {
    const data = JSON.parse(raw) as BehaviorData;
    if (!data || data.version !== 1 || !Array.isArray(data.events) || data.events.length > 2000 || !data.events.every((e: ChildInteractionEvent) =>
      e && typeof e.eventId === 'string' && e.eventId.length <= 140 && typeof e.sessionId === 'string' && e.sessionId.length <= 100 &&
      typeof e.activityId === 'string' && e.activityId.length <= 80 && ['MOVE', 'LEARN', 'CREATE', 'CALM'].includes(e.activityCategory) &&
      ['VIDEO', 'INTERACTIVE', 'GUIDED_OFFSCREEN'].includes(e.activityMode) && ['', 'CHOICE', 'MEMORY_SEQUENCE', 'SORTING', 'MOVEMENT_CHALLENGE'].includes(e.gameType) &&
      EVENT_TYPES.includes(e.eventType) && Number.isFinite(e.timestamp) && e.timestamp > 0 &&
      Number.isFinite(e.elapsedSeconds) && e.elapsedSeconds >= -1 && e.elapsedSeconds <= 86400 &&
      Number.isInteger(e.attemptNumber) && e.attemptNumber >= 0 && e.attemptNumber <= 1000 && typeof e.demo === 'boolean' &&
      ['Gentle', 'Standard', 'Hard'].includes(e.difficulty) && ['BUILT_IN', 'GEMINI_AI', 'HUAWEI_AI', 'USER_VIDEO'].includes(e.contentSource) &&
      ['', 'Liked', 'Okay', 'Disliked'].includes(e.feedback) && ['', 'Too easy', 'Just right', 'Too hard'].includes(e.difficultyFeedback) &&
      ['', 'Yes', 'Maybe', 'No'].includes(e.repeatFeedback))) { return new BehaviorData(); }
    data.events.forEach((e: ChildInteractionEvent) => { if (typeof e.selectedAnswer !== 'string' || e.selectedAnswer.length > 160) { e.selectedAnswer = ''; } if (!Number.isFinite(e.plannedMinutes) || e.plannedMinutes < 0 || e.plannedMinutes > 10) { e.plannedMinutes = 0; } });
    return data;
  } catch { return new BehaviorData(); }
}
export function appendEvent(data: BehaviorData, event: ChildInteractionEvent): BehaviorData {
  if (data.events.some((e: ChildInteractionEvent) => e.eventId === event.eventId)) { return data; }
  const next = new BehaviorData(); next.events = [...data.events, event].slice(-2000); return parseBehavior(JSON.stringify(next));
}
export class InsightMetrics {
  started: number = 0; completed: number = 0; skipped: number = 0; retries: number = 0; repeated: number = 0;
  attempted: number = 0; correct: number = 0; moreTime: number = 0; sample: string = 'Not enough data yet';
}
export function sampleLabel(count: number): string { return count < 3 ? 'Not enough data yet' : count < 6 ? `Early pattern based on ${count} activities` : `Recent pattern based on ${count} activities`; }
export class BehaviorInsightEngine {
  static window(data: BehaviorData, days: number, now: number): ChildInteractionEvent[] {
    return data.events.filter((e: ChildInteractionEvent) => !e.demo && e.timestamp <= now &&
      (days === 1 ? dayKey(e.timestamp) === dayKey(now) : e.timestamp >= now - days * 86400000));
  }
  static metrics(events: ChildInteractionEvent[]): InsightMetrics {
    const metrics = new InsightMetrics();
    metrics.started = new Set(events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_STARTED').map((e: ChildInteractionEvent) => e.sessionId)).size;
    const starts = events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_STARTED').map((e: ChildInteractionEvent) => e.sessionId);
    metrics.completed = new Set(events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_COMPLETED' && starts.includes(e.sessionId)).map((e: ChildInteractionEvent) => e.sessionId)).size;
    metrics.skipped = new Set(events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_SKIPPED' && starts.includes(e.sessionId)).map((e: ChildInteractionEvent) => e.sessionId)).size;
    metrics.retries = events.filter((e: ChildInteractionEvent) => e.eventType === 'RETRY').length;
    metrics.repeated = events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_REPEATED').length;
    metrics.attempted = events.filter((e: ChildInteractionEvent) => e.eventType === 'ANSWER_SELECTED').length;
    metrics.correct = events.filter((e: ChildInteractionEvent) => e.eventType === 'ANSWER_CORRECT').length;
    metrics.moreTime = events.filter((e: ChildInteractionEvent) => e.eventType === 'NEED_MORE_TIME').length;
    metrics.sample = sampleLabel(metrics.started); return metrics;
  }
  static score(events: ChildInteractionEvent[], category: string, gameType: string): number {
    const relevant = events.filter((e: ChildInteractionEvent) => e.activityCategory === category && e.gameType === gameType);
    if (BehaviorInsightEngine.metrics(relevant).started < 3) { return 0; }
    return relevant.reduce((score: number, e: ChildInteractionEvent) => score + (e.eventType === 'ACTIVITY_COMPLETED' ? 1 :
      e.eventType === 'ACTIVITY_SKIPPED' ? -2 : e.eventType === 'ACTIVITY_REPEATED' ? 2 : e.eventType === 'FEEDBACK_SUBMITTED' ? (e.feedback === 'Liked' ? 3 : e.feedback === 'Disliked' ? -3 : 0) : 0), 0);
  }
  static recommendGame(events: ChildInteractionEvent[], fallback: string): string {
    const types: string[] = ['CHOICE', 'MEMORY_SEQUENCE', 'SORTING'];
    let chosen = fallback; let highest = BehaviorInsightEngine.score(events, 'LEARN', fallback);
    types.forEach((type: string) => { const score = BehaviorInsightEngine.score(events, 'LEARN', type); if (score > highest) { chosen = type; highest = score; } });
    return chosen;
  }
  static recommendDifficulty(events: ChildInteractionEvent[], fallback: string): string {
    const feedback = events.filter((e: ChildInteractionEvent) => e.activityCategory === 'LEARN' && e.eventType === 'FEEDBACK_SUBMITTED' && e.difficultyFeedback !== '');
    if (feedback.length < 3) { return fallback; }
    const hard = feedback.filter((e: ChildInteractionEvent) => e.difficultyFeedback === 'Too hard').length;
    const easy = feedback.filter((e: ChildInteractionEvent) => e.difficultyFeedback === 'Too easy').length;
    return hard > feedback.length / 2 ? 'Gentle' : easy > feedback.length / 2 ? 'Standard' : fallback;
  }
  static rate(done: number, starts: number): string { return starts > 0 ? `${Math.round(done * 100 / starts)}%` : 'Not enough data yet'; }
  static guidedMinutes(events: ChildInteractionEvent[], category: string): number {
    const completed = events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_COMPLETED').map((e: ChildInteractionEvent) => e.sessionId);
    return events.filter((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_STARTED' && completed.includes(e.sessionId) &&
      e.activityMode !== 'VIDEO' && (category === '' || e.activityCategory === category)).reduce((sum: number, e: ChildInteractionEvent) => sum + e.plannedMinutes, 0);
  }
  static formats(events: ChildInteractionEvent[]): string[] {
    return ['INTERACTIVE', 'VIDEO', 'GUIDED_OFFSCREEN'].map((mode: string) => {
      const relevant = events.filter((e: ChildInteractionEvent) => e.activityMode === mode);
      const m = BehaviorInsightEngine.metrics(relevant);
      const liked = relevant.filter((e: ChildInteractionEvent) => e.eventType === 'FEEDBACK_SUBMITTED' && e.feedback === 'Liked').length;
      return `${mode}: ${m.completed}/${m.started} marked complete (${BehaviorInsightEngine.rate(m.completed, m.started)}); ${m.skipped} skipped, ${m.repeated} repeated, ${liked} liked. Why? Local events in the selected window; ${m.sample.toLowerCase()}.`;
    });
  }
  static challenge(events: ChildInteractionEvent[]): string[] {
    const selected = events.filter((e: ChildInteractionEvent) => e.eventType === 'ANSWER_SELECTED');
    const challenges = new Set(selected.map((e: ChildInteractionEvent) => e.sessionId)).size;
    const wrong = events.filter((e: ChildInteractionEvent) => e.eventType === 'ANSWER_INCORRECT');
    const wrongIds = Array.from(new Set(wrong.map((e: ChildInteractionEvent) => e.sessionId)));
    const retried = wrongIds.filter((id: string) => events.some((e: ChildInteractionEvent) => e.sessionId === id && e.eventType === 'RETRY')).length;
    return [challenges > 0 ? `Average answers selected: ${(selected.length / challenges).toFixed(1)} per attempted challenge.` : 'No task responses yet.',
      `After a wrong answer, tried again in ${retried} of ${wrongIds.length} challenges. Why? Explicit incorrect-answer and retry events in this window; no ability assessment.`];
  }
  static weekly(data: BehaviorData, now: number): string[] {
    const lines: string[] = [];
    for (let offset = 6; offset >= 0; offset--) {
      const date = new Date(now); date.setDate(date.getDate() - offset);
      const events = BehaviorInsightEngine.window(data, 1, date.getTime());
      lines.push(`${dayKey(date.getTime())}: MOVE ${BehaviorInsightEngine.guidedMinutes(events, 'MOVE')} min | LEARN ${BehaviorInsightEngine.guidedMinutes(events, 'LEARN')} min`);
    }
    return lines;
  }
  static observations(events: ChildInteractionEvent[]): string[] {
    const metrics = BehaviorInsightEngine.metrics(events); const lines: string[] = [metrics.sample];
    if (metrics.started < 3) { lines.push('Why am I seeing this? At least three non-Demo starts are needed. Older records have unknown interaction fields.'); return lines; }
    lines.push(`${metrics.completed} of ${metrics.started} started activities were marked complete; ${metrics.skipped} were skipped. Remaining starts may be unfinished.`);
    lines.push(`Why am I seeing this? Based on local starts and parent-confirmed completion events in this time window.`);
    if (metrics.retries > 0) { lines.push(`${metrics.retries} explicit retries were recorded after incorrect task responses. Why? RETRY events, not a personality or attention assessment.`); }
    if (metrics.moreTime > 0) { lines.push(`Need more time was chosen ${metrics.moreTime} times. Why? Explicit button interactions; movement is not sensor-verified.`); }
    const interactive = BehaviorInsightEngine.metrics(events.filter((e: ChildInteractionEvent) => e.activityMode === 'INTERACTIVE'));
    const video = BehaviorInsightEngine.metrics(events.filter((e: ChildInteractionEvent) => e.activityMode === 'VIDEO'));
    if (interactive.started >= 3 && video.started >= 3) {
      lines.push(`Interactive: ${interactive.completed}/${interactive.started} marked complete. Video: ${video.completed}/${video.started}. Why? Both formats have at least three starts; no causal claim.`);
    } else { lines.push('Not enough data to compare Interactive and Video: each format needs three starts.'); }
    ['MOVE', 'LEARN', 'CREATE', 'CALM'].forEach((category: string) => {
      const m = BehaviorInsightEngine.metrics(events.filter((e: ChildInteractionEvent) => e.activityCategory === category));
      if (m.started >= 3) { lines.push(`${category}: ${m.completed}/${m.started} marked complete, ${m.skipped} skipped. Why? At least three local starts in this category.`); }
    });
    ['CHOICE', 'MEMORY_SEQUENCE', 'SORTING', 'MOVEMENT_CHALLENGE'].forEach((game: string) => {
      const m = BehaviorInsightEngine.metrics(events.filter((e: ChildInteractionEvent) => e.gameType === game));
      if (m.started >= 3) { lines.push(`${game}: ${m.repeated} repeats, ${m.completed}/${m.started} marked complete. Why? Matching game-type events, not a learning ability measure.`); }
    });
    const shorter = BehaviorInsightEngine.metrics(events.filter((e: ChildInteractionEvent) => e.plannedMinutes > 0 && e.plannedMinutes < 5));
    const longer = BehaviorInsightEngine.metrics(events.filter((e: ChildInteractionEvent) => e.plannedMinutes >= 5));
    if (shorter.started >= 3 && longer.started >= 3) {
      lines.push(`Shorter activities: ${shorter.completed}/${shorter.started} complete; five minutes or longer: ${longer.completed}/${longer.started}. Why? Planned duration groups with three starts each; time is not measured exercise.`);
    }
    return lines;
  }
}
