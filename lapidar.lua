-- Lapidar: Global "Improve Writing" for macOS using LLM CLI
-- From "lapidary" — the art of cutting and polishing gems
-- https://github.com/daredammy/lapidar

local M = {}

-- Configuration
M.config = {
    hotkey = {"ctrl", "alt", "cmd"},
    key = "i",

    -- Provider: "gemini", "claude", or "copilot"
    provider = "copilot",

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

    prompt_file = "/Users/dami/development/open_source/lapidar/prompt.txt",
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
local function buildCommand(text)
    local prompt = getPrompt()

    if M.config.provider == "gemini" then
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
        -- Claude CLI: claude --model model --print "prompt" <<'EOF'\ntext\nEOF
        local cmd = string.format(
            '%s --model %s --print %q <<\'LAPIDAR_EOF\'\n%s\nLAPIDAR_EOF',
            M.config.claude_path,
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
local function improveWithLLM(text, callback)
    local cmd = buildCommand(text)

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
    })

    task:start()

    hs.timer.doAfter(M.config.timeout, function()
        if task:isRunning() then
            task:terminate()
            callback(false, "Timeout: LLM took too long to respond")
        end
    end)
end

-- Main handler function
local function improveWritingHandler()
    local text = getSelectedText()

    if not text or #text == 0 then
        notify("Lapidar", "No text selected", false)
        playSound(false)
        return
    end

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
    end)
end

-- Bind hotkey
function M.start()
    hs.hotkey.bind(M.config.hotkey, M.config.key, function()
        improveWritingHandler()
    end)
    local providerNames = {gemini = "Gemini", claude = "Claude", copilot = "Copilot"}
    local provider = providerNames[M.config.provider] or M.config.provider
    print(string.format("Lapidar loaded (%s): Press Ctrl+Alt+Cmd+I to polish your writing", provider))
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
