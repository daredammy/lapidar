# Contributing to Lapidar

Thanks for your interest in contributing to Lapidar!

## Getting Started

1. Fork the repository
2. Clone your fork to `~/.hammerspoon/lapidar`
3. Make your changes
4. Test with Hammerspoon (`Cmd+Shift+R` to reload config)
5. Submit a pull request

## Development Setup

```bash
# Clone to Hammerspoon config directory
git clone https://github.com/YOUR_USERNAME/lapidar.git ~/.hammerspoon/lapidar

# Add to your ~/.hammerspoon/init.lua
require("lapidar").setup()
```

## Code Style

- Use 4 spaces for indentation
- Keep functions focused and small
- Add comments for non-obvious logic
- Follow existing naming conventions (camelCase for functions, UPPER_CASE for constants)

## Testing Changes

1. Reload Hammerspoon config: `Cmd+Shift+R` (or via menubar)
2. Select some text in any app
3. Test the hotkey (`Ctrl+Alt+Cmd+I`)
4. Check Hammerspoon console for errors

## Pull Requests

- Keep PRs focused on a single change
- Update README.md if adding features or changing behavior
- Test with at least one LLM provider before submitting

## Adding a New Provider

To add support for a new LLM CLI:

1. Add config options in `M.config` (path, model)
2. Add command building logic in `buildCommand()`
3. Update README.md with setup instructions
4. Test thoroughly

## Reporting Issues

When reporting bugs, please include:

- macOS version
- Hammerspoon version
- Which LLM provider you're using
- Steps to reproduce
- Any error messages from the Hammerspoon console

## Questions?

Open an issue for questions or suggestions.
