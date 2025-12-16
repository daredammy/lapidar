# Migaku ✨ 磨く

> *"To polish, refine"* — like polishing a gem

A global macOS "Improve Writing" hotkey powered by LLMs. Select text anywhere, press `⌃⌥⌘I`, get polished writing instantly.

## Features

- **Global hotkey** — Works in any application (Notion, Slack, browser, anywhere)
- **Multi-provider** — Supports Gemini and Claude
- **Fast** — Uses lightweight models for quick responses (~2-3 seconds)
- **Visual feedback** — Menu bar indicator while processing
- **Sound feedback** — Audio cues for success/failure
- **Non-destructive** — Preserves your clipboard contents

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) or [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli)

## Installation

### 1. Install Hammerspoon

```bash
brew install --cask hammerspoon
```

Launch Hammerspoon and grant Accessibility permissions when prompted.

### 2. Install your preferred LLM CLI

**Gemini (default):**
```bash
npm install -g @google/gemini-cli
gemini  # Follow authentication prompts
```

**Claude:**
```bash
npm install -g @anthropic-ai/claude-code
claude  # Follow authentication prompts
```

### 3. Install Migaku

Clone this repo:

```bash
git clone https://github.com/daredammy/migaku.git ~/.hammerspoon/migaku
```

Add to your `~/.hammerspoon/init.lua`:

```lua
local migaku = require("migaku.migaku")
migaku.start()
```

Reload Hammerspoon config (click menu bar icon → Reload Config).

## Usage

1. Select text in any application
2. Press `⌃⌥⌘I` (Control + Option + Command + I)
3. Wait for the ✨ indicator
4. Text is replaced with polished version

## Configuration

Customize in your `init.lua`:

```lua
local migaku = require("migaku.migaku")
migaku.setup({
    -- Provider: "gemini" or "claude"
    provider = "gemini",
    
    -- Gemini settings
    gemini_model = "gemini-2.5-flash-lite",
    gemini_path = "/path/to/gemini",
    
    -- Claude settings  
    claude_model = "claude-haiku-4-5-20251001",
    claude_path = "/path/to/claude",
    
    -- Change the hotkey
    hotkey = {"ctrl", "alt", "cmd"},
    key = "i",
    
    -- Timeout in seconds
    timeout = 30,
})
```

### Available Models

**Gemini:**
- `gemini-2.5-flash-lite` (default, fastest)
- `gemini-2.5-flash`
- `gemini-2.5-pro`

**Claude:**
- `claude-haiku-4-5-20251001` (default, fastest)
- `claude-sonnet-4-5-20250929`

## Troubleshooting

**"No text selected" error**
- Make sure text is actually selected before pressing the hotkey
- Some applications may not support standard copy/paste

**Hotkey not working**
- Ensure Hammerspoon has Accessibility permissions (System Settings → Privacy & Security → Accessibility)
- Check if another app is using the same hotkey

**LLM errors**
- Run `gemini --help` or `claude --version` to verify CLI is installed
- Run `gemini` or `claude` to check authentication status

## How It Works

1. Captures selected text via simulated `⌘C`
2. Sends text to LLM via CLI
3. Replaces selection with improved text via simulated `⌘V`
4. Restores original clipboard contents

## License

MIT

## Credits

Built with [Hammerspoon](https://www.hammerspoon.org/), [Gemini CLI](https://github.com/google-gemini/gemini-cli), and [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli).

---

*Migaku (磨く) — Japanese for "to polish, refine"*
