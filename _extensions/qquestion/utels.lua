
local str = pandoc.utils.stringify
local pout = quarto.log.output

-- rendering information

local function chapterinfo(book, fname)
    local first = "" 
    local last = "" 
    local chapno = nil
    local info = {}
    --if book.render then
      for _, v in pairs(book.render) do
        if str(v.type) == "chapter" then
          last = pandoc.path.split_extension(str(v.file))
          if first == "" then first = last end
          if last == fname then chapno = v.number end
        end
      end
      info.islast = (fname == last)
      info.isfirst = (fname == first)
      info.lastchapter = last
      info.chapno = chapno
     -- pout("chapter inf:", info)
      return(info)
  end


local function Meta_getinfo(meta)
    local processedfile = pandoc.path.split_extension(PANDOC_STATE.output_file)
    local ispdf, ishtml, isbook, ishtmlbook = false, false, false, false
    local rinfo={}

    -- pout("here we go")
    rinfo.ispdf = quarto.doc.is_format("pdf")
    rinfo.ishtml = quarto.doc.is_format("html")
    rinfo.isbook = meta.book ~=nil
    rinfo.ishtmlbook = rinfo.isbook and rinfo.ishtml
      
    rinfo.processedfile = processedfile
    rinfo.output_file = PANDOC_STATE.output_file
   -- pout(" now in "..processedfile.." later becomes ".. str(fbx.output_file))
    
    rinfo.isfirst = not rinfo.ishtmlbook
    rinfo.islast = not rinfo.ishtmlbook
    if rinfo.isbook then 
      local chinfo = chapterinfo(meta.book, processedfile)
      rinfo.isfirst = chinfo.isfirst 
      rinfo.islast = chinfo.islast
      if meta.chapno then  
        rinfo.chapno = str(meta.chapno)
      else
        if chinfo.chapno ~= nil then
          rinfo.chapno = str(chinfo.chapno)
        else  
          rinfo.chapno = ""
          rinfo.unnumbered = true
        end
      end
    else -- not a book. 
      rinfo.chapno = ""
      rinfo.unnumbered = true
    end
    --pout(rinfo)
    return(rinfo)
  end


--[[ 
--]]
return {
    Meta_getinfo = Meta_getinfo
}  
--[[ 
--]]