# Terminal AI assistant (bring your own LLM)

The terminal (More → Terminal) has an optional assistant that turns plain-language requests
into yt-dlp commands, explains commands, and helps troubleshoot failed downloads. It uses an
LLM provider **you** configure with **your own** API key. YTDLnis ships no key and runs no
proxy: requests go straight from your device to the provider.

## Setting up a provider

Settings → AI assistant → **Add provider**, then pick one:

| Provider | Base URL | Notes |
|---|---|---|
| OpenAI | `https://api.openai.com/v1` | |
| Anthropic | `https://api.anthropic.com/v1` | Native Messages API |
| DeepSeek | `https://api.deepseek.com` | |
| Google Gemini | `https://generativelanguage.googleapis.com/v1beta/openai` | OpenAI-compatible endpoint |
| OpenRouter | `https://openrouter.ai/api/v1` | |
| Groq | `https://api.groq.com/openai/v1` | |
| Mistral | `https://api.mistral.ai/v1` | |
| xAI | `https://api.x.ai/v1` | |
| Ollama (this device) | `http://localhost:11434/v1` | No key needed |
| Custom | any | OpenAI-compatible or Anthropic-compatible |

Enter your API key, tap the refresh icon in the **Model** field to load the provider's model
list (or type a model id), then **Test**. You can keep several providers and switch the active
one from the same screen.

- Base URLs must use HTTPS. Plain `http://` is accepted only for `localhost`, for model servers
  running on the phone itself.
- **Request JSON replies** asks the provider for structured output. If a provider rejects it,
  the app retries without it automatically; you can also switch it off.
- **Max output tokens** caps the reply length. Reasoning models spend part of this budget
  thinking, so keep it at a few thousand for them.

## Using it in the terminal

Tap the sparkle button in the terminal's bottom bar.

- **Generate** — describe what you want ("best audio of this playlist as MP3, numbered").
- **Explain** — explains the command on the current prompt line (or any command you paste).
- **Troubleshoot** — sends the current line and, if you leave the box ticked, recent terminal
  output so the model can diagnose the error and propose a fix.

The answer comes with an **editable command preview**. Nothing runs until you choose:

- **Insert** types the command at the prompt (replacing what was there) without running it.
- **Run** types it and presses Enter. If the command looks risky — it is not a yt-dlp
  command, chains or redirects commands, runs other programs (`--exec`, `--netrc-cmd`, …),
  updates yt-dlp, or contains credentials — you are asked to confirm first.

Follow-up requests keep the conversation context ("now only 720p"); **New** starts over.

## Privacy and security

- API keys are encrypted with AES-256-GCM using a key held in the Android Keystore, stored in
  a private file of their own, and never included in the app's settings backup or Android
  backups. They are sent only to the provider they belong to.
- Provider profiles (name, URL, model) are also kept out of the settings backup.
- What is sent: your request, the command being explained or troubleshot, and — only in
  Troubleshoot with the box ticked — up to ~6,000 characters of recent terminal output.
  Passwords and usernames passed to yt-dlp, auth/cookie headers, bearer tokens, credentials in
  URLs, secret URL parameters and API-key-looking strings are redacted first. Redaction is
  best-effort; avoid troubleshooting output that contains secrets in other forms.
- Model output is treated as untrusted: control characters and line breaks are stripped or
  blocked so a suggestion can never press Enter by itself, and risky commands need an explicit
  confirmation.
