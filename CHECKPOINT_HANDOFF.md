# CHECKPOINT_HANDOFF — ApexAiOfficial/ytdlnis revival

Living handoff for the two-phase revival of the ApexAiOfficial fork of
[deniscerri/ytdlnis](https://github.com/deniscerri/ytdlnis). Read this first after any
resume (usage reset, compaction, new session).

## Retired (2026-10-23)

The project was retired by the owner. Valuable work was contributed upstream to
`deniscerri/ytdlnis` and all local Android tooling was removed.

| Upstream | What | State |
|---|---|---|
| [#1444](https://github.com/deniscerri/ytdlnis/issues/1444) | Bug report: terminal ANR while the runtime unpacks | open |
| [#1445](https://github.com/deniscerri/ytdlnis/pull/1445) | Fix for #1444 (`fix/terminal-first-launch-anr`, 1 commit, `TerminalFragment` only) | open, ready for review |
| [#1446](https://github.com/deniscerri/ytdlnis/issues/1446) | Feature request: optional BYO-LLM terminal assistant | open |
| [#1447](https://github.com/deniscerri/ytdlnis/pull/1447) | Assistant (`feature/terminal-llm-assistant`, 1 commit, 30 files) | **draft**: UI success path not verified on a device |

- Both PR branches are based on upstream `main` 8fd423f1 and contain no ApexAI-specific
  files (no handoff, devcontainer or fork CI). Verified in a Codespace before submitting:
  `assembleGithubDebug` + `testGithubDebugUnitTest` pass on both. The assistant's 33
  `core/llm` unit tests pass, and `LiveProviderTest` passed 3/3 against DeepSeek
  (`deepseek-flash`).
- A security review before submission added: no HTTP redirects (a redirect could forward
  `x-api-key` to another host), a response-size cap, `llm_secrets.xml` excluded from cloud
  backup and device transfer, and `--ppa`/`--downloader-args` flagged as risky.
- Not submitted: the fork-only CI signing fallback (`app/build.gradle` trim), which matters
  only to forks without upstream's secrets.
- Preserved on the fork: `apex/upstream-sync`, `apex/byo-llm` (this branch, full history),
  and the two PR branches. Fork `main` untouched. The fork is kept.
- Codespace `ytdlnis-build-v674p6wwgv9vh6xj9` was deleted after checking it had no
  uncommitted, stashed or unpushed work. The `DEEPSEEK_API_KEY` Codespaces secret was
  deleted (the fork now has no secrets).
- Local cleanup with each tool's own commands first (`gradlew clean`,
  `avdmanager delete avd`, `sdkmanager --uninstall` for the system image, emulator,
  platform, build-tools, platform-tools and cmdline-tools). Then the leftovers with no
  uninstaller were removed: `~/.local/opt/{android-sdk,jdk-17}`, `~/.gradle`, `~/.android`,
  `~/.java`, `~/.emulator_console_auth_token`, and the repo's `build/`, `.gradle/` and
  `local.properties`. All were created by this project on 2026-10-21 and referenced by
  nothing else (shell profiles, systemd units, crontab, agent configs, other repositories
  and workflows were checked). Free space went from 6.2 GB to 14 GB (8.10 GB recovered).
- To work on the PRs again: create a Codespace from `apex/byo-llm` (its devcontainer needs
  the SDK license hash copied in, or `sdkmanager --licenses` run interactively, because
  current cmdline-tools skip `--licenses`) or install JDK 17 + the SDK locally as described
  below.

## Goal

1. **Phase 1 — baseline.** Bring the fork up to current upstream, fix compatibility
   issues, and produce a verified working Android APK.
2. **Phase 2 — BYO-LLM terminal assistant.** Provider-agnostic "bring your own LLM"
   integration in the in-app terminal: natural-language → yt-dlp command generation,
   explanations, troubleshooting, an editable preview, and user-approved execution.
   Users configure their own providers, models and API keys; DeepSeek is one preset,
   never the only provider. Credentials are handled securely.
3. **Infra — off the laptop.** The owner's laptop is short on RAM and SSD. Builds move to a
   GitHub Codespace; local Android tooling is removed once remote builds are verified.

## Current status (2026-10-21)

- **Phase 1:** done and verified.
- **Phase 2:** implemented, unit-tested and walked through on an emulator; the live
  success path (a real model answering) still needs a valid API key — see "Decisions".
- **Infra:** moving to Codespaces. Blocked on the owner granting the `codespace` scope.
- **Branches (pushed to `origin`):**
  - `apex/upstream-sync` = `upstream/main` (9a529f85) + fork commits: CI signing fallback,
    terminal ANR fix, handoff, manual-only fork CI, devcontainer.
  - `apex/byo-llm` — Phase 2, stacked on `apex/upstream-sync`.
  - Fork `main` untouched.
- **Actions:** no workflow has ever run on the fork (GitHub keeps workflows disabled on a
  fork until enabled in the Actions tab). `apex-ci.yml` is manual-only (`workflow_dispatch`).

## Repository facts

- Fork `origin` = `ApexAiOfficial/ytdlnis` (public, owned by the personal account
  `ApexAiOfficial`, GitHub Free plan). `upstream` = `deniscerri/ytdlnis` (remote added
  locally).
- Fork `main` had zero fork-only commits and was 496 commits behind `upstream/main`, so the
  sync is a pure fast-forward.
- Build: AGP 8.13.2, Gradle 8.13, Kotlin 2.3.0, KSP 2.3.4, compile/target SDK 36, min SDK
  24, JDK 17. Flavors `github` (default), `foss`, `izzy`; ABI splits + universal APK.
  `gradlew` is not executable in Git; run it as `bash ./gradlew`.
- Signing: without `keystore.properties` (gitignored) debug and release builds use the
  Android debug keystore. The debug APK has upstream's applicationId `com.deniscerri.ytdl`
  but a different signature, so it cannot be installed over an official YTDLnis.
- Upstream `android.yml` runs 3 release builds on every push to any branch once Actions
  are enabled on the fork; it is left unchanged.

## Phase 1 results

1. Upstream sync: fast-forward to `9a529f85` (v1.9.1.1) on `apex/upstream-sync`.
2. First build of `githubDebug` succeeded with no code changes (32 min cold on the laptop).
3. `testGithubDebugUnitTest` passes.
4. APK: `com.deniscerri.ytdl` 1.9.1.1 (versionCode 109010100), min 24 / target 36, ABIs
   arm64-v8a, armeabi-v7a, x86, x86_64. On an API 34 emulator the app launches, the terminal
   starts the bundled bash and `yt-dlp --version` prints `2026.08.19`.
5. Fork CI fix: `app/build.gradle` trims `keystore.properties` before using it, so the
   blank file CI writes without secrets falls back to debug signing.
6. **Upstream ANR fixed:** opening the terminal while the first launch was still unpacking
   the runtime blocked the main thread in `RuntimeManager.assertInit()` (ANR trace "Input
   dispatching timed out … RuntimeManager.assertInit"); a start slower than 30 s threw. The
   wait now runs on `Dispatchers.IO` and keeps waiting while unpacking. Verified on a wiped
   emulator: shell up after ~35 s, no ANR, no crash.

## Phase 2 results

Code: `core/llm/*` (provider layer), `ui/more/settings/ai/*` (settings page, provider
dialog), `ui/more/terminal/assistant/*` (sheet + ViewModel), wiring in `TerminalFragment`,
settings nav/registry and a `SettingsActivity` deep link. User docs: `docs/AI_ASSISTANT.md`.

- **Providers:** OpenAI-compatible Chat Completions and Anthropic Messages protocols;
  presets OpenAI, Anthropic, DeepSeek, Gemini, OpenRouter, Groq, Mistral, xAI, Ollama
  (localhost), custom. Models are loaded from `/models`; nothing is hardcoded (DeepSeek's
  model names already changed to `deepseek-flash` / `deepseek-v4-pro` since earlier
  docs). On HTTP 400 the request is retried once without optional fields.
- **Credentials:** AES-256-GCM, non-exportable Android Keystore key, private
  `llm_secrets` prefs file; profiles in `llm_providers`. Neither is in the default prefs that
  the settings backup exports. Keys are scrubbed from error messages.
- **Execution:** editable preview → Insert (types, no Enter) or Run (types + Enter; confirm
  dialog when risky: not yt-dlp, shell operators, `--exec`/`--netrc-cmd`/plugins/config,
  `-U`, credentials, unclosed quote). Control characters/newlines are stripped or blocked.
  Troubleshoot output is redacted and capped at 6,000 characters.
- **Tests:** 31 JVM unit tests pass (CommandSafety 7, LlmClient 12, SecretRedactor 4,
  YtdlpAssistant 8). `LiveProviderTest` (3 tests) is skipped unless `YTDLNIS_LLM_KEY_FILE`
  names a key file:
  `YTDLNIS_LLM_KEY_FILE=/path/key YTDLNIS_LLM_PRESET=DEEPSEEK bash ./gradlew testGithubDebugUnitTest --tests '*LiveProviderTest*'`
- **Emulator walkthrough:** sparkle button → setup prompt → preset list → DeepSeek form;
  required-field validation; Test against the real DeepSeek API with an invalid key returns
  HTTP 401 shown as "The provider rejected the API key"; profile saved; key stored only as
  ciphertext; sheet opens and shows the same 401 for a request. UI polish found there is
  fixed in `c7893e58`. **Not yet verified:** a successful generation, Insert/Run into the
  shell, Explain/Troubleshoot against a real model.

## Remote development (Codespaces)

- `.devcontainer/devcontainer.json`: `mcr.microsoft.com/devcontainers/java:3-17-bookworm`
  + `sshd` feature (needed by `gh codespace ssh`); `install-android-sdk.sh` installs
  cmdline-tools (SHA-1 checked), `platforms;android-36`, `build-tools;35.0.0` into
  `/home/vscode/android-sdk` and writes `local.properties`. No emulator (Codespaces has no
  KVM): test APKs on a phone, or run `apex-ci.yml` manually for the KVM emulator smoke test.
- Quota (GitHub Free, personal account): 120 core-hours and 15 GB-month storage per month.
  A 4-core machine (16 GB RAM, 32 GB disk) uses 4 core-hours per hour, so ~30 h/month.
  Stopped codespaces still use storage; delete them when idle for long.
- Workflow from this laptop: edit and push locally, then
  `gh codespace ssh -c <name> -- 'cd /workspaces/ytdlnis && git pull && bash ./gradlew testGithubDebugUnitTest assembleGithubDebug'`,
  and `gh codespace cp -e 'remote:/workspaces/ytdlnis/app/build/outputs/apk/github/debug/<apk>' .`
  for APKs.
- Blocker: the `gh` token lacks the `codespace` scope. Owner runs
  `gh auth refresh -h github.com -s codespace` (browser approval).

## Local footprint of this work (laptop) and reclaim plan

Measured 2026-10-21 (free disk went 22 GB → 15 GB):

| Path | Size | What |
|---|---|---|
| `~/.local/opt/android-sdk` | 3.0 GB | system image 1.7 GB, emulator 0.86 GB, cmdline-tools, platform 36, build-tools 35, platform-tools |
| `~/.gradle` | 2.2 GB | dependency caches + wrapper (did not exist before) |
| `~/.android` | 1.4 GB | AVD `ytdlnis34`, debug keystore, adb keys |
| repo `app/build`, `.gradle` | 1.2 GB | build outputs (gitignored) |
| `~/.local/opt/jdk-17` | 0.3 GB | Temurin 17 |
| `~/.java`, `~/.emulator_console_auth_token` | tiny | created by sdkmanager / emulator |

All of it is regenerable and was created by this session. RAM: nothing stays resident —
Gradle daemons, emulator and adb are stopped after use. Reclaim only after a remote build is
verified, with each tool's own command where one exists (`avdmanager delete avd`,
`sdkmanager --uninstall`, `gradlew clean`/`--stop`), then remove the now-empty install dirs.

## Decisions requiring owner approval

1. **Codespaces scope** — run `gh auth refresh -h github.com -s codespace`.
2. **Codespace machine** — recommend 4-core (faster Gradle, ~30 h/month free) vs 2-core
   (~60 h/month, slower builds).
3. **API key for live tests** — never paste it in chat. Options: a repository/Codespaces
   secret set by the owner (`gh secret set DEEPSEEK_API_KEY --app codespaces -R ApexAiOfficial/ytdlnis`
   prompts without echo) or a 0600 key file read via `YTDLNIS_LLM_KEY_FILE`.
4. **Fork `main`** — fast-forward to `upstream/main` (and later merge the apex branches)
   when the owner wants; untouched so far.
5. **Actions** — leave fork workflows disabled (current) or enable them for the manual
   emulator smoke test; enabling also activates upstream's `android.yml` on every push.

## Continuation state

- Local checkout is on `apex/upstream-sync` or `apex/byo-llm`; both pushed. No stashes needed.
- 2026-10-21 21:46 EDT: owner granted the `codespace` scope. Codespace
  `ytdlnis-build-v674p6wwgv9vh6xj9` (4-core, 16 GB, 32 GB; `apex/byo-llm`; idle timeout 30 min;
  auto-deleted after 7 days stopped) was created and is provisioning.
- Next: when it is `Available`, run the build + unit tests over `gh codespace ssh`, record
  the result here, then reclaim the local tooling listed above.
