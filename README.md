# aegisub_scripts

## Add k Tags.lua  
Generate K by :  
1.Average  
2.k1  
3.Percentage

## Combine Overlaps.lua  
Combine subtitle lines whose times are overlapped regardless of tags.  

## Space K Checker.lua
Check K tags for selected lines, following the rules below:  
1.In karaskel, a syl whose text contains a full-width blank will affect the sizing information calculated.
Under such condition, the full-width blank should be given a separated K tag.  
2.Normally, the last syl of a line should not be blank.  

## Time Scaler.lua  
You can use this if only BPM changed.  

## delete_fx.lua  
A very simple script to remove fx lines after sorting by effect.   
  
## template&fx checker.lua  
A set of basic functions for checking/printing mistakes in template lines and fx lines.  
Code blocks and most parameters of tags are ignored.  
