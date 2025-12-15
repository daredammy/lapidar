# Migaku ✨ 磨く

> *"To polish, refine"* — like polishing a gem

A global macOS "Improve Writing" hotkey powered by Claude AI. Select text anywhere, press `⌃⌥⌘I`, get polished writing instantly.

## Features

- **Global hotkey** — Works in any application (Notion, Slack, browser, anywhere)
- **Fast** — Uses Claude Haiku 4.5 for quick responses (~2-3 seconds)
- **Visual feedback** — Menu bar indicator while processing
- **Sound feedback** — Audio cues for success/failure
- **Non-destructive** — Preserves your clipboard contents

## Requirements

- macOS
- [Hammerspoon](https://www.hammerspoon.org/)
- [Claude CLI](https://docs.anthropic.com/en/docs/claude-cli) (authenticated)

## Installation

### 1. Install Hammerspoon

```bash
brew install --cask hammerspoon
```

Launch Hammerspoon and grant Accessibility permissions when prompted.

### 2. Install Claude CLI

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
    -- Change the hotkey
    hotkey = {"ctrl", "alt", "cmd"},
    key = "i",
    
    -- Use a different model
    model = "claude-sonnet-4-5-20250929",
    
    -- Custom prompt
    prompt = "Fix grammar and spelling only. Output ONLY the corrected text.",
    
    -- Timeout in seconds
    timeout = 30,
    
    -- Path to Claude CLI (if not in default location)
    claude_path = "/usr/local/bin/claude",
})
```

## Troubleshooting

**"No text selected" error**
- Make sure text is actually selected before pressing the hotkey
- Some applications may not support standard copy/paste

**Hotkey not working**
- Ensure Hammerspoon has Accessibility permissions (System Preferences → Security & Privacy → Accessibility)
- Check if another app is using the same hotkey

**Claude errors**
- Run `claude --version` to verify CLI is installed
- Run `claude` to check authentication status

## How It Works

1. Captures selected text via simulated `⌘C`
2. Sends text to Claude Haiku via CLI
3. Replaces selection with improved text via simulated `⌘V`
4. Restores original clipboard contents

## License

MIT

## Credits

Built with [Hammerspoon](https://www.hammerspoon.org/) and [Claude](https://claude.ai).

---

*Migaku (磨く) — Japanese for "to polish, refine"*
