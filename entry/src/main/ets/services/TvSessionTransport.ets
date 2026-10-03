import { Activity } from '../model/Companion';
import { VideoSource } from '@companion/protocol';

export class TvFrame {
  content: VideoSource = new VideoSource();
  activityId: string = '';
  videoUrl: string = '';
  videoSource: string = 'FALLBACK';
  sessionId: string = '';
  title: string = '';
  instruction: string = 'Choose an activity on your phone.';
  visual: string = 'Together';
  remaining: number = 0;
  phase: string = 'idle';
  step: number = 0;
  steps: number = 1;
}

export interface TvSessionTransport {
  connect(): Promise<void>;
  disconnect(): void;
  startActivity(activity: Activity, frame: TvFrame): void;
  pauseActivity(frame: TvFrame): void;
  resumeActivity(frame: TvFrame): void;
  cancelActivity(frame: TvFrame): void;
  nextStep(frame: TvFrame): void;
  previousStep(frame: TvFrame): void;
  synchronize(frame: TvFrame): void;
}

export type TvEventListener = (event: string, frame: TvFrame) => void;

// Frames are projections of phone state. This receiver never runs a second timer or writes history.
export class LocalDemoTvTransport implements TvSessionTransport {
  private connected: boolean = false;
  private listener: TvEventListener;
  constructor(listener: TvEventListener) { this.listener = listener; }
  async connect(): Promise<void> { this.connected = true; this.listener('connected', new TvFrame()); }
  disconnect(): void { this.connected = false; this.listener('disconnected', new TvFrame()); }
  startActivity(activity: Activity, frame: TvFrame): void { this.emit('activityStarted', frame); }
  pauseActivity(frame: TvFrame): void { this.emit('activityPaused', frame); }
  resumeActivity(frame: TvFrame): void { this.emit('activityResumed', frame); }
  cancelActivity(frame: TvFrame): void { this.emit('activityCancelled', frame); }
  nextStep(frame: TvFrame): void { this.emit('stepChanged', frame); }
  previousStep(frame: TvFrame): void { this.emit('stepChanged', frame); }
  synchronize(frame: TvFrame): void {
    this.emit(frame.phase === 'completed' ? 'activityCompleted' : 'stateChanged', frame);
  }
  private emit(event: string, frame: TvFrame): void {
    if (this.connected) { this.listener(event, frame); }
  }
}

// A real TV receiver must implement this channel with pairing, acknowledgement and ordered delivery.
export interface DistributedTvChannel {
  connect(): Promise<void>;
  close(): void;
  send(event: string, frame: TvFrame): void;
}

export class HarmonyDistributedTvTransport implements TvSessionTransport {
  private channel: DistributedTvChannel;
  constructor(channel: DistributedTvChannel) { this.channel = channel; }
  connect(): Promise<void> { return this.channel.connect(); }
  disconnect(): void { this.channel.close(); }
  startActivity(activity: Activity, frame: TvFrame): void { this.channel.send('activityStarted', frame); }
  pauseActivity(frame: TvFrame): void { this.channel.send('activityPaused', frame); }
  resumeActivity(frame: TvFrame): void { this.channel.send('activityResumed', frame); }
  cancelActivity(frame: TvFrame): void { this.channel.send('activityCancelled', frame); }
  nextStep(frame: TvFrame): void { this.channel.send('stepChanged', frame); }
  previousStep(frame: TvFrame): void { this.channel.send('stepChanged', frame); }
  synchronize(frame: TvFrame): void { this.channel.send(frame.phase === 'completed' ? 'activityCompleted' : 'stateChanged', frame); }
}
