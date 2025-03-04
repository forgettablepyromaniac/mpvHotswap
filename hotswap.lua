local mp = require 'mp'
local utils = require 'mp.utils'

-- OS detection
local is_windows = package.config:sub(1,1) == "\\"
local is_unix = not is_windows

function kill_other_instances()
    local current_pid = tostring(mp.get_property("pid"))
    
    -- Define cmds based on OS
    local process_list_cmd
    if is_windows then
        process_list_cmd = {'tasklist', '/FI', 'IMAGENAME eq mpv.exe'}
    elseif is_unix then
        process_list_cmd = {'ps', '-A', '-o', 'pid,comm'}
    end

    -- Get list of processes
    local result = utils.subprocess({args = process_list_cmd, cancellable = false})
    if result.status ~= 0 then
        mp.msg.error("Failed to fetch process list: " .. (result.error or "unknown"))
        return
    end

    for line in result.stdout:gmatch("[^\r\n]+") do
        -- Extract PID and process name
        local pid, process_name
        if is_windows then
            pid = line:match("%s(%d+)%s")
            process_name = line:match("^mpv%.exe")
        elseif is_unix then
            pid, process_name = line:match("^%s*(%d+)%s+(.+)")
        end

        mp.msg.info("is_unix: " .. tostring(pid))

        -- Kill the process if it's an MPV instance and not the current one
        if pid and (process_name == "mpv" or process_name == "mpv.exe") then
            if pid ~= current_pid then
                mp.msg.info("Killing MPV instance with PID: " .. pid)
                if is_windows then
                    os.execute('taskkill /PID ' .. pid .. ' /F')
                elseif is_unix then
                    os.execute('kill -9 ' .. pid)
                end
            end
        end
    end
end

-- Run the function on load
kill_other_instances()
