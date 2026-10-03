import { GameState, GameEngine, gameDefinition } from './InteractiveActivity';
@Component
export struct GameBoard {
  @Prop state: GameState = new GameState();
  onAction: (action: string, value: string) => void = () => {};
  build() {
    Column({ space: 12 }) {
      Text(gameDefinition(this.state.id).theme).fontSize(15).fontColor('#36584A')
      if (this.state.id === 'robot-memory') { Image($rawfile('game-robot.svg')).width(100).height(100) }
      else if (this.state.id === 'animal-sorting' && this.state.round === 1) { Image($rawfile('game-lion.svg')).width(100).height(100) }
      else if (this.state.id === 'animal-sorting') { Image($rawfile('game-dolphin.svg')).width(100).height(100) }
      else if (this.state.id === 'penguin-move') { Image($rawfile('game-penguin.svg')).width(100).height(100) }
      else { Image($rawfile('game-dino.svg')).width(100).height(100) }
      Text(GameEngine.prompt(this.state)).fontSize(24).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
      if (['dino-number', 'animal-sorting'].includes(this.state.id)) { Text(`${this.state.stars} stars found`).fontSize(16).fontColor('#36584A') }
      if (this.state.paused) { Text('Take a gentle break. Your adult can resume.').fontSize(20) }
      else if (this.state.phase === 'preview') {
        Row({ space: 12 }) {
          ForEach(this.state.sequence, (item: string) => {
            Column({ space: 4 }) {
              if (item === 'Star') { Image($rawfile('game-star.svg')).width(48).height(48) }
              else if (item === 'Penguin') { Image($rawfile('game-penguin.svg')).width(48).height(48) }
              else if (item === 'Rocket') { Image($rawfile('game-rocket.svg')).width(48).height(48) }
              else { Image($rawfile('game-dino.svg')).width(48).height(48) }
              Text(item).fontSize(13)
            }
          })
        }.justifyContent(FlexAlign.Center).width('100%')
        Text(`Look carefully: ${this.state.remaining} seconds`).fontSize(17)
      } else if (['input', 'retry', 'round-success'].includes(this.state.phase)) {
        if (this.state.id === 'robot-memory') { Text(`${this.state.selected.length} of ${this.state.sequence.length} pictures chosen`).fontSize(17) }
        if (this.state.phase === 'input') {
          ForEach(GameEngine.choices(this.state), (value: string) => {
            Button(value).width('100%').height(54).fontSize(22).backgroundColor('#287452').fontColor('#FFFFFF').onClick(() => this.onAction('answer', value))
          })
        }
        if (this.state.phase === 'retry') { Button('Try again').width('100%').height(54).backgroundColor('#287452').fontColor('#FFFFFF').onClick(() => this.onAction('retry', '')) }
        if (this.state.phase === 'round-success') { Button('Next discovery').width('100%').height(54).backgroundColor('#287452').fontColor('#FFFFFF').onClick(() => this.onAction('next', '')) }
      } else if (['movement', 'confirm'].includes(this.state.phase)) {
        Text(this.state.phase === 'movement' ? `${this.state.remaining} seconds` : 'Check in: did you finish?').fontSize(28).fontWeight(FontWeight.Bold)
        Text('Adult nearby. Small steps or seated moves. Rest whenever you need. No climbing or jumping.').fontSize(16)
        Button('Done!').width('100%').height(54).enabled(this.state.phase === 'confirm').onClick(() => this.onAction('done', ''))
        Button('More time').width('100%').height(50).backgroundColor('#E1EEE8').fontColor('#203C31').onClick(() => this.onAction('more', ''))
      }
      Text(this.state.message).fontSize(20).fontColor('#36584A').textAlign(TextAlign.Center)
      if (!['success', 'skipped', 'idle'].includes(this.state.phase)) { Button('Skip game').width('100%').height(48).backgroundColor('#E1EEE8').fontColor('#203C31').onClick(() => this.onAction('skip', '')) }
    }.width('100%').padding(18).backgroundColor('#E6F0E9').borderRadius(24)
  }
}
