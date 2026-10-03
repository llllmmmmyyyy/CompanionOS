export class ParentSettings {
  age: string = '4–5';
  interests: string[] = ['Movement'];
  minutes: number = 3;
  aiEndpoint: string = '';
}

export class Activity {
  id: string;
  title: string;
  interest: string;
  steps: string[];
  constructor(id: string, title: string, interest: string, steps: string[]) {
    this.id = id;
    this.title = title;
    this.interest = interest;
    this.steps = steps;
  }
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
  countDay: string = '';
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
    typeof settings.aiEndpoint === 'string' && settings.aiEndpoint.length <= 200 &&
    (settings.aiEndpoint === '' || validEndpoint(settings.aiEndpoint));
}

export function validEndpoint(endpoint: string): boolean {
  return /^https:\/\/[a-zA-Z0-9.-]+(:[0-9]{1,5})?(\/[a-zA-Z0-9/_-]*)?$/.test(endpoint);
}

export function restoreSnapshot(raw: string): Snapshot {
  try {
    const data = JSON.parse(raw) as Snapshot;
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
      return new Snapshot();
    }
    return data;
  } catch {
    return new Snapshot();
  }
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
    return this.phase === 'running' ? Math.max(0, Math.ceil((this.deadline - now) / 1000)) : 0;
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
