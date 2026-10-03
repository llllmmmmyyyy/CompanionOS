import { Activity, ActivityStep } from '../model/Companion';

export class ActivityPlanRequest {
  childAge: string = '4–5';
  interest: string = 'Movement';
  category: string = 'MOVE';
  durationMinutes: number = 3;
  educationalGoal: string = 'Practice together';
}

export class ActivityPlan {
  title: string = '';
  theme: string = '';
  steps: ActivityStep[] = [];
  videoPrompts: string[] = [];
  source: string = 'mock';
}

export interface AiActivityService {
  generateActivityPlan(request: ActivityPlanRequest): Promise<ActivityPlan>;
}

export const TV_CATEGORIES: string[] = ['MOVE', 'LEARN', 'IMAGINE', 'CALM'];
export const TV_TITLES: string[] = ['Dino Movement Adventure', 'Space Counting Mission',
  'Magic Forest Story', 'Cloud Breathing Adventure'];
const INSTRUCTIONS: string[][] = [
  ['Make a clear space with your parent. Stand or sit comfortably.',
    'Take tiny dinosaur steps, or move your hands gently. Count five together.',
    'Rest beside your parent. Share your favorite dinosaur move.'],
  ['Sit beside your parent. Imagine a friendly spaceship.',
    'Count five pretend stars on your fingers. Take turns counting.',
    'Rest and tell your parent which star you would visit.'],
  ['Sit comfortably with your parent. Imagine a peaceful forest.',
    'Take turns describing a friendly animal and its cozy home.',
    'Give your story a happy ending. Rest together.'],
  ['Sit comfortably beside your parent. Relax your shoulders.',
    'Breathe normally and imagine a soft cloud drifting. No breath holding.',
    'Rest. Tell your parent how you feel. Stop whenever you need.']
];

export class MockAiActivityService implements AiActivityService {
  async generateActivityPlan(request: ActivityPlanRequest): Promise<ActivityPlan> {
    const index = TV_CATEGORIES.indexOf(request.category);
    if (index < 0 || !['4–5', '6–8'].includes(request.childAge) ||
      ![3, 5, 10].includes(request.durationMinutes)) { throw new Error('Unsupported activity request'); }
    const plan = new ActivityPlan();
    plan.title = TV_TITLES[index];
    plan.theme = ['Friendly dinosaurs', 'Peaceful space', 'Gentle forest', 'Soft clouds'][index];
    plan.steps = INSTRUCTIONS[index].map((instruction: string) => {
      const step = new ActivityStep(instruction);
      step.durationSeconds = request.durationMinutes * 20;
      step.learningGoal = request.educationalGoal;
      step.fallbackVisual = plan.theme;
      return step;
    });
    plan.videoPrompts = plan.steps.map((step: ActivityStep) =>
      `Gentle ${plan.theme} illustration: ${step.instruction} No flashing, danger or frightening imagery.`);
    return plan;
  }
}

export function activityFromPlan(plan: ActivityPlan, request: ActivityPlanRequest): Activity {
  if (plan.source !== 'mock' && plan.source !== 'ai') { throw new Error('Unknown source'); }
  if (!plan.title || plan.title.length > 80 || !plan.steps.length || plan.steps.length > 10 ||
    plan.steps.some((step: ActivityStep) => !step.instruction || step.instruction.length > 400 ||
      !Number.isFinite(step.durationSeconds) || step.durationSeconds <= 0 ||
      (step.videoUrl !== '' && !/^https:\/\//.test(step.videoUrl))) ||
    plan.steps.reduce((total: number, step: ActivityStep) => total + step.durationSeconds, 0) !== request.durationMinutes * 60) {
    throw new Error('Invalid activity plan');
  }
  const activity = new Activity(`tv-${request.category.toLowerCase()}`, plan.title, request.interest,
    plan.steps.map((step: ActivityStep) => step.instruction));
  activity.category = request.category;
  activity.duration = request.durationMinutes;
  activity.theme = plan.theme;
  activity.educationalGoal = request.educationalGoal;
  activity.activitySteps = plan.steps;
  activity.videoSegments = plan.steps.map((step: ActivityStep) => step.videoUrl);
  activity.generatedByAI = plan.source === 'ai';
  return activity;
}
