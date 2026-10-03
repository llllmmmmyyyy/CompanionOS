import { TvMessage, contentLabel } from '@companion/protocol';
import { TvReceiver } from '../services/TvReceiver';

@Entry
@Component
struct TvHome {
  @State connection: string = 'OFFLINE';
  @State frame: TvMessage = new TvMessage();
  @State endpoint: string = 'http://127.0.0.1:18080';
  @State room: string = 'family-demo';
  @State mediaState: string = 'WAITING';
  @State failedUrl: string = '__none__';
  @StorageLink('tvForeground') @Watch('foregroundChanged') foreground: boolean = true;
  private receiver: TvReceiver | undefined = undefined;
  private controller: VideoController = new VideoController();
  private appliedKey: string = '';
  private appliedPhase: string = '';

  aboutToAppear(): void { this.connect(); }
  aboutToDisappear(): void { this.receiver?.stop(); this.stopVideo(); }
  private foregroundChanged(): void {
    if (this.foreground) { this.connect(); } else { this.receiver?.stop(); this.stopVideo(); }
  }
  private connect(): void {
    this.receiver?.stop();
    this.receiver = new TvReceiver(this.endpoint.trim(), this.room.trim(), (status: string, message: TvMessage) => {
      this.connection = status;
      if (status === 'CONNECTED') { this.apply(message); }
      else { this.stopVideo(); this.appliedPhase = ''; }
    });
    this.receiver.start();
  }
  private apply(message: TvMessage): void {
    const key = `${message.sessionId}:${message.stepIndex}:${message.content.uri}`;
    if (key !== this.appliedKey) {
      this.stopVideo(); this.failedUrl = '__none__'; this.mediaState = 'BUFFERING';
      this.appliedKey = key; this.receiver?.feedback('VIDEO_BUFFERING');
    }
    this.frame = message;
    if (message.phase !== this.appliedPhase) {
      this.appliedPhase = message.phase;
      try {
        if (message.phase === 'paused') { this.controller.pause(); }
        else if (message.phase === 'running' && ['PLAYING', 'PAUSED', 'READY'].includes(this.mediaState)) { this.controller.start(); }
        else if (['ready', 'completed', 'cancelled', 'idle'].includes(message.phase)) { this.stopVideo(); }
      } catch { this.videoFailed(); }
    }
  }
  private stopVideo(): void { try { this.controller.pause(); } catch { /* No attached video yet. */ } }
  private videoFailed(): void {
    this.failedUrl = this.frame.content.uri; this.mediaState = 'FALLBACK'; this.receiver?.feedback('VIDEO_FAILED');
  }
  private prepared(): void {
    this.mediaState = this.frame.phase === 'paused' ? 'PAUSED' : 'READY'; this.receiver?.feedback('VIDEO_READY');
    if (this.frame.phase === 'running' && this.connection === 'CONNECTED') {
      try { this.controller.start(); } catch { this.videoFailed(); }
    }
  }
  private videoKey(): string { return `${this.frame.sessionId}:${this.frame.stepIndex}:${this.frame.content.uri}`; }
  private stateLabel(): string {
    if (this.connection === 'DISCONNECTED') { return 'Connection lost — waiting to reconnect'; }
    if (this.frame.phase === 'completed') { return 'COMPLETED'; }
    if (this.frame.phase === 'cancelled') { return 'CANCELLED'; }
    if (this.frame.phase === 'paused') { return 'PAUSED'; }
    if (this.frame.phase === 'ready') { return 'Waiting for parent confirmation'; }
    if (this.frame.phase === 'idle') { return 'WAITING'; }
    return this.mediaState === 'BUFFERING' ? 'BUFFERING' : 'PLAYING';
  }
  build() {
    Column({ space: 12 }) {
      Row({ space: 20 }) {
        Text('CompanionOS TV').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        Text(this.frame.title).fontSize(22).fontColor('#D9EFE3').layoutWeight(1)
        Text(this.connection).fontSize(18).fontColor('#BCE5D0')
      }.width('100%')
      Stack({ alignContent: Alignment.Center }) {
        if (this.frame.content.uri !== this.failedUrl &&
          ['running', 'paused'].includes(this.frame.phase)) {
          ForEach([this.videoKey()], (key: string) => {
          Video({ src: this.frame.content.uri !== '' ? this.frame.content.uri : $rawfile('fallback.mp4'), controller: this.controller }).width('100%').height('100%')
            .objectFit(ImageFit.Contain).controls(false).autoPlay(false).loop(true).muted(true)
            .onPrepared(() => this.prepared()).onError(() => this.videoFailed())
            .onStart(() => { this.mediaState = 'PLAYING'; })
            .onPause(() => { this.mediaState = 'PAUSED'; })
          }, (key: string) => key)
          Text(this.frame.content.uri === '' ? 'CompanionOS Built-in • Fallback video' : contentLabel(this.frame.content.sourceType))
            .fontSize(16).fontColor('#FFFFFF').padding(12).backgroundColor('#B0101D26').position({ x: 12, y: 12 })
        } else {
          Column({ space: 20 }) {
            Text(this.frame.phase === 'completed' ? '★ Wonderful moments together ★' :
              this.frame.phase === 'ready' ? '★ Great play! ★' : this.frame.phase === 'idle' || this.frame.phase === 'cancelled' ?
                'Waiting for phone...' : this.frame.visual).fontSize(52).fontWeight(FontWeight.Bold).fontColor('#203C31')
            Text(this.frame.phase === 'completed' ? 'Your parent saved this shared moment.' :
              this.frame.phase === 'ready' ? 'Ask your parent to confirm on the phone.' :
                'Safe local visual • No AI video available').fontSize(25).fontColor('#36584A')
            Text('An adult stays beside you. Take breaks whenever you need.').fontSize(23).fontColor('#36584A')
          }.width('100%').height('100%').justifyContent(FlexAlign.Center).padding(32).backgroundColor('#DDEEE3')
        }
        if (this.frame.phase === 'paused' || this.connection === 'DISCONNECTED') {
          Text(this.connection === 'DISCONNECTED' ? 'Connection lost' : 'Paused — rest together')
            .fontSize(30).fontColor(Color.White).padding(24).backgroundColor('#B0101D26').borderRadius(20)
        }
        if (this.mediaState === 'BUFFERING' && ['running', 'paused'].includes(this.frame.phase)) {
          Text('Preparing video...').fontSize(24).fontColor(Color.White).padding(20).backgroundColor('#B0101D26')
        }
      }.layoutWeight(1).width('100%').borderRadius(24).clip(true)
      Text(this.frame.phase === 'idle' || this.frame.phase === 'cancelled' ? 'Choose and start an adventure on your phone.' :
        this.frame.instruction).fontSize(30).fontWeight(FontWeight.Medium).fontColor('#FFFFFF').textAlign(TextAlign.Center)
        .maxLines(2).width('100%')
      Row({ space: 20 }) {
        Text(`Step ${this.frame.stepIndex + 1} / ${this.frame.totalSteps}`).fontSize(20).fontColor('#D9EFE3')
        Progress({ value: this.frame.phase === 'completed' ? this.frame.totalSteps : this.frame.stepIndex + 1,
          total: this.frame.totalSteps, type: ProgressType.Linear }).layoutWeight(1).color('#A6DEC0')
        Text(this.stateLabel()).fontSize(18).fontColor('#D9EFE3')
        if (['running', 'paused'].includes(this.frame.phase)) { Text(`Video: ${this.mediaState}`).fontSize(16).fontColor('#B3C7BB') }
        Text(`${Math.floor(this.frame.remaining / 60)}:${(this.frame.remaining % 60).toString().padStart(2, '0')}`)
          .fontSize(16).fontColor('#B3C7BB')
      }.width('100%')
      if (this.frame.phase === 'idle' || this.connection === 'OFFLINE' || this.connection === 'ERROR') {
        Row({ space: 12 }) {
          TextInput({ text: this.endpoint, placeholder: 'Backend URL' }).layoutWeight(2).onChange((value: string) => { this.endpoint = value; })
          TextInput({ text: this.room, placeholder: 'Room' }).layoutWeight(1).onChange((value: string) => { this.room = value; })
          Button('Connect').onClick(() => this.connect())
        }.width('100%')
      }
    }.width('100%').height('100%').padding({ left: 40, right: 40, top: 28, bottom: 28 }).backgroundColor('#101D26')
  }
}
