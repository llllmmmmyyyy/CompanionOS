// Pure, reusable game rules shared by native Phone and Tablet views.
export class InteractiveActivity {
  id: string = ''; title: string = ''; theme: string = ''; category: string = 'LEARN'; gameType: string = 'CHOICE';
  learningGoal: string = ''; ageRange: string = '4-8'; difficulty: string = 'Gentle'; estimatedDuration: number = 3;
  instruction: string = ''; storyContext: string = ''; safetyFlags: string[] = ['INDOOR', 'ADULT_NEARBY', 'NO_JUMPING'];
  questions: string[] = []; choices: string[] = [];
}
export const GAME_IDS: string[] = ['dino-number', 'robot-memory', 'animal-sorting', 'penguin-move', 'number-move'];
export function gameDefinition(id: string, difficulty: string = 'Gentle'): InteractiveActivity {
  const game = new InteractiveActivity(); game.id = GAME_IDS.includes(id) ? id : 'dino-number'; game.difficulty = difficulty;
  if (game.id === 'dino-number') { game.title = 'Dino Number Adventure'; game.theme = 'Dino Forest'; game.instruction = 'Help Dino find three stars.'; game.storyContext = 'A little number adventure in the forest.'; game.learningGoal = 'Recognize numbers and count'; game.questions = ['Count the dinosaurs', 'Find number 5', 'Find number 4']; game.choices = ['2', '3', '4']; }
  else if (game.id === 'robot-memory') { game.title = 'Robot Memory Rescue'; game.theme = 'Robot City'; game.gameType = 'MEMORY_SEQUENCE'; game.instruction = 'Remember the pictures. Then tap them in order.'; game.storyContext = 'Help repair a friendly robot.'; game.learningGoal = 'Recall a short visual sequence'; game.choices = ['Star', 'Penguin', 'Rocket', 'Dino']; }
  else if (game.id === 'animal-sorting') { game.title = 'Animal Sorting Adventure'; game.theme = 'Ocean World'; game.gameType = 'SORTING'; game.instruction = 'Help each animal find its home.'; game.storyContext = 'Three animals are ready for an adventure.'; game.learningGoal = 'Classify animals by habitat'; game.choices = ['Land', 'Water']; }
  else { game.title = game.id === 'number-move' ? 'Number Move' : 'Penguin Move'; game.theme = 'Dino Forest'; game.category = 'MOVE'; game.gameType = 'MOVEMENT_CHALLENGE'; game.learningGoal = game.id === 'number-move' ? 'Recognize four, then follow gentle movement instructions' : 'Follow gentle movement instructions'; game.instruction = game.id === 'number-move' ? 'Find 4. Then try four gentle marches or seated arm moves.' : 'Try ten seconds of tiny penguin steps or seated flipper moves.'; game.storyContext = 'Move comfortably, with an adult nearby. No jumping or climbing.'; game.choices = ['2', '5', '4']; }
  return game;
}
export class GameState {
  revision: number = 0;
  version: number = 1; id: string = ''; difficulty: string = 'Gentle'; phase: string = 'idle';
  round: number = 0; stars: number = 0; attempts: number = 0; correct: number = 0; retries: number = 0;
  selected: string[] = []; sequence: string[] = []; message: string = ''; lastInput: string = '';
  deadline: number = 0; remaining: number = 0; paused: boolean = false; savedPhase: string = '';
  movementConfirmed: boolean = false; learned: boolean = false; demo: boolean = false;
}
export class GameTransition { state: GameState = new GameState(); events: string[] = []; }
function clone(state: GameState): GameState { return JSON.parse(JSON.stringify(state)) as GameState; }
export function validGame(state: GameState): boolean {
  return !!state && state.version === 1 && (state.id === '' || GAME_IDS.includes(state.id)) && ['Gentle', 'Standard', 'Hard'].includes(state.difficulty) &&
    ['idle', 'preview', 'input', 'retry', 'round-success', 'movement', 'confirm', 'success', 'skipped'].includes(state.phase) &&
    [state.revision, state.round, state.stars, state.attempts, state.correct, state.retries, state.remaining].every((n: number) => Number.isInteger(n) && n >= 0 && n <= 1000) &&
    Number.isFinite(state.deadline) && typeof state.paused === 'boolean' && typeof state.demo === 'boolean' &&
    typeof state.message === 'string' && state.message.length <= 200 && typeof state.lastInput === 'string' && state.lastInput.length <= 160 &&
    Array.isArray(state.selected) && state.selected.length <= 4 && Array.isArray(state.sequence) && state.sequence.length <= 4 &&
    [...state.selected, ...state.sequence].every((s: string) => ['Star', 'Penguin', 'Rocket', 'Dino'].includes(s)) &&
    typeof state.learned === 'boolean' && typeof state.movementConfirmed === 'boolean';
}
export class GameEngine {
  static create(id: string, difficulty: string = 'Gentle', demo: boolean = false): GameState {
    const state = new GameState(); state.id = gameDefinition(id).id; state.difficulty = ['Gentle', 'Standard', 'Hard'].includes(difficulty) ? difficulty : 'Gentle'; state.demo = demo;
    state.sequence = ['Star', 'Penguin', 'Rocket', 'Dino'].slice(0, state.difficulty === 'Hard' ? 4 : state.difficulty === 'Standard' ? 3 : 2); return state;
  }
  static start(state: GameState, now: number): GameState {
    const next = clone(state); if (next.phase !== 'idle') { return next; }
    next.phase = next.id === 'robot-memory' ? 'preview' : next.id === 'penguin-move' ? 'movement' : 'input';
    next.deadline = now + (next.phase === 'preview' ? 5000 : next.phase === 'movement' ? (next.demo ? 3000 : 10000) : 0); return next;
  }
  static tick(state: GameState, now: number): GameState {
    const next = clone(state); if (next.paused || !['preview', 'movement'].includes(next.phase)) { return next; }
    next.remaining = Math.max(0, Math.ceil((next.deadline - now) / 1000));
    if (next.remaining === 0) { next.revision++; next.phase = next.phase === 'preview' ? 'input' : 'confirm'; } return next;
  }
  static pause(state: GameState, now: number): GameState { const next = GameEngine.tick(state, now); next.remaining = Math.max(0, Math.ceil((next.deadline - now) / 1000)); next.paused = true; return next; }
  static resume(state: GameState, now: number): GameState { const next = clone(state); next.deadline = now + next.remaining * 1000; next.paused = false; return next; }
  static choices(state: GameState): string[] {
    if (state.id === 'robot-memory') { return ['Star', 'Penguin', 'Rocket', 'Dino']; }
    if (state.id === 'animal-sorting') { return ['Land', 'Water']; }
    if (state.id === 'number-move') { return ['2', '5', '4']; }
    return state.round === 0 ? (state.difficulty === 'Gentle' ? ['2', '3', '4'] : ['4', '6', '8']) : state.round === 1 ? ['3', '5', '8'] : ['2', '4', '6'];
  }
  static prompt(state: GameState): string {
    if (state.phase === 'success') { return 'Great work! Check in with your adult.'; }
    if (state.id === 'robot-memory') { return state.phase === 'preview' ? 'Remember these pictures!' : 'Tap the pictures in the order you saw.'; }
    if (state.id === 'animal-sorting') { return ['Dolphin: where does it live?', 'Lion: where does it live?', 'Whale: where does it live?'][Math.min(2, state.round)]; }
    if (state.id === 'number-move' && ['input', 'retry'].includes(state.phase)) { return 'Find number 4!'; }
    if (['movement', 'confirm'].includes(state.phase)) { return state.id === 'number-move' ? 'Try four gentle marches or seated arm moves.' : 'Tiny penguin steps or seated flipper moves. No jumping!'; }
    return state.round === 0 ? (state.difficulty === 'Gentle' ? 'Two dinosaurs meet one more. How many?' : 'Four dinosaurs meet two more. How many?') : state.round === 1 ? 'Dino lost five stars. Find number 5!' : 'Find number 4 to open the forest gate!';
  }
  static act(state: GameState, action: string, value: string, now: number): GameTransition {
    const result = new GameTransition(); const next = GameEngine.tick(state, now); result.state = next;
    if (next.paused || ['idle', 'success', 'skipped'].includes(next.phase)) { return result; }
    next.revision++;
    if (action === 'skip') { next.phase = 'skipped'; result.events = ['ACTIVITY_SKIPPED']; return result; }
    if (action === 'more' && ['movement', 'confirm'].includes(next.phase)) { next.phase = 'movement'; next.deadline = now + (next.demo ? 3000 : 10000); next.remaining = next.demo ? 3 : 10; result.events = ['NEED_MORE_TIME']; return result; }
    if (action === 'done' && next.phase === 'confirm') { next.movementConfirmed = true; next.phase = 'success'; next.message = 'Lovely effort! Movement is child-confirmed.'; result.events = ['MOVEMENT_CONFIRMED']; return result; }
    if (action === 'retry' && next.phase === 'retry') { next.retries++; next.selected = []; next.message = 'A fresh try. Take your time!'; next.phase = next.id === 'robot-memory' ? 'preview' : 'input'; next.deadline = now + 5000; result.events = ['RETRY']; return result; }
    if (action === 'next' && next.phase === 'round-success') { next.phase = 'input'; next.message = ''; return result; }
    if (action !== 'answer' || next.phase !== 'input' || !GameEngine.choices(next).includes(value)) { return result; }
    next.lastInput = value; result.events = ['ANSWER_SELECTED'];
    if (next.id === 'robot-memory') {
      next.selected.push(value); if (next.selected.length < next.sequence.length) { return result; }
      next.lastInput = next.selected.join(', '); next.attempts++;
      if (next.selected.every((item: string, at: number) => item === next.sequence[at])) { next.correct++; next.learned = true; next.phase = 'success'; next.message = 'Robot remembers! Nice trying!'; result.events.push('ANSWER_CORRECT'); }
      else { next.phase = 'retry'; next.message = 'Almost! Let us look again.'; result.events.push('ANSWER_INCORRECT'); } return result;
    }
    next.attempts++;
    const correct = next.id === 'animal-sorting' ? ['Water', 'Land', 'Water'][Math.min(2, next.round)] : next.id === 'number-move' ? '4' : next.round === 0 ? (next.difficulty === 'Gentle' ? '3' : '6') : next.round === 1 ? '5' : '4';
    if (value !== correct) { next.phase = 'retry'; next.message = 'Almost! Try one more time.'; result.events.push('ANSWER_INCORRECT'); return result; }
    next.correct++; next.stars++; result.events.push('ANSWER_CORRECT');
    if (next.id === 'number-move') { next.learned = true; next.phase = 'movement'; next.deadline = now + (next.demo ? 3000 : 10000); next.remaining = next.demo ? 3 : 10; next.message = 'You found four! Time to move comfortably.'; }
    else { next.round++; next.learned = next.round === 3; next.phase = next.learned ? 'success' : 'round-success'; next.message = next.learned ? 'You helped everyone! Great work today!' : 'Yes! Another star found!'; }
    return result;
  }
}
