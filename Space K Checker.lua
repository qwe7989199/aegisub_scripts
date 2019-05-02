local tr = aegisub.gettext
script_name = tr"Space K Checker"
script_description = tr"Check invalid k tag"
script_author = "domo"
script_version = 1.1

re = require 'aegisub.re'
function wrong_k_checker(subtitles, selected_lines)
	for i=1,#subtitles do
		if subtitles[i].class=="dialogue" then
			dialogue_start=i
			break
		end
	end
	for z, i in ipairs(selected_lines) do
		local l=subtitles[i]
		text=tostring(l.text)
		if string.find(text,"\\k")~=nil then
			if (re.find(text,"\\}[^　{]+　\\{|\\}　[^　{]+\\{")~=nil) --Not End of Line Condition
			or 
			(re.find(text,"\\}?　[^{　]+$")~=nil)		--End of Line Condition 1
			or
			(re.find(text,"\\}?[^{　]+　$")~=nil)		--End of Line Condition 2
			or
			(string.find(text,"{\\k%d}[　 ]?$")~=nil)	--Single K at the End of Line
			then
				aegisub.debug.out("Wrong k tag in line "..(i-dialogue_start+1).."\n")
			end
		end
	end
	aegisub.debug.out("Done.")
end

aegisub.register_macro(script_name, script_description, wrong_k_checker)