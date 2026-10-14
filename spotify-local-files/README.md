# SpotifyLocalFiles

A LiveContainer/Ellekit-compatible tweak for Spotify 9.0.48 that imports audio files from the iOS Files picker and keeps a local per-playlist mapping.

## Current build

- Adds a small "♫+" button to Spotify.
- Imports MP3/M4A/AAC and other iOS-supported audio types through the Files picker.
- Copies imported files into Documents/SpotifyLocalFiles inside the Spotify guest container.
- Reads basic title and artist metadata when available.
- Lets the user associate an imported track with the currently visible Spotify screen title.
- Shows a small LOCAL panel on screens whose title matches that local playlist key.
- Plays the local file with AVAudioPlayer.

## Important limitation

This first build does not write to Spotify's server-side playlist database or create a real Spotify track URI. The "playlist" association is local to the tweak. That avoids faking server state and gives us a stable v1 while we capture the exact 9.0.48 playlist data-source classes.

## Build

This is a Theos tweak:

    export THEOS=/path/to/theos
    make package FINALPACKAGE=1

The target is arm64 / iOS 15+, matching Spotify 9.0.48.

## LiveContainer

Use an app-specific tweak folder for Spotify. LiveContainer can load .dylib tweaks through TweakLoader, and its documentation recommends app-specific folders when a tweak should only affect one guest app.

The plist filter is already restricted to com.spotify.client.

## Next reverse-engineering step

To make local tracks behave like real playlist rows inside Spotify rather than a local overlay, the next phase needs a 9.0.48 runtime class probe and playlist data-source hooks. Spotify changes these private classes frequently, so the hook should be version-gated.
