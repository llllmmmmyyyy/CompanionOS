import { preferences } from '@kit.ArkData';

class AnimalActivity {
  id: string;
  animal: string;
  title: string;
  description: string;
  minutes: number;
  steps: string[];
  constructor(id: string, animal: string, title: string, description: string, minutes: number, steps: string[]) {
    this.id = id;
    this.animal = animal;
    this.title = title;
    this.description = description;
    this.minutes = minutes;
    this.steps = steps;
  }
}

class CompletionRecord {
  id: string = '';
  title: string = '';
  animal: string = '';
  completedAt: number = 0;
}

const ACTIVITIES: AnimalActivity[] = [
  new AnimalActivity('penguin', 'Penguin', 'Penguin Walk', 'Waddle side by side on a little penguin adventure.', 5,
    ['Find a clear space and stand beside your parent.',
      'Hold your arms like little flippers and take ten small waddling steps together.',
      'Turn around slowly, waddle back, and finish with a high five.']),
  new AnimalActivity('sounds', 'Animals', 'Animal Sounds', 'Listen, guess, and laugh together.', 3,
    ['Choose an animal without telling each other its name.',
      'Make its sound and let your partner guess the animal.',
      'Swap roles and try three more animals together.']),
  new AnimalActivity('butterfly', 'Butterfly', 'Butterfly Stretch', 'Spread your wings for a gentle family stretch.', 3,
    ['Stand or sit comfortably beside your parent.',
      'Open your arms like butterfly wings and gently stretch upward.',
      'Slowly lower your wings. Repeat five times, staying comfortable.'])
];

@Entry
@Component
struct Index {
  @State screen: string = 'home';
  @State selected: AnimalActivity = ACTIVITIES[0];
  @State records: CompletionRecord[] = [];
  @State todayCount: number = 0;
  @State saving: boolean = false;
  @State storageReady: boolean = false;
  @State notice: string = '';
  @State justCompleted: boolean = false;
  private store: preferences.Preferences | undefined = undefined;
  private countDay: string = '';
  private dayTimer: number = -1;
  private scroller: Scroller = new Scroller();

  private dayKey(timestamp: number): string {
    const date = new Date(timestamp);
    return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
  }

  private refreshDay(): void {
    const today = this.dayKey(Date.now());
    if (this.countDay !== today) {
      this.countDay = today;
      this.todayCount = 0;
    }
  }

  onPageShow(): void {
    this.refreshDay();
  }

  aboutToDisappear(): void {
    clearInterval(this.dayTimer);
  }

  aboutToAppear(): void {
    try {
      this.store = preferences.getPreferencesSync(this.getUIContext().getHostContext(), { name: 'companion_history' });
      const saved = JSON.parse(this.store.getSync('records', '[]') as string) as CompletionRecord[];
      if (Array.isArray(saved) && saved.every((record: CompletionRecord) => record !== null &&
        typeof record.id === 'string' && typeof record.title === 'string' &&
        typeof record.animal === 'string' && typeof record.completedAt === 'number')) {
        this.records = saved;
      } else {
        this.notice = 'Saved history could not be read. New activities can still be saved.';
      }
      this.countDay = this.store.getSync('countDay', '') as string;
      const count = this.store.getSync('todayCount', 0) as number;
      this.todayCount = Number.isFinite(count) && count >= 0 ? Math.floor(count) : 0;
      if (this.countDay === '') {
        this.countDay = this.dayKey(Date.now());
        this.todayCount = this.records.filter((record: CompletionRecord) =>
          this.dayKey(record.completedAt) === this.countDay).length;
      }
      this.refreshDay();
      this.storageReady = true;
    } catch {
      this.notice = 'Local storage is unavailable. Please reopen the app to try again.';
    }
    this.dayTimer = setInterval(() => { this.refreshDay(); }, 1000);
  }

  private async completeActivity(): Promise<void> {
    if (this.saving || !this.store || !this.storageReady || this.screen !== 'detail') {
      return;
    }
    this.saving = true;
    const record = new CompletionRecord();
    record.completedAt = Date.now();
    record.id = `${this.selected.id}-${record.completedAt}`;
    record.title = this.selected.title;
    record.animal = this.selected.animal;
    // Bound the serialized value to fit the Preferences storage limit.
    const updated: CompletionRecord[] = [record, ...this.records].slice(0, 30);
    this.refreshDay();
    const completedDay = this.dayKey(record.completedAt);
    const updatedCount = this.todayCount + 1;
    try {
      this.store.putSync('records', JSON.stringify(updated));
      this.store.putSync('countDay', completedDay);
      this.store.putSync('todayCount', updatedCount);
      await this.store.flush();
      this.records = updated;
      this.countDay = completedDay;
      this.todayCount = updatedCount;
      this.refreshDay();
      this.justCompleted = true;
      this.notice = `${record.title} completed. Well done, together!`;
      this.screen = 'home';
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
    } catch {
      this.notice = 'We could not save this activity. Please try confirming again.';
    } finally {
      this.saving = false;
    }
  }

  private goBack(): void {
    if (this.saving) { return; }
    this.justCompleted = false;
    this.screen = 'home';
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }

  onBackPress(): boolean {
    if (this.screen === 'home') { return false; }
    this.goBack();
    return true;
  }

  private dateLabel(timestamp: number): string {
    const date = new Date(timestamp);
    const months: string[] = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return `${months[date.getMonth()]} ${date.getDate()}, ${date.getFullYear()} at ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
  }

  @Builder
  homeContent() {
    Column({ space: 16 }) {
      Text('Small activities. Meaningful family moments.').fontSize(26).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      Text(`Completed today: ${this.todayCount}`).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#28745E')
        .padding(20).width('100%').backgroundColor('#E0EEE5').borderRadius(20)
      Text('Choose an adventure. A parent stays with their child throughout each activity.')
        .fontSize(16).fontColor('#52645C').width('100%')
      ForEach(ACTIVITIES, (activity: AnimalActivity) => {
        Column({ space: 10 }) {
          Text(`${activity.animal.toUpperCase()} • ${activity.minutes} min`).fontSize(14).fontColor('#28745E').width('100%')
          Text(activity.title).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
          Text(activity.description).fontSize(16).fontColor('#52645C').width('100%')
          Button('Explore activity').width('100%').backgroundColor('#28745E')
            .onClick(() => {
              this.selected = activity;
              if (this.storageReady) { this.notice = ''; }
              this.screen = 'detail';
              this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
            })
        }.padding(20).width('100%').backgroundColor(Color.White).borderRadius(20)
      }, (activity: AnimalActivity) => activity.id)
      Button(`Completion history (${this.records.length})`).width('100%').backgroundColor('#E0EEE5').fontColor('#203C31')
        .onClick(() => { this.justCompleted = false; this.screen = 'records'; })
    }.width('100%')
  }

  @Builder
  detailContent() {
    Column({ space: 18 }) {
      Text(this.selected.animal.toUpperCase()).fontSize(14).fontColor('#28745E').width('100%')
      Text(this.selected.title).fontSize(30).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      Text(`Suggested duration: ${this.selected.minutes} minutes`).fontSize(16).fontColor('#28745E').width('100%')
      Text(this.selected.description).fontSize(17).fontColor('#52645C').width('100%')
      Text('Your steps').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      ForEach(this.selected.steps, (step: string, index: number) => {
        Row({ space: 12 }) {
          Text(`${index + 1}`).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#28745E').width(26)
          Text(step).fontSize(17).fontColor('#203C31').layoutWeight(1)
        }.alignItems(VerticalAlign.Top).padding(16).width('100%').backgroundColor(Color.White).borderRadius(14)
      }, (step: string) => step)
      Text('Parent / caregiver: tap below when you have completed this activity together.')
        .fontSize(16).fontColor('#52645C').width('100%')
      Button(this.saving ? 'Saving...' : 'Mark as completed').width('100%').backgroundColor('#28745E')
        .enabled(!this.saving && this.storageReady).onClick(() => { this.completeActivity(); })
    }.width('100%')
  }

  @Builder
  historyContent() {
    Column({ space: 16 }) {
      if (this.justCompleted) {
        Text('Well done, together!\nYour activity has been saved.').fontSize(24).fontWeight(FontWeight.Bold)
          .fontColor('#28745E').padding(20).width('100%').backgroundColor('#E0EEE5').borderRadius(20)
      }
      Text('Completion history').fontSize(30).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
      Text('The latest 30 parent-confirmed activities, saved on this device.').fontSize(16).fontColor('#52645C').width('100%')
      if (this.records.length === 0) {
        Text('Your first adventure is waiting.\nComplete an activity together to see it here.')
          .fontSize(18).fontColor('#52645C').padding(24).width('100%').backgroundColor(Color.White).borderRadius(20)
      }
      ForEach(this.records, (record: CompletionRecord) => {
        Column({ space: 8 }) {
          Text(`${record.animal} • Completed`).fontSize(14).fontColor('#28745E').width('100%')
          Text(record.title).fontSize(21).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
          Text(this.dateLabel(record.completedAt)).fontSize(15).fontColor('#52645C').width('100%')
          Text('Confirmed by parent / caregiver').fontSize(14).fontColor('#52645C').width('100%')
        }.padding(20).width('100%').backgroundColor(Color.White).borderRadius(20)
      }, (record: CompletionRecord) => record.id)
      Button('Choose another adventure').width('100%').backgroundColor('#28745E')
        .onClick(() => { this.justCompleted = false; this.screen = 'home'; })
    }.width('100%')
  }

  build() {
    Column() {
      Row({ space: 12 }) {
        if (this.screen !== 'home') {
          Button('Back').fontSize(14).backgroundColor('#E0EEE5').fontColor('#203C31')
            .enabled(!this.saving).onClick(() => this.goBack())
        }
        Text('CompanionOS').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#203C31')
        Blank()
        Text('OFFLINE').fontSize(11).fontColor('#28745E')
      }.width('100%').padding({ left: 20, right: 20, top: 16, bottom: 16 })
      Scroll(this.scroller) {
        Column({ space: 16 }) {
          if (this.notice !== '') {
            Text(this.notice).fontSize(15).fontColor('#8A451D').padding(16)
              .width('100%').backgroundColor('#FFF0D9').borderRadius(14)
          }
          if (this.screen === 'home') { this.homeContent() }
          else if (this.screen === 'records') { this.historyContent() }
          else { this.detailContent() }
          Text('Made for moments together • HackYeah Demo').fontSize(12).fontColor('#52645C')
            .padding({ top: 12, bottom: 20 })
        }.padding({ left: 20, right: 20, top: 8 }).width('100%')
      }.layoutWeight(1).width('100%').align(Alignment.Top).scrollBar(BarState.Auto)
    }.height('100%').width('100%').backgroundColor('#F4F7F0')
  }
}
