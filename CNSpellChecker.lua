local tr = aegisub.gettext
script_name = tr"文本纠错"
script_description = tr"利用百度的API进行文本纠错"
script_author = "domo"
script_version = "0.1"

local request = require('luajit-request')
local json = require('json')
local utf8 = require('utf8')
local ffi = require"ffi"
local C = ffi.C

ffi.cdef[[
void Sleep(int ms);
]]

-- Necessary
local AccessToken = ""

function split(str, split_char)
	local sub_str_tab = {}
		while true do
			local pos = string.find(str, split_char)
			if not pos then
			_G.table.insert(sub_str_tab,str)
				break
			end
			local sub_str = string.sub(str, 1, pos - 1)
			_G.table.insert(sub_str_tab,sub_str)
			str = string.sub(str, pos + 1, string.len(str))
		end
	return sub_str_tab
end

function sendRequest(text)
	local url = "https://aip.baidubce.com/rpc/2.0/nlp/v1/ecnet"
	local url = url.."?charset=UTF-8&access_token="..AccessToken
	text = json.encode({text = text})
	local result, err, message = request.send(url, {
		method = "POST",
		headers = {['content-type'] = "application/json"},
		data = text
	})
	if (not result) then
		aegisub.debug.out(err, message)
	else
		return result.body
	end
end

function showSuggestion(orgText,startLineNum)
	-- aegisub.debug.out(utf8.len(orgText))
	-- aegisub.debug.out(string.len(orgText))
	orgTextTbl = split(orgText,"&")
	response = sendRequest(orgText)
	result = json.decode(response)
	if result.error_code then
		aegisub.debug.out("error_code: "..result.error_code..", error_msg: "..result.error_msg)
	else
		wholeResult = result.item["correct_query"]
		resultWords = result.item["vec_fragment"]
		lineCount = 1
		allNewWords = {}
		andPos = string.find(wholeResult,"&") or string.len(wholeResult)
		for i=1,#resultWords do
			wrongWord = resultWords[i]["ori_frag"]
			guessWord = resultWords[i]["correct_frag"]
			beginPos = resultWords[i]["begin_pos"]
			endPos = resultWords[i]["end_pos"]
			if beginPos > andPos-1 then
				lineCount = lineCount + 1
				andPos = string.find(wholeResult,"&",andPos+1)
			end
			table.insert(allNewWords,{sPos = beginPos,ePos = endPos,guessWord = guessWord,wrongWord = wrongWord,inLine = lineCount})
		end
		resultTextTbl = split(wholeResult,"&")
		counter = 0
		for i=1,#resultTextTbl do
			if orgTextTbl[i]~=resultTextTbl[i] then
				counter = counter + 1
				content = "---------------第"..tostring(startLineNum+i-#resultTextTbl).."行---------------\n建议："..orgTextTbl[i].."->"..resultTextTbl[i]..'\n细节：\n'
				aegisub.debug.out(content)
				file:write(content)
				for j=#allNewWords,1,-1 do
					if allNewWords[j].inLine==i then
						aegisub.debug.out(allNewWords[j].wrongWord..'->'..allNewWords[j].guessWord..'\n')
						file:write(allNewWords[j].wrongWord..'->'..allNewWords[j].guessWord..'\n')
						table.remove(allNewWords,j)
					end
				end
			end
		end
	end
end

function checkText(subtitles,selected_lines)
	local requestNum = 0
	local path = aegisub.decode_path("?data".."\\CNCheckHis")
	local timestamp = os.date("%Y%m%d_%H%M%S")
	fileName = path.."\\"..timestamp..".txt"
	if not io.open(path, "rb") then
		os.execute("mkdir "..path)
	end
	file = io.open(fileName,"w")
	for i=1,#subtitles do
		if subtitles[i].class=="dialogue" then
			dialogue_start=i
			break
		end
	end
	orgText = ""
	for z, i in ipairs(selected_lines) do
		l = subtitles[i]
		if string.len(l.text)>=511 then
			aegisub.debug.out("第"..tostring(i-dialogue_start+1).."行的文本过长，无法处理。")
		end
		if (string.len(orgText)+string.len(l.text.."&"))<511 and z~=#selected_lines then
			orgText = orgText..l.text.."&"
			multipleLine = true
		else
			if multipleLine then
				showSuggestion(orgText,i-dialogue_start+1)
				requestNum = requestNum + 1
				C.Sleep(250)
			end
			multipleLine = false
			orgText = l.text
			showSuggestion(orgText,i-dialogue_start+1)
			requestNum = requestNum + 1
			C.Sleep(250)
		end
	end
	file:close()
	btn, result = aegisub.dialog.display({{class="label",label="是否保留本地文件？"}},{"OK","Cancel"})
	if btn ~= "OK" then
		os.remove(fileName)
	end
	aegisub.debug.out("完成，共请求"..tostring(requestNum).."次")
end

aegisub.register_macro(script_name, script_description, checkText)
