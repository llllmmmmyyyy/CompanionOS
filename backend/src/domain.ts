import { createHash } from 'node:crypto';

export const SAFETY_PROMPT = `Create an adult-accompanied activity for ages 4-8. Return only the requested JSON schema.
Use simple age-appropriate language, gentle safe movement, clear educational objectives, seated alternatives and rest.
No jumping challenges, dangerous movements, climbing, violence, weapons, frightening imagery, flashing/strobe patterns,
breath holding or risky physical challenges. No camera, microphone, emotion analysis or personal data.
Every video prompt must describe a gentle steady-camera 16:9 child-friendly illustration and repeat these safety exclusions.
Use 3-6 steps whose integer durations sum exactly to durationMinutes * 60. Do not output external URLs.`;
export interface GenerateRequest { childAge: string; interests: string[]; activityCategory: string; educationalGoal: string; durationMinutes: number; provider?: 'GEMINI' | 'HUAWEI'; }
export interface Step { id: string; instruction: string; durationSeconds: number; learningGoal: string; veoPrompt: string; }
export interface Plan { title: string; theme: string; educationalGoal: string; steps: Step[]; }
export const categories = ['MOVE', 'LEARN', 'IMAGINE', 'CALM'];
const unsafe = /\b(jump|climb|weapon|fight|kill|strobe|flash|hold your breath|knife|fire|scary|terrifying|run fast)\b/i;
function text(value: unknown, max: number): value is string { return typeof value === 'string' && value.trim().length > 0 && value.length <= max; }
export function validateRequest(value: unknown): GenerateRequest {
  const r = value as GenerateRequest;
  if (!r || (r.provider !== undefined && !['GEMINI', 'HUAWEI'].includes(r.provider)) || !['4–5', '6–8'].includes(r.childAge) || !categories.includes(r.activityCategory) ||
    ![3, 5, 10].includes(r.durationMinutes) || !Array.isArray(r.interests) || !r.interests.length || r.interests.length > 3 ||
    !r.interests.every(v => ['Movement', 'Sounds', 'Nature'].includes(v)) || !text(r.educationalGoal, 100) || unsafe.test(r.educationalGoal)) {
    throw new Error('Invalid or unsafe generation request');
  }
  return { childAge: r.childAge, interests: [...r.interests], activityCategory: r.activityCategory, educationalGoal: r.educationalGoal, durationMinutes: r.durationMinutes,
    ...(r.provider ? { provider: r.provider } : {}) };
}
export function validatePlan(value: unknown, request: GenerateRequest): Plan {
  const p = value as Plan;
  if (!p || Object.keys(p).some(k => !['title', 'theme', 'educationalGoal', 'steps'].includes(k)) ||
    !text(p.title, 80) || !text(p.theme, 100) || !text(p.educationalGoal, 100) ||
    !Array.isArray(p.steps) || p.steps.length < 3 || p.steps.length > 6 || new Set(p.steps.map(s => s?.id)).size !== p.steps.length ||
    p.steps.some(s => !s || Object.keys(s).some(k => !['id', 'instruction', 'durationSeconds', 'learningGoal', 'veoPrompt'].includes(k)) ||
      !/^step-[1-6]$/.test(s.id) || !text(s.instruction, 400) || !text(s.learningGoal, 100) || !text(s.veoPrompt, 1200) ||
      !Number.isInteger(s.durationSeconds) || s.durationSeconds < 10 || s.durationSeconds > 300 ||
      unsafe.test(s.instruction) || unsafe.test(s.learningGoal)) ||
    p.steps.reduce((n, s) => n + s.durationSeconds, 0) !== request.durationMinutes * 60 ||
    !p.steps.some(s => /rest|break|relax/i.test(s.instruction))) { throw new Error('Invalid or unsafe provider plan'); }
  // Never trust a provider's media prompt verbatim: enforce server-controlled framing and safety.
  return { title: p.title, theme: p.theme, educationalGoal: p.educationalGoal, steps: p.steps.map(s => ({ ...s,
    veoPrompt: `Gentle child-friendly illustration, steady camera, soft colors, landscape 16:9. ${s.instruction} ${s.veoPrompt} No violence, weapons, frightening imagery, flashing, strobe, climbing or risky challenges. Adult accompanied; include a rest moment.` })) };
}
export function fallbackPlan(r: GenerateRequest): Plan {
  const index = categories.indexOf(r.activityCategory);
  const titles = ['Dino Movement Adventure', 'Space Counting Mission', 'Magic Forest Story', 'Cloud Breathing Adventure'];
  const themes = ['Friendly dinosaurs', 'Peaceful space', 'Gentle forest', 'Soft clouds'];
  const middle = ['Count five tiny dinosaur steps or gentle seated hand movements together.',
    'Count five pretend stars on your fingers. Take turns.', 'Take turns describing a friendly forest animal.',
    'Breathe normally and imagine a soft cloud drifting.'];
  return { title: titles[index], theme: themes[index], educationalGoal: r.educationalGoal,
    steps: ['Sit or stand comfortably beside your parent in a clear space.', middle[index],
      'Rest beside your parent and share how you feel. Stop whenever you need.'].map((instruction, i) => ({
      id: `step-${i + 1}`, instruction, durationSeconds: r.durationMinutes * 20,
      learningGoal: r.educationalGoal, veoPrompt: `Peaceful ${themes[index]} illustration. Gentle movements, no flashing or danger.` })) };
}
export function cacheKey(activityId: string, step: Step, model: string): string {
  return createHash('sha256').update(JSON.stringify([activityId, step.id, step.veoPrompt, model, '16:9', '720p', 'safety-v1'])).digest('hex');
}
export const planSchema = { type: 'object', additionalProperties: false, required: ['title', 'theme', 'educationalGoal', 'steps'], properties: {
  title: { type: 'string' }, theme: { type: 'string' }, educationalGoal: { type: 'string' }, steps: { type: 'array', minItems: 3, maxItems: 6,
    items: { type: 'object', additionalProperties: false, required: ['id', 'instruction', 'durationSeconds', 'learningGoal', 'veoPrompt'], properties: {
      id: { type: 'string' }, instruction: { type: 'string' }, durationSeconds: { type: 'integer' }, learningGoal: { type: 'string' }, veoPrompt: { type: 'string' }
    } } } } };
