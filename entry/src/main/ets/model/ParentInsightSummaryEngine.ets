import { WorldResult, validWorldResult } from '@companion/protocol';
import { BehaviorInsightEngine, ChildInteractionEvent, InsightMetrics } from './BehaviorInsightEngine';

export class SummaryEvidence {
  sentence: string = ''; basis: string = ''; rows: WorldResult[] = [];
}
export class ParentInsightSummary {
  summaryTitle: string = 'What We Noticed';
  primaryObservation: string = 'Complete a few more adventures to start seeing reliable activity patterns.';
  secondaryObservation: string = ''; challengeObservation: string = '';
  nextSessionSuggestion: string = ''; confidenceLabel: string = 'NOT ENOUGH DATA';
  evidenceItems: SummaryEvidence[] = []; timeWindow: string = '7 days'; sampleSize: number = 0;
}
export class ParentInsightSummaryEngine {
  static window(rows: WorldResult[], days: number, now: number): WorldResult[] {
    const seen: string[] = [];
    return rows.filter((r: WorldResult) => {
      if (!validWorldResult(r) || !r.id || seen.includes(r.id) || r.timestamp > now ||
        (days === 1 ? new Date(r.timestamp).toDateString() !== new Date(now).toDateString() : r.timestamp < now - days * 86400000)) { return false; }
      seen.push(r.id); return true;
    });
  }
  // Aggregate outcomes adapt to the existing metric engine. Each mission ID is
  // one outcome sample, not the whole multi-mission session ID. Unfinished
  // starts are unknown in this journal and never added to the denominator.
  // These temporary events are never persisted or uploaded.
  static metrics(rows: WorldResult[]): InsightMetrics {
    const events: ChildInteractionEvent[] = [];
    rows.forEach((r: WorldResult) => {
      const start = new ChildInteractionEvent(); start.sessionId = r.id; start.eventType = 'ACTIVITY_STARTED'; events.push(start);
      const end = new ChildInteractionEvent(); end.sessionId = r.id; end.eventType = r.completed ? 'ACTIVITY_COMPLETED' : 'ACTIVITY_SKIPPED'; events.push(end);
    });
    const m = BehaviorInsightEngine.metrics(events);
    m.retries = rows.reduce((sum: number, r: WorldResult) => sum + r.retries, 0);
    m.attempted = rows.reduce((sum: number, r: WorldResult) => sum + r.attempts, 0);
    return m;
  }
  static add(summary: ParentInsightSummary, sentence: string, basis: string, rows: WorldResult[]): void {
    const item = new SummaryEvidence(); item.sentence = sentence; item.basis = basis; item.rows = rows.slice(); summary.evidenceItems.push(item);
  }
  static summarize(source: WorldResult[], days: number, now: number): ParentInsightSummary {
    const s = new ParentInsightSummary(); const rows = ParentInsightSummaryEngine.window(source, days, now);
    s.timeWindow = days === 1 ? 'Today' : `${days} days`; s.sampleSize = rows.length;
    s.confidenceLabel = rows.length < 3 ? 'NOT ENOUGH DATA' : rows.length < 6 ? 'EARLY PATTERN' : 'RECENT PATTERN';
    if (rows.length < 3) { return s; }
    const styles: string[] = ['BUILDING', 'MEMORY', 'SORTING', 'COUNTING', 'MOVEMENT', 'CREATING', 'EXPLORING', 'WATCHING'];
    const names: string[] = ['Building activities', 'Memory missions', 'Sorting activities', 'Counting activities', 'Movement activities', 'Garden activities', 'Calm activities', 'Story activities'];
    let best = -1; let bestRate = 0;
    styles.forEach((style: string, index: number) => {
      const m = ParentInsightSummaryEngine.metrics(rows.filter((r: WorldResult) => r.style === style));
      const rate = m.started ? m.completed / m.started : 0;
      if (m.started >= 3 && rate >= 0.75 && (rate > bestRate || (rate === bestRate && best >= 0 && m.started > rows.filter((r: WorldResult) => r.style === styles[best]).length))) { best = index; bestRate = rate; }
    });
    if (best >= 0) {
      const group = rows.filter((r: WorldResult) => r.style === styles[best]);
      ParentInsightSummaryEngine.add(s, `${names[best]} were usually completed in this period.`, 'At least three outcomes; at least three quarters completed. This describes completion, not preference or ability.', group);
    }
    const memory = rows.filter((r: WorldResult) => r.style === 'MEMORY');
    if (memory.length >= 3 && memory.filter((r: WorldResult) => r.retries > 0).length >= memory.length / 2) {
      ParentInsightSummaryEngine.add(s, 'Memory missions often needed another try.', 'At least three memory outcomes; at least half recorded a retry. Sequence length is not stored, so no length comparison is inferred.', memory);
    }
    const play = rows.filter((r: WorldResult) => ['BUILDING', 'MEMORY', 'SORTING', 'COUNTING'].includes(r.style));
    const watch = rows.filter((r: WorldResult) => r.style === 'WATCHING');
    const pm = ParentInsightSummaryEngine.metrics(play); const wm = ParentInsightSummaryEngine.metrics(watch);
    if (pm.started >= 3 && wm.started >= 3 && pm.completed / pm.started - wm.completed / wm.started >= 0.25) {
      ParentInsightSummaryEngine.add(s, 'Recorded play activities were completed more consistently than stories.', 'Each format has at least three outcomes and completion rates differ by at least 25 percentage points. These are assigned activity outcomes, not choices offered or a video preference.', [...play, ...watch]);
    }
    let feedbackIndex = -1; let feedbackCount = 0;
    styles.forEach((style: string, index: number) => {
      const group = rows.filter((r: WorldResult) => r.style === style && r.feedback !== '');
      const liked = group.filter((r: WorldResult) => r.feedback === 'liked').length;
      if (group.length >= 3 && liked >= group.length * 0.75 && liked > feedbackCount) { feedbackIndex = index; feedbackCount = liked; }
    });
    if (feedbackIndex >= 0) { ParentInsightSummaryEngine.add(s, `${names[feedbackIndex]} often received Loved it feedback.`, 'At least three explicit feedback responses; at least three quarters were Loved it. Unanswered feedback is excluded.', rows.filter((r: WorldResult) => r.style === styles[feedbackIndex] && r.feedback !== '')); }
    if (s.evidenceItems.length === 0) {
      const m = ParentInsightSummaryEngine.metrics(rows);
      const observation = m.completed === 0 ? 'No activities were recorded as completed in this period.' : m.completed === m.started ? 'The recorded activities were completed, but each activity group has too few outcomes for a pattern.' : 'Activity completion varied in this period.';
      ParentInsightSummaryEngine.add(s, observation, 'All recorded outcomes in the selected window; no preference is inferred from mixed or sparse category data.', rows);
    }
    const observations = s.evidenceItems.slice(0, 3);
    s.primaryObservation = observations[0].sentence; s.secondaryObservation = observations.length > 1 ? observations[1].sentence : '';
    s.challengeObservation = observations.length > 2 ? observations[2].sentence : '';
    s.evidenceItems = observations;
    let suggestionRows = rows; let basis = 'Mixed or limited category evidence. This is an optional suggestion; it never changes the saved session plan.';
    if (memory.length >= 3 && memory.filter((r: WorldResult) => r.retries > 0).length >= memory.length / 2) {
      s.nextSessionSuggestion = 'Try a shorter memory sequence together, while keeping learning, movement, creating and calm time.'; suggestionRows = memory;
      basis = 'Memory retry evidence above; trying a shorter sequence is an optional next experience, not a claim that longer sequences caused retries.';
    } else if (best >= 0) {
      s.nextSessionSuggestion = best === 0 ? 'Keep a building activity within learning time, alongside movement, creating and calm time.' : 'Keep a familiar activity alongside learning, movement, creating and calm time.';
      suggestionRows = rows.filter((r: WorldResult) => r.style === styles[best]); basis = 'Completion evidence above supports retaining a familiar activity, without changing category allocations.';
    } else { s.nextSessionSuggestion = 'Try a familiar activity together, keeping learning, movement, creating and calm time.'; }
    ParentInsightSummaryEngine.add(s, s.nextSessionSuggestion, basis, suggestionRows);
    return s;
  }
  static evidenceText(item: SummaryEvidence): string {
    const m = ParentInsightSummaryEngine.metrics(item.rows);
    const feedback = item.rows.filter((r: WorldResult) => r.feedback !== '');
    const feedbackLine = feedback.length > 0 ? `${feedback.filter((r: WorldResult) => r.feedback === 'liked').length} / ${feedback.length} explicit responses were Loved it.\n` : '';
    return `${item.sentence}\n${item.basis}\n${m.completed} / ${m.started} completed; ${m.skipped} skipped; ${m.retries} retries.\n${feedbackLine}` +
      item.rows.map((r: WorldResult) => `${r.title} | ${new Date(r.timestamp).toLocaleDateString()} | ${r.completed ? 'completed' : 'skipped'} | ${r.retries} retries | ${r.feedback || 'no feedback'} | ${r.id}`).join('\n');
  }
}
