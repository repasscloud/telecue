# TeleCue for iPhone and iPad

A prototype iOS and iPadOS app built on the shared `TeleCueCore` library in
[`src/macos`](../macos), which also powers the macOS app. The prompter engine,
settings, Markdown handling, and word counts are identical on both platforms;
this directory contains only the iOS shell.

## Status

Prototype. It builds for the iOS Simulator and passes its unit and UI tests, but
it has not yet been signed for a device or submitted to the App Store.

What works:

- Write or paste a script, or open a UTF-8 `.txt`, `.md`, or `.markdown` file
  from Files.
- Live word count and reading-time estimate, with pace from 80–250 WPM.
- A full-screen prompter with smooth WPM-paced scrolling, a focus guide with an
  adjustable position, font size controls, and mirror mode for teleprompter glass.
- Tap the script to show or hide the controls. They fade out once playback starts.
- Drag to reposition the script while it is paused or playing.
- The screen stays awake while the prompter is open.
- Portrait and landscape on iPhone, and every orientation on iPad.

Hardware keyboards and Bluetooth page-turner remotes work in the prompter:

| Key | Action |
| --- | --- |
| Space | Play or pause |
| R | Restart from the beginning |
| Up Arrow / Down Arrow | Change pace by 5 WPM |
| M | Toggle mirror mode |
| Escape | Close the prompter |

## Build and test

Requirements: Xcode 16 or later with an iOS 17+ Simulator runtime.

```bash
open src/ios/TeleCue.xcodeproj
```

From the command line:

```bash
xcodebuild -project src/ios/TeleCue.xcodeproj -scheme TeleCue \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

To run on a physical device, select your team under Signing & Capabilities for
the `TeleCueiOS` target.

## Layout

```text
src/ios/
├── TeleCue.xcodeproj/       app, unit-test, and UI-test targets (folder-synced groups)
├── TeleCue-Info.plist       Markdown file-type declaration, merged with generated keys
├── TeleCue/                 SwiftUI app: editor, prompter, UITextView bridge, assets
├── TeleCueTests/            UIKit layout and scroll tests for the prompter text view
└── TeleCueUITests/          end-to-end flow: write, prompt, play, mirror, close
```

The app target is named `TeleCueiOS` (module `TeleCueiOS`) so it doesn't clash
with the macOS `TeleCue` executable in the shared package. It still builds
`TeleCue.app` and appears as "TeleCue" on the Home Screen.

## Not yet done

- An external display mode, where an iPad drives a separate monitor or
  teleprompter screen.
- Opening scripts directly from Files ("Open in TeleCue") and a document browser.
- App Store signing, privacy manifest, and release automation.
