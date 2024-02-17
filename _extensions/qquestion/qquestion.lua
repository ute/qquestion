-- nice rename function learned from shafayetShafee :-)
-- local str = pandoc.utils.stringify
-- local pout = quarto.log.output

-- important quasi global variables

local ishtml = quarto.doc.is_format("html")
local ispdf = quarto.doc.is_format("pdf")
local qnum = 0

local function qstart()
  qnum = qnum+1
  if ishtml then
    return pandoc.RawInline("html",'🤔<sub>[Q'..qnum..']</sub><span class="qquestion" number='..qnum..'>')
  elseif ispdf then 
    return pandoc.RawInline("tex",'\\qquestion{'..qnum.."}{")
  else
    return pandoc.Str("<QStart>")  
  end
end  

local function qend()
  if ishtml then
    return pandoc.RawInline("html",'</span>')
  elseif ispdf then 
    return pandoc.RawInline("tex",'}')
  else
    return pandoc.Str("<QEnde>")  
  end
end  

local function qans()
  if ishtml then
    return pandoc.RawInline("html",'</span><span class="qanswer" number='..qnum..'>')
  elseif ispdf then 
    return pandoc.RawInline("tex",'}\\qanswer{'..qnum.."}{")
  else
    return pandoc.Str("<QEnde><QAnswer>")  
  end
end  


-- find {?? bla ??}

Inlines = function(el)
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


-- TODO: book, save number between processed files? 

Pandoc = function(doc)
  if ishtml
  then 
    quarto.doc.add_html_dependency({
      name = 'qqstyle',
      stylesheets = {'qquestion.css'}
    })
   elseif ispdf
    then
      quarto.doc.use_latex_package("tcolorbox")
      quarto.doc.include_file('before-body','qquestion.tex')
      quarto.doc.add_format_resource("Emo_think.png")
  end
  return(doc)
end  