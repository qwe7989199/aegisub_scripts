local tr = aegisub.gettext

script_name = tr"Delete FX"
script_description = tr"Removes all FX lines by range"
script_author = "domo"
script_version = "1"

function delete_fx(subs)
    for i = 1, #subs do
        if subs[i].class == "dialogue" and subs[i].effect == "fx" then
			idx_start = i
			break
        end
    end
    for i = #subs, 1,-1 do
        if subs[i].class == "dialogue" and subs[i].effect == "fx" then
			idx_end = i
			break
        end
    end
	subs.deleterange(idx_start,idx_end)
end


aegisub.register_macro(script_name, script_description, delete_fx)