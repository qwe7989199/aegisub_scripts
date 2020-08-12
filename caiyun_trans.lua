local tr = aegisub.gettext
script_name = tr"彩云小译"
script_author = "domo"
script_description = "彩云小译翻译"
script_version = "0.2"

local linesPerReq = 40
local ffi = require"ffi"
local C = ffi.C
-- local Y = require 'Yutils'
-- local tts = Y.table.tostring

ffi.cdef[[
void Sleep(int ms);
]]

function translate(source, direction)
	aegisub.progress.task("请求API中")
	local request = require'luajit-request'
	local json = require'json'
	local url = "http://api.interpreter.caiyunai.com/v1/translator"
	local token = "3975l6lr5pcbvidl6jl2"  --测试token，如有需要请自行申请
    payload = json.encode({
            ["source"] = source, 
            ["trans_type"] = direction,
            ["request_id"] = "aegisub-translator",
			["detect"] = string.find(direction, "auto"),
			["replaced"] = true,
            })
	local headers = {
            ['content-type'] = "application/json",
            ['x-authorization'] = "token "..token
    }
    local response, err, message = request.send(url,{ method = "POST", headers = headers, data = payload})
	if (not response) then
		aegisub.debug.out(err, message)
	else
		-- aegisub.debug.out(tts(json.decode(response.body)))
		return json.decode(response.body)
	end
end

function responseDealer(response, orgTimes, stdLine, subtitles)
	if response['message'] then
		aegisub.debug.out(response['message'].."\n")
	elseif response['target'] then
		toAssLines(response['target'], orgTimes, stdLine, subtitles)
	else
		aegisub.debug.out("未知错误\n")
	end
end

function toAssLines(texts, times, stdLine, subtitles)
	aegisub.progress.task("正在转换为ASS格式")
	if #texts ~= #times and #times~=1 then
		aegisub.debug.out("发送的行数和返回的行数不一致\n")
		aegisub.cancel()
	end
	if type(texts)=="string" then
		stdLine.text = texts
		stdLine.actor = direction
		stdLine.start_time = times[1].start_time
		stdLine.end_time = times[1].end_time
		subtitles.append(stdLine)
	else
		for i=1,#texts do
			stdLine.text = texts[i]
			stdLine.actor = direction
			stdLine.start_time = times[i].start_time
			stdLine.end_time = times[i].end_time
			subtitles.append(stdLine)
		end
	end
end

function transLines(subtitles, selected_lines)
	direction = getDirection()
	local orgTimes, source, lineCount, requestNum = {}, {}, 1, 0
	for i=1,#subtitles do
		if subtitles[i].class=="dialogue" then
			dialogue_start = i
			stdLine = subtitles[i]
			break
		end
	end
	for z, i in ipairs(selected_lines) do
		aegisub.progress.set(z/#selected_lines*100)
		aegisub.debug.out("正在翻译，进度 ["..tostring(z).."/"..tostring(#selected_lines).."]\n")
        local line = subtitles[i]
		if lineCount<linesPerReq then
			orgTimes[lineCount] = {start_time = line.start_time, end_time = line.end_time}
			source[lineCount] = line.text:gsub("{[^}]+}", "")
			lineCount = lineCount + 1
			if z==#selected_lines then
				requestNum = requestNum + 1
				response = translate(source, direction)
				responseDealer(response, orgTimes, stdLine, subtitles)
			end
		else
			orgTimes[lineCount] = {start_time = line.start_time, end_time = line.end_time}
			source[lineCount] = line.text:gsub("{[^}]+}", "")
			requestNum = requestNum + 1
			response = translate(source, direction)
			responseDealer(response, orgTimes, stdLine, subtitles)
			orgTimes, source, lineCount = {}, {}, 1
			C.Sleep(200)
		end
	end
	aegisub.debug.out("————————————————————\n翻译完成，共请求 ["..tostring(requestNum).."] 次\n\n*如发现未翻译的行，请尝试手动指定翻译方向")
end

function getDirection()
	btn,res = aegisub.dialog.display({
	{x=0,y=0,class="label",label="选择翻译方向："},
	{x=1,y=0,class="dropdown",name="direction",value="auto2zh",items={'auto2zh','en2zh','jp2zh','zh2en','zh2jp'}}},
	{"OK","Cancel"})
	if btn~="Cancel" then
		return res.direction
	else 
		aegisub.cancel()
	end
end	

aegisub.register_macro("文本工具/"..script_name, script_description, transLines)