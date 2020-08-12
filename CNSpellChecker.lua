local tr = aegisub.gettext
script_name = tr"文本纠错"
script_description = tr"利用百度的API进行文本纠错"
script_author = "domo"
script_version = "0.3"

local request = require('luajit-request')
local json = require('json')
-- local utf8 = require('utf8')
local ffi = require"ffi"
local C = ffi.C
local lfs = require('lfs')
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
	-- aegisub.debug.out(tostring(string.len(orgText)).."长度\n")
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
		andPos = string.find(wholeResult,"&") or string.len(wholeResult) --得到 & 的位置，结合beginPos可以知道错别字归属于哪行
		for i=1,#resultWords do
			wrongWord = resultWords[i]["ori_frag"]
			guessWord = resultWords[i]["correct_frag"]
			beginPos = resultWords[i]["begin_pos"]
			endPos = resultWords[i]["end_pos"]
			while beginPos > andPos-1 do --如果错别字的beginPos 比 & 的位置大，那么就进入下一行
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
				for j=#allNewWords,1,-1 do --涉及
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
	local path = aegisub.decode_path("?data")
	lfs.chdir(path)
	local timestamp = os.date("%Y%m%d_%H%M%S")
	--检查是否存在历史存储目录
	tmpfile,err = io.open(path.."\\CNCheckHist")
	if string.find(err,"No such") then
		aegisub.debug.out("尝试创建目录")
		lfs.mkdir("CNCheckHist") --用lfs建文件夹，os.execute会有命令行弹出来，不优雅
	end
	fileName = path.."\\CNCheckHist".."\\"..timestamp..".txt"
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
		--在行与行之间插入&作为分割符号
		if (string.len(orgText)+string.len(l.text.."&"))<511 and z~=#selected_lines then 
			orgText = orgText..l.text.."&" 					--如果长度没有超过511，可以合并文本
		elseif (string.len(orgText)+string.len(l.text.."&"))>=511 and z~=#selected_lines then
			-- aegisub.debug.out(tostring(string.len(orgText)).."多行长度\n")
			showSuggestion(orgText,i-dialogue_start+1) --请求api给出建议
			C.Sleep(250)
			orgText = ""
			requestNum = requestNum + 1					--请求计数+1
		else
			showSuggestion(l.text,i-dialogue_start+1)
			C.Sleep(250)
			requestNum = requestNum + 1
		end
		aegisub.progress.set(z/#selected_lines*100)
		aegisub.progress.task("已处理到第"..tostring(selected_lines[z]-dialogue_start+1).."行")
	end
	aegisub.debug.out("完成，共请求"..tostring(requestNum).."次")
	file:close()
	btn, result = aegisub.dialog.display({{class="label",label="是否保留本地文件？"}},{"OK","Cancel"})
	if btn ~= "OK" then
		os.remove(fileName)
	end
end

aegisub.register_macro("文本工具/"..script_name, script_description, checkText)