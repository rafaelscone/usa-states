# USA States Quiz

A native SwiftUI iOS quiz app for learning all 50 USA states. Each game shuffles the 50 states, highlights one state on the map per round, and asks the player to spell the state name using letter tiles.

Correct letters fill the next slot. Wrong letters are not accepted; the current answer slot and tapped key flash red instead.

## Run

Open `USAStatesQuiz/USAStatesQuiz.xcodeproj` in Xcode and run the `USAStatesQuiz` scheme on an iPhone simulator or device.

Command-line build:

```sh
xcodebuild -project USAStatesQuiz/USAStatesQuiz.xcodeproj -scheme USAStatesQuiz -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build
```
