import { ActivityContentSource } from '@companion/protocol';
export { ActivityContentSource } from '@companion/protocol';

export class ParentSettings {
  age: string = '4–5';
  interests: string[] = ['Movement'];
  minutes: number = 3;
  aiEndpoint: string = '';
  preferredActivityTypes: string[] = ['MOVE', 'LEARN', 'CREATE', 'CALM'];
  sessionDuration: number = 30;
  activityDifficulty: string = 'Gentle';
  indoorOnly: boolean = true;
  noJumping: boolean = true;
  lowIntensity: boolean = true;
}

export class Activity {
  contentSource: ActivityContentSource = ActivityContentSource.BUILT_IN;
  videoUrl: string = '';
  localVideoPath: string = '';
  aiGenerationId: string = '';
  aiProvider: string = '';
  category: string = 'MOVE';
  duration: number = 3;
  theme: string = 'Family animals';
  educationalGoal: string = 'Take turns together';
  activitySteps: ActivityStep[] = [];
  videoSegments: string[] = [];
  generatedByAI: boolean = false;
  id: string;
  title: string;
  interest: string;
  steps: string[];
  constructor(id: string, title: string, interest: string, steps: string[]) {
    this.id = id;
    this.title = title;
    this.interest = interest;
    this.steps = steps;
    this.activitySteps = steps.map((instruction: string) => new ActivityStep(instruction));
  }
}

export class ActivityStep {
  instruction: string;
  durationSeconds: number = 60;
  learningGoal: string = 'Practice together';
  videoUrl: string = '';
  fallbackVisual: string = 'Together';
  constructor(instruction: string) { this.instruction = instruction; }
}

export const ACTIVITIES: Activity[] = [
  new Activity('penguin', 'Penguin Walk', 'Movement', [
    'Stand beside your parent in a clear space, or sit comfortably together.',
    'Hold your arms like flippers. Take ten small waddling steps, or sway your arms while seated.',
    'Take turns leading your penguin family. Repeat at a comfortable pace and finish with a high five.'
  ]),
  new Activity('sounds', 'Animal Sounds', 'Sounds', [
    'Choose an animal without telling each other its name.',
    'Make a gentle animal sound and let your partner guess. Take turns.',
    'Try more animals, then invent a little animal conversation together.'
  ]),
  new Activity('butterfly', 'Butterfly Stretch', 'Nature', [
    'Stand or sit comfortably beside your parent with space for your arms.',
    'Open your arms like butterfly wings and stretch gently within a comfortable range.',
    'Lower your wings slowly. Repeat together, take breaks, and share your favorite butterfly color.'
  ])
];

export class Completion {
  contentSource: ActivityContentSource = ActivityContentSource.BUILT_IN;
  id: string = '';
  activityId: string = '';
  title: string = '';
  completedAt: number = 0;
  minutes: number = 3;
  demo: boolean = false;
}

export class Snapshot {
  version: number = 1;
  settings: ParentSettings = new ParentSettings();
  records: Completion[] = [];
  total: number = 0;
  countDay: string = dayKey(Date.now());
  todayCount: number = 0;
}

export function dayKey(timestamp: number): string {
  const date = new Date(timestamp);
  return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
}

export function countToday(data: Snapshot, now: number): number {
  return data.countDay === dayKey(now) ? data.todayCount : 0;
}

export function validSettings(settings: ParentSettings): boolean {
  return settings !== null && (settings.age === '4–5' || settings.age === '6–8') &&
    [3, 5, 10].includes(settings.minutes) && Array.isArray(settings.interests) &&
    settings.interests.length > 0 && settings.interests.length <= 3 &&
    settings.interests.every((item: string) => ['Movement', 'Sounds', 'Nature'].includes(item)) &&
    Array.isArray(settings.preferredActivityTypes) && settings.preferredActivityTypes.length > 0 &&
    settings.preferredActivityTypes.length <= 4 && settings.preferredActivityTypes.every((value: string) => ['MOVE', 'LEARN', 'CREATE', 'CALM'].includes(value)) &&
    [15, 30, 45, 60].includes(settings.sessionDuration) && ['Gentle', 'Standard'].includes(settings.activityDifficulty) &&
    typeof settings.indoorOnly === 'boolean' && typeof settings.noJumping === 'boolean' && typeof settings.lowIntensity === 'boolean' &&
    typeof settings.aiEndpoint === 'string' && settings.aiEndpoint.length <= 200 &&
    (settings.aiEndpoint === '' || validEndpoint(settings.aiEndpoint));
}

export function validEndpoint(endpoint: string): boolean {
  return /^https:\/\/[a-zA-Z0-9.-]+(:[0-9]{1,5})?(\/[a-zA-Z0-9/_-]*)?$/.test(endpoint);
}

export function parseSnapshot(raw: string): Snapshot | undefined {
  try {
    const data = JSON.parse(raw) as Snapshot;
    if (data && data.settings) {
      const defaults = new ParentSettings();
      if (data.settings.preferredActivityTypes === undefined) { data.settings.preferredActivityTypes = defaults.preferredActivityTypes; }
      if (data.settings.sessionDuration === undefined) { data.settings.sessionDuration = defaults.sessionDuration; }
      if (data.settings.activityDifficulty === undefined) { data.settings.activityDifficulty = defaults.activityDifficulty; }
      if (data.settings.indoorOnly === undefined) { data.settings.indoorOnly = true; }
      if (data.settings.noJumping === undefined) { data.settings.noJumping = true; }
      if (data.settings.lowIntensity === undefined) { data.settings.lowIntensity = true; }
    }
    if (data === null || data.version !== 1 || !validSettings(data.settings) ||
      !Array.isArray(data.records) || data.records.length > 20 ||
      !Number.isSafeInteger(data.total) || data.total < data.records.length ||
      !Number.isSafeInteger(data.todayCount) || data.todayCount < 0 || data.todayCount > data.total ||
      typeof data.countDay !== 'string' || !data.records.every((record: Completion) =>
        record !== null && typeof record.id === 'string' && record.id.length <= 100 &&
        typeof record.activityId === 'string' && record.activityId.length <= 40 &&
        typeof record.title === 'string' && record.title.length <= 80 &&
        Number.isFinite(record.completedAt) && record.completedAt > 0 &&
        [3, 5, 10].includes(record.minutes) && typeof record.demo === 'boolean')) {
      return undefined;
    }
    for (const record of data.records) {
      if (record.contentSource === undefined) { record.contentSource = ActivityContentSource.BUILT_IN; }
      if (!['GEMINI_AI', 'HUAWEI_AI', 'BUILT_IN', 'USER_VIDEO'].includes(record.contentSource)) { return undefined; }
    }
    return data;
  } catch {
    return undefined;
  }
}

export function restoreSnapshot(raw: string): Snapshot {
  const saved = parseSnapshot(raw);
  return saved ? saved : new Snapshot();
}

export function addCompletion(data: Snapshot, record: Completion): Snapshot {
  if (data.records.some((item: Completion) => item.id === record.id)) {
    return data;
  }
  const updated = new Snapshot();
  updated.settings = data.settings;
  updated.records = [record, ...data.records].slice(0, 20);
  updated.total = data.total + 1;
  updated.countDay = dayKey(record.completedAt);
  updated.todayCount = countToday(data, record.completedAt) + 1;
  return updated;
}

export class ActivitySession {
  contentSource: ActivityContentSource = ActivityContentSource.BUILT_IN;
  videoUrl: string = '';
  localVideoPath: string = '';
  aiGenerationId: string = '';
  aiProvider: string = '';
  private pausedMilliseconds: number = 0;
  id: string = '';
  deadline: number = 0;
  phase: string = 'idle';
  notificationHandled: boolean = false;
  demo: boolean = false;
  minutes: number = 3;

  start(now: number, minutes: number, demo: boolean): void {
    this.id = `session-${now}`;
    this.minutes = minutes;
    this.demo = demo;
    this.deadline = now + (demo ? 10 : minutes * 60) * 1000;
    this.phase = 'running';
    this.notificationHandled = false;
  }

  remaining(now: number): number {
    if (this.phase === 'paused') { return Math.ceil(this.pausedMilliseconds / 1000); }
    return this.phase === 'running' ? Math.max(0, Math.ceil((this.deadline - now) / 1000)) : 0;
  }

  pause(now: number): void {
    if (this.phase !== 'running' || now >= this.deadline) { return; }
    this.pausedMilliseconds = this.deadline - now;
    this.phase = 'paused';
  }

  continueActivity(now: number): void {
    if (this.phase !== 'paused') { return; }
    this.deadline = now + this.pausedMilliseconds;
    this.phase = 'running';
  }

  tick(now: number, foreground: boolean): boolean {
    if (!foreground || this.phase !== 'running' || now < this.deadline) { return false; }
    this.phase = 'ready';
    const notify = !this.notificationHandled;
    this.notificationHandled = true;
    return notify;
  }

  resume(now: number): void {
    // An interval is not a background alarm. Do not notify for a deadline missed in the background.
    if (this.phase === 'running' && now >= this.deadline) {
      this.phase = 'ready';
      this.notificationHandled = true;
    }
  }

  cancel(): void { this.phase = 'cancelled'; }
}
