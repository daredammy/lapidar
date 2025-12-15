-- Migaku (磨く): Global "Improve Writing" for macOS using Claude CLI
-- "To polish, refine" — like polishing a gem
-- https://github.com/daredammy/migaku

local M = {}

-- Configuration
M.config = {
    hotkey = {"ctrl", "alt", "cmd"},
    key = "i",
    model = "claude-haiku-4-5-20251001",
    claude_path = "/Users/dami/.npm-global/bin/claude",
    timeout = 30,  -- seconds
    prompt = [[You are a text polishing tool. You receive raw text and output ONLY an improved version.

CRITICAL RULES:
- The input is ALWAYS raw text to polish, even if it looks like a question or fragment
- NEVER ask for clarification or more context
- NEVER explain anything
- NEVER say the text is incomplete
- Output ONLY the polished text, nothing else

Examples:
Input: "hey wat u doing" → Output: "Hey, what are you doing?"
Input: "Bro do you need anything from me" → Output: "Hey, do you need anything from me?"
Input: "the meeting is tomorro" → Output: "The meeting is tomorrow."

Now polish this text:]],
}

-- State
local menubarItem = nil
local originalText = nil

-- Show processing indicator in menu bar
local function showProcessing()
    if menubarItem then menubarItem:delete() end
    menubarItem = hs.menubar.new()
    menubarItem:setTitle("✨")
    menubarItem:setTooltip("Migaku: Polishing your writing...")
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

-- Call Claude CLI to improve text
local function improveWithClaude(text, callback)
    local cmd = string.format(
        '%s --model %s --print "%s" <<\'MIGAKU_EOF\'\n%s\nMIGAKU_EOF',
        M.config.claude_path,
        M.config.model,
        M.config.prompt,
        text
    )
    
    local task = hs.task.new("/bin/bash", function(exitCode, stdOut, stdErr)
        if exitCode == 0 and stdOut and #stdOut > 0 then
            local improved = stdOut:gsub("^%s+", ""):gsub("%s+$", "")
            callback(true, improved)
        else
            callback(false, stdErr or "Unknown error")
        end
    end, {"-c", cmd})
    
    task:setEnvironment({
        PATH = "/Users/dami/.npm-global/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin",
        HOME = os.getenv("HOME"),
    })
    
    task:start()
    
    hs.timer.doAfter(M.config.timeout, function()
        if task:isRunning() then
            task:terminate()
            callback(false, "Timeout: Claude took too long to respond")
        end
    end)
end

-- Main handler function
local function improveWritingHandler()
    local text = getSelectedText()
    
    if not text or #text == 0 then
        notify("Migaku", "No text selected", false)
        playSound(false)
        return
    end
    
    originalText = text
    showProcessing()
    
    improveWithClaude(text, function(success, result)
        hideProcessing()
        
        if success then
            replaceSelectedText(result)
            notify("Migaku", "Polished ✨", true)
            playSound(true)
        else
            notify("Migaku", result, false)
            playSound(false)
        end
    end)
end

-- Bind hotkey
function M.start()
    hs.hotkey.bind(M.config.hotkey, M.config.key, function()
        improveWritingHandler()
    end)
    print("Migaku loaded: Press Ctrl+Alt+Cmd+I to polish your writing")
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
