# USA States Quiz

A native SwiftUI iOS map quiz app. The first screen lets players choose a quiz mode:

- USA States
- Brazil States
- South America Countries
- Central America Countries
- Europe Countries

Each game shuffles the selected map set, highlights one state or country per round, and asks the player to spell the answer using letter tiles.

Correct letters fill the next slot. Wrong letters are not accepted; the current answer slot and tapped key flash red instead.

Maps are bundled as local GeoJSON resources, so the quiz works offline.

## Run

Open `USAStatesQuiz/USAStatesQuiz.xcodeproj` in Xcode and run the `USAStatesQuiz` scheme on an iPhone simulator or device.

Command-line build:

```sh
xcodebuild -project USAStatesQuiz/USAStatesQuiz.xcodeproj -scheme USAStatesQuiz -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```
