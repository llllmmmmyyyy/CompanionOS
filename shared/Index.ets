export { backendRequest } from './Network';
export enum ActivityContentSource {
  GEMINI_AI = 'GEMINI_AI', HUAWEI_AI = 'HUAWEI_AI', BUILT_IN = 'BUILT_IN', USER_VIDEO = 'USER_VIDEO'
}
export class VideoSource {
  sourceType: ActivityContentSource = ActivityContentSource.BUILT_IN;
  uri: string = '';
  title: string = '';
  activityId: string = '';
  provider: string = '';
}
export function contentLabel(source: ActivityContentSource): string {
  if (source === ActivityContentSource.GEMINI_AI) { return 'Generated with Gemini'; }
  if (source === ActivityContentSource.HUAWEI_AI) { return 'Generated via Huawei Cloud MaaS'; }
  return source === ActivityContentSource.USER_VIDEO ? 'My Video' : 'CompanionOS Built-in';
}
export function validVideoSource(source: VideoSource): boolean {
  return source !== null && source !== undefined && ['GEMINI_AI', 'HUAWEI_AI', 'BUILT_IN', 'USER_VIDEO'].includes(source.sourceType) &&
    typeof source.uri === 'string' && source.uri.length <= 1000 && validMediaUrl(source.uri) &&
    typeof source.title === 'string' && source.title.length <= 80 && typeof source.activityId === 'string' && source.activityId.length <= 80 &&
    (source.provider === undefined || (typeof source.provider === 'string' && ['GEMINI', 'HUAWEI', ''].includes(source.provider)));
}
export const MESSAGE_TYPES: string[] = ['PING', 'HELLO', 'STATE_SYNC', 'START', 'PAUSE', 'RESUME',
  'NEXT_STEP', 'PREVIOUS_STEP', 'CANCEL', 'COMPLETE', 'VIDEO_READY', 'VIDEO_BUFFERING', 'VIDEO_FAILED'];

export class TvMessage {
  content: VideoSource = new VideoSource();
  protocolVersion: number = 1;
  type: string = 'STATE_SYNC';
  sessionId: string = '';
  activityId: string = '';
  title: string = 'CompanionOS TV';
  stepIndex: number = 0;
  totalSteps: number = 1;
  instruction: string = 'Waiting for phone...';
  videoUrl: string = '';
  videoSource: string = 'FALLBACK';
  visual: string = 'Together';
  phase: string = 'idle';
  remaining: number = 0;
}

export function validMediaUrl(url: string): boolean {
  return url === '' || /^https:\/\/[a-zA-Z0-9.-]+(:[0-9]+)?\/[a-zA-Z0-9/_?.=&%-]+$/.test(url) ||
    /^http:\/\/127\.0\.0\.1:18080\/videos\/[a-f0-9]+$/.test(url);
}

export function parseMessage(raw: string): TvMessage | undefined {
  try {
    if (raw.length > 16384) { return undefined; }
    const value = JSON.parse(raw) as TvMessage;
    if (value === null || value.protocolVersion !== 1 || !MESSAGE_TYPES.includes(value.type) ||
      typeof value.sessionId !== 'string' || value.sessionId.length > 100 ||
      typeof value.activityId !== 'string' || value.activityId.length > 80 ||
      typeof value.title !== 'string' || value.title.length > 80 ||
      typeof value.instruction !== 'string' || value.instruction.length > 400 ||
      !Number.isInteger(value.totalSteps) || value.totalSteps < 1 || value.totalSteps > 10 ||
      !Number.isInteger(value.stepIndex) || value.stepIndex < 0 || value.stepIndex >= value.totalSteps ||
      !Number.isInteger(value.remaining) || value.remaining < 0 || value.remaining > 600 ||
      !['idle', 'running', 'paused', 'ready', 'completed', 'cancelled'].includes(value.phase) ||
      !['FALLBACK', 'LOCAL', 'REMOTE_CACHED', 'REMOTE_STREAM'].includes(value.videoSource) ||
      typeof value.videoUrl !== 'string' || value.videoUrl.length > 1000 || !validMediaUrl(value.videoUrl) ||
      typeof value.visual !== 'string' || value.visual.length > 100) { return undefined; }
    if (value.content === undefined) {
      value.content = new VideoSource(); value.content.uri = value.videoUrl;
      value.content.title = value.title; value.content.activityId = value.activityId;
    }
    if (!validVideoSource(value.content) || value.content.uri !== value.videoUrl || value.content.activityId !== value.activityId) { return undefined; }
    return value;
  } catch { return undefined; }
}

export class RelayStatus {
  revision: number = 0;
  connected: boolean = false;
  receiverConnected: boolean = false;
  message: TvMessage = new TvMessage();
  videoStatus: string = 'IDLE';
}

export function validBackendUrl(url: string): boolean {
  return url === 'http://127.0.0.1:18080' || /^https:\/\/[a-zA-Z0-9.-]+(:[0-9]{1,5})?$/.test(url);
}
