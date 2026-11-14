# handy-rewrite

A tiny rewrite picker for [Handy](https://github.com/cjpais/Handy), the free, open-source
speech-to-text app. After each dictation a small hotbar appears next to Handy's overlay and
lets you choose what gets pasted:

<p align="center"><img src="docs/picker-en.png" width="336" alt="The picker: Insert, Fix, Casual, Professional"></p>

| Key | Tile | What it does |
|---|---|---|
| `↵` | **Insert** | paste the transcript unchanged (default, also when the countdown runs out) |
| `F` / `1` | **Fix** | fix speech-recognition mistakes, spelling and punctuation – your wording stays |
| `C` / `2` | **Casual** | natural and friendly, for colleagues and Slack/Teams |
| `P` / `3` | **Professional** | clear and concise, for customers, emails and tickets |
| `Esc` | – | cancel: paste nothing, put the transcript on the clipboard |

Arrow keys and the mouse work too; hovering the picker pauses the countdown. With the UI
in German (`"language": "de"`, or `auto` on a German system) the tiles read
*Direkt · Korrigieren · Locker · Professionell* with the keys `K`, `L`, `P`:

<p align="center"><img src="docs/picker-de.png" width="336" alt="The picker in German"></p>

The rewrite goes through any **OpenAI-compatible** `/chat/completions` endpoint (OpenAI,
OpenRouter, a local LLM server, a proxy, …). The prompts are tuned for German, English
and mixed German/English ("Denglisch") dictation, e.g. *"das Verlease gemacht und das
Auf-Modul gematcht"* → *"das Release gemacht und das Auth-Modul gemergt"*.

## Why

Handy has its own post-processing, but it is bound to a separate shortcut. handy-rewrite
lets you dictate with one shortcut and decide *afterwards* – in every app, including
terminals and Electron apps that don't support the macOS Services menu. If you don't
choose, nothing changes: after 15 s the transcript is pasted as-is.

## Requirements

- macOS 14 or later
- [Handy](https://handy.computer) 0.10 or later (transcription hooks)
- Swift compiler – the Command Line Tools are enough: `xcode-select --install`
- An API key for an OpenAI-compatible endpoint

## Install

```sh
git clone https://github.com/aNNdii/handy-rewrite.git
cd handy-rewrite
./install.sh
```

The script builds the binary to `~/.local/bin/handy-rewrite` (override with `PREFIX=…`),
installs Handy's transcription hook (an existing hook is backed up) and creates
`~/.config/handy-rewrite/config.json`.

Then configure the endpoint and store the API key in the macOS Keychain:

```sh
$EDITOR ~/.config/handy-rewrite/config.json
security add-generic-password -s handy-rewrite -a "$USER" -w   # prompts for the key
handy-rewrite config                                           # check
```

Uninstall with `./install.sh --uninstall` (keeps the config).

## Configuration

`~/.config/handy-rewrite/config.json`:

```json
{
  "base_url": "https://api.openai.com/v1",
  "model": "gpt-4.1-mini",
  "keychain_service": "handy-rewrite",
  "pick_timeout": 15,
  "language": "auto"
}
```

| Key | Default | |
|---|---|---|
| `base_url` | – | OpenAI-compatible base URL (without `/chat/completions`) |
| `model` | – | model name; a small, fast model is best |
| `keychain_service` | `handy-rewrite` | Keychain item (generic password) holding the API key |
| `pick_timeout` | `15` | seconds until the transcript is pasted as-is |
| `language` | `auto` | picker language: `auto` (system), `de` or `en` |

Every key can be overridden with an environment variable (`HANDY_REWRITE_BASE_URL`,
`HANDY_REWRITE_MODEL`, `HANDY_REWRITE_KEYCHAIN_SERVICE`, `HANDY_REWRITE_PICK_TIMEOUT`,
`HANDY_REWRITE_LANGUAGE`). `HANDY_REWRITE_API_KEY` skips the Keychain. The API key is
never read from the config file.

## Command line

The rewrite modes also work on their own:

```sh
pbpaste | handy-rewrite professional | pbcopy
echo "also äh das verlease ist durch" | handy-rewrite clean
```

Modes: `clean` (Fix), `casual`, `professional`.

## How it works

Handy runs `~/Library/Application Support/com.pais.handy/hooks/transcription` after every
transcription: the transcript arrives on stdin, whatever the hook prints is pasted. Handy
kills hooks after 30 s, so handy-rewrite always answers within 28 s – the pick window
closes after at most 22 s (even while hovering), the rest is reserved for the LLM call.

- **Insert / timeout** – prints the transcript unchanged.
- **A rewrite mode** – one request to your endpoint; on any error the original is pasted
  and a notification tells you why.
- **Esc** – copies the transcript to the clipboard and prints nothing, so Handy pastes
  nothing. Handy's history keeps every transcript as well.

The picker is a single Swift file (SwiftUI + AppKit), ~0.6 MB, starts in about 10 ms and
uses no CPU while it waits (the countdown is a Core Animation layer). Your text is only
sent to the endpoint when you choose a rewrite mode.

## License

MIT – see [LICENSE](LICENSE). Not affiliated with Handy; colors and overlay geometry are
borrowed from Handy (MIT) so the picker looks like part of it.
