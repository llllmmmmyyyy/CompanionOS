export const types = ['PING', 'HELLO', 'STATE_SYNC', 'START', 'PAUSE', 'RESUME', 'NEXT_STEP', 'PREVIOUS_STEP', 'CANCEL', 'COMPLETE', 'VIDEO_READY', 'VIDEO_BUFFERING', 'VIDEO_FAILED'];
export interface VideoSource { sourceType: string; uri: string; title: string; activityId: string; provider?: string; }
export interface TvMessage { content?: VideoSource; protocolVersion: number; type: string; sessionId: string; activityId: string; title: string;
  stepIndex: number; totalSteps: number; instruction: string; videoUrl: string; videoSource: string; visual: string; phase: string; remaining: number; }
export function validMessage(m: unknown): m is TvMessage {
  const v = m as TvMessage; return !!v && (!v.content || (['GEMINI_AI', 'HUAWEI_AI', 'BUILT_IN', 'USER_VIDEO'].includes(v.content.sourceType) &&
    v.content.uri === v.videoUrl && typeof v.content.title === 'string' && v.content.title.length <= 80 && v.content.activityId === v.activityId &&
    (!v.content.provider || ['GEMINI', 'HUAWEI'].includes(v.content.provider)))) && v.protocolVersion === 1 && types.includes(v.type) &&
    typeof v.sessionId === 'string' && v.sessionId.length <= 100 && typeof v.activityId === 'string' && v.activityId.length <= 80 &&
    typeof v.title === 'string' && v.title.length <= 80 && typeof v.instruction === 'string' && v.instruction.length <= 400 &&
    typeof v.visual === 'string' && v.visual.length <= 100 && Number.isInteger(v.totalSteps) && v.totalSteps > 0 && v.totalSteps <= 10 &&
    Number.isInteger(v.stepIndex) && v.stepIndex >= 0 && v.stepIndex < v.totalSteps && Number.isInteger(v.remaining) && v.remaining >= 0 && v.remaining <= 600 &&
    ['idle', 'running', 'paused', 'ready', 'completed', 'cancelled'].includes(v.phase) &&
    ['FALLBACK', 'LOCAL', 'REMOTE_CACHED', 'REMOTE_STREAM'].includes(v.videoSource) && typeof v.videoUrl === 'string' && v.videoUrl.length <= 1000 &&
    (v.videoUrl === '' || /^http:\/\/127\.0\.0\.1:18080\/videos\/[a-f0-9]+$/.test(v.videoUrl) || /^https:\/\/[a-zA-Z0-9.-]+(:[0-9]+)?\/[a-zA-Z0-9/_?.=&%-]+$/.test(v.videoUrl));
}
export function waitingMessage(): TvMessage { return { protocolVersion: 1, type: 'STATE_SYNC', sessionId: '', activityId: '', title: 'CompanionOS TV',
  instruction: 'Waiting for phone...', stepIndex: 0, totalSteps: 1, videoUrl: '', videoSource: 'FALLBACK', visual: 'Together', phase: 'idle', remaining: 0 }; }
interface Room { message: TvMessage; revision: number; phoneAt: number; receiverAt: number; videoStatus: string; }
export class Relay {
  private rooms = new Map<string, Room>();
  private room(code: string): Room {
    if (!/^[a-zA-Z0-9_-]{4,32}$/.test(code)) throw new Error('Invalid room code');
    if (!this.rooms.has(code)) {
      if (this.rooms.size >= 100) throw new Error('Room limit reached');
      this.rooms.set(code, { message: waitingMessage(), revision: 0, phoneAt: 0, receiverAt: 0, videoStatus: 'IDLE' });
    }
    return this.rooms.get(code)!;
  }
  send(code: string, message: unknown, now = Date.now()): void {
    if (!validMessage(message)) throw new Error('Invalid protocol message');
    const room = this.room(code); room.message = message; room.phoneAt = now; room.revision++;
  }
  status(code: string, receiver: boolean, now = Date.now()) {
    const room = this.room(code); if (receiver) room.receiverAt = now;
    return { message: room.message, revision: room.revision, connected: room.phoneAt > 0 && now - room.phoneAt < 6000,
      receiverConnected: room.receiverAt > 0 && now - room.receiverAt < 6000, videoStatus: room.videoStatus };
  }
  feedback(code: string, status: string): void {
    if (!['VIDEO_READY', 'VIDEO_BUFFERING', 'VIDEO_FAILED', 'IDLE'].includes(status)) throw new Error('Invalid feedback');
    this.room(code).videoStatus = status;
  }
  disconnect(code: string): void { this.room(code).phoneAt = 0; }
}
