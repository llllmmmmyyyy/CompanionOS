const storage = new LocalStorage();

@Entry(storage)
@Component
struct TodayCard {
  @LocalStorageProp('activityTitle') activityTitle: string = 'Penguin Walk';
  @LocalStorageProp('todayCount') todayCount: string = '0';
  @LocalStorageProp('updatedDate') updatedDate: string = '';

  build() {
    FormLink({ action: 'router', abilityName: 'EntryAbility', moduleName: 'entry' }) {
      Column({ space: 8 }) {
        Text('CompanionOS').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#203C31').width('100%')
        Text(this.activityTitle).fontSize(19).fontWeight(FontWeight.Bold).fontColor('#28745E').maxLines(2).width('100%')
        Text(`Completed today: ${this.todayCount}`).fontSize(14).fontColor('#203C31').width('100%')
        Text(`As of ${this.updatedDate}`).fontSize(11).fontColor('#52645C').width('100%')
        Text('Tap to play together').fontSize(12).fontColor('#28745E').width('100%')
      }.padding(14).height('100%').width('100%').backgroundColor('#F4F7F0')
    }
  }
}
