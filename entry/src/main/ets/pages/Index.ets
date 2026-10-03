import { common } from '@kit.AbilityKit';
import { ACTIVITIES, Activity, ActivitySession, Completion, ParentSettings, Snapshot,
  addCompletion, countToday, validSettings } from '../model/Companion';
import { LocalStore } from '../services/LocalStore';
import { Notifications } from '../services/Notifications';
import { AiService } from '../services/AiService';
import { Widgets } from '../services/Widgets';
import { window } from '@kit.ArkUI';
import { ActivityPlanRequest, MockAiActivityService, TV_CATEGORIES, TV_TITLES, activityFromPlan } from '../services/AiActivityService';
import { LocalDemoTvTransport, TvSessionTransport, TvFrame } from '../services/TvSessionTransport';
import { NearbyTv } from '../services/NearbyTv';
import { EmulatorTvTransport } from '../services/EmulatorTvTransport';
import { BackendActivityService, backendActivity } from '../services/BackendActivityService';
import { ActivityContentSource, VideoSource, contentLabel, EMULATOR_RELAY_ENDPOINT, connectionError } from '@companion/protocol';
import { UserVideo, UserVideoStore } from '../services/UserVideoStore';

@Entry
@Component
struct Index {
  @State selectedProvider: string = 'GEMINI';
  @State userVideo: UserVideo | undefined = undefined;
  @State videoTitle: string = 'My family video';
  @State importingVideo: boolean = false;
  private videos: UserVideoStore | undefined = undefined;
  private phoneVideoController: VideoController = new VideoController();
  @State backendUrl: string = EMULATOR_RELAY_ENDPOINT;
  @State roomCode: string = 'family-demo';
  @State transportMode: string = 'demo';
  @State generationCategory: string = 'MOVE';
  @State learningGoal: string = 'Count five gentle movements together';
  @State generationProgress: string = '';
  @State activitySource: string = 'Offline activity';
  @State backendLoading: boolean = false;
  private generationToken: number = 0;
  private videoPollPending: boolean = false;
  private videoPollAt: number = 0;
  private activeJobId: string = '';
  private activeJobEndpoint: string = '';
  private activeRequest: ActivityPlanRequest = new ActivityPlanRequest();
  private stepBoundary: number = 0;
  @State tvConnection: string = 'Not connected';
  @State nearby: string = 'Search for authorized HarmonyOS devices.';
  @State tvFrame: TvFrame = new TvFrame();
  @State stepIndex: number = 0;
  @State planLoading: boolean = false;
  private transport: TvSessionTransport | undefined = undefined;
  private previousOrientation: window.Orientation = window.Orientation.UNSPECIFIED;
  @State screen: string = 'home';
  @State data: Snapshot = new Snapshot();
  @State draft: ParentSettings = new ParentSettings();
  @State selected: Activity = ACTIVITIES[0];
  @State phase: string = 'idle';
  @State remaining: number = 0;
  @State demo: boolean = false;
  @State confirmed: boolean = false;
  @State busy: boolean = false;
  @State storageReady: boolean = false;
  @State notice: string = '';
  @State today: number = 0;
  @State aiLoading: boolean = false;
  @State recommendation: string = '';
  @State recommendationId: string = '';
  @State notificationStatus: string = 'Optional: enable a system notification when a foreground activity ends.';
  @StorageLink('appForeground') @Watch('foregroundChanged') foreground: boolean = true;
  private session: ActivitySession = new ActivitySession();
  private store: LocalStore | undefined = undefined;
  private timer: number = -1;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.store = new LocalStore(context);
      this.videos = new UserVideoStore(context); this.userVideo = this.videos.load();
      this.data = this.store.load();
      this.storageReady = true;
      Widgets.update(context, this.data);
      if (this.store.recovered) { this.notice = 'Some local data was unreadable. Safe defaults have been restored.'; }
    } catch {
      this.notice = 'Local storage is unavailable. You can explore activities, but saving is disabled. Reopen the app to retry.';
    }
    this.updateClock();
    this.startTimer();
  }

  aboutToDisappear(): void { clearInterval(this.timer); this.generationToken++; this.transport?.disconnect(); }
  onPageShow(): void { this.foregroundChanged(); }
  onPageHide(): void { clearInterval(this.timer); }

  private startTimer(): void {
    clearInterval(this.timer);
    if (this.foreground) { this.timer = setInterval(() => { this.updateClock(); }, 500); }
  }

  private foregroundChanged(): void {
    clearInterval(this.timer);
    if (this.foreground) {
      this.session.resume(Date.now());
      this.phase = this.session.phase;
      this.updateClock();
      this.startTimer();
      if (this.phase === 'running') { try { this.phoneVideoController.start(); } catch {} }
    } else { try { this.phoneVideoController.pause(); } catch {} }
  }

  private updateClock(): void {
    this.today = countToday(this.data, Date.now());
    if (this.session.tick(Date.now(), this.foreground)) {
      try { this.phoneVideoController.pause(); } catch {}
      this.notice = 'Time is up. Parent / caregiver: confirm when you have finished together.';
      this.publishEndNotification();
    }
    this.phase = this.session.phase;
    this.remaining = this.session.remaining(Date.now());
    if (this.phase === 'running' && this.remaining <= this.stepBoundary && this.stepIndex < this.selected.activitySteps.length - 1) {
      this.stepIndex++; this.stepBoundary -= this.stepSeconds(); this.transport?.nextStep(this.frame());
    }
    if (this.activeJobId !== '' && Date.now() >= this.videoPollAt) { this.refreshVideos(); }
    this.syncTv();
  }

  private frame(): TvFrame {
    const frame = new TvFrame();
    frame.sessionId = this.session.id;
    frame.activityId = this.selected.id;
    frame.title = this.selected.title;
    frame.phase = this.session.phase;
    frame.remaining = this.session.remaining(Date.now());
    frame.steps = this.selected.activitySteps.length;
    frame.step = this.stepIndex;
    const step = this.selected.activitySteps[this.stepIndex];
    frame.instruction = step ? step.instruction : 'Play gently together.';
    frame.visual = step ? step.fallbackVisual : this.selected.theme;
    frame.videoUrl = step ? step.videoUrl : '';
    frame.videoSource = frame.videoUrl === '' ? 'FALLBACK' : 'REMOTE_CACHED';
    const content = new VideoSource(); content.sourceType = this.selected.contentSource;
    content.uri = frame.videoUrl; content.title = this.selected.title; content.activityId = this.selected.id;
    content.provider = this.selected.aiProvider; frame.content = content;
    return frame;
  }

  private syncTv(): void { this.transport?.synchronize(this.frame()); }

  private async connectDemoTv(): Promise<void> {
    if (this.tvConnection === 'Connecting') { return; }
    this.tvConnection = 'Connecting';
    this.transport?.disconnect();
    this.transportMode = 'demo';
    this.transport = new LocalDemoTvTransport((event: string, frame: TvFrame) => {
      if (event === 'connected') { this.tvConnection = 'Connected'; }
      else if (event === 'disconnected') { this.tvConnection = 'Disconnected'; }
      else if (event === 'error') { this.notice = 'TV unavailable. Continue on your phone.'; }
      else { this.tvFrame = frame; }
    });
    await this.transport.connect();
    this.syncTv();
    this.notice = 'Demo TV connected locally. No real TV connection.';
  }

  private async connectEmulatorTv(): Promise<void> {
    if (this.tvConnection === 'Connecting') { return; }
    this.transport?.disconnect(); this.transport = undefined;
    this.tvConnection = 'Connecting'; this.transportMode = 'emulator';
    const transport = new EmulatorTvTransport(this.backendUrl.trim(), this.roomCode.trim(), (event: string) => {
      if (event === 'connected') { this.tvConnection = 'Connected'; }
      else if (event === 'disconnected') { this.tvConnection = 'Disconnected'; }
      else if (event === 'videoFallback') { this.notice = 'TV video unavailable. Safe fallback visual is playing.'; }
    });
    try {
      await transport.connect(); this.transport = transport; this.syncTv();
      this.notice = 'Connected to Emulator TV. Your phone controls the separate TV application.';
    } catch (error) {
      this.tvConnection = 'Disconnected';
      this.notice = `Connection failed: ${connectionError(error as Error)}. Check the Windows relay and matching room.`;
      console.error(`[CompanionPhoneTV] endpoint=${this.backendUrl} room=${this.roomCode} ${this.notice}`);
    }
  }

  private async createAdventure(provider: string = 'GEMINI'): Promise<void> {
    if (this.backendLoading || ['running', 'paused', 'ready'].includes(this.phase)) {
      this.notice = 'Finish or cancel your current activity before creating another.'; return;
    }
    this.backendLoading = true; this.generationProgress = 'Creating your adventure... Planning activity...';
    const token = ++this.generationToken;
    const request = new ActivityPlanRequest(); request.childAge = this.data.settings.age;
    request.interest = this.data.settings.interests[0]; request.category = this.generationCategory;
    request.durationMinutes = this.data.settings.minutes; request.educationalGoal = this.learningGoal.trim();
    const endpoint = this.backendUrl.trim();
    try {
      const job = await BackendActivityService.create(endpoint, request, this.data.settings.interests,
        (message: string) => { if (token === this.generationToken) { this.generationProgress = message; } },
        () => token === this.generationToken, provider);
      if (token !== this.generationToken) { return; }
      const activity = backendActivity(job, request, endpoint); this.openActivity(activity);
      this.activitySource = job.source === 'ai' ? `${contentLabel(activity.contentSource)} • Video availability shown separately` : 'CompanionOS Built-in • Offline activity';
      this.notice = job.source === 'ai' ? job.message : `${provider} unavailable. Use Built-in Video or try ${provider === 'GEMINI' ? 'Huawei AI' : 'Gemini AI'}.`;
      this.activeJobId = job.source === 'ai' ? job.id : '';
      this.activeRequest = request; this.activeJobEndpoint = endpoint;
    } catch {
      if (token === this.generationToken) {
        await this.generatePlan(request.category);
        this.notice = `${provider} unavailable, timed out or invalid. Built-in content is ready. Try ${provider === 'GEMINI' ? 'Huawei AI' : 'Gemini AI'} or Built-in Video.`;
      }
    } finally { if (token === this.generationToken) { this.backendLoading = false; } }
  }

  private async refreshVideos(): Promise<void> {
    if (this.videoPollPending) { return; }
    this.videoPollPending = true; this.videoPollAt = Date.now() + 3000;
    const id = this.activeJobId;
    try {
      const job = await BackendActivityService.status(this.activeJobEndpoint, id);
      const updated = backendActivity(job, this.activeRequest, this.activeJobEndpoint);
      if (this.activeJobId === id && this.selected.id === id) {
        this.selected = updated; this.syncTv();
        if (job.state === 'FAILED') { this.activeJobId = ''; }
      }
    } catch { /* Keep the validated plan and local fallback while network is unavailable. */ }
    finally { this.videoPollPending = false; }
  }

  private disconnectTv(): void {
    this.transport?.disconnect(); this.transport = undefined;
    this.notice = 'TV disconnected. Your phone activity and saved history are safe.';
    if (this.screen === 'tv') { this.leaveTv(); }
  }

  private async searchTv(): Promise<void> {
    this.tvConnection = 'Searching';
    // Yield a frame so the searching status is visible before the synchronous SDK query.
    await new Promise<void>((resolve: () => void) => { setTimeout(resolve, 100); });
    this.nearby = await NearbyTv.search(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.tvConnection = this.transport ? 'Connected' : 'Not connected';
  }

  private async generatePlan(category: string): Promise<void> {
    if (this.planLoading) { return; }
    this.planLoading = true;
    try {
      const request = new ActivityPlanRequest();
      request.childAge = this.data.settings.age;
      request.interest = this.data.settings.interests[0];
      request.category = category;
      request.durationMinutes = this.data.settings.minutes;
      request.educationalGoal = category === 'LEARN' ? 'Count five objects together' : 'Practice gentle turn taking';
      const plan = await new MockAiActivityService().generateActivityPlan(request);
      this.openActivity(activityFromPlan(plan, request));
      this.notice = 'Mock activity plan — deterministic local content, not real AI output.';
    } catch { this.notice = 'Plan unavailable. The original offline activities remain ready.'; }
    finally { this.planLoading = false; }
  }

  private pauseActivity(): void {
    try { this.phoneVideoController.pause(); } catch { /* No attached video. */ }
    this.session.pause(Date.now()); this.updateClock(); this.transport?.pauseActivity(this.frame());
  }

  private resumeActivity(): void {
    try { this.phoneVideoController.start(); } catch { /* No attached video. */ }
    this.session.continueActivity(Date.now()); this.updateClock(); this.transport?.resumeActivity(this.frame());
  }

  private nextStep(): void {
    if (!['running', 'paused'].includes(this.phase)) { return; }
    this.stepIndex = Math.min(this.stepIndex + 1, this.selected.activitySteps.length - 1);
    this.stepBoundary = this.remaining - this.stepSeconds();
    this.transport?.nextStep(this.frame());
  }

  private previousStep(): void {
    if (!['running', 'paused'].includes(this.phase)) { return; }
    this.stepIndex = Math.max(0, this.stepIndex - 1); this.stepBoundary = this.remaining - this.stepSeconds();
    this.transport?.previousStep(this.frame());
  }

  private stepSeconds(): number {
    const sum = this.selected.activitySteps.reduce((total: number, step) => total + step.durationSeconds, 0);
    return (this.session.demo ? 10 : this.session.minutes * 60) * this.selected.activitySteps[this.stepIndex].durationSeconds / sum;
  }

  private async showTv(): Promise<void> {
    if (this.tvConnection !== 'Connected') { this.navigate('connect'); return; }
    this.syncTv();
    if (this.transportMode === 'emulator') {
      this.notice = 'Play on the separate TV. Start, pause and change steps on this phone.'; return;
    }
    try {
      const appWindow = await window.getLastWindow(this.getUIContext().getHostContext() as common.UIAbilityContext);
      this.previousOrientation = appWindow.getPreferredOrientation();
      await appWindow.setPreferredOrientation(window.Orientation.LANDSCAPE);
    } catch { this.notice = 'Landscape orientation unavailable; the local player still works.'; }
    this.navigate('tv');
  }

  private leaveTv(): void {
    this.navigate('activity');
    window.getLastWindow(this.getUIContext().getHostContext() as common.UIAbilityContext)
      .then((appWindow: window.Window) => appWindow.setPreferredOrientation(this.previousOrientation)).catch(() => {});
  }

  private async publishEndNotification(): Promise<void> {
    const id = this.session.id;
    const status = await Notifications.publish(this.selected.title, () =>
      this.foreground && this.session.id === id && this.session.phase === 'ready');
    if (this.session.id === id && this.session.phase === 'ready' && status !== '') { this.notice = status; }
  }

  private async enableNotifications(): Promise<void> {
    if (this.busy) { return; }
    this.busy = true;
    this.notificationStatus = await Notifications.enable(this.getUIContext().getHostContext() as common.UIAbilityContext);
    this.busy = false;
  }

  private async recommendActivity(): Promise<void> {
    if (this.aiLoading) { return; }
    this.aiLoading = true;
    const settings = this.data.settings;
    try {
      const result = await AiService.recommend(settings);
      if (this.data.settings === settings) {
        const activity = ACTIVITIES.find((item: Activity) => item.id === result.activityId);
        this.recommendation = `${result.message}\n${activity ? activity.title : 'Penguin Walk'}`;
        this.recommendationId = result.activityId;
      }
    } catch {
      this.recommendation = 'AI service unavailable. All offline activities remain ready.';
    } finally { this.aiLoading = false; }
  }

  private navigate(screen: string): void {
    this.screen = screen;
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }

  private openActivity(activity: Activity): void {
    if (['running', 'paused', 'ready'].includes(this.phase)) { this.notice = 'Finish or cancel the current activity first.'; return; }
    this.selected = activity;
    this.activeJobId = '';
    this.activitySource = activity.id.startsWith('tv-') ? 'Mock plan • Not real AI output' : 'Offline activity';
    this.session = new ActivitySession();
    this.phase = 'idle';
    this.confirmed = false;
    this.demo = false;
    this.stepIndex = 0;
    if (this.storageReady) { this.notice = ''; }
    this.navigate('activity');
  }

  private chooseBuiltIn(): void {
    if (this.backendLoading || this.importingVideo || ['running', 'paused', 'ready'].includes(this.phase)) { return; }
    const original = ACTIVITIES.find((item: Activity) => item.id === this.selected.id) || ACTIVITIES[0];
    this.openActivity(original); this.activitySource = 'CompanionOS Built-in • Offline activity';
    this.notice = 'Original content is ready. No AI request was made.';
  }

  private async importVideo(): Promise<void> {
    if (!this.videos || this.importingVideo || this.backendLoading) { return; }
    this.importingVideo = true;
    try {
      const value = await this.videos.pick(this.videoTitle);
      if (value) { this.userVideo = value; this.notice = 'Video saved on this phone. Review it before playing with your child.'; }
      else { this.notice = 'No video selected. Built-in Video remains ready.'; }
    } catch { this.notice = 'Import failed. Choose a readable MP4 up to 40 MiB, or use Built-in Video.'; }
    finally { this.importingVideo = false; }
  }

  private async useMyVideo(): Promise<void> {
    if (!this.videos || this.importingVideo || this.backendLoading || ['running', 'paused', 'ready'].includes(this.phase)) { return; }
    const value = this.videos.load();
    if (!value) { this.userVideo = undefined; this.notice = 'Saved video is missing. Import a video or choose Built-in Video.'; return; }
    this.importingVideo = true;
    try {
      // The TV cannot read a phone-private file. Cache this explicitly selected video through the same relay.
      let url: string = '';
      try { url = await this.videos.publish(value, this.backendUrl.trim()); }
      catch { /* Private phone copy remains available offline; TV uses its labelled fallback. */ }
      const activity = new Activity('user-video', value.title, this.data.settings.interests[0], ACTIVITIES[0].steps);
      activity.contentSource = ActivityContentSource.USER_VIDEO; activity.localVideoPath = value.path; activity.videoUrl = url;
      activity.activitySteps.forEach((step) => { step.videoUrl = url; });
      this.openActivity(activity); this.activitySource = 'My Video';
      this.notice = `My Video • ${Math.ceil(value.durationSeconds)} seconds • Not AI generated. Plays muted and loops during the activity.${url === '' ? ' Offline phone video; TV uses Built-in fallback until the backend is available.' : ''}`;
    } catch { this.notice = 'Saved video could not be sent to the player. Start the local backend, retry, or choose Built-in Video.'; }
    finally { this.importingVideo = false; }
  }

  private startActivity(): void {
    if (this.busy || this.backendLoading || this.importingVideo || this.phase === 'running' || this.phase === 'paused' || this.phase === 'ready') { return; }
    if (this.selected.contentSource === ActivityContentSource.USER_VIDEO && !this.videos?.load()) {
      this.notice = 'Saved video is missing. Import a video or choose Built-in Video.'; return;
    }
    this.session.contentSource = this.selected.contentSource; this.session.videoUrl = this.selected.videoUrl;
    this.session.localVideoPath = this.selected.localVideoPath; this.session.aiProvider = this.selected.aiProvider;
    this.session.aiGenerationId = this.selected.aiGenerationId;
    this.session.start(Date.now(), this.data.settings.minutes, this.demo);
    this.stepIndex = 0; this.stepBoundary = (this.demo ? 10 : this.session.minutes * 60) - this.stepSeconds();
    this.confirmed = false;
    this.notice = '';
    this.updateClock();
    this.transport?.startActivity(this.selected, this.frame());
  }

  private cancelActivity(): void {
    if (this.busy) { return; }
    if (this.phase === 'running' || this.phase === 'paused' || this.phase === 'ready') {
      this.getUIContext().showAlertDialog({
        title: 'Cancel this activity?',
        message: 'No completion will be recorded.',
        primaryButton: { value: 'Keep playing', action: () => {} },
        secondaryButton: { value: 'Cancel activity', action: () => {
          this.session.cancel(); this.phase = 'cancelled'; this.confirmed = false;
          this.activeJobId = '';
          this.transport?.cancelActivity(this.frame());
          this.notice = 'Activity cancelled. No completion was recorded.';
          this.navigate('home');
        } }
      });
    } else { this.navigate('home'); }
  }

  onBackPress(): boolean {
    if (this.screen === 'home') { return false; }
    if (this.backendLoading) { this.generationToken++; this.backendLoading = false; this.generationProgress = 'Generation view cancelled. Backend jobs may continue.'; }
    if (this.screen === 'tv') { this.leaveTv(); }
    else if (this.screen === 'activity') { this.cancelActivity(); }
    else if (!this.busy) { this.navigate('home'); }
    return true;
  }

  private async completeActivity(): Promise<void> {
    if (this.busy || !this.store || !this.storageReady || this.phase !== 'ready' || !this.confirmed) { return; }
    this.busy = true;
    const record = new Completion();
    record.id = this.session.id;
    record.activityId = this.selected.id;
    record.title = this.selected.title;
    record.completedAt = Date.now();
    record.minutes = this.session.minutes;
    record.demo = this.session.demo;
    record.contentSource = this.session.contentSource;
    const updated = addCompletion(this.data, record);
    try {
      await this.store.save(updated);
      this.data = updated;
      this.session.phase = 'completed';
      this.activeJobId = '';
      Widgets.update(this.getUIContext().getHostContext() as common.UIAbilityContext, updated);
      this.phase = 'completed';
      this.syncTv();
      this.confirmed = false;
      this.today = countToday(updated, Date.now());
      this.notice = `${record.title} completed. Well done, together!`;
      this.navigate('progress');
    } catch {
      this.notice = 'Saving failed. Your activity is ready to confirm again.';
    } finally { this.busy = false; }
  }

  private openSettings(): void {
    const settings = new ParentSettings();
    settings.age = this.data.settings.age;
    settings.interests = this.data.settings.interests.slice();
    settings.minutes = this.data.settings.minutes;
    settings.aiEndpoint = this.data.settings.aiEndpoint;
    this.draft = settings;
    this.navigate('settings');
  }

  private async saveSettings(): Promise<void> {
    if (this.busy || !this.store || !this.storageReady) { return; }
    if (!validSettings(this.draft)) { this.notice = 'Choose at least one interest and a valid HTTPS service URL, or leave the URL empty.'; return; }
    this.busy = true;
    const updated = new Snapshot();
    updated.settings = this.draft;
    updated.records = this.data.records;
    updated.total = this.data.total;
    updated.countDay = this.data.countDay;
    updated.todayCount = this.data.todayCount;
    try {
      await this.store.save(updated);
      this.data = updated;
      this.notice = 'Parent settings saved on this device.';
      Widgets.update(this.getUIContext().getHostContext() as common.UIAbilityContext, updated);
      this.recommendation = '';
      this.recommendationId = '';
      this.navigate('home');
    } catch { this.notice = 'Settings could not be saved. Please try again.'; }
    finally { this.busy = false; }
  }

  private toggleInterest(interest: string): void {
    this.draft.interests = this.draft.interests.includes(interest) ?
      this.draft.interests.filter((item: string) => item !== interest) : [...this.draft.interests, interest];
  }

  private clockLabel(): string {
    return `${Math.floor(this.remaining / 60).toString().padStart(2, '0')}:${(this.remaining % 60).toString().padStart(2, '0')}`;
  }

  private dateLabel(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')} ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  @Builder
  heading(title: string) {
    Text(title).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
  }

  @Builder
  homeContent() {
    Column({ space: 16 }) {
      this.heading('Small activities. Meaningful family moments.')
      Text(`Completed today: ${this.today}`).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#28745E')
        .padding(20).width('100%').backgroundColor('#E0EEE5').borderRadius(20)
      Text(`Ages ${this.data.settings.age} • ${this.data.settings.minutes} minutes • Adult accompanied`)
        .fontSize(15).fontColor('#52645C').width('100%')
      Text(this.data.settings.aiEndpoint === '' ? 'AI service: not configured. All three activities work offline.' :
        'AI service: configured, connection not yet verified. Offline activities stay available.')
        .fontSize(14).fontColor('#52645C').width('100%')
      Button(this.aiLoading ? 'Finding an activity...' : 'Recommend an activity').width('100%')
        .backgroundColor('#E0EEE5').fontColor('#203C31').enabled(!this.aiLoading)
        .onClick(() => { this.recommendActivity(); })
      if (this.recommendation !== '') {
        Text(this.recommendation).fontSize(16).fontColor('#28745E').width('100%')
      }
      ForEach(ACTIVITIES, (activity: Activity) => {
        Column({ space: 10 }) {
          Text('Offline activity').fontSize(13).fontColor('#28745E').width('100%')
          Text(activity.title).fontSize(23).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
          Text(activity.interest).fontSize(15).fontColor('#52645C').width('100%')
          if (this.recommendationId === activity.id) {
            Text('Recommended activity').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#28745E').width('100%')
          }
          if (this.data.settings.interests.includes(activity.interest)) {
            Text('Matches your interests').fontSize(13).fontColor('#28745E').width('100%')
          }
          Button('Explore activity').width('100%').backgroundColor('#28745E').fontColor(Color.White)
            .onClick(() => this.openActivity(activity))
        }.padding(20).width('100%').backgroundColor(Color.White).borderRadius(20)
      }, (activity: Activity) => activity.id)
      Button('Parent settings').width('100%').backgroundColor('#E0EEE5').fontColor('#203C31').onClick(() => this.openSettings())
      Button('Progress').width('100%').backgroundColor('#E0EEE5').fontColor('#203C31').onClick(() => this.navigate('progress'))
      Button('Play on TV').width('100%').backgroundColor('#28745E').fontColor(Color.White).onClick(() => this.navigate('connect'))
    }.width('100%')
  }

  @Builder
  settingsContent() {
    Column({ space: 16 }) {
      this.heading('Parent settings')
      Text('Stored only on this device. Changes apply to your next activity.').fontSize(16).fontColor('#52645C')
      Text('Age group').fontSize(20).fontColor('#203C31').width('100%')
      Row({ space: 12 }) {
        ForEach(['4–5', '6–8'], (age: string) => {
          Button(age).layoutWeight(1).backgroundColor(this.draft.age === age ? '#28745E' : '#E0EEE5')
            .fontColor(this.draft.age === age ? Color.White : '#203C31').onClick(() => { this.draft.age = age; })
        })
      }.width('100%')
      Text('Interests (choose at least one)').fontSize(20).fontColor('#203C31').width('100%')
      ForEach(['Movement', 'Sounds', 'Nature'], (interest: string) => {
        Button(`${this.draft.interests.includes(interest) ? '✓ ' : ''}${interest}`).width('100%')
          .backgroundColor(this.draft.interests.includes(interest) ? '#28745E' : '#E0EEE5')
          .fontColor(this.draft.interests.includes(interest) ? Color.White : '#203C31')
          .onClick(() => this.toggleInterest(interest))
      })
      Text('Activity duration').fontSize(20).fontColor('#203C31').width('100%')
      Row({ space: 12 }) {
        ForEach([3, 5, 10], (minutes: number) => {
          Button(`${minutes} min`).layoutWeight(1).backgroundColor(this.draft.minutes === minutes ? '#28745E' : '#E0EEE5')
            .fontColor(this.draft.minutes === minutes ? Color.White : '#203C31').onClick(() => { this.draft.minutes = minutes; })
        })
      }.width('100%')
      Text('Optional AI service (parent only)').fontSize(20).fontColor('#203C31').width('100%')
      Text('Leave empty for offline mode. Enter a trusted HTTPS recommendation endpoint. Never enter an API key here. Only age group, interests and duration are sent when you request a recommendation.')
        .fontSize(14).fontColor('#52645C').width('100%')
      TextInput({ text: this.draft.aiEndpoint, placeholder: 'https://your-service/recommend' })
        .maxLength(200).onChange((value: string) => { this.draft.aiEndpoint = value.trim(); })
      Text(this.notificationStatus).fontSize(15).fontColor('#52645C').width('100%')
      Button('Enable notifications').width('100%').backgroundColor('#E0EEE5').fontColor('#203C31')
        .enabled(!this.busy).onClick(() => { this.enableNotifications(); })
      Button(this.busy ? 'Saving...' : 'Save settings').width('100%').backgroundColor('#28745E').fontColor(Color.White)
        .enabled(this.storageReady && !this.busy).onClick(() => { this.saveSettings(); })
    }.width('100%').enabled(!this.busy)
  }

  @Builder
  activityContent() {
    Column({ space: 16 }) {
      Text(this.selected.title).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      if (this.selected.id.startsWith('tv-')) {
        Text(`${this.selected.category} • Mock plan • ${this.selected.theme}`).fontSize(16).fontColor('#28745E')
      }
      Text(`TV: ${this.tvConnection}`).fontSize(16).fontColor('#52645C')
      Button('Play on TV').width('100%').onClick(() => { this.showTv(); })
      Text(this.activitySource).fontSize(14).fontColor('#28745E').width('100%')
      Text(`Suitable for ages 4–5 and 6–8 • Your age group: ${this.data.settings.age}`)
        .fontSize(16).fontColor('#52645C').width('100%')
      Text(`${this.data.settings.minutes} minutes • Parent / caregiver must stay with the child.`)
        .fontSize(16).fontColor('#52645C').width('100%')
      Text(this.data.settings.age === '6–8' ? 'Take turns leading and invent a new move or sound.' :
        'Parent leads first. Use simple turns and gentle movements.').fontSize(16).fontColor('#203C31').width('100%')
      ForEach(this.selected.steps, (step: string, index: number) => {
        Text(`${index + 1}. ${step}`).fontSize(17).fontColor('#203C31').padding(16)
          .width('100%').backgroundColor(Color.White).borderRadius(14)
      }, (step: string) => step)
      if (this.phase === 'idle' || this.phase === 'cancelled' || this.phase === 'completed') {
        this.contentChoices()
        Row({ space: 8 }) {
          Checkbox({ name: 'demoMode' }).select(this.demo).selectedColor('#28745E')
            .onChange((value: boolean) => { this.demo = value; })
          Text('Demo Mode — 10-second countdown').fontSize(16).fontColor('#203C31').layoutWeight(1)
        }
        Text('Normal mode uses your selected duration. Demo completions are labelled in Progress.')
          .fontSize(14).fontColor('#52645C').width('100%')
        Button('Start activity').width('100%').backgroundColor('#28745E').fontColor(Color.White)
          .enabled(!this.backendLoading && !this.importingVideo)
          .onClick(() => this.startActivity())
      } else {
        if (this.selected.contentSource === ActivityContentSource.USER_VIDEO) {
          Video({ src: `file://${this.selected.localVideoPath}`, controller: this.phoneVideoController })
            .width('100%').height(180).controls(false).autoPlay(false).loop(true).muted(true)
            .onPrepared(() => {
              if (this.phase === 'running') { try { this.phoneVideoController.start(); } catch {} }
            }).onDisAppear(() => { try { this.phoneVideoController.pause(); } catch {} })
            .onError(() => { this.notice = 'My Video cannot play. Cancel and choose Built-in Video.'; })
        }
        Text('Put the screen down and play together.').fontSize(25).fontWeight(FontWeight.Bold)
          .fontColor('#28745E').width('100%')
        Text(this.session.demo ? 'DEMO MODE • 10 seconds' : `NORMAL MODE • ${this.session.minutes} minutes`)
          .fontSize(14).fontColor('#52645C').width('100%')
        Text(this.phase === 'ready' ? 'Time is up!' : this.clockLabel()).fontSize(42).fontWeight(FontWeight.Bold).fontColor('#203C31')
        if (this.phase === 'running') { Button('Pause activity').onClick(() => this.pauseActivity()) }
        if (this.phase === 'paused') {
          Text('Paused — take a comfortable break.').fontSize(22).fontColor('#28745E')
          Button('Resume activity').onClick(() => this.resumeActivity())
        }
        Text(`Step ${this.stepIndex + 1} / ${this.selected.activitySteps.length}`).fontSize(20)
        Text(this.selected.steps[this.stepIndex]).fontSize(18)
        Button('Next step').enabled(this.phase !== 'ready' && this.stepIndex < this.selected.activitySteps.length - 1)
          .onClick(() => this.nextStep())
        Button('Previous step').enabled(this.phase !== 'ready' && this.stepIndex > 0).onClick(() => this.previousStep())
        if (this.tvConnection === 'Connected') { Button('Disconnect TV').onClick(() => this.disconnectTv()) }
        Text('If you leave the app, the deadline is checked when you return. Background reminders are not guaranteed.')
          .fontSize(14).fontColor('#52645C').width('100%')
        if (this.phase === 'ready') {
          Row({ space: 8 }) {
            Checkbox({ name: 'confirmParent' }).select(this.confirmed).selectedColor('#28745E').enabled(!this.busy)
              .onChange((value: boolean) => { this.confirmed = value; })
            Text('I am the parent / caregiver. We completed this activity together.').fontSize(16).fontColor('#203C31').layoutWeight(1)
          }
          Button(this.busy ? 'Saving...' : 'Mark as completed').width('100%').backgroundColor('#28745E').fontColor(Color.White)
            .enabled(this.confirmed && !this.busy && this.storageReady).onClick(() => { this.completeActivity(); })
        }
        Button('Cancel activity').width('100%').backgroundColor('#E0EEE5').fontColor('#203C31')
          .enabled(!this.busy).onClick(() => this.cancelActivity())
      }
    }.width('100%')
  }

  @Builder
  contentChoices() {
    Column({ space: 10 }) {
      Text('Choose Activity Content').fontSize(23).fontWeight(FontWeight.Bold).width('100%')
      Button('Gemini AI').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => { this.createAdventure('GEMINI'); })
      Text('Create a personalized activity with Gemini').fontSize(14).width('100%')
      Button('Huawei AI').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => { this.createAdventure('HUAWEI'); })
      Text('Create a personalized activity with Huawei Cloud AI').fontSize(14).width('100%')
      Button('Built-in Video').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => this.chooseBuiltIn())
      Text('Use original CompanionOS content').fontSize(14).width('100%')
      Button('My Video').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => { this.useMyVideo(); })
      Text('Use my own saved/imported video').fontSize(14).width('100%')
      TextInput({ text: this.videoTitle, placeholder: 'Video title' }).maxLength(80)
        .onChange((value: string) => { this.videoTitle = value; })
      Button(this.importingVideo ? 'Working with video...' : 'Import video').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => { this.importVideo(); })
      if (this.userVideo) { Text(`Saved: ${this.userVideo.title} • ${Math.ceil(this.userVideo.durationSeconds)} seconds`).fontSize(15) }
      Text('Choose a family-friendly MP4 up to 40 MiB. An adult reviews imported and generated videos.').fontSize(14)
      if (this.backendLoading) { Text(this.generationProgress).fontSize(17) }
    }.width('100%').padding(16).backgroundColor('#E0EEE5').borderRadius(16)
  }

  @Builder
  connectionContent() {
    Column({ space: 16 }) {
      this.heading('Connect to TV')
      Text(`Connection: ${this.tvConnection}`).fontSize(22).fontColor('#28745E')
      Text('Nearby devices').fontSize(22).fontWeight(FontWeight.Bold)
      Text(this.nearby).fontSize(16)
      Button('Search nearby devices').enabled(this.tvConnection !== 'Searching').onClick(() => { this.searchTv(); })
      Text('Real TV requires a compatible distributed receiver. Local Demo works without TV hardware or network.').fontSize(16)
      Button('Demo TV Mode').enabled(this.tvConnection !== 'Connecting').onClick(() => { this.connectDemoTv(); })
      Text('Emulator TV + AI backend').fontSize(22).fontWeight(FontWeight.Bold)
      TextInput({ text: this.backendUrl, placeholder: 'Backend base URL' }).onChange((value: string) => { this.backendUrl = value; })
      TextInput({ text: this.roomCode, placeholder: 'Room code' }).maxLength(32).onChange((value: string) => { this.roomCode = value; })
      Button('Connect to Emulator TV').enabled(this.tvConnection !== 'Connecting').onClick(() => { this.connectEmulatorTv(); })
      if (this.tvConnection === 'Connected') {
        Text(this.transportMode === 'demo' ? 'Connected • Local Demo TV' : 'Connected • Separate Emulator TV').fontSize(20)
        Button(this.transportMode === 'demo' ? 'View Demo TV' : 'Phone controller').onClick(() => {
          if (this.transportMode === 'demo') { this.showTv(); } else { this.navigate('activity'); }
        })
        Button('Disconnect TV').onClick(() => this.disconnectTv())
      }
      Text('Choose a mock adventure').fontSize(22).fontWeight(FontWeight.Bold)
      ForEach(TV_CATEGORIES, (category: string, index: number) => {
        Button(`${category}: ${TV_TITLES[index]}`).width('100%').enabled(!this.planLoading)
          .onClick(() => { this.generatePlan(category); })
      })
      Text('Mock plans are preset local content. No Gemini or Veo connection.').fontSize(14)
      Text('Create AI Activity').fontSize(24).fontWeight(FontWeight.Bold)
      Row({ space: 10 }) {
        Button('Gemini AI').onClick(() => { this.selectedProvider = 'GEMINI'; })
        Button('Huawei AI').onClick(() => { this.selectedProvider = 'HUAWEI'; })
        Text(`Provider: ${this.selectedProvider}`).fontSize(14)
      }
      Text(`Age ${this.data.settings.age} • Interests: ${this.data.settings.interests.join(', ')} • ${this.data.settings.minutes} min`).fontSize(16)
      Button('Edit age, interests and duration').onClick(() => this.openSettings())
      Row({ space: 6 }) {
        ForEach(TV_CATEGORIES, (category: string) => {
          Button(category).layoutWeight(1).backgroundColor(category === this.generationCategory ? '#28745E' : '#52645C')
            .onClick(() => { this.generationCategory = category; })
        })
      }.width('100%')
      TextInput({ text: this.learningGoal, placeholder: 'Educational goal' }).maxLength(100)
        .onChange((value: string) => { this.learningGoal = value; })
      Button(this.backendLoading ? 'Creating your adventure...' : 'Create Adventure').width('100%').enabled(!this.backendLoading)
        .onClick(() => { this.createAdventure(this.selectedProvider); })
      if (this.generationProgress !== '') { Text(this.generationProgress).fontSize(17) }
      Text('Provider keys stay on the backend. Missing keys or failed generation produce clearly labelled fallback content.').fontSize(14)
    }.width('100%')
  }

  @Builder
  tvContent() {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        Text(this.tvFrame.title || 'Companion TV').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1)
        Text('LOCAL DEMO TV').fontSize(14)
        Button('Phone controller').onClick(() => this.leaveTv())
      }.width('100%')
      Row({ space: 20 }) {
        Column({ space: 12 }) {
          Text(this.tvFrame.phase === 'ready' || this.tvFrame.phase === 'completed' ? '★ Together!' :
            this.tvFrame.phase === 'paused' ? '☁ Rest time' : this.tvFrame.visual).fontSize(36).fontWeight(FontWeight.Bold)
          Text('Local illustration • Video unavailable').fontSize(15)
          Text('Gentle play. An adult stays beside you.').fontSize(18)
        }.layoutWeight(1).height('100%').backgroundColor('#DCEBDD').borderRadius(24).padding(20)
        Column({ space: 12 }) {
          Text(this.tvFrame.phase === 'paused' ? 'Paused' : this.tvFrame.phase === 'ready' ? 'Great play! Ask your parent to confirm.' :
            this.tvFrame.phase === 'completed' ? 'Completed together!' : this.tvFrame.instruction).fontSize(25).fontWeight(FontWeight.Bold)
          Text(this.clockLabel()).fontSize(40).fontWeight(FontWeight.Bold)
          Text(`Step ${this.tvFrame.step + 1} / ${this.tvFrame.steps}`).fontSize(22)
          Progress({ value: this.tvFrame.step + 1, total: this.tvFrame.steps, type: ProgressType.Linear }).width('100%')
          Text('Your phone controls play. Take breaks whenever you need.').fontSize(16)
        }.layoutWeight(1)
      }.layoutWeight(1).width('100%')
    }.padding(20).width('100%').height('100%').backgroundColor('#F4F7F0')
  }

  @Builder
  progressContent() {
    Column({ space: 16 }) {
      this.heading('Progress')
      Text(`Completed today: ${this.today} • Total completions: ${this.data.total}`).fontSize(20).fontColor('#28745E').width('100%')
      Text(this.data.total >= 10 ? 'Family Explorer • 10+ moments together' :
        this.data.total >= 3 ? 'Together Team • 3+ moments together' :
        this.data.total >= 1 ? 'First Adventure • First moment together' : 'Your first badge is waiting!')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#203C31').padding(20)
        .width('100%').backgroundColor('#E0EEE5').borderRadius(16)
      Text('Latest 20 completions. Total includes earlier and Demo Mode completions.').fontSize(14).fontColor('#52645C').width('100%')
      if (this.data.records.length === 0) {
        Text('Complete an activity together to start your story.').fontSize(18).fontColor('#52645C').width('100%')
      }
      ForEach(this.data.records, (record: Completion) => {
        Column({ space: 8 }) {
          Text(record.title).fontSize(21).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
          Text(contentLabel(record.contentSource)).fontSize(14).fontColor('#28745E').width('100%')
          Text(this.dateLabel(record.completedAt)).fontSize(15).fontColor('#52645C').width('100%')
          Text(record.demo ? 'Demo Mode • 10 seconds • Parent confirmed' : `${record.minutes} min • Parent confirmed`)
            .fontSize(14).fontColor('#28745E').width('100%')
        }.padding(20).width('100%').backgroundColor(Color.White).borderRadius(20)
      }, (record: Completion) => record.id)
      Button('Choose another adventure').width('100%').backgroundColor('#28745E').fontColor(Color.White).onClick(() => this.navigate('home'))
    }.width('100%')
  }

  build() {
    if (this.screen === 'tv') { this.tvContent() }
    else {
    Column() {
      Row({ space: 12 }) {
        if (this.screen !== 'home') {
          Button('Back').fontSize(14).backgroundColor('#E0EEE5').fontColor('#203C31').enabled(!this.busy)
            .onClick(() => { this.onBackPress(); })
        }
        Text('CompanionOS').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#203C31')
        Blank()
        Text('OFFLINE').fontSize(11).fontColor('#28745E')
      }.width('100%').padding(16)
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          if (this.notice !== '') {
            Text(this.notice).fontSize(15).fontColor('#6B451C').padding(16).width('100%').backgroundColor('#FFF0D9').borderRadius(14)
          }
          if (this.screen === 'home') { this.homeContent() }
          else if (this.screen === 'settings') { this.settingsContent() }
          else if (this.screen === 'progress') { this.progressContent() }
          else if (this.screen === 'connect') { this.connectionContent() }
          else { this.activityContent() }
          Text('Made for moments together • HackYeah MVP').fontSize(12).fontColor('#52645C').padding({ top: 12, bottom: 24 })
        }.width('100%').padding({ left: 20, right: 20, top: 8 })
      }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Auto)
    }.height('100%').width('100%').backgroundColor('#F4F7F0')
    }
  }
}
