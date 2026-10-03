import { Activity, ParentSettings } from './Companion';

export const WORK_TYPES: string[] = ['MOVE', 'LEARN', 'CREATE', 'CALM'];
export const PREPARATIONS: string[] = ['Recommended', 'Built-in', 'Huawei AI', 'Gemini AI', 'My Videos'];
export class WorkEntry {
  category: string = 'MOVE';
  minutes: number = 5;
  outcome: string = 'pending';
  demo: boolean = false;
}
export class WorkState {
  version: number = 1;
  id: string = '';
  minutes: number = 30;
  preparation: string = 'Recommended';
  entries: WorkEntry[] = [];
  index: number = 0;
  phase: string = 'idle';
  remaining: number = 0;
  step: number = 0;
  activityPhase: string = 'idle';
  activityId: string = '';
  activityDemo: boolean = false;
  finishedAt: number = 0;
}
export function planWork(minutes: number, settings: ParentSettings): WorkState {
  const state = new WorkState();
  state.id = `work-${Date.now()}`; state.minutes = minutes; state.phase = 'active';
  const types = WORK_TYPES.filter((type: string) => settings.preferredActivityTypes.includes(type));
  const count = Math.max(2, Math.floor(minutes / 5));
  state.entries = Array.from({ length: count }, (_value: number, index: number) => {
    const entry = new WorkEntry(); entry.category = types[index % types.length] || 'CALM'; return entry;
  });
  return state;
}
export function settleEntry(state: WorkState, outcome: string, demo: boolean): WorkState {
  if (state.phase !== 'active' || !['completed', 'skipped'].includes(outcome) || !state.entries[state.index] ||
    state.entries[state.index].outcome !== 'pending') { return state; }
  const next = copyWork(state);
  next.entries[next.index].outcome = outcome; next.entries[next.index].demo = demo;
  next.index++; next.remaining = 0; next.step = 0; next.activityPhase = 'idle'; next.activityId = '';
  if (next.index === next.entries.length) { next.phase = 'completed'; next.finishedAt = Date.now(); }
  return next;
}
export function endWork(state: WorkState): WorkState {
  const next = copyWork(state); next.phase = 'ended'; next.finishedAt = Date.now();
  next.entries.forEach((entry: WorkEntry) => { if (entry.outcome === 'pending') { entry.outcome = 'skipped'; } });
  return next;
}
export function copyWork(state: WorkState): WorkState { return JSON.parse(JSON.stringify(state)) as WorkState; }
export function parseWork(raw: string): WorkState {
  try {
    const state = JSON.parse(raw) as WorkState;
    if (!state || state.version !== 1 || typeof state.id !== 'string' || state.id.length > 100 ||
      ![15, 30, 45, 60].includes(state.minutes) || !PREPARATIONS.includes(state.preparation) ||
      !['idle', 'active', 'completed', 'ended'].includes(state.phase) || !Array.isArray(state.entries) || state.entries.length > 12 ||
      !Number.isInteger(state.index) || state.index < 0 || state.index > state.entries.length ||
      (state.phase === 'active' && state.index >= state.entries.length) ||
      !Number.isFinite(state.remaining) || state.remaining < 0 || state.remaining > 600 ||
      !Number.isInteger(state.step) || state.step < 0 || state.step > 2 ||
      !['idle', 'running', 'paused', 'ready', 'completed', 'cancelled'].includes(state.activityPhase) ||
      typeof state.activityId !== 'string' || state.activityId.length > 100 || !Number.isFinite(state.finishedAt) ||
      typeof state.activityDemo !== 'boolean' ||
      !state.entries.every((entry: WorkEntry) => entry && WORK_TYPES.includes(entry.category) && [3, 5, 10].includes(entry.minutes) &&
        ['pending', 'completed', 'skipped'].includes(entry.outcome) && typeof entry.demo === 'boolean')) { return new WorkState(); }
    return state;
  } catch { return new WorkState(); }
}
export function remainingWork(state: WorkState): number {
  return state.entries.slice(state.index).reduce((sum: number, entry: WorkEntry, index: number) =>
    sum + (index === 0 && state.activityPhase !== 'idle' ? Math.ceil(state.remaining / 60) : entry.minutes), 0);
}
export function categoryMinutes(state: WorkState, category: string): number {
  return state.entries.filter((entry: WorkEntry) => entry.category === category && entry.outcome === 'completed' && !entry.demo)
    .reduce((sum: number, entry: WorkEntry) => sum + entry.minutes, 0);
}
export function workActivity(category: string, settings: ParentSettings): Activity {
  let title = 'Cloud Breathing'; let interest = 'Nature';
  let steps: string[] = ['Sit comfortably in your indoor activity space. Let an adult know you are ready.',
    'Imagine a cloud drifting slowly. Breathe normally and gently relax your hands.',
    'Notice three quiet colors around you. Rest and tell your adult how the activity felt.'];
  if (category === 'MOVE') {
    title = 'Penguin Walk'; interest = 'Movement';
    steps = ['Ask an adult to clear a small indoor space. Sit comfortably if you prefer.',
      'Hold your arms like flippers. Sway slowly or take small walking steps. No jumping or climbing.',
      'Count five gentle flipper moves. Rest whenever you like and let your adult know when you finish.'];
  } else if (category === 'LEARN') {
    title = 'Animal Number Adventure'; interest = 'Sounds';
    steps = ['Sit in your prepared indoor space. Imagine a friendly animal.',
      settings.age === '6–8' ? 'Count ten imaginary animal footprints. Group them in pairs.' : 'Count five imaginary animal footprints using your fingers.',
      'Make a gentle animal sound. Repeat your counting and tell your adult your favorite animal.'];
  } else if (category === 'CREATE') {
    title = 'Imagine a Tiny World'; interest = 'Nature';
    steps = ['Sit comfortably. This activity needs only your imagination: no tools or small objects.',
      'Imagine a tiny garden. Name three colors and invent a friendly creature who lives there.',
      'Draw the creature in the air with one finger. Think of a name and share your story when your adult is free.'];
  }
  const activity = new Activity(`work-${category.toLowerCase()}`, title, interest, steps);
  if (settings.activityDifficulty === 'Standard' && category === 'CREATE') {
    activity.steps[2] = 'Imagine a second creature. Give each a name and invent a short story to share with your adult.';
    activity.activitySteps[2].instruction = activity.steps[2];
  }
  activity.category = category; activity.duration = 5; activity.theme = 'Safe indoor adventure';
  activity.educationalGoal = category === 'LEARN' ? 'Practice counting' : category === 'CREATE' ? 'Practice imagination' : 'Follow gentle instructions';
  return activity;
}
