local tr = aegisub.gettext
script_name = tr"HDRifySub"
script_description = tr"Change subtitle color to adapt HDR video in PQ(ST2084) format"
script_author = "domo"
script_version = "0.2"

require("karaskel")
require("utils")
-- local Y = require("Yutils")
-- local printt = Y.table.tostring

local function iPQEOTF(L, scale)
	local L = scale*L/100
	local c2 = 32*2413/4096
	local c3 = 32*2392/4096
	local c1 = c3 - c2 + 1
	local m = 128*2523/4096
	local n = 0.25*2610/4096
	return ((c1 + c2*L^n)/(1 + c3*L^n))^m
end

local function bt709EOTF(V)
	return V < 0.081 and V/4.5 or ((V + 0.099)/1.099)^(1/0.45)
end

local function RGB_to_HSL(R, G, B)
	R, G, B = R/255, G/255, B/255
	Cmax, Cmin= math.max(R, G, B), math.min(R, G, B)
	delta = Cmax - Cmin
	L = 0.5 * (Cmax + Cmin)
	if delta == 0 then
		H = 0
		S = 0
	else
		if Cmax == R then
			H = 60 * ((G - B)/delta)%6
		elseif Cmax == G then
			H = 60 * ((B - R)/delta + 2)
		else
			H = 60 * ((R - G)/delta + 4)
		end
		S = delta/(1 - math.abs(2*L - 1))
	end
	return H, S, L
end

local function lightnessProcessor(colorStr, hasA, winOrSDR, scale)
	R, G, B, A = extract_color(colorStr)
	-- main purpose is to get Lightness L
	H, S, L = RGB_to_HSL(R, G, B)
	-- aegisub.debug.out("H:"..tostring(H).."\nS:"..tostring(S).."\nL:"..tostring(L).."\n")
	if winOrSDR == "Windows" then
		L = L > 0.67 and 0.67 or L
	else
		L = iPQEOTF(bt709EOTF(L), scale)
	end
	R, G, B = HSL_to_RGB(H, S, L)
	-- aegisub.debug.out("R:"..tostring(R).."\nG:"..tostring(G).."\nB:"..tostring(B).."\n")
	newColorStr = hasA and ass_style_color(R, G, B, A) or ass_color(R, G, B)
	if newColorStr:sub(-1) ~= "&" then
		newColorStr = newColorStr.."&"
	end
	if colorStr~=newColorStr then
		aegisub.debug.out(colorStr.." --> "..newColorStr.." \n")
	end
	return newColorStr
end

local function styleProcessor(styleLineTbl, winOrSDR, scale)
	-- aegisub.debug.out(printt(styleLineTbl))
	for i = 1, 4 do
		colorStr = styleLineTbl['color'..tostring(i)]
		styleLineTbl['color'..tostring(i)] = lightnessProcessor(colorStr, true, winOrSDR, scale)
	end
	return styleLineTbl
end

local function lineTagsProcessor(lineText, winOrSDR, scale)
	for orgTag in string.gmatch(lineText, '&H%x%x%x%x%x%x&?') do
		newTag = orgTag:sub(-1) ~= "&" and orgTag.."&" or orgTag
		newTag = lightnessProcessor(newTag, false, winOrSDR, scale)
		lineText = string.gsub(lineText, orgTag, newTag)
	end
	return lineText
end

function limiter(subtitles, styles)
	-- first pass to get the start line number
	for i=1,#subtitles do
		if subtitles[i].class=="dialogue" then
			dialogueStart=i
			break
		end
	end
	config = {{x=0,y=0,class="label",label="Choose standard:"}}
	btn, result = aegisub.dialog.display(config,{"Windows", "SDR", "Custom"})
	winOrSDR = btn
	if btn == "Custom" then
		lightConfig = {{x=0,y=0,width=2,class="label",label="Set a maxmium lightness:"},
					   {x=0,y=1,class="intedit",value=203,max=500,min=100,name="lightness"},
					   {x=1,y=1,class="label",label=" nit"},
					   {x=0,y=2,width=2,class="label",label="from 100 to 500 nit"}}
		button, res = aegisub.dialog.display(lightConfig)
		if not button then aegisub.cancel() end
		scale = res.lightness/100.0
	else
		scale = 1
	end
	if not btn then aegisub.cancel() end
	for i = 1, #subtitles do
		line = subtitles[i]
        if line.class == "style" then
			aegisub.debug.out("\nStyle: ["..line.name.."] is under process...\n")
			subtitles[i] = styleProcessor(line, winOrSDR, scale)
		elseif line.class == "dialogue" then 
			aegisub.debug.out("\nLine: ["..tostring(i - dialogueStart).."] is under process...\n")
			line.text = lineTagsProcessor(line.text, winOrSDR, scale)
			subtitles[i] = line
        end
    end
	aegisub.debug.out("\nDone.")
end

aegisub.register_macro(script_name, script_description, limiter)