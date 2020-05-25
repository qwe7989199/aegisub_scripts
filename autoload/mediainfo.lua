local tr = aegisub.gettext
script_name = tr"MediaInfo"
script_description = tr"Get MediaInfo of selected file"
script_author = "domo"
script_version = "0.1"

local ffi =require("ffi")
local mediaInfo = require("ffi-mediaInfo")

ffi.cdef[[

enum{CP_UTF8 = 65001};
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef const char* LPCSTR;
typedef const char* LPSTR;
typedef const wchar_t* LPCWSTR;
typedef wchar_t* LPWSTR;
typedef int LPBOOL;
int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
int WideCharToMultiByte(UINT, DWORD, LPCWSTR,int, LPSTR, int, LPCSTR, LPBOOL);
typedef int INT;

]]


local function utf8_to_utf16(s)
	-- Get resulting utf16 characters number (+ null-termination)
	local wlen = ffi.C.MultiByteToWideChar(ffi.C.CP_UTF8, 0x0, s, -1, nil, 0)
	-- Allocate array for utf16 characters storage
	local ws = ffi.new("wchar_t[?]", wlen)
	-- Convert utf8 string to utf16 characters
	ffi.C.MultiByteToWideChar(ffi.C.CP_UTF8, 0x0, s, -1, ws, wlen)
	-- Return utf16 C string
	return ws
end

--The reverse conversion of utf8_to_utf16
local function utf16_to_utf8(s)
	local wlen = ffi.C.WideCharToMultiByte(ffi.C.CP_UTF8, 0x0, s, -1, nil, 0, nil, 0)
	local ws = ffi.new("char[?]", wlen)
	ffi.C.WideCharToMultiByte(ffi.C.CP_UTF8, 0x0, s, -1, ws, wlen, nil, 0)
	return ws
end

function mediainfo(filePath)
	--  print Mediainfo version  to console
	aegisub.debug.out("[MediaInfo Version]\n"..ffi.string(mediaInfo.MediaInfoA_Option(nil,"Info_Version", ""))..'\n\n')
	-- create MediaInfo Instance
	local mi = mediaInfo.MediaInfo_New()
	mediaInfo.MediaInfo_Open (mi,filePath)
	mediaInfo.MediaInfoA_Option(mi,"Inform","")
	local generalInfo = mediaInfo.MediaInfo_Inform(mi,1)
	generalInfo = utf16_to_utf8(generalInfo)
	-- close
	-- mediaInfo.MediaInfoA_Option(mi,"Inform","General;%Duration/String1%")
	-- local durationInfo = mediaInfo.MediaInfoA_Inform(mi,1)
	--get general info
	aegisub.debug.out("[General Information]\n"..ffi.string(generalInfo).."\n\n")
	--test for single item
	-- aegisub.debug.out("TEST2:[Single Information]\n".."准确时长: "..ffi.string(durationInfo).."\n\n")
	-- close handle
	mediaInfo.MediaInfo_Close (mi) 
	-- delete MediaInfo instance
	mediaInfo.MediaInfo_Delete (mi)
end

local function audioInfo()
	properties = aegisub.project_properties()
	local filePath = properties.audio_file
	if filePath:sub(1,11)=="dummy-audio" then
		aegisub.debug.out("dummy audio!",3)
		aegisub.cancel()
	elseif filePath=="" then
		filePath = aegisub.dialog.open('Select File','','','',false,true)
		if not filePath then aegisub.cancel() end
	end
	filePath = utf8_to_utf16(filePath)
	mediainfo(filePath)
end

local function videoInfo()
	properties = aegisub.project_properties()
	local filePath = properties.video_file
	if filePath:sub(1,6)=="?dummy" then
		aegisub.debug.out("dummy video!",3)
		aegisub.cancel()
	elseif filePath=="" then
		filePath = aegisub.dialog.open('Select File','','','',false,true)
		if not filePath then aegisub.cancel() end
	end
	filePath = utf8_to_utf16(filePath)
	mediainfo(filePath)
end

local function otherInfo()
	local filePath = aegisub.dialog.open('Select File','','','',false,true)
	if not filePath then aegisub.cancel() end
	filePath = utf8_to_utf16(filePath)
	mediainfo(filePath)
end


aegisub.register_macro(script_name.."/Video", script_description, videoInfo)
aegisub.register_macro(script_name.."/Audio", script_description, audioInfo)
aegisub.register_macro(script_name.."/Other", script_description, otherInfo)