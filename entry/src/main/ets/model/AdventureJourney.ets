import { Completion, dayKey } from './Companion';
export const WORLDS: string[] = ['Dino Forest', 'Space Station', 'Ocean World', 'Robot City'];
export class JourneyState {
  version: number = 1; completedDays: string[] = []; demoDays: string[] = []; claimed: string[] = [];
  demoWorlds: number[] = [0, 0, 0, 0];
  worlds: number[] = [0, 0, 0, 0]; numberGames: number = 0; memoryGames: number = 0; movement: number = 0; creative: number = 0;
}
export function worldIndex(now: number): number { return Math.min(3, Math.floor((new Date(now).getDate() - 1) / 7)); }
export function worldName(now: number): string { return WORLDS[worldIndex(now)]; }
export function parseJourney(raw: string): JourneyState {
  try { const data = JSON.parse(raw) as JourneyState;
    if (data && data.demoWorlds === undefined) { data.demoWorlds = [0, 0, 0, 0]; }
    if (!data || data.version !== 1 || !Array.isArray(data.completedDays) || !Array.isArray(data.demoDays) || !Array.isArray(data.claimed) ||
      data.completedDays.length > 1000 || data.demoDays.length > 1000 || data.claimed.length > 400 ||
      ![...data.completedDays, ...data.demoDays, ...data.claimed].every((s: string) => typeof s === 'string' && s.length > 0 && s.length <= 100) ||
      !Array.isArray(data.demoWorlds) || data.demoWorlds.length !== 4 || !Array.isArray(data.worlds) || data.worlds.length !== 4 || ![...data.worlds, ...data.demoWorlds, data.numberGames, data.memoryGames, data.movement, data.creative].every((n: number) => Number.isSafeInteger(n) && n >= 0)) { return new JourneyState(); } return data;
  } catch { return new JourneyState(); }
}
export function claimActivity(data: JourneyState, record: Completion): JourneyState {
  if (record.demo || data.claimed.includes(record.id)) { return data; }
  const next = parseJourney(JSON.stringify(data)); next.claimed = [...next.claimed, record.id].slice(-400);
  if (record.gameType === 'CHOICE' && record.completed) { next.numberGames++; }
  if (record.gameType === 'MEMORY_SEQUENCE' && record.completed) { next.memoryGames++; }
  if (record.movementConfirmed) { next.movement++; }
  if (record.category === 'CREATE') { next.creative++; } return next;
}
export function completeAdventure(data: JourneyState, date: string, demo: boolean, now: number): JourneyState {
  const next = parseJourney(JSON.stringify(data)); if (date.length > 30 || date.length < 5) { return next; }
  if (demo) { if (!next.demoDays.includes(date)) { next.demoDays = [...next.demoDays, date].slice(-1000); next.demoWorlds[worldIndex(now)]++; } }
  else if (!next.completedDays.includes(date)) { next.completedDays = [...next.completedDays, date].slice(-1000); next.worlds[worldIndex(now)]++; } return next;
}
export function collectibles(data: JourneyState): string[] {
  const result: string[] = [];
  if (data.completedDays.length > 0) { result.push('Dino Explorer - a Daily Adventure marked complete.'); }
  if (data.numberGames >= 3) { result.push('Number Hero - three number games marked complete.'); }
  if (data.memoryGames >= 3) { result.push('Memory Star - three memory games marked complete.'); }
  if (data.movement >= 3) { result.push('Movement Explorer - three child-confirmed movement activities.'); }
  if (data.creative >= 3) { result.push('Creative Builder - three creative activities marked complete.'); }
  return result;
}
