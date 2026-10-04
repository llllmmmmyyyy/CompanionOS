// Local-first world rules. No raw interaction log is sent to the relay.
export const WORLD_GAMES: string[] = ['bridge', 'memory', 'rescue', 'stars', 'copy', 'number', 'rocket', 'garden', 'calm', 'watch'];
export const WORLD_TITLES: string[] = ['Dino Bridge Builder', 'Robot Memory Repair', 'Animal Rescue World', 'Star Collector', 'Copy Pico', 'Number Move', 'Build the Rocket', 'Creative Garden', 'Calm Sky', 'Storybook'];
export const WORLD_STYLES: string[] = ['BUILDING', 'MEMORY', 'SORTING', 'COUNTING', 'MOVEMENT', 'MOVEMENT', 'BUILDING', 'CREATING', 'EXPLORING', 'WATCHING'];
export const WORLD_NAMES: string[] = ['Dino Forest', 'Robot Lab', 'Ocean Cove', 'Dino Forest', 'Home Base', 'Space Station', 'Space Station', 'Creative Garden', 'Calm Sky', 'Home Base'];
export class WorldSlot { category: string = 'LEARN'; minutes: number = 3; mode: string = 'INTERACTIVE'; gameType: string = ''; }
export class WorldCommand { id: string = ''; type: string = ''; minutes: number = 30; slots: WorldSlot[] = []; difficulty: number = 2; }
export class WorldResult {
  id: string = ''; sessionId: string = ''; activityId: string = ''; title: string = ''; style: string = ''; category: string = 'LEARN';
  completed: boolean = false; skipped: boolean = false; attempts: number = 0; retries: number = 0; duration: number = 0; timestamp: number = 0;
  feedback: string = ''; difficultyFeedback: string = ''; movementConfirmed: boolean = false;
}
export class WorldStatus {
  active: boolean = false; paused: boolean = false; ended: boolean = false; sessionId: string = ''; world: string = 'Home Base';
  mission: string = 'Explore with Pico'; style: string = 'EXPLORING'; phase: string = 'hub'; remaining: number = 0; completed: number = 0; total: number = 0;
}
export class WorldEnvelope { commands: WorldCommand[] = []; status: WorldStatus = new WorldStatus(); results: WorldResult[] = []; connected: boolean = false; }
export class WorldEvent { id: string = ''; type: string = ''; activityId: string = ''; value: string = ''; timestamp: number = 0; }
export class WorldState {
  version: number = 1; active: boolean = false; paused: boolean = false; ended: boolean = false; sessionId: string = ''; missionId: string = '';
  game: string = ''; phase: string = 'hub'; pico: string = 'IDLE'; message: string = 'Pico is ready! Where shall we explore?';
  placed: number[] = []; selected: number = -1; progress: number = 0; attempts: number = 0; retries: number = 0; sequence: number[] = [0, 1];
  previewAt: number = 0; flash: number = -1; remaining: number = 0; lastTick: number = 0; elapsed: number = 0; movementSeconds: number = 0;
  difficulty: number = 2; color: string = '#F4B860'; flowers: number[] = []; calmTaps: number = 0;
  sessionRemaining: number = 0; slots: WorldSlot[] = []; slotIndex: number = 0; daily: boolean = false; dailyDate: string = '';
  results: WorldResult[] = []; events: WorldEvent[] = []; days: string[] = []; decorations: number = 0; handled: string[] = [];
  feedback: string = ''; difficultyFeedback: string = ''; savedAt: number = 0;
}
function copy(s: WorldState): WorldState { return JSON.parse(JSON.stringify(s)) as WorldState; }
export function worldCategory(game: string): string { return ['copy', 'number'].includes(game) ? 'MOVE' : game === 'garden' ? 'CREATE' : ['calm', 'watch'].includes(game) ? 'CALM' : 'LEARN'; }
export function worldTitle(game: string): string { return WORLD_TITLES[WORLD_GAMES.indexOf(game)] || 'Home Base'; }
export function worldStyle(game: string): string { return WORLD_STYLES[WORLD_GAMES.indexOf(game)] || 'EXPLORING'; }
export function worldName(game: string): string { return WORLD_NAMES[WORLD_GAMES.indexOf(game)] || 'Home Base'; }
export function worldDate(now: number): string { const d = new Date(now); return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`; }
export function validWorldResult(r: WorldResult): boolean {
  return !!r && [r.id, r.sessionId, r.activityId, r.title].every((v: string) => typeof v === 'string' && v.length <= 100) && WORLD_GAMES.includes(r.activityId) && WORLD_STYLES.includes(r.style) &&
    ['MOVE', 'LEARN', 'CREATE', 'CALM'].includes(r.category) && [r.completed, r.skipped, r.movementConfirmed].every((v: boolean) => typeof v === 'boolean') && r.completed !== r.skipped &&
    [r.attempts, r.retries, r.duration, r.timestamp].every((v: number) => Number.isSafeInteger(v) && v >= 0) && r.attempts <= 100000 && r.retries <= 100000 && r.duration <= 100000 &&
    ['', 'liked', 'okay', 'disliked'].includes(r.feedback) && ['', 'too easy', 'just right', 'too hard'].includes(r.difficultyFeedback);
}
export function parseWorld(raw: string): WorldState {
  try {
    if (raw.length > 2000000) { return new WorldState(); }
    const s = JSON.parse(raw) as WorldState;
    if (!s || s.version !== 1 || !['', ...WORLD_GAMES].includes(s.game) || !['hub', 'input', 'preview', 'retry', 'movement', 'confirm', 'success', 'feedback', 'ending', 'watch'].includes(s.phase) ||
      ![s.progress, s.attempts, s.retries, s.elapsed, s.sessionRemaining, s.slotIndex, s.decorations].every((n: number) => Number.isInteger(n) && n >= 0 && n < 1000000) ||
      ![s.active, s.paused, s.ended, s.daily].every((v: boolean) => typeof v === 'boolean') ||
      !Array.isArray(s.placed) || s.placed.length > 12 || !s.placed.every((n: number) => Number.isInteger(n) && n >= 0 && n < 12) ||
      !Array.isArray(s.sequence) || s.sequence.length < 2 || s.sequence.length > 5 || !s.sequence.every((n: number) => Number.isInteger(n) && n >= 0 && n < 4) ||
      !Array.isArray(s.results) || s.results.length > 300 || !s.results.every((r: WorldResult) => validWorldResult(r)) || !Array.isArray(s.events) || s.events.length > 1000 || !s.events.every((e: WorldEvent) => e && typeof e.id === 'string' && typeof e.type === 'string' && typeof e.value === 'string' && typeof e.activityId === 'string' && Number.isSafeInteger(e.timestamp) && e.timestamp >= 0) || !Array.isArray(s.days) || s.days.length > 1000 || !s.days.every((v: string) => typeof v === 'string' && /^\d{4}-\d{1,2}-\d{1,2}$/.test(v)) ||
      !Array.isArray(s.handled) || s.handled.length > 100 || !Array.isArray(s.flowers) || s.flowers.length > 12 || !Array.isArray(s.slots) || s.slots.length > 20 || !s.slots.every((slot: WorldSlot) => slot && ['MOVE', 'LEARN', 'CREATE', 'CALM'].includes(slot.category) && Number.isInteger(slot.minutes) && slot.minutes >= 1 && slot.minutes <= 5 && ['VIDEO', 'INTERACTIVE', 'GUIDED_OFFSCREEN'].includes(slot.mode) && typeof slot.gameType === 'string') ||
      !Number.isInteger(s.difficulty) || s.difficulty < 2 || s.difficulty > 5 || !['', 'liked', 'okay', 'disliked'].includes(s.feedback) || !['', 'too easy', 'just right', 'too hard'].includes(s.difficultyFeedback) ||
      typeof s.sessionId !== 'string' || typeof s.missionId !== 'string' || typeof s.message !== 'string') { return new WorldState(); }
    return s;
  } catch { return new WorldState(); }
}
export function worldSlots(slots: WorldSlot[], preferred: string): WorldSlot[] {
  const result: WorldSlot[] = [];
  slots.forEach((slot: WorldSlot) => {
    const item = JSON.parse(JSON.stringify(slot)) as WorldSlot;
    if (item.category === 'LEARN' && item.mode === 'INTERACTIVE') {
      item.gameType = ['bridge', 'rocket', 'memory', 'rescue', 'stars'].includes(preferred) ? preferred : 'bridge';
      if (item.minutes >= 4) { const second = JSON.parse(JSON.stringify(item)) as WorldSlot; item.minutes -= 2; second.minutes = 2; second.gameType = item.gameType === 'memory' ? 'bridge' : 'memory'; result.push(item); result.push(second); }
      else { result.push(item); }
    } else { result.push(item); }
  }); return result;
}
export function recommendedWorld(results: WorldResult[], now: number): string {
  let choice = 'bridge'; let best = 0;
  ['bridge', 'rocket', 'memory', 'rescue', 'stars'].forEach((game: string) => {
    const rows = results.filter((r: WorldResult) => r.activityId === game && r.timestamp <= now && r.timestamp >= now - 7 * 86400000);
    if (rows.length < 3) { return; }
    const score = rows.reduce((sum: number, r: WorldResult) => sum + (r.completed ? 1 : -2) + (r.feedback === 'liked' ? 3 : r.feedback === 'disliked' ? -3 : 0), 0) / rows.length;
    if (score > best) { best = score; choice = game; }
  }); return choice;
}
export class WorldEngine {
  static log(s: WorldState, type: string, value: string, now: number): void {
    const event = new WorldEvent(); event.id = `${now}-${s.events.length}-${s.missionId}`; event.type = type; event.value = value;
    event.activityId = s.game; event.timestamp = now; s.events = [...s.events, event].slice(-1000);
  }
  static open(state: WorldState, game: string, now: number): WorldState {
    const s = copy(state); if (!WORLD_GAMES.includes(game) || s.paused || s.ended) { return s; }
    s.game = game; s.missionId = `${s.sessionId || 'explore'}-${now}-${s.results.length}`; s.phase = game === 'memory' ? 'preview' : game === 'copy' ? 'movement' : game === 'watch' ? 'watch' : 'input';
    s.pico = 'CURIOUS'; s.placed = []; s.selected = -1; s.progress = 0; s.attempts = 0; s.retries = 0; s.elapsed = 0; s.flowers = []; s.calmTaps = 0;
    s.feedback = ''; s.difficultyFeedback = ''; s.remaining = game === 'copy' ? 10 : 0; s.movementSeconds = 0; s.previewAt = now; s.lastTick = now;
    s.sequence = [0, 1, 2, 3, 0].slice(0, s.difficulty); s.flash = game === 'memory' ? 0 : -1;
    s.message = game === 'bridge' ? 'Dino needs three stones to cross the river. Drag each stone onto the bridge.' : game === 'memory' ? 'Robot needs your help. Watch the lights!' : game === 'rescue' ? 'The animals are lost. Tap an animal, then its home.' : game === 'stars' ? 'Five blue stars will open the gate. Leave the amber star.' : game === 'number' ? 'Pico needs four blue energy crystals. Find them, then march together.' : game === 'copy' ? 'Copy Pico: tiny penguin steps or seated arm moves. Adult nearby.' : game === 'rocket' ? 'Fit the three shapes into the rocket.' : game === 'garden' ? 'Choose colors and plant your own garden. Every garden is welcome.' : game === 'calm' ? 'Watch the cloud. Breathe slowly, then tap it gently.' : "Pico found a little cloud that can't find its way home.";
    WorldEngine.log(s, 'MISSION_STARTED', worldStyle(game), now); return s;
  }
  static backToWorld(state: WorldState): WorldState {
    const s = copy(state);
    if (!s.ended || s.phase !== 'ending') { return s; }
    // Returning home is navigation, not a new session or another completion.
    s.phase = 'hub'; s.game = ''; s.pico = 'RESTING';
    s.message = 'Home Base. Your adventure is complete. Take a break together.';
    return s;
  }
  static tick(state: WorldState, now: number): WorldState {
    const s = copy(state); if (!s.active || s.paused || s.ended) { s.lastTick = now; return s; }
    const delta = Math.min(3600, Math.max(0, Math.floor((now - s.lastTick) / 1000))); if (delta > 0) { s.lastTick = now; s.elapsed += delta; s.sessionRemaining = Math.max(0, s.sessionRemaining - delta); }
    if (s.sessionId && s.sessionRemaining === 0) { if (s.game && !['feedback', 'ending', 'hub'].includes(s.phase)) { WorldEngine.finish(s, s.phase === 'success', now); } s.ended = true; s.phase = 'ending'; s.message = 'Our time together is complete. Take a break with your family.'; return s; }
    if (s.phase === 'preview') {
      const at = Math.floor((now - s.previewAt) / 1000); s.flash = at < s.sequence.length ? s.sequence[at] : -1;
      if (at >= s.sequence.length + 1) { s.phase = 'input'; s.message = 'Now wake Robot with the same lights.'; }
    }
    if (s.phase === 'movement') { s.pico = 'MOVING'; s.remaining = Math.max(0, s.remaining - delta); s.movementSeconds += delta; if (s.remaining === 0) { s.phase = 'confirm'; s.pico = 'RESTING'; s.message = 'Comfortable movement is enough. Tap Done when you are ready.'; } }
    return s;
  }
  static success(s: WorldState): void { s.phase = 'success'; s.pico = 'CELEBRATING'; s.message = s.game === 'bridge' ? 'The bridge is repaired! Dino and Pico can cross. 5 + 3 = 8.' : s.game === 'memory' ? 'Robot is awake! The lights are back.' : s.game === 'rescue' ? 'Everyone is home! Watch the animals settle in.' : s.game === 'stars' ? 'Five stars! The forest gate opens.' : s.game === 'rocket' ? 'The rocket is ready. Off we go!' : s.game === 'calm' ? 'Nice and calm.' : 'Our world changed because of you!'; }
  static act(state: WorldState, action: string, value: number, now: number): WorldState {
    const s = copy(state);
    if (s.active && !s.ended && s.game === 'watch' && action === 'video-ended' && s.phase === 'watch') {
      WorldEngine.log(s, 'VIDEO_COMPLETED', '', now); s.phase = 'input'; s.message = 'Can you help the cloud find the sky?'; s.pico = 'CURIOUS'; return s;
    }
    if (!s.active || s.paused || s.ended || ['feedback', 'ending'].includes(s.phase)) { return s; }
    if (action === 'pico') { s.pico = s.pico === 'HAPPY' ? 'SURPRISED' : 'HAPPY'; s.message = 'Pico waves! Where shall we explore?'; return s; }
    if (action === 'ambient') { s.pico = 'LOOKING'; s.message = value === 0 ? 'The lamp glows softly.' : value === 1 ? 'A tiny seed becomes a leaf.' : 'The backpack has a little map.'; return s; }
    if (action === 'skip') { WorldEngine.finish(s, false, now); s.phase = 'feedback'; return s; }
    if (s.game === 'watch') {
      if (action === 'story-select' && s.phase === 'input') { s.selected = 0; return s; }
      if (action === 'story-step' && s.phase === 'input') {
        if (s.selected !== 0 || value !== s.progress) { s.selected = -1; s.pico = 'ENCOURAGING'; s.message = 'The glowing path will guide our cloud.'; return s; }
        WorldEngine.log(s, 'OBJECT_PLACED', `cloud:${value}`, now); s.progress++; s.selected = -1; s.pico = 'HAPPY';
        if (s.progress === 3) { WorldEngine.success(s); s.message = 'The cloud found its home!'; }
        else { s.message = 'Our cloud is getting closer. Follow the gentle glow.'; }
        return s;
      }
      return s;
    }
    if (action === 'more' && ['movement', 'confirm'].includes(s.phase)) { s.phase = 'movement'; s.remaining = 10; s.retries++; s.pico = 'ENCOURAGING'; WorldEngine.log(s, 'NEED_MORE_TIME', '', now); return s; }
    if (action === 'done' && s.phase === 'confirm') { WorldEngine.success(s); return s; }
    if (action === 'done' && ['garden', 'calm', 'watch'].includes(s.game) && (s.game !== 'garden' || s.flowers.length > 0)) { WorldEngine.success(s); return s; }
    if (action === 'retry' && s.phase === 'retry') { s.retries++; s.phase = s.game === 'memory' ? 'preview' : 'input'; s.progress = s.game === 'memory' ? 0 : s.progress; s.previewAt = now; s.flash = s.game === 'memory' ? s.sequence[0] : -1; s.pico = 'ENCOURAGING'; s.message = 'We can try again. Take your time.'; WorldEngine.log(s, 'MISSION_RETRIED', '', now); return s; }
    if (s.phase !== 'input') { return s; }
    if (action === 'select' && s.game === 'rescue' && value >= 0 && value < 3 && !s.placed.includes(value)) { s.selected = value; s.pico = 'LOOKING'; WorldEngine.log(s, 'OBJECT_SELECTED', `${value}`, now); return s; }
    if (action === 'flower' && s.game === 'garden' && value >= 0 && value < 12 && !s.flowers.includes(value)) { s.flowers.push(value); s.pico = 'HAPPY'; WorldEngine.log(s, 'OBJECT_PLACED', `${value}`, now); return s; }
    if (action === 'cloud' && s.game === 'calm') { s.calmTaps++; s.pico = 'RESTING'; return s; }
    if (!['place', 'panel', 'collect', 'habitat'].includes(action)) { return s; }
    let valid = false;
    if (s.game === 'bridge' || s.game === 'rocket') { if (value >= 0 && value < 3 && s.placed.includes(value)) { return s; } valid = value >= 0 && value < 3; }
    if (s.game === 'memory') { valid = value === s.sequence[s.progress]; }
    if (s.game === 'rescue') { if (s.selected < 0) { return s; } valid = value === (s.selected === 1 ? 0 : 1); }
    if (['stars', 'number'].includes(s.game)) { if (s.placed.includes(value)) { return s; } valid = value >= 0 && value < (s.game === 'stars' ? 5 : 4); }
    s.attempts++; s.pico = valid ? 'HAPPY' : 'THINKING';
    WorldEngine.log(s, valid ? 'OBJECT_PLACED' : 'OBJECT_PLACED_INCORRECTLY', `${value}`, now);
    if (!valid) { s.phase = 'retry'; s.message = 'That one does not fit yet. Let us try another way.'; return s; }
    s.progress++; if (s.game === 'rescue') { s.placed.push(s.selected); s.selected = -1; } else if (s.game !== 'memory') { s.placed.push(value); }
    if (s.game === 'memory') { s.flash = value; WorldEngine.log(s, 'SEQUENCE_ATTEMPT', `${s.progress}`, now); }
    if (s.progress >= (s.game === 'memory' ? s.sequence.length : s.game === 'stars' ? 5 : s.game === 'number' ? 4 : 3)) {
      if (s.game === 'number') { s.phase = 'movement'; s.remaining = 10; s.message = "Four crystals! Let's do four gentle marches or seated arm moves together."; } else { WorldEngine.success(s); }
    }
    return s;
  }
  static finish(s: WorldState, completed: boolean, now: number): void {
    const existing = s.results.find((r: WorldResult) => r.id === s.missionId);
    if (existing) { existing.feedback = s.feedback; existing.difficultyFeedback = s.difficultyFeedback; return; }
    if (!s.game) { return; }
    const r = new WorldResult(); r.id = s.missionId; r.sessionId = s.sessionId; r.activityId = s.game; r.title = worldTitle(s.game); r.style = worldStyle(s.game); r.category = s.slots[s.slotIndex]?.category || worldCategory(s.game);
    r.completed = completed; r.skipped = !completed; r.attempts = s.attempts; r.retries = s.retries; r.duration = s.elapsed; r.timestamp = now;
    r.feedback = s.feedback; r.difficultyFeedback = s.difficultyFeedback; r.movementConfirmed = completed && ['copy', 'number'].includes(s.game);
    s.results = [...s.results, r].slice(-300); WorldEngine.log(s, completed ? 'MISSION_COMPLETED' : 'ACTIVITY_SKIPPED', '', now);
  }
  static next(state: WorldState, now: number): WorldState {
    const s = copy(state); if (s.phase !== 'success' && s.phase !== 'feedback') { return s; }
    WorldEngine.finish(s, s.phase === 'success', now);
    if (!s.slots.length) { s.phase = 'hub'; s.game = ''; s.message = 'A new path is ready whenever you are.'; return s; }
    s.slotIndex++;
    if (s.slotIndex >= s.slots.length) {
      s.phase = 'ending'; s.ended = true; s.sessionRemaining = 0; s.pico = 'CELEBRATING'; s.message = "Today's Adventure Complete. Time for a family break.";
      if (s.daily && s.results.filter((r: WorldResult) => r.sessionId === s.sessionId && r.completed).length === s.slots.length && !s.days.includes(s.dailyDate)) { s.days = [...s.days, s.dailyDate].slice(-1000); s.decorations++; }
      return s;
    }
    return WorldEngine.open(s, WorldEngine.slotGame(s), now);
  }
  static slotGame(s: WorldState): string { const slot = s.slots[s.slotIndex]; if (!slot) { return 'bridge'; } return slot.mode === 'VIDEO' ? 'watch' : slot.category === 'MOVE' ? 'copy' : slot.category === 'CREATE' ? 'garden' : slot.category === 'CALM' ? 'calm' : ['bridge', 'rocket', 'memory', 'rescue', 'stars'].includes(slot.gameType) ? slot.gameType : s.slotIndex === 0 ? 'bridge' : 'memory'; }
  static command(state: WorldState, command: WorldCommand, now: number): WorldState {
    let s = copy(state); if (s.handled.includes(command.id)) { return s; } s.handled = [...s.handled, command.id].slice(-100);
    if (command.type === 'ENTER_CHILD_MODE') { s.active = true; s.paused = false; s.lastTick = now; if (s.ended) { s.phase = 'hub'; s.game = ''; s.sessionId = ''; s.slots = []; s.daily = false; s.sessionRemaining = 0; s.message = 'Pico is ready! Where shall we explore?'; } s.ended = false; s.pico = 'CURIOUS'; }
    if (command.type === 'EXIT_CHILD_MODE') { s.active = false; s.paused = true; }
    if (command.type === 'PAUSE_SESSION') { s.paused = true; s.pico = 'RESTING'; }
    if (command.type === 'RESUME_SESSION') { s.paused = false; s.lastTick = now; if (s.phase === 'preview') { s.previewAt = now; s.flash = s.sequence[0]; } }
    if (command.type === 'END_SESSION') { if (s.game && !['ending', 'hub'].includes(s.phase)) { WorldEngine.finish(s, s.phase === 'success', now); } s.ended = true; s.sessionRemaining = 0; s.phase = 'ending'; s.message = 'Adventure finished. Time to put the screen down together.'; }
    if (command.type === 'START_SESSION') { if (s.game && !s.ended && s.phase !== 'hub') { WorldEngine.finish(s, s.phase === 'success', now); } s.active = true; s.paused = false; s.ended = false; s.sessionId = command.id; s.sessionRemaining = command.minutes * 60; s.slots = command.slots; s.slotIndex = 0; s.daily = true; s.dailyDate = worldDate(now); s.difficulty = Math.max(2, Math.min(5, command.difficulty)); s = WorldEngine.open(s, WorldEngine.slotGame(s), now); }
    if (command.type === 'NEXT_ACTIVITY' && s.slots.length && !s.ended) { WorldEngine.finish(s, s.phase === 'success', now); s.phase = 'feedback'; s = WorldEngine.next(s, now); }
    return s;
  }
  static status(s: WorldState): WorldStatus { const status = new WorldStatus(); status.active = s.active; status.paused = s.paused; status.ended = s.ended; status.sessionId = s.sessionId; status.world = worldName(s.game); status.mission = worldTitle(s.game); status.style = worldStyle(s.game); status.phase = s.phase; status.remaining = s.sessionRemaining; status.completed = s.results.filter((r: WorldResult) => r.sessionId === s.sessionId && r.completed).length; status.total = s.slots.length; return status; }
}
