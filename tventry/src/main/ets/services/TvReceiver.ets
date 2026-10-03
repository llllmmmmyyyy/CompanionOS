import { TvMessage, RelayStatus, parseMessage, backendRequest, validBackendUrl } from '@companion/protocol';

export type ReceiverListener = (status: string, message: TvMessage) => void;
export class TvReceiver {
  private timer: number = -1;
  private pending: boolean = false;
  private active: boolean = false;
  private last: TvMessage = new TvMessage();
  private revision: number = -1;
  private everConnected: boolean = false;
  private endpoint: string;
  private room: string;
  private listener: ReceiverListener;
  constructor(endpoint: string, room: string, listener: ReceiverListener) {
    this.endpoint = endpoint; this.room = room; this.listener = listener;
  }
  start(): void {
    if (!validBackendUrl(this.endpoint) || !/^[a-zA-Z0-9_-]{4,32}$/.test(this.room)) {
      this.listener('ERROR', this.last); return;
    }
    this.active = true; this.listener('CONNECTING', this.last);
    this.timer = setInterval(() => { this.poll(); }, 500); this.poll();
  }
  stop(): void { this.active = false; clearInterval(this.timer); }
  async feedback(status: string): Promise<void> {
    try { await backendRequest(`${this.endpoint}/tv/rooms/${this.room}/feedback`, 'POST', JSON.stringify({ status })); }
    catch { /* Video errors never prevent phone completion. */ }
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
        this.listener('CONNECTED', this.last);
      } else { this.listener(this.everConnected ? 'DISCONNECTED' : 'WAITING', this.last); }
    } catch {
      if (this.active) { this.listener(this.everConnected ? 'DISCONNECTED' : 'OFFLINE', this.last); }
    } finally { this.pending = false; }
  }
}
