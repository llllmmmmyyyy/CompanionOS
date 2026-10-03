export const BALANCE_PRESETS: string[] = ['Balanced', 'More Movement', 'More Learning', 'Low Energy', 'Custom'];
export class BalanceRules {
  preset: string = 'Balanced';
  movement: number = 20;
  learning: number = 30;
  passive: number = 30;
}
export class BalancedSlot {
  category: string = 'MOVE';
  minutes: number = 3;
  mode: string = 'GUIDED_OFFSCREEN';
  gameType: string = 'MOVEMENT_CHALLENGE';
}
export function validRules(rules: BalanceRules): boolean {
  return rules !== null && rules !== undefined && BALANCE_PRESETS.includes(rules.preset) &&
    [rules.movement, rules.learning, rules.passive].every((v: number) => Number.isFinite(v) && Number.isInteger(v)) &&
    rules.movement >= 10 && rules.movement <= 50 && rules.learning >= 20 && rules.learning <= 50 &&
    rules.movement + rules.learning <= 80 && rules.passive >= 0 && rules.passive <= 30;
}
export function presetRules(preset: string): BalanceRules {
  const rules = new BalanceRules(); rules.preset = BALANCE_PRESETS.includes(preset) ? preset : 'Balanced';
  if (preset === 'More Movement') { rules.movement = 35; rules.learning = 25; }
  if (preset === 'More Learning') { rules.movement = 15; rules.learning = 40; }
  if (preset === 'Low Energy') { rules.movement = 10; rules.learning = 25; }
  return rules;
}
export class SessionBalanceEngine {
  static plan(minutes: number, request: BalanceRules): BalancedSlot[] {
    const duration = [15, 30, 45, 60].includes(minutes) ? minutes : 30;
    const rules = validRules(request) ? request : new BalanceRules();
    const move = Math.ceil(duration * rules.movement / 100);
    const learn = Math.ceil(duration * rules.learning / 100);
    const flexible = duration - move - learn;
    const calm = rules.preset === 'Low Energy' ? Math.ceil(flexible * 0.7) : Math.floor(flexible / 2);
    const totals: number[] = [move, learn, flexible - calm, calm];
    const categories: string[] = ['MOVE', 'LEARN', 'CREATE', 'CALM'];
    const slots: BalancedSlot[] = [];
    totals.forEach((total: number, index: number) => {
      let left = total;
      while (left > 0) {
        const slot = new BalancedSlot(); slot.category = categories[index]; slot.minutes = Math.min(5, left);
        slot.mode = index <= 1 ? 'INTERACTIVE' : 'GUIDED_OFFSCREEN';
        slot.gameType = index === 1 ? (slots.filter((item: BalancedSlot) => item.category === 'LEARN').length % 2 === 0 ? 'CHOICE' : 'MEMORY_SEQUENCE') : index === 0 ? 'MOVEMENT_CHALLENGE' : '';
        slots.push(slot); left -= slot.minutes;
      }
    });
    // Start with a learning game, then alternate categories rather than one long block.
    const ordered: BalancedSlot[] = [];
    while (slots.length > 0) {
      ['LEARN', 'MOVE', 'CREATE', 'CALM'].forEach((category: string) => {
        const at = slots.findIndex((slot: BalancedSlot) => slot.category === category);
        if (at >= 0) { ordered.push(slots.splice(at, 1)[0]); }
      });
    }
    // Include a finite video segment alongside games where the configured budget permits.
    const calmVideo = ordered.findIndex((slot: BalancedSlot) => slot.category === 'CALM');
    if (calmVideo >= 0 && SessionBalanceEngine.videoAllowed(ordered, calmVideo, rules.passive)) { ordered[calmVideo].mode = 'VIDEO'; ordered[calmVideo].gameType = ''; }
    const learnVideo = ordered.map((slot: BalancedSlot, at: number) => slot.category === 'LEARN' ? at : -1).filter((at: number) => at >= 0);
    if (learnVideo.length > 1) { const at = learnVideo[learnVideo.length - 1]; if (SessionBalanceEngine.videoAllowed(ordered, at, rules.passive)) { ordered[at].mode = 'VIDEO'; ordered[at].gameType = ''; } }
    return ordered;
  }
  static videoAllowed(slots: BalancedSlot[], index: number, maximum: number): boolean {
    if (!Number.isFinite(maximum) || maximum < 0 || maximum > 30 || !slots[index]) { return false; }
    // Preserve at least one interactive learning opportunity; video may also teach or guide movement.
    if (slots[index].mode === 'INTERACTIVE' && !slots.some((slot: BalancedSlot, at: number) => at !== index && slot.mode === 'INTERACTIVE' && (slots[index].category !== 'LEARN' || slot.category === 'LEARN'))) { return false; }
    const total = slots.reduce((sum: number, slot: BalancedSlot) => sum + slot.minutes, 0);
    const used = slots.reduce((sum: number, slot: BalancedSlot, at: number) => sum + (at === index || slot.mode === 'VIDEO' ? slot.minutes : 0), 0);
    return used <= total * maximum / 100;
  }
}
