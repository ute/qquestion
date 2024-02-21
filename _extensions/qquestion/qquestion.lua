--[[ qquestion.lua, qquestion.tex, qquestion.css
  filter for numbered quick questions to the reader
  for html and pdf format
]]-- 

--[[
MIT License

Copyright (c) 2024 Ute Hahn

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--


local str = pandoc.utils.stringify
local pout = quarto.log.output

-- initiate rendering information and global question number
local utelz = require("./renderinfo")
local rinfo = {}
local qcount = 0
local qnum = 0

-- initialize qnum, store and retrieve
-- only relevant if there are several files to process
function init_qnum(renderinfo)
  qnum = 0
  qcount = 0
  -- pout("init qnum. current index "..renderinfo.currentindex)
  if renderinfo.ishtmlbook and renderinfo.currentindex > 0 then 
    for i, v in ipairs(renderinfo.rendr) do
      if i < renderinfo.currentindex 
        then if v.qcount then 
            -- if v.qcount > 0 then pout("add counts "..v.qcount) end
            qnum = qnum + v.qcount 
        end end
    end  
  end  
end  


-- functions for rendering

local function qstart()
  qnum = qnum + 1
  qcount = qcount + 1
  -- pout("qstart "..rinfo.qnum)
  if rinfo.ishtml then
    return pandoc.RawInline("html",'🤔<sub>[Q'..qnum..']</sub><span class="qquestion" number='..qnum..'>')
  elseif rinfo.ispdf then 
    return pandoc.RawInline("tex",'\\qquestion{'..qnum.."}{")
  else
    return pandoc.Str("<QStart>")  
  end
end  

local function qend()
  if rinfo.ishtml then
    return pandoc.RawInline("html",'</span>')
  elseif rinfo.ispdf then 
    return pandoc.RawInline("tex",'}')
  else
    return pandoc.Str("<QEnde>")  
  end
end  

local function qans()
  if rinfo.ishtml then
    return pandoc.RawInline("html",'</span><span class="qanswer" number='..qnum..'>')
  elseif rinfo. ispdf then 
    return pandoc.RawInline("tex",'}\\qanswer{'..qnum.."}{")
  else
    return pandoc.Str("<QEnde><QAnswer>")  
  end
end  


-- find {?? bla ??}

function Inlines_parse(el)
  -- pout("the inlines")
  for i,ele in pairs(el) do
    if ele.t == "Str" then 
      if ele.text == "{??" then
        ele = qstart()
      elseif ele.text == "??}" then
        ele = qend()
      elseif ele.text == ":|:" then
        ele = qans()--"<Answer to "..qnum..">"
      end
    end
    el[i] = ele
  end
  return el
end


function Pandoc_doit(doc)
  if rinfo.ishtml
  then 
    quarto.doc.add_html_dependency({
      name = 'qqstyle',
      stylesheets = {'qquestion.css'}
    })
   elseif rinfo.ispdf
    then
      quarto.doc.include_file('before-body','qquestion.tex')
      quarto.doc.add_format_resource("Emo_think.png")
  end
 
  if rinfo.ishtmlbook and rinfo.currentindex > 0 then
    -- pout ("updating render info with counts "..qcount)
    rinfo.rendr[rinfo.currentindex].qcount = qcount
  end;  
  -- pout ("save rinfo for current index"..rinfo.currentindex)
  utelz.save_info(rinfo)
  return(doc)
end  


return{
{ -- first get rendering information
  Meta = function(meta) 
    rinfo = utelz.Meta_getinfo(meta)
    init_qnum(rinfo)
    -- pout("fertig")
  end  
},
{
  Inlines = Inlines_parse,
  Pandoc = Pandoc_doit
}
}
