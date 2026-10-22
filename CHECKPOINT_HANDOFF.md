# CHECKPOINT_HANDOFF — ApexAiOfficial/ytdlnis revival

Living handoff for the two-phase revival of the ApexAiOfficial fork of
[deniscerri/ytdlnis](https://github.com/deniscerri/ytdlnis). Read this first after any
resume (usage reset, compaction, new session). Newest status is at the top of each section.

## Goal

1. **Phase 1 — baseline.** Bring the fork up to current upstream, fix compatibility
   issues, and produce a verified working Android APK.
2. **Phase 2 — BYO-LLM terminal assistant.** Provider-agnostic "bring your own LLM"
   integration in the in-app terminal: natural-language → yt-dlp command generation,
   explanations, troubleshooting, an editable preview, and user-approved execution.
   Users configure their own providers, models and API keys; DeepSeek is one preset,
   never the only provider. Credentials are handled securely.

## Current status

- **Phase:** 1 (baseline) — done and verified; Phase 2 starting on `apex/byo-llm`.
- **Branches (local only, not pushed — see "Decisions"):**
  - `apex/upstream-sync` = `upstream/main` (9a529f85) + 2 fork commits (CI signing
    fallback, terminal ANR fix).
  - `apex/byo-llm` — Phase 2, stacked on `apex/upstream-sync`.
- **Last verified (2026-10-21):** `assembleGithubDebug` OK; `testGithubDebugUnitTest` OK;
  APK installed on an API 34 x86_64 emulator, app launches, terminal starts bundled bash,
  `yt-dlp --version` → `2026.08.19`.

## Repository facts (assessed 2026-10-21)

- Fork `origin` = `ApexAiOfficial/ytdlnis` (public, Actions enabled, no secrets).
  `upstream` = `deniscerri/ytdlnis` (remote added locally).
- Fork `main` had **zero fork-only commits** and was **496 commits behind**
  `upstream/main` (last fork sync 2026-06-22, upstream head `9a529f85`, 2026-10-19,
  v1.9.1.1). The sync is therefore a pure fast-forward; no merge conflicts.
- All upstream feature branches (`feature/terminal-rework`, `bgutils-service`,
  `downloadable-plugins`, `searchable-settings`) are already merged into `upstream/main`.
- Build: AGP 8.13.2, Gradle 8.13, Kotlin 2.3.0, KSP 2.3.4, compileSdk/targetSdk 36,
  minSdk 24, JDK 17. Flavors `github` (default), `foss`, `izzy`; ABI splits + universal APK.
- `settings.gradle` includes `:common`, `:library`, `:ffmpeg`, which do not exist on disk
  (Gradle treats them as empty projects).
- Signing: `keystore.properties` (gitignored) is optional locally; without it debug and
  release both use the Android debug keystore.
- Upstream CI (`.github/workflows/android.yml`) runs on push to **any** branch on
  GitHub-hosted runners and needs `BASE_64_SIGNING_KEY` / `LOCAL_PROPERTIES` secrets the
  fork does not have, so it would fail on every fork push.

## Local toolchain (this laptop)

Installed user-locally (no sudo), checksum-verified:

| Tool | Path |
|---|---|
| Temurin JDK 17.0.20.1 | `~/.local/opt/jdk-17` |
| Android cmdline-tools 23.0, platform-tools, platforms;android-36, build-tools;35.0.0 | `~/.local/opt/android-sdk` |
| Gradle caches | `~/.gradle` (standard location) |

Android SDK licenses were accepted with `sdkmanager --licenses` (required to build).

Environment for every shell:

```bash
export JAVA_HOME=$HOME/.local/opt/jdk-17
export ANDROID_HOME=$HOME/.local/opt/android-sdk
export ANDROID_SDK_ROOT=$ANDROID_HOME
export PATH=$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH
```

`local.properties` (gitignored) holds `sdk.dir=$HOME/.local/opt/android-sdk`.
`gradlew` is not executable in Git; run it as `bash ./gradlew`.

The laptop is memory-constrained (7.6 GB RAM, other services running). Build with a
smaller heap and in-process Kotlin compilation:

```bash
bash ./gradlew assembleGithubDebug \
  -Dorg.gradle.jvmargs="-Xmx3g -XX:MaxMetaspaceSize=1g -Dfile.encoding=UTF-8" \
  -Pkotlin.compiler.execution.strategy=in-process --console=plain
```

Stop the daemon when finished (`bash ./gradlew --stop`).

## Phase 1 plan

1. [x] Add `upstream` remote, assess divergence.
2. [x] Branch `apex/upstream-sync` at `upstream/main` (fast-forward of fork `main`).
3. [x] First local build of `githubDebug`: **succeeded with no code changes** (32 min
   cold). No compatibility fixes were needed for the toolchain itself.
4. [x] Unit tests (`testGithubDebugUnitTest`): pass (upstream has only the example test).
5. [x] APK verified: `aapt2 dump badging` → `com.deniscerri.ytdl` 1.9.1.1 (versionCode
   109010100), min 24 / target 36, ABIs arm64-v8a, armeabi-v7a, x86, x86_64; debug-signed.
   Emulator smoke test as above.
6. [x] Fork CI: `app/build.gradle` now trims `keystore.properties` before deciding to use
   it, so the blank file CI writes without secrets falls back to debug signing (verified:
   Gradle configures with a blank file). The Telegram notify job already has
   `continue-on-error`.
7. [x] **Found and fixed an upstream ANR:** opening the terminal before the first-launch
   runtime unpack finished blocked the main thread in `RuntimeManager.assertInit()`
   (ANR trace: "Input dispatching timed out … RuntimeManager.assertInit"). The wait now
   runs on `Dispatchers.IO` (commit 093d89e1). Verified: no app ANR, terminal UI renders
   while unpacking; warm start opens the shell in ~15 s on the emulator. The cold path with
   the longer wait is re-verified with the Phase 2 APK (same code).

Emulator notes: `~/.android/avd/ytdlnis34.avd` (API 34 default x86_64, 2 GB). Start
headless with `emulator -avd ytdlnis34 -no-window -no-audio -no-boot-anim -no-snapshot
-gpu swiftshader_indirect -memory 2048 -cores 2`. **Gradle and the emulator cannot run at
the same time on this laptop** (swap exhausts; the watchdog kills Gradle) — stop the
emulator (`adb emu kill`) before building. Its System UI/launcher ANRs under load are
emulator artefacts; `adb shell settings put global hide_error_dialogs 1` hides them.

## Phase 2 design (draft — refined after Phase 1)

Existing terminal: `ui/more/terminal/*` — a Termux `TerminalView` backed by a bundled bash
(`MkSession`), with `yt-dlp`, `ffmpeg`, `python`, … exposed as shell functions; a bottom app
bar (`res/menu/terminal_menu.xml`) inserts templates/shortcuts/paths into the prompt via
`session.write()`.

Planned architecture (package `com.deniscerri.ytdl.llm`):

- **Provider profiles** (`LlmProviderConfig`): name, protocol, base URL, model, optional
  temperature/max tokens. Presets: OpenAI, Anthropic, DeepSeek, Google Gemini
  (OpenAI-compatible endpoint), OpenRouter, Groq, Mistral, xAI, local Ollama, Custom.
  Two wire protocols cover these: **OpenAI-compatible Chat Completions** and
  **Anthropic Messages**. Model lists are fetched from the provider (`/models`), never
  hardcoded; presets only suggest a default.
- **Credentials:** API keys encrypted with AES-256-GCM using a non-exportable Android
  Keystore key, stored in a dedicated private prefs file — never in the default
  preferences (the app's settings backup exports `getDefaultSharedPreferences().all`),
  never logged, never sent to the model. `android:allowBackup="false"` already.
- **Network:** HTTPS only, except loopback (matches the existing
  `network_security_config.xml`).
- **Terminal assistant UI:** new bottom-bar action opens a sheet: natural-language
  request → structured JSON reply (`command`, `explanation`, `warnings`) → **editable
  command preview** → *Insert* (types it at the prompt, never executes) or *Run* (explicit
  tap; extra confirmation when risk flags are present). Also *Explain* (explain a
  command) and *Troubleshoot* (sends the command + recent terminal output, redacted, only
  when the user asks).
- **Safety:** the model's output is untrusted. Strip/deny control characters and
  newlines before writing to the terminal (a newline would execute), require the command
  to start with `yt-dlp`, flag shell metacharacters (`; && || | \` $( > <`), and redact
  secrets (`--password`, `--username`, `--video-password`, `--ap-password`, auth/cookie
  headers, tokens) from anything sent to the provider.
- **Tests:** JVM unit tests for parsing, sanitising, redaction and request building
  (MockWebServer); optional live test gated on an environment variable, key never written
  to disk or committed.

## Decisions requiring owner approval

1. **Pushing branches to the fork.** Not done yet. Any push triggers upstream's
   `android.yml` (3 GitHub-hosted release builds — free on a public repo, not billable) which
   currently fails without upstream's signing secrets. Phase 1 step 6 makes it pass.
2. **Updating fork `main`.** Fork `main` can be fast-forwarded to `upstream/main` with no
   conflicts; left untouched until approved.

## Continuation state

- Phase 2 drafts (provider layer, settings page, terminal sheet, tests, docs) are in
  `git stash` entry "phase2-drafts" (made on `apex/byo-llm`) and in the session scratchpad
  `p2/`. Next: `git checkout apex/byo-llm && git rebase apex/upstream-sync && git stash pop`,
  then wire them in (strings, terminal menu + TerminalFragment, settings nav/registry,
  SettingsActivity deep link), build, run unit tests, emulator test.
- Builds: incremental ~6–7 min. A memory watchdog (scratchpad `memguard.sh`) kills Gradle
  if MemAvailable+SwapFree < 600 MB so the OOM killer never hits the comms-bot/Hermes
  services.
