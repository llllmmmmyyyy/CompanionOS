import { backendRequest, validBackendUrl, validMediaUrl } from '@companion/protocol';
import { Activity, ActivityStep, ActivityContentSource } from '../model/Companion';
import { ActivityPlanRequest } from './AiActivityService';

export class BackendStep {
  id: string = '';
  instruction: string = '';
  durationSeconds: number = 0;
  learningGoal: string = '';
}
export class BackendPlan {
  title: string = '';
  theme: string = '';
  educationalGoal: string = '';
  steps: BackendStep[] = [];
}
export class BackendSegment {
  id: string = '';
  state: string = 'QUEUED';
  videoUrl: string = '';
}
export class BackendJob {
  provider: string = 'GEMINI';
  id: string = '';
  state: string = '';
  source: string = '';
  message: string = '';
  plan: BackendPlan | undefined = undefined;
  segments: BackendSegment[] = [];
}

export function backendActivity(job: BackendJob, request: ActivityPlanRequest, endpoint: string): Activity {
  const plan = job.plan;
  if (!plan || !/^[a-f0-9]{32}$/.test(job.id) || !['ai', 'fallback'].includes(job.source) ||
    typeof plan.title !== 'string' || !plan.title || plan.title.length > 80 || typeof plan.theme !== 'string' || plan.theme.length > 100 ||
    !Array.isArray(plan.steps) || plan.steps.length < 3 || plan.steps.length > 6 ||
    !Array.isArray(job.segments) || job.segments.length !== plan.steps.length ||
    plan.steps.some((step: BackendStep) => !step || typeof step.instruction !== 'string' || !step.instruction || step.instruction.length > 400 ||
      !Number.isInteger(step.durationSeconds) || step.durationSeconds < 10 || step.durationSeconds > 300 ||
      typeof step.learningGoal !== 'string' || step.learningGoal.length > 100) ||
    plan.steps.reduce((sum: number, step: BackendStep) => sum + step.durationSeconds, 0) !== request.durationMinutes * 60) {
    throw new Error('Invalid backend activity');
  }
  const activity = new Activity(job.id, plan.title, request.interest, plan.steps.map((step: BackendStep) => step.instruction));
  activity.category = request.category; activity.duration = request.durationMinutes; activity.theme = plan.theme;
  activity.educationalGoal = plan.educationalGoal; activity.generatedByAI = job.source === 'ai';
  activity.contentSource = job.source === 'ai' ?
    (job.provider === 'HUAWEI' ? ActivityContentSource.HUAWEI_AI : ActivityContentSource.GEMINI_AI) : ActivityContentSource.BUILT_IN;
  activity.aiProvider = job.source === 'ai' ? (job.provider === 'HUAWEI' ? 'HUAWEI' : 'GEMINI') : '';
  activity.aiGenerationId = job.source === 'ai' ? job.id : '';
  activity.activitySteps = plan.steps.map((step: BackendStep, index: number) => {
    const result = new ActivityStep(step.instruction); result.durationSeconds = step.durationSeconds;
    result.learningGoal = step.learningGoal; result.fallbackVisual = plan.theme;
    const segment = job.segments[index];
    if (segment && segment.state === 'READY' && typeof segment.videoUrl === 'string' && segment.videoUrl !== '') {
      const url = segment.videoUrl.startsWith('/videos/') ? `${endpoint}${segment.videoUrl}` : segment.videoUrl;
      if (!validMediaUrl(url)) { throw new Error('Invalid video URL'); }
      result.videoUrl = url;
    }
    return result;
  });
  activity.videoSegments = activity.activitySteps.map((step: ActivityStep) => step.videoUrl);
  return activity;
}

export class BackendActivityService {
  static async create(endpoint: string, request: ActivityPlanRequest, interests: string[],
    progress: (message: string) => void, active: () => boolean, provider: string = 'GEMINI'): Promise<BackendJob> {
    if (!validBackendUrl(endpoint)) { throw new Error('Invalid backend URL'); }
    const initial = JSON.parse(await backendRequest(`${endpoint}/activities/generate`, 'POST', JSON.stringify({
      childAge: request.childAge, interests, activityCategory: request.category,
      educationalGoal: request.educationalGoal, durationMinutes: request.durationMinutes, provider
    }))) as BackendJob;
    if (!/^[a-f0-9]{32}$/.test(initial.id)) { throw new Error('Invalid activity ID'); }
    const deadline = Date.now() + 15 * 60 * 1000;
    while (active() && Date.now() < deadline) {
      const job = await BackendActivityService.status(endpoint, initial.id);
      if (typeof job.message !== 'string' || job.message.length > 200) { throw new Error('Invalid progress'); }
      progress(job.message);
      if (job.state === 'PLAYABLE' || job.state === 'READY') { return job; }
      if (job.state === 'FAILED') { throw new Error('Generation failed'); }
      await new Promise<void>((resolve: () => void) => { setTimeout(resolve, 1000); });
    }
    throw new Error('Generation stopped or timed out');
  }
  static async status(endpoint: string, id: string): Promise<BackendJob> {
    if (!validBackendUrl(endpoint) || !/^[a-f0-9]{32}$/.test(id)) { throw new Error('Invalid status request'); }
    return JSON.parse(await backendRequest(`${endpoint}/activities/${id}/status`)) as BackendJob;
  }
}
