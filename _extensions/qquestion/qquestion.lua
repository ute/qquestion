-- nice rename function learned from shafayetShafee :-)
-- local str = pandoc.utils.stringify
local pout = quarto.log.output

-- initiate rendering information and global question number
local utelz = require("./utels")
local rinfo = {}

-- initialize qnum, store and retrieve

local function readqnum(renderinfo)
  local file = io.open(renderinfo.qnumstore,"r")
  local qnum = 0
  if file then 
    local qnumjson = file:read "*a"
    file:close()
    if qnumjson 
       then qnum = quarto.json.decode(qnumjson)
    end
  end  
  -- pout("got qnum as "..qnum)
  -- pout(rinfo)
  return(qnum)
end;  

local function store_qnum(renderinfo)
  local qnjson = quarto.json.encode(renderinfo.qnum)
  local file = io.open(renderinfo.qnumstore,"w")
  if file ~= nil then 
    file:write(qnjson) 
    file:close()
  end
end
 
function init_qnum(renderinfo)
  if renderinfo.ishtmlbook then 
    if renderinfo.isfirst then 
      renderinfo.qnum = 0
    else
      renderinfo.qnum = readqnum(renderinfo)
    end
  else
    renderinfo.qnum = 0    
  end  
end  

-- functions for rendering

local function qstart()
  rinfo.qnum = rinfo.qnum+1
  -- pout("qstart "..rinfo.qnum)
  if rinfo.ishtml then
    return pandoc.RawInline("html",'🤔<sub>[Q'..rinfo.qnum..']</sub><span class="qquestion" number='..rinfo.qnum..'>')
  elseif rinfo.ispdf then 
    return pandoc.RawInline("tex",'\\qquestion{'..rinfo.qnum.."}{")
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
    return pandoc.RawInline("html",'</span><span class="qanswer" number='..rinfo.qnum..'>')
  elseif rinfo. ispdf then 
    return pandoc.RawInline("tex",'}\\qanswer{'..rinfo.qnum.."}{")
  else
    return pandoc.Str("<QEnde><QAnswer>")  
  end
end  


-- find {?? bla ??}

function Inlines_parse(el)
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
      quarto.doc.use_latex_package("tcolorbox")
      quarto.doc.include_file('before-body','qquestion.tex')
      quarto.doc.add_format_resource("Emo_think.png")
  end
 
  -- pout("yeah, still have to store qnum "..rinfo.qnum)
  store_qnum(rinfo)
  return(doc)
end  


return{
{ -- first get rendering information
  Meta = function(meta) 
    rinfo = utelz.Meta_getinfo(meta)
    rinfo.qnumstore = "_qnumstore.json"
    init_qnum(rinfo)
   -- pout("render info ")
   -- pout("==== book render info ==")
   -- pout(meta.book.render)
   -- pout("==== book chapter info ==")
   -- pout(meta.book.chapters)
  end  
},
{
  Inlines = Inlines_parse,
  Pandoc = Pandoc_doit
}
}
