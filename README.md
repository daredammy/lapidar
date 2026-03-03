# Lapidar

> *From "lapidary"* — the art of cutting and polishing gems

A global macOS "Improve Writing" hotkey powered by LLMs. Select text anywhere, press a hotkey, get polished writing instantly.

## Features

- **Global hotkeys** — Works in any application (Notion, Slack, browser, anywhere)
- **Multi-provider** — Supports Copilot, Gemini, and Claude
- **Chooser mode** — Pick from presets (shorten, formalize, casualize, markdown, bullets) or enter a custom instruction
- **Fast** — Uses lightweight models for quick responses (~2-3 seconds)
- **Visual feedback** — Menu bar `✨` indicator while processing
- **Sound feedback** — Audio cues for success/failure
- **Non-destructive** — Preserves your clipboard contents

## Hotkeys

| Hotkey | Action |
|---|---|
| `Ctrl+Alt+Cmd+I` | Quick polish — improves writing using default prompt |
| `Ctrl+Alt+Cmd+J` | Chooser — pick a preset or enter a custom instruction |

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- One of: [Copilot CLI](https://github.com/github/gh-copilot), [Gemini CLI](https://github.com/google-gemini/gemini-cli), or [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli)

## Installation

### 1. Install Hammerspoon

```bash
brew install --cask hammerspoon
```

Launch Hammerspoon and grant Accessibility permissions when prompted (System Settings → Privacy & Security → Accessibility).

### 2. Install your preferred LLM CLI

**Copilot (default):**
```bash
gh extension install github/gh-copilot
# Then alias: alias copilot="gh copilot"
```

**Gemini:**
```bash
npm install -g @google/gemini-cli
gemini  # Follow authentication prompts
```

**Claude:**
```bash
npm install -g @anthropic-ai/claude-code
claude  # Follow authentication prompts
```

### 3. Install Lapidar

Clone this repo into your Hammerspoon config:

```bash
git clone https://github.com/daredammy/lapidar.git ~/.hammerspoon/lapidar
```

Or symlink from wherever you keep your projects:

```bash
git clone https://github.com/daredammy/lapidar.git ~/development/lapidar
ln -s ~/development/lapidar ~/.hammerspoon/lapidar
```

Add to your `~/.hammerspoon/init.lua` (see [init.lua.example](init.lua.example) for reference):

```lua
local lapidar = require("lapidar.lapidar")
lapidar.start()
```

Reload Hammerspoon config (click menu bar icon → Reload Config, or `Cmd+Shift+R`).

## Usage

### Quick polish (`Ctrl+Alt+Cmd+I`)

1. Select text in any application
2. Press `Ctrl+Alt+Cmd+I`
3. Wait for the `✨` menu bar indicator
4. Text is replaced with a polished version

### Chooser mode (`Ctrl+Alt+Cmd+J`)

1. Select text in any application
2. Press `Ctrl+Alt+Cmd+J`
3. Pick a preset from the list (or choose **Custom instruction…**)
4. Text is replaced with the result

#### Built-in presets

| Preset | What it does |
|---|---|
| ✂️ Shorten | Makes text more concise while preserving the key message |
| 👔 More formal | Shifts tone to be professional and formal |
| 😊 More casual | Shifts tone to be casual and friendly |
| 📝 Format as markdown | Applies proper markdown syntax |
| 📋 Convert to bullets | Converts text into a bulleted list |
| ✏️ Custom instruction… | Opens a dialog for a freeform instruction |

## Configuration

Customize in your `~/.hammerspoon/init.lua` by calling `setup()` instead of `start()`:

```lua
local lapidar = require("lapidar.lapidar")
lapidar.setup({
    -- Provider: "copilot", "gemini", or "claude"
    provider = "copilot",

    -- Copilot settings
    copilot_model = "gpt-4.1",
    copilot_path = "copilot",  -- or full path if not in PATH

    -- Gemini settings
    gemini_model = "gemini-2.5-flash-lite",
    gemini_path = "gemini",

    -- Claude settings
    claude_model = "claude-haiku-4-5-20251001",
    claude_path = "claude",

    -- Quick polish hotkey
    hotkey = {"ctrl", "alt", "cmd"},
    key = "i",

    -- Chooser hotkey
    chooser_hotkey = {"ctrl", "alt", "cmd"},
    chooser_key = "j",

    -- Timeout in seconds
    timeout = 30,
})
```

### Available Models

**Copilot:**
- `gpt-4.1` (default)

**Gemini:**
- `gemini-2.5-flash-lite` (default, fastest)
- `gemini-2.5-flash`
- `gemini-2.5-pro`

**Claude:**
- `claude-haiku-4-5-20251001` (default, fastest)
- `claude-sonnet-4-5-20250929`

### Custom presets

Override the default presets in `setup()`:

```lua
lapidar.setup({
    presets = {
        { id = "shorten",  text = "✂️  Shorten",     instruction = "Make this text more concise." },
        { id = "eli5",     text = "👶  Simplify",     instruction = "Explain this like I'm 5." },
        { id = "custom",   text = "✏️  Custom…",      instruction = nil },  -- keep this last
    },
})
```

Each preset requires `id` (unique string), `text` (chooser label), and `instruction` (prompt appended to the base prompt, or `nil` for the custom dialog).

### Custom prompt

The base writing prompt lives in `prompt.txt` inside the lapidar directory. Edit it to change the default polish behavior, or point to a different file:

```lua
lapidar.setup({
    prompt_file = hs.configdir .. "/lapidar/my-prompt.txt",
})
```

## Troubleshooting

**"No text selected" error**
- Make sure text is selected before pressing the hotkey
- Some apps may not support standard copy/paste shortcuts

**Hotkey not working**
- Ensure Hammerspoon has Accessibility permissions: System Settings → Privacy & Security → Accessibility
- Check whether another app is consuming the same hotkey

**LLM errors**
- Verify the CLI is installed and authenticated: run `gemini`, `claude`, or your copilot command directly in a terminal
- Check the Hammerspoon console (menu bar icon → Open Console) for the full error message

**Output looks wrong or is empty**
- Check `prompt.txt` is readable and non-empty
- Try increasing `timeout` if you're using a slower model

## How It Works

1. Captures selected text via simulated `Cmd+C`
2. Builds a shell command for the configured LLM CLI
3. Runs the command asynchronously via `hs.task`
4. Replaces the selection with the improved text via simulated `Cmd+V`
5. Restores original clipboard contents

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT

## Credits

Built with [Hammerspoon](https://www.hammerspoon.org/), [Gemini CLI](https://github.com/google-gemini/gemini-cli), and [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli).
