import { GameState, validGame } from './InteractiveActivity';
import { BusinessError } from '@kit.BasicServicesKit';
export { GameState, GameEngine, InteractiveActivity, gameDefinition, GAME_IDS, validGame } from './InteractiveActivity';
export { GameBoard } from './GameBoard';
export { backendRequest } from './Network';
export const EMULATOR_RELAY_ENDPOINT: string = 'http://10.0.2.2:18080';
export function connectionError(error: Error): string {
  if (!error) { return 'Unknown network error'; }
  const code = (error as BusinessError).code;
  const message = typeof error.message === 'string' ? error.message.slice(0, 180) : 'Unknown network error';
  return typeof code === 'number' ? `Error ${code}: ${message}` : message;
}
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
  game: GameState = new GameState();
  activityMode: string = 'VIDEO';
  content: VideoSource = new VideoSource();
  protocolVersion: number = 1;
  type: string = 'STATE_SYNC';
  sessionId: string = '';
  activityId: string = '';
  title: string = 'CompanionOS Large Screen';
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
    /^http:\/\/(10\.0\.2\.2|127\.0\.0\.1):18080\/videos\/[a-f0-9]+$/.test(url);
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
    if (value.game === undefined) { value.game = new GameState(); }
    if (!validGame(value.game)) { return undefined; }
    if (value.activityMode === undefined) { value.activityMode = 'VIDEO'; }
    if (!['VIDEO', 'INTERACTIVE', 'GUIDED_OFFSCREEN'].includes(value.activityMode)) { return undefined; }
    if (value.content === undefined) {
      value.content = new VideoSource(); value.content.uri = value.videoUrl;
      value.content.title = value.title; value.content.activityId = value.activityId;
    }
    if (!validVideoSource(value.content) || value.content.uri !== value.videoUrl || value.content.activityId !== value.activityId) { return undefined; }
    return value;
  } catch { return undefined; }
}

export class GameCommand {
  id: string = ''; sessionId: string = ''; action: string = ''; value: string = '';
  revision: number = 0; round: number = 0; phase: string = ''; selectedCount: number = 0;
}
export function validGameCommand(command: GameCommand): boolean {
  return !!command && typeof command.id === 'string' && command.id.length <= 80 && typeof command.sessionId === 'string' && command.sessionId.length <= 100 &&
    ['answer', 'retry', 'next', 'more', 'done', 'skip'].includes(command.action) && typeof command.value === 'string' && command.value.length <= 40 &&
    Number.isInteger(command.revision) && command.revision >= 0 && command.revision <= 1000 && Number.isInteger(command.round) && command.round >= 0 && command.round <= 3 && Number.isInteger(command.selectedCount) && command.selectedCount >= 0 && command.selectedCount <= 4 &&
    ['input', 'retry', 'round-success', 'movement', 'confirm', 'preview'].includes(command.phase);
}
export class RelayStatus {
  actions: GameCommand[] = [];
  revision: number = 0;
  connected: boolean = false;
  receiverConnected: boolean = false;
  message: TvMessage = new TvMessage();
  videoStatus: string = 'IDLE';
}

export function validBackendUrl(url: string): boolean {
  return url === EMULATOR_RELAY_ENDPOINT || url === 'http://127.0.0.1:18080' || /^https:\/\/[a-zA-Z0-9.-]+(:[0-9]{1,5})?$/.test(url);
}

export { WorldEngine, WorldState, WorldStatus, WorldCommand, WorldResult, WorldEnvelope, WorldSlot, parseWorld, validWorldResult, worldSlots, recommendedWorld, WORLD_GAMES, worldTitle, worldStyle, worldName } from './ChildWorldModel';
