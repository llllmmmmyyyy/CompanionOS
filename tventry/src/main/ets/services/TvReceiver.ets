import { TvMessage, RelayStatus, parseMessage, backendRequest, validBackendUrl, connectionError, GameCommand } from '@companion/protocol';

export type ReceiverListener = (status: string, message: TvMessage, detail: string) => void;
export class TvReceiver {
  private timer: number = -1;
  private pending: boolean = false;
  private active: boolean = false;
  private last: TvMessage = new TvMessage();
  private revision: number = -1;
  private everConnected: boolean = false;
  private lastStatus: string = '';
  private lastDetail: string = '';
  private endpoint: string;
  private room: string;
  private listener: ReceiverListener;
  constructor(endpoint: string, room: string, listener: ReceiverListener) {
    this.endpoint = endpoint; this.room = room; this.listener = listener;
  }
  start(): void {
    console.info(`[CompanionTV] connection attempt endpoint=${this.endpoint} room=${this.room}`);
    if (!validBackendUrl(this.endpoint) || !/^[a-zA-Z0-9_-]{4,32}$/.test(this.room)) {
      this.report('ERROR', 'Invalid endpoint or room. Use http://10.0.2.2:18080 and family-demo.'); return;
    }
    this.active = true; this.report('CONNECTING', 'Connecting...');
    this.timer = setInterval(() => { this.poll(); }, 500); this.poll();
  }
  stop(): void { this.active = false; clearInterval(this.timer); }
  private report(status: string, detail: string): void {
    if (status !== this.lastStatus || detail !== this.lastDetail) {
      const log = `[CompanionTV] endpoint=${this.endpoint} room=${this.room} ${status}: ${detail}`;
      if (status === 'ERROR' || status === 'OFFLINE' || status === 'DISCONNECTED') { console.error(log); }
      else { console.info(log); }
      this.lastStatus = status; this.lastDetail = detail;
    }
    this.listener(status, this.last, detail);
  }
  async gameInput(command: GameCommand): Promise<boolean> {
    try { await backendRequest(`${this.endpoint}/tv/rooms/${this.room}/game`, 'POST', JSON.stringify(command)); return true; }
    catch (error) { this.report(this.lastStatus, `Game input failed: ${connectionError(error as Error)}. Continue on Phone.`); return false; }
  }
  async feedback(status: string): Promise<void> {
    try { await backendRequest(`${this.endpoint}/tv/rooms/${this.room}/feedback`, 'POST', JSON.stringify({ status })); }
    catch (error) { console.error(`[CompanionTV] feedback endpoint=${this.endpoint} room=${this.room}: ${connectionError(error as Error)}`); }
  }
  private async poll(): Promise<void> {
    if (!this.active || this.pending) { return; } this.pending = true;
    try {
      const result = JSON.parse(await backendRequest(`${this.endpoint}/tv/rooms/${this.room}/state?receiver=true`)) as RelayStatus;
      const message = parseMessage(JSON.stringify(result.message));
      if (!message || typeof result.connected !== 'boolean' || !Number.isSafeInteger(result.revision)) { throw new Error('Invalid state'); }
      if (!this.active) { return; }
      if (result.connected) {
        this.everConnected = true;
        if (result.revision !== this.revision) { this.last = message; this.revision = result.revision; }
        this.report('CONNECTED', 'Connected • Phone online');
      } else {
        this.report(this.everConnected ? 'DISCONNECTED' : 'WAITING',
          this.everConnected ? 'Relay connected; Phone heartbeat expired. Reconnect on Phone.' : 'Connected to Windows relay • Waiting for Phone');
      }
    } catch (error) {
      if (this.active) { this.report(this.everConnected ? 'DISCONNECTED' : 'OFFLINE', `Connection failed: ${connectionError(error as Error)}`); }
    } finally { this.pending = false; }
  }
}
