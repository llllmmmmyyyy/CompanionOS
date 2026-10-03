import { common } from '@kit.AbilityKit';
import { ACTIVITIES, Activity, ActivitySession, Completion, ParentSettings, Snapshot,
  addCompletion, countToday, validSettings } from '../model/Companion';
import { LocalStore } from '../services/LocalStore';
import { Notifications } from '../services/Notifications';
import { AiService } from '../services/AiService';
import { Widgets } from '../services/Widgets';

@Entry
@Component
struct Index {
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

  aboutToDisappear(): void { clearInterval(this.timer); }
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
    }
  }

  private updateClock(): void {
    this.today = countToday(this.data, Date.now());
    if (this.session.tick(Date.now(), this.foreground)) {
      this.notice = 'Time is up. Parent / caregiver: confirm when you have finished together.';
      this.publishEndNotification();
    }
    this.phase = this.session.phase;
    this.remaining = this.session.remaining(Date.now());
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
    this.selected = activity;
    this.session = new ActivitySession();
    this.phase = 'idle';
    this.confirmed = false;
    this.demo = false;
    if (this.storageReady) { this.notice = ''; }
    this.navigate('activity');
  }

  private startActivity(): void {
    if (this.busy || this.phase === 'running' || this.phase === 'ready') { return; }
    this.session.start(Date.now(), this.data.settings.minutes, this.demo);
    this.confirmed = false;
    this.notice = '';
    this.updateClock();
  }

  private cancelActivity(): void {
    if (this.busy) { return; }
    if (this.phase === 'running' || this.phase === 'ready') {
      this.getUIContext().showAlertDialog({
        title: 'Cancel this activity?',
        message: 'No completion will be recorded.',
        primaryButton: { value: 'Keep playing', action: () => {} },
        secondaryButton: { value: 'Cancel activity', action: () => {
          this.session.cancel(); this.phase = 'cancelled'; this.confirmed = false;
          this.notice = 'Activity cancelled. No completion was recorded.';
          this.navigate('home');
        } }
      });
    } else { this.navigate('home'); }
  }

  onBackPress(): boolean {
    if (this.screen === 'home') { return false; }
    if (this.screen === 'activity') { this.cancelActivity(); }
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
    const updated = addCompletion(this.data, record);
    try {
      await this.store.save(updated);
      this.data = updated;
      this.session.phase = 'completed';
      Widgets.update(this.getUIContext().getHostContext() as common.UIAbilityContext, updated);
      this.phase = 'completed';
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
      this.heading(this.selected.title)
      Text('Offline activity').fontSize(14).fontColor('#28745E').width('100%')
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
        Row({ space: 8 }) {
          Checkbox({ name: 'demoMode' }).select(this.demo).selectedColor('#28745E')
            .onChange((value: boolean) => { this.demo = value; })
          Text('Demo Mode — 10-second countdown').fontSize(16).fontColor('#203C31').layoutWeight(1)
        }
        Text('Normal mode uses your selected duration. Demo completions are labelled in Progress.')
          .fontSize(14).fontColor('#52645C').width('100%')
        Button('Start activity').width('100%').backgroundColor('#28745E').fontColor(Color.White)
          .onClick(() => this.startActivity())
      } else {
        Text('Put the screen down and play together.').fontSize(25).fontWeight(FontWeight.Bold)
          .fontColor('#28745E').width('100%')
        Text(this.session.demo ? 'DEMO MODE • 10 seconds' : `NORMAL MODE • ${this.session.minutes} minutes`)
          .fontSize(14).fontColor('#52645C').width('100%')
        Text(this.phase === 'ready' ? 'Time is up!' : this.clockLabel()).fontSize(42).fontWeight(FontWeight.Bold).fontColor('#203C31')
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
          Text(this.dateLabel(record.completedAt)).fontSize(15).fontColor('#52645C').width('100%')
          Text(record.demo ? 'Demo Mode • 10 seconds • Parent confirmed' : `${record.minutes} min • Parent confirmed`)
            .fontSize(14).fontColor('#28745E').width('100%')
        }.padding(20).width('100%').backgroundColor(Color.White).borderRadius(20)
      }, (record: Completion) => record.id)
      Button('Choose another adventure').width('100%').backgroundColor('#28745E').fontColor(Color.White).onClick(() => this.navigate('home'))
    }.width('100%')
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        if (this.screen !== 'home') {
          Button('Back').fontSize(14).backgroundColor('#E0EEE5').fontColor('#203C31').enabled(!this.busy)
            .onClick(() => { if (this.screen === 'activity') { this.cancelActivity(); } else { this.navigate('home'); } })
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
          else { this.activityContent() }
          Text('Made for moments together • HackYeah MVP').fontSize(12).fontColor('#52645C').padding({ top: 12, bottom: 24 })
        }.width('100%').padding({ left: 20, right: 20, top: 8 })
      }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Auto)
    }.height('100%').width('100%').backgroundColor('#F4F7F0')
  }
}
