import { ParentDashboard } from './ParentDashboard';
﻿import { common } from '@kit.AbilityKit';
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
import { WorkState, WorkEntry, WORK_TYPES, PREPARATIONS, planWork, settleEntry, endWork, remainingWork, categoryMinutes, workActivity } from '../model/WorkSession';
import { WorkStore } from '../services/WorkStore';

import { BalanceRules, BALANCE_PRESETS, presetRules, validRules, SessionBalanceEngine } from '../model/SessionBalanceEngine';
import { BehaviorData, ChildInteractionEvent, appendEvent, BehaviorInsightEngine } from '../model/BehaviorInsightEngine';
import { GameState, GameEngine, GameBoard, GAME_IDS, gameDefinition } from '@companion/protocol';
import { JourneyState, WORLDS, worldName, completeAdventure, claimActivity, collectibles } from '../model/AdventureJourney';
import { JourneyStore } from '../services/JourneyStore';
import { BehaviorStore } from '../services/BehaviorStore';

@Entry
@Component
struct Index {
  @State game: GameState = new GameState();
  @State journey: JourneyState = new JourneyState();
  private journeyStore: JourneyStore | undefined = undefined;
  @State behavior: BehaviorData = new BehaviorData();
  @State workRules: BalanceRules = new BalanceRules();
  @State insightDays: number = 7;
  @State sequenceVisible: boolean = true;
  @State gameLevel: string = 'Gentle';
  @State gameSolved: boolean = false;
  @State gameMessage: string = '';
  @State taskAttempts: number = 0;
  @State taskCorrect: number = 0;
  @State childFeedback: string = '';
  @State difficultyFeedback: string = '';
  @State repeatFeedback: string = '';
  @State activityMode: string = 'GUIDED_OFFSCREEN';
  @State gameType: string = '';
  private behaviorStore: BehaviorStore | undefined = undefined;
  private eventSequence: number = 0;
  private activityStarted: number = 0;
  @State work: WorkState = new WorkState();
  @State workMinutes: number = 30;
  @State preparation: string = 'Recommended';
  @State filter: string = 'ALL';
  @State parentControls: boolean = false;
  @State pressedCard: string = '';
  private workStore: WorkStore | undefined = undefined;
  private workSavedAt: number = 0;
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
      try { this.behaviorStore = new BehaviorStore(context); this.behavior = this.behaviorStore.load(); } catch { this.notice = 'Local interaction storage is unavailable. Core activities remain available.'; }
      try { this.journeyStore = new JourneyStore(context); this.journey = this.journeyStore.load(); } catch { this.notice = 'Journey storage unavailable. Games remain playable.'; }
      this.workRules = this.data.settings.balanceRules;
      this.workStore = new WorkStore(context); this.work = this.workStore.load();
      this.workMinutes = this.data.settings.sessionDuration;
      if (this.work.phase === 'active') {
        this.selected = workActivity(this.work.entries[this.work.index].category, this.data.settings);
        this.preparation = this.work.preparation;
        this.activityMode = this.work.entries[this.work.index].mode; this.gameType = this.work.entries[this.work.index].gameType;
        if (['running', 'paused', 'ready'].includes(this.work.activityPhase)) {
          this.game = this.work.game; if (this.game.id !== '' && this.game.phase !== 'idle') { this.game = GameEngine.pause(this.game, Date.now()); }
          this.demo = this.work.activityDemo;
          this.session.start(Date.now(), this.work.entries[this.work.index].minutes, this.demo);
          this.session.id = `${this.work.id}-${this.work.index}`;
          const restoredEvents = this.behavior.events.filter((e: ChildInteractionEvent) => e.sessionId === this.session.id);
          this.gameSolved = this.game.phase === 'success';
          this.gameLevel = restoredEvents.length > 0 ? restoredEvents[0].difficulty : this.data.settings.activityDifficulty;
          this.taskAttempts = restoredEvents.filter((e: ChildInteractionEvent) => e.eventType === 'ANSWER_SELECTED').length;
          this.taskCorrect = restoredEvents.filter((e: ChildInteractionEvent) => e.eventType === 'ANSWER_CORRECT').length;
          this.activityStarted = restoredEvents.find((e: ChildInteractionEvent) => e.eventType === 'ACTIVITY_STARTED')?.timestamp || 0;
          const feedback = restoredEvents.find((e: ChildInteractionEvent) => e.eventType === 'FEEDBACK_SUBMITTED');
          if (feedback) { this.childFeedback = feedback.feedback; this.difficultyFeedback = feedback.difficultyFeedback; }
          this.selected.title = this.game.id !== '' ? gameDefinition(this.game.id).title : this.activityMode === 'VIDEO' ? this.selected.category === 'LEARN' ? 'Dino Counting Adventure' : this.selected.category === 'CALM' ? 'Cloud Breathing' : this.selected.title : this.selected.title;
          this.session.deadline = Date.now() + this.work.remaining * 1000;
          if (this.work.remaining > 0) { this.session.pause(Date.now()); }
          else { this.session.phase = 'ready'; }
          this.stepIndex = this.work.step; this.screen = 'work-status';
          this.stepBoundary = (this.demo ? 10 : this.session.minutes * 60) - (this.stepIndex + 1) * this.stepSeconds();
          this.notice = 'Work session restored safely. Resume when ready; content returns to Built-in after restart.';
        }
      }
      this.saveAdventureEnding();
      this.storageReady = true;
      Widgets.update(context, this.data);
      if (this.store.recovered) { this.notice = 'Some local data was unreadable. Safe defaults have been restored.'; }
    } catch {
      this.notice = 'Local storage is unavailable. You can explore activities, but saving is disabled. Reopen the app to retry.';
    }
    this.updateClock();
    this.startTimer();
  }

  aboutToDisappear(): void { this.persistWork(); clearInterval(this.timer); this.generationToken++; this.transport?.disconnect(); }
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
    } else { this.persistWork(); try { this.phoneVideoController.pause(); } catch {} }
  }

  private updateClock(): void {
    this.today = countToday(this.data, Date.now());
    if (this.game.id !== '' && this.foreground && ['running', 'ready'].includes(this.session.phase)) { this.game = GameEngine.tick(this.game, Date.now()); }
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
    if (this.work.phase === 'active' && Date.now() - this.workSavedAt > 2000) { this.persistWork(); }
  }

  private frame(): TvFrame {
    const frame = new TvFrame();
    frame.game = this.game; frame.activityMode = this.activityMode;
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
    if (this.activityMode === 'INTERACTIVE' && this.game.id !== '') { frame.instruction = GameEngine.prompt(this.game); }
    if (this.activityMode === 'VIDEO' && this.selected.contentSource === ActivityContentSource.BUILT_IN && this.selected.category === 'LEARN') { frame.instruction = `Count together: ${Math.min(5, Math.floor(((this.demo ? 10 : this.session.minutes * 60) - this.remaining) % 10 / 2) + 1)} dinosaurs. One, two, three, four, five!`; }
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
      else if (event === 'error') { this.notice = 'Large Screen unavailable. Continue on your phone.'; }
      else { this.tvFrame = frame; }
    });
    await this.transport.connect();
    this.syncTv();
    this.notice = 'Demo Large Screen connected locally. No real Large Screen connection.';
  }

  private async connectEmulatorTv(): Promise<void> {
    if (this.tvConnection === 'Connecting') { return; }
    this.transport?.disconnect(); this.transport = undefined;
    this.tvConnection = 'Connecting'; this.transportMode = 'emulator';
    const transport = new EmulatorTvTransport(this.backendUrl.trim(), this.roomCode.trim(), (event: string, frame: TvFrame) => {
      if (event === 'gameInput') { const command = frame.gameCommand; if (this.session.id === command.sessionId && this.game.revision === command.revision && this.game.round === command.round && this.game.phase === command.phase && this.game.selected.length === command.selectedCount) { this.gameAction(command.action, command.value); } }
      if (event === 'connected') { this.tvConnection = 'Connected'; }
      else if (event === 'disconnected') { this.tvConnection = 'Disconnected'; }
      else if (event === 'videoFallback') { this.notice = 'Large Screen video unavailable. Safe fallback visual is playing.'; }
    });
    try {
      await transport.connect(); this.transport = transport; this.syncTv();
      this.notice = 'Connected to Emulator Tablet. Your phone controls the separate Large Screen application.';
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
    request.durationMinutes = this.work.phase === 'active' ? (this.work.entries[this.work.index].minutes <= 3 ? 3 : 5) : this.data.settings.minutes; request.educationalGoal = this.learningGoal.trim();
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
    this.notice = 'Large Screen disconnected. Your phone activity and saved history are safe.';
    if (this.screen === 'tv') { this.leaveTv(); }
    else if (this.screen === 'connect' && ['running', 'paused', 'ready'].includes(this.phase)) { this.navigate('activity'); }
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
      request.durationMinutes = this.work.phase === 'active' ? (this.work.entries[this.work.index].minutes <= 3 ? 3 : 5) : this.data.settings.minutes;
      request.educationalGoal = category === 'LEARN' ? 'Count five objects together' : 'Practice gentle turn taking';
      const plan = await new MockAiActivityService().generateActivityPlan(request);
      this.openActivity(activityFromPlan(plan, request));
      this.notice = 'Mock activity plan — deterministic local content, not real AI output.';
    } catch { this.notice = 'Plan unavailable. The original offline activities remain ready.'; }
    finally { this.planLoading = false; }
  }

  private pauseActivity(): void {
    try { this.phoneVideoController.pause(); } catch { /* No attached video. */ }
    this.recordBehavior('PAUSE');
    this.game = GameEngine.pause(this.game, Date.now()); this.session.pause(Date.now()); this.updateClock(); this.transport?.pauseActivity(this.frame());
  }

  private resumeActivity(): void {
    try { this.phoneVideoController.start(); } catch { /* No attached video. */ }
    this.recordBehavior('RESUME');
    this.game = GameEngine.resume(this.game, Date.now()); this.session.continueActivity(Date.now()); this.updateClock(); this.transport?.resumeActivity(this.frame());
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
      this.notice = 'Play on the separate Large Screen. Start, pause and change steps on this phone.'; return;
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
    if (screen === 'home') { this.filter = 'ALL'; }
    this.screen = screen;
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }

  private persistWork(): void {
    if (!this.workStore) { return; }
    if (this.work.phase === 'active') {
      this.work.remaining = this.session.remaining(Date.now()); this.work.activityPhase = this.session.phase;
      this.work.step = Math.min(2, this.stepIndex); this.work.activityId = this.selected.id;
      this.work.game = this.game; this.work.activityDemo = this.demo;
    }
    try { this.workStore.save(this.work); this.workSavedAt = Date.now(); }
    catch { this.notice = 'Work session could not be saved. Keep the app open and retry.'; }
  }

  private async startWork(daily: boolean = false): Promise<void> {
    if (this.busy || !this.storageReady || ['running', 'paused', 'ready'].includes(this.phase)) { return; }
    if (!validRules(this.workRules)) { this.notice = 'Choose valid movement/learning goals (combined at most 80%).'; return; }
    this.busy = true;
    this.data.settings.balanceRules = this.workRules;
    try { await this.store?.save(this.data); } catch { this.notice = 'Session goals could not be saved. Retry before starting.'; return; } finally { this.busy = false; }
    this.work = planWork(this.workMinutes, this.previewSettings()); this.work.preparation = this.preparation; this.work.daily = daily; this.work.adventureDate = this.dayLabel(Date.now());
    this.openWorkEntry(); this.persistWork();
  }

  private openWorkEntry(): void {
    this.game = new GameState(); this.session = new ActivitySession(); this.phase = 'idle';
    const activity = workActivity(this.work.entries[this.work.index].category, this.data.settings);
    const entry = this.work.entries[this.work.index];
    activity.duration = entry.minutes;
    this.activityMode = entry.mode; this.gameType = entry.gameType;
    if (entry.category === 'LEARN') {
      const recent = BehaviorInsightEngine.window(this.behavior, 7, Date.now());
      this.gameLevel = BehaviorInsightEngine.recommendDifficulty(recent, this.data.settings.activityDifficulty);
      if (entry.mode === 'INTERACTIVE') { this.gameType = BehaviorInsightEngine.recommendGame(recent, this.gameType); entry.gameType = this.gameType; }
      if (entry.mode === 'INTERACTIVE') { this.game = GameEngine.create(this.gameType === 'MEMORY_SEQUENCE' ? 'robot-memory' : this.gameType === 'SORTING' ? 'animal-sorting' : 'dino-number', this.gameLevel); activity.title = gameDefinition(this.game.id).title; }
      else if (entry.mode === 'VIDEO') { activity.title = 'Dino Counting Adventure'; }
    }
    if (entry.category === 'MOVE' && entry.gameType === 'MOVEMENT_CHALLENGE') { this.activityMode = 'INTERACTIVE'; entry.mode = 'INTERACTIVE'; this.game = GameEngine.create('penguin-move', this.data.settings.activityDifficulty); activity.title = 'Penguin Move'; }
    if (entry.category === 'CALM' && entry.mode === 'VIDEO') { activity.title = 'Cloud Breathing'; }
    this.generationCategory = activity.category; this.learningGoal = activity.educationalGoal;
    this.openActivity(activity); this.parentControls = false;
    this.notice = 'Review this short activity before starting. Take breaks between activities.';
    this.persistWork();
    if (this.work.preparation === 'Huawei AI' || this.work.preparation === 'Gemini AI') {
      this.createAdventure(this.work.preparation === 'Huawei AI' ? 'HUAWEI' : 'GEMINI');
    } else if (this.work.preparation === 'My Videos') {
      if (this.userVideo) { this.useMyVideo(); }
      else { this.notice = 'Import and review your video below, or start with safe Built-in content.'; }
    }
  }

  private skipWorkEntry(): void {
    if (this.busy || this.work.phase !== 'active') { return; }
    this.getUIContext().showAlertDialog({ title: 'Change activity?', message: 'This activity will be marked skipped, not completed.',
      primaryButton: { value: 'Keep activity', action: () => {} },
      secondaryButton: { value: 'Skip activity', action: () => {
        if (['running', 'paused', 'ready'].includes(this.phase)) { this.recordBehavior('ACTIVITY_SKIPPED'); }
        this.session.cancel(); this.transport?.cancelActivity(this.frame());
        this.work = settleEntry(this.work, 'skipped', this.demo); this.persistWork();
        if (this.work.phase === 'active') { this.openWorkEntry(); } else { this.navigate('work-summary'); }
      } }
    });
  }

  private finishWork(): void {
    if (this.busy) { return; }
    this.getUIContext().showAlertDialog({ title: 'End work session?', message: 'Unfinished activities will be skipped. Saved completions remain.',
      primaryButton: { value: 'Keep session', action: () => {} },
      secondaryButton: { value: 'End Session', action: () => {
        if (['running', 'paused', 'ready'].includes(this.phase)) { this.recordBehavior('ACTIVITY_SKIPPED'); }
        this.session.cancel(); this.phase = 'cancelled'; this.transport?.cancelActivity(this.frame());
        this.work = endWork(this.work); this.persistWork(); this.navigate('work-summary');
      } }
    });
  }

  private typeColor(type: string): string {
    return type === 'MOVE' ? '#F7E0CA' : type === 'LEARN' ? '#DDECF2' : type === 'CREATE' ? '#ECE3F4' : '#DDEBE2';
  }
  private activityArt(activity: Activity): string {
    return activity.id === 'butterfly' ? 'butterfly' : activity.id === 'sounds' ? 'sounds' : activity.category;
  }
  private catalog(): Activity[] {
    const originals = ACTIVITIES.map((activity: Activity, index: number) => {
      activity.category = index === 1 ? 'LEARN' : index === 2 ? 'CALM' : 'MOVE'; return activity;
    });
    return [...originals, workActivity('CREATE', this.data.settings), workActivity('CALM', this.data.settings)]
      .filter((activity: Activity) => this.filter === 'ALL' || activity.category === this.filter);
  }
  private selectTab(tab: string): void {
    if (tab === 'home') { this.filter = 'ALL'; }
    if (tab === 'settings') { this.openSettings(); } else { this.navigate(tab); }
  }

  private openActivity(activity: Activity): void {
    if (['running', 'paused', 'ready'].includes(this.phase)) { this.notice = 'Finish or cancel the current activity first.'; return; }
    this.selected = activity;
    this.generationCategory = activity.category; this.learningGoal = activity.educationalGoal;
    this.activeJobId = '';
    if (this.work.phase !== 'active') { this.game = new GameState(); this.activityMode = 'GUIDED_OFFSCREEN'; this.gameType = ''; }
    this.activitySource = activity.id.startsWith('tv-') ? 'Mock plan • Not real AI output' : 'Offline activity';
    this.session = new ActivitySession();
    this.phase = 'idle';
    this.confirmed = false;
    this.demo = false;
    this.stepIndex = 0;
    if (this.storageReady) { this.notice = ''; }
    this.navigate('activity');
  }

  private chooseBuiltIn(video: boolean = false): void {
    if (this.backendLoading || this.importingVideo || ['running', 'paused', 'ready'].includes(this.phase)) { return; }
    const original = this.work.phase === 'active' ? workActivity(this.work.entries[this.work.index].category, this.data.settings) :
      ACTIVITIES.find((item: Activity) => item.id === this.selected.id) || this.catalog().find((item: Activity) => item.id === this.selected.id) || ACTIVITIES[0];
    this.openActivity(original);
    if (video) { this.game = new GameState(); if (original.category === 'LEARN') { this.selected.title = 'Dino Counting Adventure'; } if (original.category === 'CALM') { this.selected.title = 'Cloud Breathing'; } }
    this.activityMode = video ? 'VIDEO' : this.work.phase === 'active' && original.category === 'LEARN' ? 'INTERACTIVE' : 'GUIDED_OFFSCREEN';
    this.gameType = video ? '' : this.work.phase === 'active' ? this.work.entries[this.work.index].gameType : original.category === 'MOVE' ? 'MOVEMENT_CHALLENGE' : '';
    if (!video && this.work.phase === 'active' && original.category === 'LEARN') { this.game = GameEngine.create(this.gameType === 'MEMORY_SEQUENCE' ? 'robot-memory' : this.gameType === 'SORTING' ? 'animal-sorting' : 'dino-number', this.gameLevel); this.selected.title = gameDefinition(this.game.id).title; }
    if (!video && this.work.phase === 'active' && original.category === 'MOVE') { this.game = GameEngine.create('penguin-move', this.gameLevel); this.activityMode = 'INTERACTIVE'; this.gameType = 'MOVEMENT_CHALLENGE'; this.selected.title = 'Penguin Move'; }
    this.activitySource = 'CompanionOS Built-in • Offline activity';
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
      const template = this.work.phase === 'active' ? workActivity(this.work.entries[this.work.index].category, this.data.settings) : ACTIVITIES[0];
      const activity = new Activity('user-video', value.title, this.data.settings.interests[0], template.steps);
      activity.category = template.category; activity.educationalGoal = template.educationalGoal;
      activity.contentSource = ActivityContentSource.USER_VIDEO; activity.localVideoPath = value.path; activity.videoUrl = url;
      activity.activitySteps.forEach((step) => { step.videoUrl = url; });
      this.openActivity(activity); this.activitySource = 'My Video';
      this.notice = `My Video • ${Math.ceil(value.durationSeconds)} seconds • Not AI generated. Plays muted and loops during the activity.${url === '' ? ' Offline phone video; Large Screen uses Built-in fallback until the backend is available.' : ''}`;
    } catch { this.notice = 'Saved video could not be sent to the player. Start the local backend, retry, or choose Built-in Video.'; }
    finally { this.importingVideo = false; }
  }

  private startActivity(): void {
    if (this.busy || this.backendLoading || this.importingVideo || this.phase === 'running' || this.phase === 'paused' || this.phase === 'ready') { return; }
    if (this.selected.contentSource === ActivityContentSource.USER_VIDEO && !this.videos?.load()) {
      this.notice = 'Saved video is missing. Import a video or choose Built-in Video.'; return;
    }
    if (this.work.phase === 'active') {
      const entry = this.work.entries[this.work.index];
      const hasVideo = this.activityMode === 'VIDEO' || this.selected.videoUrl !== '' || this.selected.localVideoPath !== '';
      if (hasVideo && !SessionBalanceEngine.videoAllowed(this.work.entries, this.work.index, this.work.rules.passive)) {
        this.notice = 'This video would exceed the video allowance or remove the last interactive learning activity. A Built-in activity is ready.';
        this.chooseBuiltIn();
      } else if (hasVideo) { this.activityMode = 'VIDEO'; }
      entry.mode = this.activityMode;
    } else {
      this.activityMode = this.selected.videoUrl !== '' || this.selected.localVideoPath !== '' || this.activityMode === 'VIDEO' ? 'VIDEO' : this.game.id !== '' ? 'INTERACTIVE' : 'GUIDED_OFFSCREEN';
    }
    if (this.activityMode === 'VIDEO') { this.gameType = ''; }
    if (this.activityMode === 'INTERACTIVE' && this.game.id !== '') { this.game = GameEngine.start(GameEngine.create(this.game.id, this.game.difficulty, this.demo), Date.now()); }
    this.sequenceVisible = true; this.gameSolved = false; this.gameMessage = ''; this.taskAttempts = 0; this.taskCorrect = 0;
    this.childFeedback = ''; this.difficultyFeedback = ''; this.repeatFeedback = '';
    this.activityStarted = Date.now();
    this.session.contentSource = this.selected.contentSource; this.session.videoUrl = this.selected.videoUrl;
    this.session.localVideoPath = this.selected.localVideoPath; this.session.aiProvider = this.selected.aiProvider;
    this.session.aiGenerationId = this.selected.aiGenerationId;
    this.session.start(Date.now(), this.work.phase === 'active' ? this.work.entries[this.work.index].minutes : this.data.settings.minutes, this.demo);
    if (this.work.phase === 'active') { this.session.id = `${this.work.id}-${this.work.index}`; }
    this.stepIndex = 0; this.stepBoundary = (this.demo ? 10 : this.session.minutes * 60) - this.stepSeconds();
    this.recordBehavior('ACTIVITY_STARTED');
    if (this.behavior.events.some((event: ChildInteractionEvent) => !event.demo && event.gameType === this.gameType && event.activityMode === this.activityMode && event.activityId === (this.game.id !== '' ? this.game.id : this.selected.id) && event.eventType === 'ACTIVITY_COMPLETED' && event.sessionId !== this.session.id)) { this.recordBehavior('ACTIVITY_REPEATED'); }
    this.confirmed = false;
    this.notice = '';
    this.updateClock();
    this.transport?.startActivity(this.selected, this.frame());
    this.parentControls = false; this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); this.persistWork();
  }

  private cancelActivity(): void {
    if (this.work.phase === 'active') { this.navigate('work-status'); return; }
    if (this.busy) { return; }
    if (this.phase === 'running' || this.phase === 'paused' || this.phase === 'ready') {
      this.getUIContext().showAlertDialog({
        title: 'Cancel this activity?',
        message: 'No completion will be recorded.',
        primaryButton: { value: 'Keep playing', action: () => {} },
        secondaryButton: { value: 'Cancel activity', action: () => {
          this.recordBehavior('ACTIVITY_SKIPPED'); this.session.cancel(); this.phase = 'cancelled'; this.confirmed = false;
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
    else if (this.screen === 'connect' && ['running', 'paused', 'ready'].includes(this.phase)) { this.navigate('activity'); }
    else if (this.screen === 'activity') { this.cancelActivity(); }
    else if (!this.busy) { this.navigate('home'); }
    return true;
  }

  private async completeActivity(): Promise<void> {
    if (this.busy || !this.store || !this.storageReady || this.phase !== 'ready' || !this.confirmed || (this.activityMode === 'INTERACTIVE' && !this.gameSolved)) { return; }
    this.busy = true;
    const record = new Completion();
    record.id = this.session.id;
    record.activityId = this.game.id !== '' ? this.game.id : this.selected.id;
    record.title = this.selected.title;
    record.completedAt = Date.now();
    record.minutes = this.session.minutes;
    record.demo = this.session.demo;
    record.contentSource = this.session.contentSource;
    record.sessionId = this.session.id; record.category = this.selected.category; record.activityMode = this.activityMode;
    record.gameType = this.gameType; record.plannedDuration = this.session.minutes; record.startedAt = this.activityStarted || undefined;
    record.actualDuration = this.activityStarted > 0 ? Math.max(0, Math.round((Date.now() - this.activityStarted) / 1000)) : undefined;
    record.completed = true; record.skipped = false; record.childFeedback = this.childFeedback; record.difficultyFeedback = this.difficultyFeedback;
    record.movementPlanned = this.selected.category === 'MOVE'; record.movementConfirmed = this.game.movementConfirmed;
    record.learningActivityCompleted = this.game.learned || this.selected.category === 'LEARN'; record.questionsAttempted = this.activityMode === 'INTERACTIVE' ? this.game.attempts : undefined;
    record.questionsCorrect = this.activityMode === 'INTERACTIVE' ? this.game.correct : undefined; record.attemptCount = record.questionsAttempted;
    const updated = addCompletion(this.data, record);
    try {
      await this.store.save(updated);
      this.data = updated;
      try { const nextJourney = claimActivity(this.journey, record); this.journeyStore?.save(nextJourney); this.journey = nextJourney; } catch { this.notice = 'Completion saved; journey update unavailable.'; }
      this.recordBehavior('ACTIVITY_COMPLETED');
      this.session.phase = 'completed';
      this.activeJobId = '';
      Widgets.update(this.getUIContext().getHostContext() as common.UIAbilityContext, updated);
      this.phase = 'completed';
      this.syncTv();
      this.confirmed = false;
      this.today = countToday(updated, Date.now());
      this.notice = `${record.title} completed. Well done, together!`;
      if (this.work.phase === 'active') {
        this.work = settleEntry(this.work, 'completed', this.demo); this.persistWork();
        if (this.work.phase === 'active') { this.openWorkEntry(); }
        else { this.saveAdventureEnding(); this.navigate('work-summary'); }
      } else { this.navigate('progress'); }
    } catch {
      this.notice = 'Saving failed. Your activity is ready to confirm again.';
    } finally { this.busy = false; }
  }

  private openSettings(): void {
    const settings = new ParentSettings();
    settings.balanceRules = JSON.parse(JSON.stringify(this.data.settings.balanceRules)) as BalanceRules;
    settings.age = this.data.settings.age;
    settings.interests = this.data.settings.interests.slice();
    settings.minutes = this.data.settings.minutes;
    settings.aiEndpoint = this.data.settings.aiEndpoint;
    settings.preferredActivityTypes = this.data.settings.preferredActivityTypes.slice();
    settings.sessionDuration = this.data.settings.sessionDuration;
    settings.activityDifficulty = this.data.settings.activityDifficulty;
    settings.indoorOnly = this.data.settings.indoorOnly; settings.noJumping = this.data.settings.noJumping;
    settings.lowIntensity = this.data.settings.lowIntensity;
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
      this.workMinutes = updated.settings.sessionDuration; this.workRules = updated.settings.balanceRules;
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

  private adjustGoals(move: number, learn: number): void {
    const rules = JSON.parse(JSON.stringify(this.workRules)) as BalanceRules; rules.movement += move; rules.learning += learn; this.workRules = rules;
  }
  private previewSettings(): ParentSettings {
    const settings = JSON.parse(JSON.stringify(this.data.settings)) as ParentSettings; settings.balanceRules = this.workRules; return settings;
  }
  private recordBehavior(type: string): void {
    if (!this.behaviorStore || !this.session.id) { return; }
    const event = new ChildInteractionEvent(); event.sessionId = this.session.id; event.activityId = this.game.id !== '' ? this.game.id : this.selected.id;
    event.activityCategory = this.selected.category; event.activityMode = this.activityMode; event.gameType = this.gameType;
    event.plannedMinutes = this.session.minutes; event.timestamp = Date.now(); event.eventType = type; event.demo = this.session.demo;
    event.attemptNumber = this.taskAttempts; event.elapsedSeconds = this.activityStarted ? Math.min(86400, Math.max(0, Math.round((Date.now() - this.activityStarted) / 1000))) : -1;
    event.selectedAnswer = this.game.lastInput; event.difficulty = this.game.id !== '' ? this.game.difficulty : this.selected.category === 'LEARN' ? this.gameLevel : this.data.settings.activityDifficulty; event.contentSource = this.selected.contentSource;
    event.feedback = this.childFeedback; event.difficultyFeedback = this.difficultyFeedback; event.repeatFeedback = this.repeatFeedback;
    event.eventId = `${event.sessionId}:${type}:${['ACTIVITY_STARTED', 'ACTIVITY_COMPLETED', 'ACTIVITY_SKIPPED', 'FEEDBACK_SUBMITTED', 'MOVEMENT_CONFIRMED'].includes(type) ? '' : Date.now().toString() + '-' + this.eventSequence++}`;
    const current = new BehaviorData(); current.events = type === 'FEEDBACK_SUBMITTED' ? this.behavior.events.filter((e: ChildInteractionEvent) => e.eventId !== event.eventId) : this.behavior.events;
    const next = appendEvent(current, event);
    try { this.behaviorStore.save(next); this.behavior = next; } catch { this.notice = 'Interaction details could not be saved. Activity completion still works; retry later.'; }
  }
  private gameAction(action: string, value: string): void {
    if (!['running', 'ready'].includes(this.phase) || this.game.id === '') { return; }
    if (action === 'skip') { if (this.work.phase === 'active') { this.skipWorkEntry(); } else { this.cancelActivity(); } return; }
    const transition = GameEngine.act(this.game, action, value, Date.now()); this.game = transition.state;
    this.taskAttempts = this.game.attempts; this.taskCorrect = this.game.correct;
    transition.events.forEach((type: string) => this.recordBehavior(type));
    this.gameSolved = this.game.phase === 'success';
    if (this.gameSolved) { this.session.deadline = Date.now(); this.session.phase = 'running'; this.updateClock(); }
    this.persistWork(); this.syncTv();
  }
  private openGame(id: string): void {
    if (['running', 'paused', 'ready'].includes(this.phase)) { this.notice = 'Finish or cancel the current activity first.'; return; }
    const definition = gameDefinition(id, BehaviorInsightEngine.recommendDifficulty(BehaviorInsightEngine.window(this.behavior, 7, Date.now()), this.data.settings.activityDifficulty));
    if (this.work.phase === 'active' && definition.category !== this.work.entries[this.work.index].category) { this.notice = 'Choose an adventure in the planned category.'; return; }
    const activity = new Activity(id, definition.title, definition.category === 'MOVE' ? 'Movement' : 'Sounds', [definition.instruction, definition.storyContext, 'Take breaks. An adult stays available and confirms completion.']);
    activity.category = definition.category; activity.educationalGoal = definition.learningGoal; activity.theme = definition.theme;
    this.openActivity(activity); this.game = GameEngine.create(id, definition.difficulty); this.gameLevel = definition.difficulty;
    this.activityMode = 'INTERACTIVE'; this.gameType = definition.gameType;
    if (this.work.phase === 'active') { this.work.entries[this.work.index].gameType = definition.gameType; this.work.entries[this.work.index].mode = 'INTERACTIVE'; this.persistWork(); }
  }
  private dayLabel(now: number): string { const d = new Date(now); return `${d.getFullYear()}-${d.getMonth() + 1}-${d.getDate()}`; }
  private saveAdventureEnding(): void {
    if (!this.work.daily || this.work.phase !== 'completed' || this.work.entries.some((entry) => entry.outcome !== 'completed')) { return; }
    try { const next = completeAdventure(this.journey, this.work.adventureDate, this.work.entries.some((entry) => entry.demo), Date.now()); this.journeyStore?.save(next); this.journey = next; }
    catch { this.notice = 'Activities saved; adventure story progress could not be saved.'; }
  }
  private preferenceExplanation(): string {
    const events = BehaviorInsightEngine.window(this.behavior, 7, Date.now()).filter((e: ChildInteractionEvent) => e.activityCategory === this.selected.category && e.gameType === this.gameType);
    const metrics = BehaviorInsightEngine.metrics(events);
    return metrics.started < 3 ? 'Not enough recent interaction data yet. This activity supports the planned category goal.' :
      `Why this choice? ${metrics.completed} of ${metrics.started} similar starts were marked complete in the last seven days. Balance goals remain protected. Difficulty: ${this.gameLevel}; changed only with at least three explicit feedback responses.`;
  }
  @Builder
  balanceControls() {
    Column({ space: 8 }) {
      Text("Today's Session Goal").fontSize(22).fontWeight(FontWeight.Bold).width('100%')
      ForEach(BALANCE_PRESETS, (preset: string) => {
        Button(`${this.workRules.preset === preset ? 'Selected: ' : ''}${preset}`).width('100%')
          .backgroundColor(this.workRules.preset === preset ? '#287452' : '#E1EEE8').fontColor(this.workRules.preset === preset ? '#FFFFFF' : '#203C31')
          .onClick(() => { this.workRules = presetRules(preset); })
      })
      if (this.workRules.preset === 'Custom') {
        Text(`MOVE minimum ${this.workRules.movement}% | LEARN minimum ${this.workRules.learning}%`).fontSize(15)
        Row({ space: 6 }) {
          Button('Move -').onClick(() => this.adjustGoals(-5, 0))
          Button('Move +').onClick(() => this.adjustGoals(5, 0))
          Button('Learn -').onClick(() => this.adjustGoals(0, -5))
          Button('Learn +').onClick(() => this.adjustGoals(0, 5))
        }.width('100%')
      }
      Text(`Interactive-first | Passive video maximum ${this.workRules.passive}%`).fontSize(14)
      if (!validRules(this.workRules)) { Text('Use MOVE 10-50%, LEARN 20-50%, combined at most 80%.').fontColor('#8A3D20') }
    }.width('100%')
  }
  @Builder
  interactionContent() {
    GameBoard({ state: this.game, onAction: (action: string, value: string) => this.gameAction(action, value) })
  }
  @Builder
  gamesContent() {
    Column({ space: 14 }) {
      this.heading('Choose your adventure')
      Text('WATCH + PLAY + MOVE + CREATE + CALM').fontSize(16).fontColor('#36584A')
      ForEach(GAME_IDS, (id: string) => {
        Column({ space: 8 }) {
          Text(gameDefinition(id).title).fontSize(22).fontWeight(FontWeight.Bold)
          Text(`${gameDefinition(id).category} | Interactive | ${gameDefinition(id).learningGoal}`).fontSize(15)
          Button(`Play ${gameDefinition(id).title}`).width('100%').height(50).onClick(() => this.openGame(id))
        }.padding(18).width('100%').backgroundColor('#E6F0E9').borderRadius(22)
      })
      Button('Watch Dino Counting Adventure').width('100%').onClick(() => { this.openActivity(workActivity('LEARN', this.data.settings)); this.chooseBuiltIn(true); })
      Button('Watch Cloud Breathing').width('100%').onClick(() => { this.openActivity(workActivity('CALM', this.data.settings)); this.chooseBuiltIn(true); })
    }.width('100%')
  }
  @Builder
  dailyContent() {
    Column({ space: 14 }) {
      this.heading(`Daily Adventure: ${worldName(Date.now())}`)
      Text('Nova says: a little counting, moving, watching and imagining. Then a gentle ending.').fontSize(18)
      Text('30 minutes planned. Adult nearby. Pause or stop whenever you need.').fontSize(16)
      ForEach(planWork(30, this.data.settings).entries, (entry: WorkEntry, index: number) => {
        Text(`${index + 1}. ${entry.category === 'LEARN' ? entry.mode === 'VIDEO' ? 'Dino Counting Adventure' : 'Dino Number Adventure' : entry.category === 'MOVE' ? 'Penguin Move' : entry.category === 'CREATE' ? 'Imagine a Dinosaur Home' : entry.mode === 'VIDEO' ? 'Cloud Breathing' : 'Cloud Rest'} | ${entry.category} | ${entry.mode} | ${entry.minutes} min`).fontSize(17).width('100%').padding(14).backgroundColor('#E6F0E9').borderRadius(18)
      })
      Button('Start Daily Adventure').width('100%').height(54).enabled(!this.busy).onClick(() => { this.workMinutes = 30; this.workRules = this.data.settings.balanceRules; this.startWork(true); })
      Text('The adventure ends after this plan. Progress stays when you miss a day; another session requires a parent to start it.').fontSize(14)
    }.width('100%')
  }
  @Builder
  journeyContent() {
    Column({ space: 14 }) {
      this.heading('Adventure Journey')
      Text('Welcome back! Your adventure is waiting.').fontSize(20)
      Text('Nova says: Great work today. A new story can wait until tomorrow.').fontSize(16)
      ForEach(WORLDS, (world: string, index: number) => {
        Column({ space: 6 }) {
          Text(`Week ${index + 1}: ${world}`).fontSize(22).fontWeight(FontWeight.Bold)
          Text(`${this.journey.worlds[index]} Daily Adventures marked complete`).fontSize(15)
          Text(index === 0 ? 'A forest grows with each adventure.' : index === 1 ? 'A spaceship gets ready to explore.' : index === 2 ? 'An ocean grows more colorful.' : 'A friendly city lights up.').fontSize(17)
          Progress({ value: Math.min(7, this.journey.worlds[index]), total: 7, type: ProgressType.Linear }).width('100%')
          if (this.journey.demoWorlds[index] > 0) { Text(`Demo story progress: ${this.journey.demoWorlds[index]} labelled adventures`).fontSize(14); Progress({ value: Math.min(7, this.journey.demoWorlds[index]), total: 7, type: ProgressType.Linear }).width('100%').color('#D79455') }
        }.padding(18).width('100%').backgroundColor('#E6F0E9').borderRadius(22)
      })
      Text('Your collection').fontSize(22).fontWeight(FontWeight.Bold)
      if (collectibles(this.journey).length === 0) { Text('Small adventures, at your own pace. No rewards disappear when you miss a day.').fontSize(16) }
      ForEach(collectibles(this.journey), (label: string) => { Text(label).fontSize(18).width('100%') })
      Text(`${this.journey.completedDays.length} days with a completed Daily Adventure. ${this.journey.demoDays.length} separately labelled Demo days.`).fontSize(15)
      Text('No purchases, random rewards, streak penalties or automatic endless play. Progress stays on this device.').fontSize(13)
    }.width('100%')
  }
  @Builder
  feedbackContent() {
    Column({ space: 10 }) {
      Text('How was this activity? Optional.').fontSize(19).fontWeight(FontWeight.Bold)
      Row({ space: 6 }) {
        ForEach(['Liked', 'Okay', 'Disliked'], (value: string) => {
          Button(value === 'Liked' ? 'I liked it' : value === 'Okay' ? 'It was okay' : "I didn't like it").layoutWeight(1).height(50).fontSize(12)
            .backgroundColor(this.childFeedback === value ? '#287452' : '#E1EEE8').fontColor(this.childFeedback === value ? '#FFFFFF' : '#203C31')
            .onClick(() => { this.childFeedback = value; this.recordBehavior('FEEDBACK_SUBMITTED'); })
        })
      }.width('100%')
      Row({ space: 6 }) {
        ForEach(['Too easy', 'Just right', 'Too hard'], (value: string) => {
          Button(value).layoutWeight(1).height(50).fontSize(14).backgroundColor(this.difficultyFeedback === value ? '#287452' : '#E1EEE8').fontColor(this.difficultyFeedback === value ? '#FFFFFF' : '#203C31')
            .onClick(() => { this.difficultyFeedback = value; this.recordBehavior('FEEDBACK_SUBMITTED'); })
        })
      }.width('100%')
      Text('Would you do this again?').fontSize(16)
      Row({ space: 6 }) {
        ForEach(['Yes', 'Maybe', 'No'], (value: string) => {
          Button(value).layoutWeight(1).height(48).backgroundColor(this.repeatFeedback === value ? '#287452' : '#E1EEE8').fontColor(this.repeatFeedback === value ? '#FFFFFF' : '#203C31')
            .onClick(() => { this.repeatFeedback = value; this.recordBehavior('FEEDBACK_SUBMITTED'); })
        })
      }.width('100%')
      Button('Skip feedback').width('100%').height(48).backgroundColor('#E1EEE8').fontColor('#203C31').onClick(() => { this.childFeedback = ''; this.difficultyFeedback = ''; this.repeatFeedback = ''; this.recordBehavior('FEEDBACK_SUBMITTED'); })
    }.width('100%')
  }
  @Builder
  insightsContent() {
    Column({ space: 14 }) {
      this.heading('Activity Insights')
      Text('What kinds of activities are working well?').fontSize(17)
      Row({ space: 6 }) {
        ForEach([1, 7, 30], (days: number) => { Button(days === 1 ? 'Today' : `Last ${days} days`).layoutWeight(1).onClick(() => { this.insightDays = days; }) })
      }.width('100%')
      Text(`${BehaviorInsightEngine.metrics(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())).completed} activities marked complete`).fontSize(23).fontWeight(FontWeight.Bold)
      Text(`${BehaviorInsightEngine.guidedMinutes(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now()), '')} planned guided minutes marked complete`).fontSize(16)
      Text('What we noticed').fontSize(22).fontWeight(FontWeight.Bold)
      ForEach(BehaviorInsightEngine.observations(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())), (line: string) => { Text(line).fontSize(16).width('100%') })
      Text('Activity balance').fontSize(22).fontWeight(FontWeight.Bold)
      ForEach(WORK_TYPES, (type: string) => {
        Text(`${type}: ${BehaviorInsightEngine.metrics(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now()).filter((e: ChildInteractionEvent) => e.activityCategory === type)).completed} marked complete`).fontSize(16).width('100%')
        Progress({ value: BehaviorInsightEngine.metrics(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now()).filter((e: ChildInteractionEvent) => e.activityCategory === type)).completed,
          total: Math.max(1, BehaviorInsightEngine.metrics(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())).completed), type: ProgressType.Linear }).width('100%')
      })
      Text('Interactive vs video').fontSize(22).fontWeight(FontWeight.Bold)
      ForEach(BehaviorInsightEngine.formats(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())), (line: string) => { Text(line).fontSize(15).width('100%') })
      Text('Challenge response').fontSize(22).fontWeight(FontWeight.Bold)
      ForEach(BehaviorInsightEngine.challenge(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())), (line: string) => { Text(line).fontSize(16).width('100%') })
      Text(`${BehaviorInsightEngine.metrics(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())).correct} correct task responses / ${BehaviorInsightEngine.metrics(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now())).attempted} answers selected`).fontSize(16)
      ForEach(['Too easy', 'Just right', 'Too hard'], (value: string) => { Text(`${value}: ${BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now()).filter((e: ChildInteractionEvent) => e.eventType === 'FEEDBACK_SUBMITTED' && e.difficultyFeedback === value).length} feedback responses`).fontSize(15) })
      Text('Last seven days').fontSize(22).fontWeight(FontWeight.Bold)
      Text('Planned guided minutes marked complete, not measured exercise or learning. Demo excluded.').fontSize(13)
      ForEach(BehaviorInsightEngine.weekly(this.behavior, Date.now()), (line: string) => { Text(line).fontSize(14).width('100%') })
      Text('Recent activity').fontSize(22).fontWeight(FontWeight.Bold)
      ForEach(BehaviorInsightEngine.window(this.behavior, this.insightDays, Date.now()).filter((e: ChildInteractionEvent) => ['ACTIVITY_COMPLETED', 'ACTIVITY_SKIPPED'].includes(e.eventType)).slice(-5).reverse(), (event: ChildInteractionEvent) => { Text(`${event.activityCategory} ? ${event.gameType || event.activityMode} ? ${event.eventType === 'ACTIVITY_COMPLETED' ? 'Marked complete' : 'Skipped'} ? ${this.dateLabel(event.timestamp)}`).fontSize(14).width('100%') })
      Text('Activity Insights summarize CompanionOS usage and child-confirmed activity interactions. They help parents understand activity preferences and engagement patterns. They are not medical, psychological or developmental assessments. Demo activities and unknown historical interaction data are excluded.').fontSize(13)
      Button('Reset local insights').width('100%').onClick(() => { this.getUIContext().showAlertDialog({ title: 'Reset insights?', message: 'Only interaction events are removed. Your completion journal stays.', primaryButton: { value: 'Keep', action: () => {} }, secondaryButton: { value: 'Reset', action: () => { const empty = new BehaviorData(); try { this.behaviorStore?.save(empty); this.behavior = empty; } catch { this.notice = 'Reset failed. Try again.'; } } } }); })
    }.width('100%')
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
  heroCard() {
    Column({ space: 10 }) {
      Row({ space: 12 }) {
        Image($rawfile('work-hero.svg')).width(110).height(98).objectFit(ImageFit.Contain)
        Column({ space: 6 }) {
          Text('PARENT WORK SESSION').fontSize(11).fontWeight(FontWeight.Bold).fontColor('#314D40').width('100%')
          Text('A little adventure for them. A little room for you to focus.').fontSize(17).fontWeight(FontWeight.Medium)
            .fontColor('#203C31').width('100%')
          Text(`${this.data.settings.sessionDuration} min suggested`).fontSize(12).fontWeight(FontWeight.Medium)
            .fontColor('#314D40').padding({ left: 8, right: 8, top: 4, bottom: 4 }).backgroundColor('#FFFFFF').borderRadius(12)
        }.layoutWeight(1)
      }.width('100%')
      Button(this.work.phase === 'active' ? 'Return to work session' : 'Start Parent Work Session')
        .width('100%').height(50).fontSize(16).fontWeight(FontWeight.Bold).backgroundColor('#287452').fontColor('#FFFFFF')
        .borderRadius(18).stateEffect(true).shadow({ radius: 5, color: '#14287452', offsetY: 2 })
        .onClick(() => { this.navigate(this.work.phase === 'active' ? 'work-status' : 'work-setup'); })
      Text(`Interactive + video + guided activities | ${this.data.settings.balanceRules.preset}`).fontSize(12).fontColor('#314D40').width('100%')
      Row({ space: 6 }) {
        ForEach(WORK_TYPES, (type: string) => { Text(`${type} ${planWork(this.data.settings.sessionDuration, this.data.settings).entries.filter((entry) => entry.category === type).reduce((sum: number, entry) => sum + entry.minutes, 0)}m`).fontSize(11).layoutWeight(1) })
      }.width('100%')
      Text('Plan 15-60 minutes of guided activities').fontSize(13).fontColor('#314D40').width('100%')
    }.width('100%').padding(14).backgroundColor('#E6F0E9').borderRadius(22)
      .border({ width: 1, color: '#C5D8CD' }).shadow({ radius: 6, color: '#0A203C31', offsetY: 2 })
      .scale({ x: this.pressedCard === 'hero' ? 0.99 : 1, y: this.pressedCard === 'hero' ? 0.99 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => { this.pressedCard = event.type === TouchType.Down ? 'hero' : ''; })
      .accessibilityGroup(true).accessibilityText('Parent Work Session. Plan fifteen to sixty minutes. Tap to prepare or return to your session.')
      .onClick(() => { this.navigate(this.work.phase === 'active' ? 'work-status' : 'work-setup'); })
  }

  private categoryInk(type: string): string {
    return type === 'MOVE' ? '#773D19' : type === 'LEARN' ? '#24526B' : type === 'CREATE' ? '#60387D' : '#2B5942';
  }

  @Builder
  typeTiles(types: string[]) {
    Row({ space: 10 }) {
      ForEach(types, (type: string) => {
        Column({ space: 5 }) {
          Row({ space: 6 }) {
            Image($rawfile(`${type}.svg`)).height(38).width(38).objectFit(ImageFit.Contain)
            Text(type).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.categoryInk(type)).layoutWeight(1)
          }.width('100%')
          Text(type === 'MOVE' ? 'Gentle energy' : type === 'LEARN' ? 'Discover something' : type === 'CREATE' ? 'Make and imagine' : 'Slow down & reset')
            .fontSize(12).fontColor('#374B40').width('100%')
        }.layoutWeight(1).padding(12).constraintSize({ minHeight: 90 }).borderRadius(18).backgroundColor(this.typeColor(type))
          .border({ width: 1, color: '#CAD3CA' })
          .scale({ x: this.pressedCard === type ? 0.98 : 1, y: this.pressedCard === type ? 0.98 : 1 })
          .animation({ duration: 120, curve: Curve.EaseOut })
          .onTouch((event: TouchEvent) => { this.pressedCard = event.type === TouchType.Down ? type : ''; })
          .accessibilityGroup(true).accessibilityText(`${type} activities. Tap to browse.`)
          .onClick(() => { this.filter = type; this.navigate('activities'); })
      })
    }.width('100%')
  }

  @Builder
  activityCard(activity: Activity) {
    Row({ space: 12 }) {
      Image($rawfile(`${this.activityArt(activity)}.svg`)).height(92).width(78).objectFit(ImageFit.Contain)
        .backgroundColor(this.typeColor(activity.category)).borderRadius(16)
      Column({ space: 5 }) {
        Text(activity.title).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
        Row({ space: 6 }) {
          Text(activity.category).fontSize(11).fontWeight(FontWeight.Bold).fontColor(this.categoryInk(activity.category))
            .padding({ left: 7, right: 7, top: 3, bottom: 3 }).backgroundColor(this.typeColor(activity.category)).borderRadius(8)
          Text(`${this.data.settings.minutes} min`).fontSize(12).fontColor('#3D5145')
        }.width('100%')
        Text('Indoor-friendly | Adult nearby').fontSize(12).fontColor('#3D5145').width('100%')
        Row() {
          Text('Offline activity').fontSize(12).fontColor('#3D5145').layoutWeight(1)
          Text('Start >').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#236144')
        }.width('100%')
      }.layoutWeight(1)
    }.width('100%').padding(12).backgroundColor('#FFFFFF').borderRadius(18)
      .border({ width: 1, color: '#D3DDD4' }).shadow({ radius: 4, color: '#08203C31', offsetY: 2 })
      .scale({ x: this.pressedCard === activity.id ? 0.985 : 1, y: this.pressedCard === activity.id ? 0.985 : 1 })
      .animation({ duration: 120, curve: Curve.EaseOut })
      .onTouch((event: TouchEvent) => { this.pressedCard = event.type === TouchType.Down ? activity.id : ''; })
      .accessibilityGroup(true).accessibilityText(`${activity.title}. ${activity.category}. ${this.data.settings.minutes} minutes. Indoor activity, adult nearby. Tap to review before starting.`)
      .onClick(() => this.openActivity(activity))
  }

  @Builder
  fallbackContent() {
    Column({ space: 12 }) {
      Text('Ready for a little adventure?').fontSize(25).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      Text("Don't just limit screen time. Transform it.").fontSize(14).fontWeight(FontWeight.Medium).fontColor('#3D5145').width('100%')
      if (this.work.phase !== 'active' && ['running', 'paused', 'ready'].includes(this.phase)) {
        Button('Return to activity').width('100%').backgroundColor('#287452').onClick(() => this.navigate('activity'))
      }
      this.heroCard()
      Button('Play interactive adventures').width('100%').height(50).onClick(() => this.navigate('games'))
      Button(`Daily Adventure: ${worldName(Date.now())}`).width('100%').height(50).onClick(() => { this.navigate(this.work.phase === 'active' ? 'work-status' : 'daily'); })
      Button('Adventure Journey').width('100%').onClick(() => this.navigate('journey'))
      Text('Quick Activities').fontSize(21).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      this.typeTiles(WORK_TYPES.slice(0, 2))
      this.typeTiles(WORK_TYPES.slice(2))
      Text('Recommended for your child').fontSize(21).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      ForEach(this.catalog().filter((activity: Activity) => this.data.settings.interests.includes(activity.interest)).slice(0, 2),
        (activity: Activity) => { this.activityCard(activity) }, (activity: Activity) => activity.id)
      Column({ space: 7 }) {
        Row() {
          Text("Today's progress").fontSize(19).fontWeight(FontWeight.Bold).fontColor('#203C31').layoutWeight(1)
          Text('Journal >').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#236144')
        }.width('100%')
        Text(`${this.today} activities confirmed today`).fontSize(21).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
        Text(`${this.data.total} moments saved | Includes labelled Demo completions`).fontSize(12).fontColor('#3D5145').width('100%')
        Progress({ value: Math.min(this.data.total, 10), total: 10, type: ProgressType.Linear }).width('100%').color('#287452')
          .animation({ duration: 160, curve: Curve.EaseOut })
        Text(this.data.total >= 10 ? 'Family Explorer badge earned' : `${Math.min(this.data.total, 10)} / 10 moments toward Family Explorer`)
          .fontSize(12).fontColor('#3D5145').width('100%')
      }.padding(14).width('100%').backgroundColor('#EEE9DE').borderRadius(18).border({ width: 1, color: '#D8D2C4' })
        .accessibilityGroup(true).accessibilityText(`Today's progress. ${this.today} activities confirmed today; ${this.data.total} saved in total, including Demo completions. Tap for journal.`)
        .onClick(() => this.navigate('progress'))
      Text('An adult stays available. CompanionOS does not replace appropriate supervision.').fontSize(12).fontColor('#3D5145').width('100%')
    }.width('100%')
  }

  @Builder
  homeContent() {
    Column({ space: 16 }) {
      ParentDashboard({ settings: this.data.settings })
      Button('Parent Settings').width('100%').onClick(() => this.openSettings())
      Button('Video library: Built-in, AI and My Video').width('100%').onClick(() => this.navigate('games'))
      Button('Phone-only fallback activities').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D').onClick(() => this.navigate('phone-fallback'))
      Button('Phone fallback Activity Insights').width('100%').onClick(() => this.navigate('insights'))
      Button('Progress and parent-confirmed records').width('100%').onClick(() => this.navigate('progress'))
    }.width('100%')
  }

  @Builder
  discoveryContent() {
    Column({ space: 16 }) {
      this.heading('Find their next adventure')
      Text('Short, guided activities. Prepared for home.').fontSize(15).fontColor('#59695F').width('100%')
      Row({ space: 5 }) {
        ForEach(['ALL', ...WORK_TYPES], (type: string) => {
          Button(type === 'ALL' ? 'All' : type).fontSize(11).padding({ left: 3, right: 3 }).layoutWeight(1).height(44)
            .backgroundColor(this.filter === type ? '#294E3D' : '#E8EDE6').fontColor(this.filter === type ? '#FFFFFF' : '#294E3D')
            .onClick(() => { this.filter = type; })
        })
      }.width('100%')
      ForEach(this.catalog(), (activity: Activity) => { this.activityCard(activity) }, (activity: Activity) => activity.id)
      Button(this.aiLoading ? 'Finding a match...' : 'Find a match').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D')
        .enabled(!this.aiLoading).onClick(() => { this.recommendActivity(); })
      if (this.recommendation !== '') { Text(this.recommendation).fontSize(15).fontColor('#426352').width('100%') }
    }.width('100%')
  }

  @Builder
  workSetupContent() {
    Column({ space: 16 }) {
      this.heading('Your focus time. Their adventure.')
      Image($rawfile('work-hero.svg')).width('100%').height(180).objectFit(ImageFit.Contain)
      Text('Choose a work window').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
      Row({ space: 8 }) {
        ForEach([15, 30, 45, 60], (minutes: number) => {
          Button(`${minutes} min`).fontSize(14).padding({ left: 4, right: 4 }).layoutWeight(1).height(48)
            .backgroundColor(this.workMinutes === minutes ? '#294E3D' : '#E1EEE8').fontColor(this.workMinutes === minutes ? '#FFFFFF' : '#294E3D')
            .onClick(() => { this.workMinutes = minutes; })
        })
      }.width('100%')
      this.balanceControls()
      Text('How should CompanionOS prepare activities?').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
      Row({ space: 6 }) {
        ForEach(WORK_TYPES.filter((type: string) => this.data.settings.preferredActivityTypes.includes(type)), (type: string) => {
          Column({ space: 4 }) {
            Image($rawfile(`${type}.svg`)).width(46).height(46).objectFit(ImageFit.Contain)
            Text(type).fontSize(11).fontWeight(FontWeight.Bold)
            Text(`${planWork(this.workMinutes, this.previewSettings()).entries.filter((entry) => entry.category === type).reduce((sum: number, entry) => sum + entry.minutes, 0)} min`).fontSize(13)
          }.layoutWeight(1).padding(8).backgroundColor(this.typeColor(type)).borderRadius(16)
        })
      }.width('100%')
      ForEach(PREPARATIONS, (source: string) => {
        Button(`${this.preparation === source ? 'Selected: ' : ''}${source}`).width('100%').height(46)
          .backgroundColor(this.preparation === source ? '#294E3D' : '#FFFFFF').fontColor(this.preparation === source ? '#FFFFFF' : '#294E3D')
          .onClick(() => { this.preparation = source; })
      })
      Text('Recommended uses safe Built-in activities. Other sources remain optional and are prepared and reviewed before each activity. AI failure never blocks Built-in content.').fontSize(14).fontColor('#59695F')
      Text(`${SessionBalanceEngine.plan(this.workMinutes, this.workRules).filter((slot) => slot.mode === 'VIDEO').reduce((sum: number, slot) => sum + slot.minutes, 0)} video minutes + interactive and guided activities`).fontSize(16).width('100%')
      Text(`${SessionBalanceEngine.plan(this.workMinutes, this.workRules).length} short activities | Breaks are welcome | No strict continuous schedule`).fontSize(15).fontColor('#426352').width('100%')
      Text('An adult sets up a clear space, stays available and checks each activity. Younger children may need closer supervision. No climbing, jumping, sharp tools or outdoor tasks.').fontSize(14).fontColor('#59695F')
      Button('Prepare work session').width('100%').height(54).backgroundColor('#294E3D').enabled(this.storageReady && !this.busy && validRules(this.workRules))
        .onClick(() => this.startWork())
    }.width('100%')
  }

  @Builder
  workStatusContent() {
    Column({ space: 16 }) {
      this.heading('Your work session')
      Image($rawfile(`${this.work.entries[this.work.index]?.category || 'CALM'}.svg`)).width('100%').height(160).objectFit(ImageFit.Contain)
      Text(this.selected.title).fontSize(26).fontWeight(FontWeight.Bold).width('100%')
      Text(`Status: ${this.phase === 'idle' ? 'Ready to review' : this.phase === 'ready' ? 'Awaiting parent confirmation' : this.phase === 'running' ? 'Playing' : 'Paused'}`).fontSize(18).width('100%')
      Text(`Remaining planned activities: ${remainingWork(this.work)} min`).fontSize(20).fontWeight(FontWeight.Bold).fontColor('#426352')
      Text(`Activities completed: ${this.work.entries.filter((entry) => entry.outcome === 'completed').length} / ${this.work.entries.length}`).fontSize(17)
      Text('Planned time is an estimate. Breaks and parent review may extend your work window.').fontSize(13).fontColor('#59695F')
      Button(this.phase === 'idle' ? 'Review next activity' : 'Open child view').width('100%').onClick(() => this.navigate('activity'))
      if (this.phase === 'running') { Button('Pause').width('100%').onClick(() => { this.pauseActivity(); this.persistWork(); }) }
      if (this.phase === 'paused') { Button('Resume').width('100%').onClick(() => { this.resumeActivity(); this.persistWork(); }) }
      Button('Change Activity').width('100%').onClick(() => this.skipWorkEntry())
      Button('End Session').width('100%').backgroundColor('#EEE9DE').fontColor('#694B3B').onClick(() => this.finishWork())
      Text('CompanionOS supports independent activity but does not replace appropriate adult supervision.').fontSize(13).fontColor('#59695F')
    }.padding(20).width('100%').backgroundColor('#FFFFFF').borderRadius(24)
  }

  @Builder
  workSummaryContent() {
    Column({ space: 16 }) {
      Image($rawfile('CALM.svg')).width('100%').height(170).objectFit(ImageFit.Contain)
      if (this.work.daily && this.work.phase === 'completed') { Text("Today's adventure is complete! Great work. A new adventure will be waiting tomorrow.").fontSize(24).fontWeight(FontWeight.Bold) }
      this.heading(this.work.phase === 'completed' ? 'Work Session Complete' : 'Work Session Ended')
      Text(`${this.work.minutes} minutes planned`).fontSize(24).fontWeight(FontWeight.Bold)
      Text(`${this.work.entries.filter((entry) => entry.outcome === 'completed').length} activities confirmed`).fontSize(20)
      ForEach(WORK_TYPES, (type: string) => {
        Text(`${type}: ${this.work.entries.filter((entry) => entry.category === type).reduce((sum: number, entry) => sum + entry.minutes, 0)} min planned`).fontSize(16).width('100%')
        Text(`${categoryMinutes(this.work, type)} min marked complete (non-Demo)`).fontSize(18).width('100%')
        Progress({ value: categoryMinutes(this.work, type), total: Math.max(1, this.work.entries.filter((entry) => entry.category === type).reduce((sum: number, entry) => sum + entry.minutes, 0)), type: ProgressType.Linear }).width('100%')
      })
      ForEach(['INTERACTIVE', 'VIDEO', 'GUIDED_OFFSCREEN'], (mode: string) => { Text(`${mode}: ${this.work.entries.filter((entry) => entry.mode === mode).reduce((sum: number, entry) => sum + entry.minutes, 0)} min planned / ${this.work.entries.filter((entry) => entry.mode === mode && entry.outcome === 'completed' && !entry.demo).reduce((sum: number, entry) => sum + entry.minutes, 0)} min marked complete`).fontSize(14).width('100%') })
      Text('Completed minute totals are planned durations marked complete, not measured exercise or learning.').fontSize(13)
      if (this.work.daily) { Button('View Adventure Journey').width('100%').onClick(() => this.navigate('journey')) }
      Button('Activity Insights').width('100%').onClick(() => this.navigate('insights'))
      Text(`${this.work.entries.filter((entry) => entry.outcome === 'skipped').length} activities skipped`).fontSize(18)
      Text('These are planned durations of confirmed activities, not measured movement or developmental outcomes. Demo activities are excluded from minute totals.').fontSize(13).fontColor('#59695F')
      Button('Back to Home').width('100%').onClick(() => this.navigate('home'))
      Button('View activity journal').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D').onClick(() => this.navigate('progress'))
    }.width('100%')
  }

  @Builder
  settingsContent() {
    Column({ space: 16 }) {
      this.heading('Child Profile & Parent Settings')
      Button('Activity Insights').width('100%').onClick(() => this.navigate('insights'))
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
      Text('Preferred activity types').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
      Row({ space: 6 }) {
        ForEach(WORK_TYPES, (type: string) => {
          Button(type).fontSize(12).padding({ left: 4, right: 4 }).layoutWeight(1).height(46)
            .backgroundColor(this.draft.preferredActivityTypes.includes(type) ? '#294E3D' : '#E1EEE8')
            .fontColor(this.draft.preferredActivityTypes.includes(type) ? '#FFFFFF' : '#294E3D')
            .onClick(() => { this.draft.preferredActivityTypes = this.draft.preferredActivityTypes.includes(type) ?
              this.draft.preferredActivityTypes.filter((value: string) => value !== type) : [...this.draft.preferredActivityTypes, type]; })
        })
      }.width('100%')
      Text('Preferred work window').fontSize(20).width('100%')
      Row({ space: 6 }) {
        ForEach([15, 30, 45, 60], (minutes: number) => {
          Button(`${minutes} min`).fontSize(13).layoutWeight(1)
            .backgroundColor(this.draft.sessionDuration === minutes ? '#294E3D' : '#E1EEE8')
            .fontColor(this.draft.sessionDuration === minutes ? '#FFFFFF' : '#294E3D')
            .onClick(() => { this.draft.sessionDuration = minutes; })
        })
      }.width('100%')
      Text('Activity difficulty').fontSize(20).width('100%')
      Row({ space: 12 }) {
        ForEach(['Gentle', 'Standard'], (difficulty: string) => {
          Button(difficulty).layoutWeight(1).backgroundColor(this.draft.activityDifficulty === difficulty ? '#294E3D' : '#E1EEE8')
            .fontColor(this.draft.activityDifficulty === difficulty ? '#FFFFFF' : '#294E3D')
            .onClick(() => { this.draft.activityDifficulty = difficulty; })
        })
      }.width('100%')
      Text('Safety defaults').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
      Row() {
        Text('Indoor only').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.draft.indoorOnly }).onChange((value: boolean) => { this.draft.indoorOnly = value; })
      }.width('100%')
      Row() {
        Text('No jumping').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.draft.noJumping }).onChange((value: boolean) => { this.draft.noJumping = value; })
      }.width('100%')
      Row() {
        Text('Low intensity').layoutWeight(1)
        Toggle({ type: ToggleType.Switch, isOn: this.draft.lowIntensity }).onChange((value: boolean) => { this.draft.lowIntensity = value; })
      }.width('100%')
      Text('Built-in activities remain indoor, gentle and jump-free even when a preference is off. No climbing or sharp tools. No camera, microphone, location or emotion monitoring.').fontSize(14).fontColor('#59695F')
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
    if (['running', 'paused', 'ready'].includes(this.phase)) { this.childContent() }
    else {
      Column({ space: 16 }) {
        Image($rawfile(`${this.activityArt(this.selected)}.svg`)).width('100%').height(180).objectFit(ImageFit.Contain)
          .backgroundColor(this.typeColor(this.selected.category)).borderRadius(26)
        Text(this.selected.title).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
        Text(`${this.selected.category} | Ages ${this.data.settings.age} | ${this.work.phase === 'active' ? this.work.entries[this.work.index].minutes : this.data.settings.minutes} min`)
          .fontSize(16).fontColor('#426352').width('100%')
        Text(this.activitySource).fontSize(13).fontColor('#59695F').width('100%')
        Column({ space: 8 }) {
          Text('Why this activity?').fontSize(20).fontWeight(FontWeight.Bold).width('100%')
          Text(`Short ${this.selected.category.toLowerCase()} practice | ${this.selected.educationalGoal}`).fontSize(16).width('100%')
          Text(this.activityMode === 'INTERACTIVE' ? 'Interactive rather than passive video. Task responses stay on this device.' : 'Guided activity: completion is confirmed, not sensor-verified.').fontSize(14).width('100%')
          Text(this.preferenceExplanation()).fontSize(14).width('100%')
          Text(`Interest: ${this.selected.interest} | Indoor-friendly | Gentle instructions`).fontSize(15).width('100%')
          Text('Adult nearby and available. Younger children may need closer support.').fontSize(14).width('100%')
        }.padding(18).width('100%').backgroundColor('#E1EEE8').borderRadius(20)
        ForEach(this.selected.steps, (step: string, index: number) => {
          Text(`${index + 1}. ${step}`).fontSize(16).fontColor('#253E33').padding(16).width('100%').backgroundColor('#FFFFFF').borderRadius(16)
        }, (step: string) => step)
        if (this.work.phase === 'active') { Text(`Preparation preference: ${this.work.preparation}. Review optional content below; Built-in is always ready.`).fontSize(14).fontColor('#59695F') }
        this.contentChoices()
        Row({ space: 8 }) {
          Checkbox({ name: 'demoMode' }).select(this.demo).selectedColor('#294E3D').onChange((value: boolean) => { this.demo = value; })
          Text('Demo Mode - 10-second countdown').fontSize(15).layoutWeight(1)
        }
        Button('Start activity').width('100%').height(54).backgroundColor('#294E3D')
          .enabled(!this.backendLoading && !this.importingVideo).onClick(() => this.startActivity())
        Button('Play on Large Screen').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D').onClick(() => this.showTv())
        Text('CompanionOS supports independent activity but does not replace appropriate adult supervision.').fontSize(13).fontColor('#59695F')
      }.width('100%')
    }
  }

  @Builder
  childContent() {
    Column({ space: 16 }) {
      Text(this.selected.title).fontSize(28).fontWeight(FontWeight.Bold).fontColor('#253E33').width('100%')
      if (this.activityMode === 'INTERACTIVE' && this.game.id !== '') { this.interactionContent() }
      if (this.phase !== 'ready' && this.activityMode === 'VIDEO') {
        if (this.selected.category === 'LEARN' && this.selected.contentSource === ActivityContentSource.BUILT_IN) { Text(`Count together: ${Math.min(5, Math.floor(((this.demo ? 10 : this.session.minutes * 60) - this.remaining) % 10 / 2) + 1)} dinosaurs. One, two, three, four, five!`).fontSize(24).fontWeight(FontWeight.Bold) }
        if (this.selected.category === 'CALM' && this.selected.contentSource === ActivityContentSource.BUILT_IN) { Text('A cloud drifts slowly. Breathe normally and relax your hands.').fontSize(22) }
        Video({ src: this.selected.contentSource === ActivityContentSource.USER_VIDEO ? `file://${this.selected.localVideoPath}` :
          (this.selected.activitySteps[this.stepIndex]?.videoUrl || $rawfile('fallback.mp4')), controller: this.phoneVideoController })
          .width('100%').height(220).controls(false).autoPlay(false).loop(true).muted(true)
          .onStart(() => { console.info('[CompanionVideo] native playback started'); })
          .onPrepared(() => { if (this.phase === 'running') { try { this.phoneVideoController.start(); } catch {} } })
          .onDisAppear(() => { try { this.phoneVideoController.pause(); } catch {} })
          .onError(() => { this.notice = 'Video unavailable. Follow the safe illustrated instructions below; the activity continues.'; })
      }
      Text(this.phase === 'ready' ? (this.activityMode === 'INTERACTIVE' && !this.gameSolved ? 'The activity window has ended. Finish the challenge or take a break.' : 'Lovely effort! Check in with your adult.') : this.phase === 'paused' ? 'Take a gentle break.' : this.selected.steps[this.stepIndex])
        .fontSize(25).fontWeight(FontWeight.Medium).fontColor('#253E33').width('100%')
      Progress({ value: this.stepIndex + 1, total: this.selected.steps.length, type: ProgressType.Linear }).width('100%').color('#547963')
        .animation({ duration: 200, curve: Curve.EaseOut })
      Row() {
        Text(`Step ${this.stepIndex + 1} of ${this.selected.steps.length}`).fontSize(15).fontColor('#59695F').layoutWeight(1)
        Text(this.phase === 'ready' ? 'Finished' : this.clockLabel()).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#294E3D')
      }.width('100%')
      if (this.game.id !== '') { Text('Built-in interactive game. Optional AI/video guidance is selected separately.').fontSize(13).fontColor('#36584A') }
      Text(this.demo ? 'Demo - 10-second activity window; movement challenge 3 seconds' : 'Play gently. Rest whenever you need.').fontSize(13).fontColor('#59695F')
      Button(this.parentControls ? 'Close parent controls' : 'Parent controls').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D')
        .onClick(() => {
          if (this.parentControls) { this.parentControls = false; }
          else { this.getUIContext().showAlertDialog({ title: 'Parent controls', message: 'Please hand the phone to your parent or caregiver.',
            primaryButton: { value: 'I am the parent', action: () => { this.parentControls = true; } },
            secondaryButton: { value: 'Keep playing', action: () => {} } }); }
        })
      if (this.parentControls || this.phase === 'ready') {
        if (this.phase === 'running') { Button('Pause activity').width('100%').onClick(() => { this.pauseActivity(); this.persistWork(); }) }
        if (this.phase === 'paused') { Button('Resume activity').width('100%').onClick(() => { this.resumeActivity(); this.persistWork(); }) }
        if (this.phase !== 'ready') {
          Row({ space: 10 }) {
            Button('Previous step').layoutWeight(1).enabled(this.stepIndex > 0).onClick(() => this.previousStep())
            Button('Next step').layoutWeight(1).enabled(this.stepIndex < this.selected.steps.length - 1).onClick(() => this.nextStep())
          }.width('100%')
        }
        if (this.phase === 'ready') {
          this.feedbackContent()
          Row({ space: 8 }) {
            Checkbox({ name: 'confirmParent' }).select(this.confirmed).selectedColor('#294E3D').enabled(!this.busy)
              .onChange((value: boolean) => { this.confirmed = value; })
            Text('I am the parent / caregiver. I confirm this activity was completed.').fontSize(16).layoutWeight(1)
          }
          Button(this.busy ? 'Saving...' : 'Mark as completed').width('100%').backgroundColor('#294E3D')
            .enabled(this.confirmed && !this.busy && this.storageReady && (this.activityMode !== 'INTERACTIVE' || this.gameSolved)).onClick(() => { this.completeActivity(); })
        }
        if (this.work.phase === 'active') { Button('Parent work view').width('100%').onClick(() => this.navigate('work-status')) }
        Button('Play on Large Screen').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D').onClick(() => this.showTv())
        Button(this.work.phase === 'active' ? 'Change Activity' : 'Cancel activity').width('100%').backgroundColor('#EEE9DE').fontColor('#694B3B')
          .enabled(!this.busy).onClick(() => { if (this.work.phase === 'active') { this.skipWorkEntry(); } else { this.cancelActivity(); } })
      }
    }.width('100%')
  }

  @Builder
  contentChoices() {
    Column({ space: 10 }) {
      Text(this.selected.category === 'LEARN' ? 'How would you like to learn?' : 'How should we prepare this activity?').fontSize(23).fontWeight(FontWeight.Bold).width('100%')
      if (['LEARN', 'MOVE'].includes(this.selected.category)) {
        ForEach(GAME_IDS.filter((id: string) => gameDefinition(id).category === this.selected.category), (id: string) => { Button(`Play ${gameDefinition(id).title}`).width('100%').height(50).onClick(() => this.openGame(id)) })
      }
      Button('Watch an adventure').width('100%').height(50).onClick(() => this.chooseBuiltIn(true))
      if (this.game.id === 'robot-memory') { Row({ space: 6 }) { ForEach(['Gentle', 'Standard', 'Hard'], (level: string) => { Button(level === 'Gentle' ? 'Easy: 2' : level === 'Standard' ? 'Medium: 3' : 'Hard: 4').layoutWeight(1).onClick(() => { this.game = GameEngine.create('robot-memory', level); this.gameLevel = level; }) }) }.width('100%') }
      Button('Recommended').width('100%').enabled(!this.backendLoading && !this.importingVideo).onClick(() => this.chooseBuiltIn())
      Text('Safe Built-in content, ready without a network.').fontSize(14)
      Button('Gemini AI').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => { this.createAdventure('GEMINI'); })
      Text('Create a personalized activity with Gemini').fontSize(14).width('100%')
      Button('Huawei AI').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => { this.createAdventure('HUAWEI'); })
      Text('Create a personalized activity with Huawei Cloud AI').fontSize(14).width('100%')
      Button('Built-in Video').width('100%').enabled(!this.backendLoading && !this.importingVideo)
        .onClick(() => this.chooseBuiltIn(true))
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
      this.heading('Play on Large Screen')
      Button('Continue on phone').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D')
        .onClick(() => this.navigate('activity'))
      Text(`Connection: ${this.tvConnection}`).fontSize(22).fontColor('#28745E')
      Text('Nearby devices').fontSize(22).fontWeight(FontWeight.Bold)
      Text(this.nearby).fontSize(16)
      Button('Search nearby devices').enabled(this.tvConnection !== 'Searching').onClick(() => { this.searchTv(); })
      Text('Nearby discovery needs a compatible receiver. Connect to Emulator Tablet below for the relay demo, or use Local Demo without another device.').fontSize(16)
      Button('Demo Large Screen Mode').enabled(this.tvConnection !== 'Connecting').onClick(() => { this.connectDemoTv(); })
      Text('Emulator Tablet + AI backend').fontSize(22).fontWeight(FontWeight.Bold)
      TextInput({ text: this.backendUrl, placeholder: 'Backend base URL' }).onChange((value: string) => { this.backendUrl = value; })
      TextInput({ text: this.roomCode, placeholder: 'Room code' }).maxLength(32).onChange((value: string) => { this.roomCode = value; })
      Button('Connect to Emulator Tablet').enabled(this.tvConnection !== 'Connecting').onClick(() => { this.connectEmulatorTv(); })
      if (this.tvConnection === 'Connected') {
        Text(this.transportMode === 'demo' ? 'Connected • Local Demo Large Screen' : 'Connected • Separate Emulator Tablet').fontSize(20)
        Button(this.transportMode === 'demo' ? 'View Demo Large Screen' : 'Phone controller').onClick(() => {
          if (this.transportMode === 'demo') { this.showTv(); } else { this.navigate('activity'); }
        })
        Button('Disconnect Large Screen').onClick(() => this.disconnectTv())
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
        Text(this.tvFrame.title || 'Companion Large Screen').fontSize(28).fontWeight(FontWeight.Bold).layoutWeight(1)
        Text('LOCAL DEMO LARGE SCREEN').fontSize(14)
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
      Button('Activity Insights').width('100%').onClick(() => this.navigate('insights'))
      Text(`Completed today: ${this.today} • Total completions: ${this.data.total}`).fontSize(20).fontColor('#28745E').width('100%')
      if (this.work.phase === 'completed' || this.work.phase === 'ended') {
        Button('Latest work session summary').width('100%').backgroundColor('#E1EEE8').fontColor('#294E3D')
          .onClick(() => this.navigate('work-summary'))
      }
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
      }.width('100%').padding({ left: 16, right: 16, top: 10, bottom: 10 })
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          if (this.notice !== '') {
            Text(this.notice).fontSize(15).fontColor('#6B451C').padding(16).width('100%').backgroundColor('#FFF0D9').borderRadius(14)
          }
          if (this.screen === 'home') { this.homeContent() }
          else if (this.screen === 'daily') { this.dailyContent() }
          else if (this.screen === 'games') { this.gamesContent() }
          else if (this.screen === 'journey') { this.journeyContent() }
          else if (this.screen === 'activities') { this.discoveryContent() }
          else if (this.screen === 'work-setup') { this.workSetupContent() }
          else if (this.screen === 'work-status') { this.workStatusContent() }
          else if (this.screen === 'work-summary') { this.workSummaryContent() }
          else if (this.screen === 'settings') { this.settingsContent() }
          else if (this.screen === 'phone-fallback') { this.fallbackContent() }
          else if (this.screen === 'insights') { this.insightsContent() }
          else if (this.screen === 'progress') { this.progressContent() }
          else if (this.screen === 'connect') { this.connectionContent() }
          else { this.activityContent() }
          Text('Small adventures. Space to focus.').fontSize(12).fontColor('#52645C').padding({ top: 12, bottom: 24 })
        }.width('100%').padding({ left: 16, right: 16, top: 4 })
      }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Auto)
      if (['home', 'activities', 'progress', 'settings'].includes(this.screen)) {
        Row() {
          ForEach(['home', 'activities', 'progress', 'settings'], (tab: string) => {
            Column({ space: 2 }) {
              Image($rawfile(`${tab === 'home' ? 'CALM' : tab === 'activities' ? 'MOVE' : tab === 'progress' ? 'LEARN' : 'CREATE'}.svg`))
                .width(26).height(24).objectFit(ImageFit.Contain)
              Text(tab === 'settings' ? 'Parent' : tab.charAt(0).toUpperCase() + tab.slice(1)).fontSize(12)
                .fontWeight(this.screen === tab ? FontWeight.Bold : FontWeight.Medium).fontColor(this.screen === tab ? '#1E583C' : '#415248')
            }.layoutWeight(1).height(52).justifyContent(FlexAlign.Center).borderRadius(14)
              .border({ width: this.screen === tab ? 1 : 0, color: '#9FC3AC' })
              .backgroundColor(this.screen === tab ? '#D6EBDC' : '#FFFFFF')
              .animation({ duration: 120, curve: Curve.EaseOut })
              .accessibilityGroup(true).accessibilityText(`${tab === 'settings' ? 'Parent' : tab}. ${this.screen === tab ? 'Selected' : 'Tap to open'}`)
              .onClick(() => this.selectTab(tab))
          })
        }.width('100%').padding({ left: 10, right: 10, top: 4, bottom: 4 }).backgroundColor('#FFFFFF')
      }
    }.height('100%').width('100%').backgroundColor('#F4F7F0')
    }
  }
}
