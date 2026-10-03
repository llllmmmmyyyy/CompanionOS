import { http } from '@kit.NetworkKit';
import { ACTIVITIES, ParentSettings, validEndpoint } from '../model/Companion';

export class AiRecommendation {
  source: string = '';
  activityId: string = '';
  ageGroup: string = '';
  minutes: number = 0;
  adultRequired: boolean = false;
}

export class RecommendationResult {
  source: string = 'offline';
  activityId: string = '';
  message: string = 'Offline activity — no AI service is configured.';
}

export function validateRecommendation(raw: string, settings: ParentSettings): string {
  try {
    if (raw.length > 8192) { return ''; }
    const value = JSON.parse(raw) as AiRecommendation;
    if (value === null || value.source !== 'ai' || value.ageGroup !== settings.age ||
      value.minutes !== settings.minutes || value.adultRequired !== true ||
      !ACTIVITIES.some((activity) => activity.id === value.activityId && settings.interests.includes(activity.interest))) {
      return '';
    }
    return value.activityId;
  } catch { return ''; }
}

export class AiService {
  static async recommend(settings: ParentSettings): Promise<RecommendationResult> {
    const result = new RecommendationResult();
    const preferred = ACTIVITIES.find((activity) => settings.interests.includes(activity.interest));
    result.activityId = preferred ? preferred.id : ACTIVITIES[0].id;
    if (!validEndpoint(settings.aiEndpoint)) { return result; }
    let request: http.HttpRequest | undefined = undefined;
    let timeout: number = -1;
    try {
      request = http.createHttp();
      const response = await Promise.race([
        request.request(settings.aiEndpoint, {
          method: http.RequestMethod.POST,
          header: { 'Content-Type': 'application/json' },
          extraData: JSON.stringify({ ageGroup: settings.age, interests: settings.interests,
            minutes: settings.minutes, adultRequired: true,
            allowedActivityIds: ACTIVITIES.filter((activity) => settings.interests.includes(activity.interest))
              .map((activity) => activity.id) }),
          expectDataType: http.HttpDataType.STRING,
          connectTimeout: 5000,
          readTimeout: 10000,
          maxLimit: 8192,
          usingCache: false
        }),
        new Promise<http.HttpResponse>((resolve, reject) => {
          timeout = setTimeout(() => { reject(new Error('AI request timed out')); }, 10000);
        })
      ]);
      if (response.responseCode !== 200 || typeof response.result !== 'string') { throw new Error('Invalid response'); }
      const id = validateRecommendation(response.result, settings);
      if (id === '') { throw new Error('Unsafe or unsupported recommendation'); }
      result.activityId = id;
      result.source = 'ai';
      result.message = 'AI service recommendation — activity steps remain locally curated.';
    } catch {
      result.message = 'AI service unavailable or response invalid. Offline activity is ready instead.';
    } finally {
      clearTimeout(timeout);
      if (request) { request.destroy(); }
    }
    return result;
  }
}
