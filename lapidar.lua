-- Lapidar: Global "Improve Writing" for macOS using LLM CLI
-- From "lapidary" — the art of cutting and polishing gems
-- https://github.com/daredammy/lapidar

local M = {}

-- Configuration
M.config = {
    hotkey = {"ctrl", "alt", "cmd"},
    key = "i",

    -- Chooser hotkey (with presets)
    chooser_hotkey = {"ctrl", "alt", "cmd"},
    chooser_key = "j",

    -- Provider: "ollama", "gemini", "claude", or "copilot"
    provider = "ollama",

    -- Ollama settings (local, via REST API at localhost:11434)
    ollama_url = "http://localhost:11434/api/generate",
    ollama_model = "gemma4:e4b",

    -- Gemini settings (uses PATH by default)
    gemini_path = "gemini",
    gemini_model = "gemini-2.5-flash-lite",

    -- Claude settings (uses PATH by default)
    claude_path = "claude",
    claude_model = "claude-haiku-4-5-20251001",

    -- Copilot settings (uses PATH by default)
    copilot_path = "copilot",
    copilot_model = "gpt-4.1",

    timeout = 30,  -- seconds

    prompt_file = hs.configdir .. "/lapidar/prompt.txt",

    -- Presets for chooser (id, text, instruction)
    presets = {
        { id = "shorten", text = "✂️  Shorten", instruction = "Make this text more concise while preserving the key message." },
        { id = "formal", text = "👔  More formal", instruction = "Make this text more formal and professional in tone." },
        { id = "casual", text = "😊  More casual", instruction = "Make this text more casual and friendly in tone." },
        { id = "markdown", text = "📝  Format as markdown", instruction = "Format this text using proper markdown syntax." },
        { id = "bullets", text = "📋  Convert to bullets", instruction = "Convert this text into a bulleted list." },
        { id = "custom", text = "✏️  Custom instruction...", instruction = nil },
    },
}

-- State
local menubarItem = nil
local originalText = nil

-- Read prompt from file
local function getPrompt()
    local file = io.open(M.config.prompt_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        return content
    else
        error("Could not read prompt file: " .. M.config.prompt_file)
    end
end

-- Show processing indicator in menu bar
local function showProcessing()
    if menubarItem then menubarItem:delete() end
    menubarItem = hs.menubar.new()
    menubarItem:setTitle("✨")
    menubarItem:setTooltip("Lapidar: Polishing your writing...")
end

-- Hide processing indicator
local function hideProcessing()
    if menubarItem then
        menubarItem:delete()
        menubarItem = nil
    end
end

-- Show notification
local function notify(title, message, success)
    hs.notify.new({
        title = title,
        informativeText = message,
        withdrawAfter = 3,
    }):send()
end

-- Play sound feedback
local function playSound(success)
    if success then
        hs.sound.getByName("Glass"):play()
    else
        hs.sound.getByName("Basso"):play()
    end
end

-- Get selected text via clipboard
local function getSelectedText()
    local originalClipboard = hs.pasteboard.getContents()

    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.usleep(100000)  -- 100ms wait for clipboard

    local selectedText = hs.pasteboard.getContents()

    if originalClipboard then
        hs.pasteboard.setContents(originalClipboard)
    end

    if selectedText == originalClipboard then
        return nil
    end

    return selectedText
end

-- Replace selected text with new text
local function replaceSelectedText(newText)
    local originalClipboard = hs.pasteboard.getContents()

    hs.pasteboard.setContents(newText)
    hs.timer.usleep(50000)
    hs.eventtap.keyStroke({"cmd"}, "v")

    hs.timer.doAfter(0.5, function()
        if originalClipboard then
            hs.pasteboard.setContents(originalClipboard)
        end
    end)
end

-- Build command based on provider
-- @param text: the text to process
-- @param instruction: optional additional instruction to append to prompt
local function buildCommand(text, instruction)
    local prompt = getPrompt()

    -- Append additional instruction if provided
    if instruction and #instruction > 0 then
        prompt = prompt .. "\n\nAdditional instruction: " .. instruction
    end

    if M.config.provider == "ollama" then
        -- Ollama REST API. jq -Rs slurps stdin as a single string so the
        -- heredoc body becomes the JSON prompt value — no manual escaping.
        -- keep_alive=24h pins the model in VRAM between polishes.
        local fullPrompt = prompt .. "\n\n" .. text
        local cmd = string.format(
            [[jq -Rs --arg model %q '{model:$model,prompt:.,stream:false,keep_alive:"24h"}' <<'LAPIDAR_EOF' | curl -sS %q -d @- | jq -er '.response // error("Ollama error: " + (.error // "unknown"))'
%s
LAPIDAR_EOF]],
            M.config.ollama_model,
            M.config.ollama_url,
            fullPrompt
        )
        return cmd
    elseif M.config.provider == "gemini" then
        -- Gemini CLI: gemini "prompt + text" --model model (positional prompt, no piping)
        local fullPrompt = prompt .. "\n\n" .. text
        local cmd = string.format(
            '%s %q --model %s',
            M.config.gemini_path,
            fullPrompt,
            M.config.gemini_model
        )
        return cmd
    elseif M.config.provider == "copilot" then
        -- Copilot CLI: copilot -p "prompt\n\ntext" --model model --silent
        local fullPrompt = prompt .. "\n\n" .. text
        local cmd = string.format(
            '%s -p %q --model %s --silent',
            M.config.copilot_path,
            fullPrompt,
            M.config.copilot_model
        )
        return cmd
    else
        -- Claude CLI: --bare skips hooks/MCP/CLAUDE.md for faster startup;
        -- apiKeyHelper retrieves the OAuth-managed key from macOS keychain
        local settings = '{"apiKeyHelper":"security find-generic-password -s \'Claude Code\' -w"}'
        local cmd = string.format(
            '%s --bare --settings %q --model %s --print %q <<\'LAPIDAR_EOF\'\n%s\nLAPIDAR_EOF',
            M.config.claude_path,
            settings,
            M.config.claude_model,
            prompt,
            text
        )
        return cmd
    end
end

-- Build PATH including common installation locations
local function buildPath()
    local home = os.getenv("HOME") or ""
    local paths = {
        home .. "/.npm-global/bin",
        "/opt/homebrew/bin",
        "/usr/local/bin",
        "/usr/bin",
        "/bin",
        home .. "/.local/bin",
        home .. "/bin",
    }
    return table.concat(paths, ":")
end

-- Call LLM to improve text
-- @param text: the text to process
-- @param callback: function(success, result) called when done
-- @param instruction: optional additional instruction
local function improveWithLLM(text, callback, instruction)
    local cmd = buildCommand(text, instruction)

    local task = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode == 0 and stdOut and #stdOut > 0 then
            local improved = stdOut:gsub("^%s+", ""):gsub("%s+$", "")
            callback(true, improved)
        else
            callback(false, stdErr or "Unknown error")
        end
    end, {"-c", cmd})

    task:setEnvironment({
        PATH = buildPath(),
        HOME = os.getenv("HOME"),
        USER = os.getenv("USER"),
    })

    task:start()

    hs.timer.doAfter(M.config.timeout, function()
        if task:isRunning() then
            task:terminate()
            callback(false, "Timeout: LLM took too long to respond")
        end
    end)
end

-- Process text with LLM and handle result (shared logic)
-- @param text: the text to process
-- @param instruction: optional additional instruction
local function processText(text, instruction)
    originalText = text
    showProcessing()

    improveWithLLM(text, function(success, result)
        hideProcessing()

        if success then
            replaceSelectedText(result)
            notify("Lapidar", "Polished ✨", true)
            playSound(true)
        else
            notify("Lapidar", result, false)
            playSound(false)
        end
    end, instruction)
end

-- Main handler function (no additional instruction)
local function improveWritingHandler()
    local text = getSelectedText()

    if not text or #text == 0 then
        notify("Lapidar", "No text selected", false)
        playSound(false)
        return
    end

    processText(text, nil)
end

-- Show custom instruction prompt and process
-- @param text: the text to process
local function showCustomPrompt(text)
    local button, input = hs.dialog.textPrompt(
        "Custom Instruction",
        "How should I modify the text?",
        "",
        "OK",
        "Cancel"
    )

    if button == "OK" and input and #input > 0 then
        processText(text, input)
    end
end

-- Build chooser choices from presets
local function buildChooserChoices()
    local choices = {}
    for _, preset in ipairs(M.config.presets) do
        table.insert(choices, {
            text = preset.text,
            subText = preset.instruction or "Enter your own instruction",
            id = preset.id,
            instruction = preset.instruction,
        })
    end
    return choices
end

-- Show chooser with presets
-- @param text: the selected text to process
local function showChooser(text)
    local chooser = hs.chooser.new(function(choice)
        if not choice then return end  -- User cancelled

        if choice.id == "custom" then
            showCustomPrompt(text)
        else
            processText(text, choice.instruction)
        end
    end)

    chooser:choices(buildChooserChoices())
    chooser:placeholderText("Choose how to modify your text...")
    chooser:searchSubText(true)
    chooser:show()
end

-- Chooser handler function
local function chooserHandler()
    local text = getSelectedText()

    if not text or #text == 0 then
        notify("Lapidar", "No text selected", false)
        playSound(false)
        return
    end

    showChooser(text)
end

-- Bind hotkeys
function M.start()
    -- Main hotkey: quick polish
    hs.hotkey.bind(M.config.hotkey, M.config.key, function()
        improveWritingHandler()
    end)

    -- Chooser hotkey: presets + custom
    hs.hotkey.bind(M.config.chooser_hotkey, M.config.chooser_key, function()
        chooserHandler()
    end)

    local providerNames = {ollama = "Ollama", gemini = "Gemini", claude = "Claude", copilot = "Copilot"}
    local provider = providerNames[M.config.provider] or M.config.provider
    print(string.format("Lapidar loaded (%s):", provider))
    print("  Ctrl+Alt+Cmd+I → Quick polish")
    print("  Ctrl+Alt+Cmd+J → Chooser with presets")
end

-- Allow configuration override
function M.setup(opts)
    if opts then
        for k, v in pairs(opts) do
            M.config[k] = v
        end
    end
    M.start()
end

return M
