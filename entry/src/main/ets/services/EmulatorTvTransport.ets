import { TvMessage, RelayStatus, parseMessage, validBackendUrl, backendRequest, connectionError } from '@companion/protocol';
import { Activity } from '../model/Companion';
import { TvFrame, TvSessionTransport, TvEventListener } from './TvSessionTransport';

class PendingCommand {
  type: string;
  frame: TvFrame;
  constructor(type: string, frame: TvFrame) { this.type = type; this.frame = frame; }
}

export class EmulatorTvTransport implements TvSessionTransport {
  private active: boolean = false;
  private pending: boolean = false;
  private commands: PendingCommand[] = [];
  private connected: boolean = false;
  private generation: number = 0;
  private endpoint: string;
  private room: string;
  private listener: TvEventListener;
  constructor(endpoint: string, room: string, listener: TvEventListener) {
    this.endpoint = endpoint; this.room = room; this.listener = listener;
  }
  async connect(): Promise<void> {
    console.info(`[CompanionPhoneTV] connection attempt endpoint=${this.endpoint} room=${this.room}`);
    if (!validBackendUrl(this.endpoint) || !/^[a-zA-Z0-9_-]{4,32}$/.test(this.room)) { throw new Error('Invalid backend or room'); }
    const state = JSON.parse(await backendRequest(`${this.endpoint}/tv/rooms/${this.room}/state`)) as RelayStatus;
    if (state.receiverConnected !== true) { throw new Error('TV receiver is not online'); }
    this.active = true; this.connected = true; this.generation++;
    this.listener('connected', new TvFrame());
    console.info(`[CompanionPhoneTV] Connected endpoint=${this.endpoint} room=${this.room}`);
  }
  disconnect(): void {
    this.active = false; this.connected = false; this.generation++; this.commands = [];
    backendRequest(`${this.endpoint}/tv/rooms/${this.room}/disconnect`, 'POST', '{}').catch(() => {});
    this.listener('disconnected', new TvFrame());
  }
  startActivity(activity: Activity, frame: TvFrame): void { this.enqueue('START', frame); }
  pauseActivity(frame: TvFrame): void { this.enqueue('PAUSE', frame); }
  resumeActivity(frame: TvFrame): void { this.enqueue('RESUME', frame); }
  cancelActivity(frame: TvFrame): void { this.enqueue('CANCEL', frame); }
  nextStep(frame: TvFrame): void { this.enqueue('NEXT_STEP', frame); }
  previousStep(frame: TvFrame): void { this.enqueue('PREVIOUS_STEP', frame); }
  synchronize(frame: TvFrame): void { this.enqueue(frame.phase === 'completed' ? 'COMPLETE' : 'STATE_SYNC', frame); }
  private enqueue(type: string, frame: TvFrame): void {
    if (!this.active) { return; }
    if (type === 'STATE_SYNC' || type === 'COMPLETE') {
      this.commands = this.commands.filter((command: PendingCommand) => command.type !== 'STATE_SYNC' && command.type !== 'COMPLETE');
    }
    if (this.commands.length >= 16) { this.commands = []; type = 'STATE_SYNC'; }
    this.commands.push(new PendingCommand(type, frame)); this.pump();
  }
  private async pump(): Promise<void> {
    if (this.pending || !this.active || !this.commands.length) { return; }
    this.pending = true;
    const generation = this.generation;
    const command = this.commands.shift();
    if (!command) { this.pending = false; return; }
    const message = new TvMessage();
    message.type = command.type; message.sessionId = command.frame.sessionId;
    message.activityId = command.frame.activityId; message.title = command.frame.title;
    message.instruction = command.frame.instruction; message.stepIndex = command.frame.step;
    message.totalSteps = command.frame.steps; message.phase = command.frame.phase;
    message.remaining = command.frame.remaining; message.visual = command.frame.visual;
    message.videoUrl = command.frame.videoUrl; message.videoSource = command.frame.videoSource;
    message.content = command.frame.content;
    try {
      if (!parseMessage(JSON.stringify(message))) { throw new Error('Invalid phone frame'); }
      const result = JSON.parse(await backendRequest(`${this.endpoint}/tv/rooms/${this.room}/phone`, 'POST', JSON.stringify(message))) as RelayStatus;
      if (this.active && generation === this.generation) {
        const wasConnected = this.connected; this.connected = result.receiverConnected === true;
        if (this.connected !== wasConnected) { this.listener(this.connected ? 'connected' : 'disconnected', command.frame); }
        if (result.videoStatus === 'VIDEO_FAILED') { this.listener('videoFallback', command.frame); }
      }
    } catch (error) {
      console.error(`[CompanionPhoneTV] endpoint=${this.endpoint} room=${this.room} ${command.type}: ${connectionError(error as Error)}`);
      if (this.active && generation === this.generation && this.connected) {
        this.connected = false; this.listener('disconnected', command.frame);
      }
    } finally {
      this.pending = false;
      if (this.active && this.commands.length) { this.pump(); }
    }
  }
}
