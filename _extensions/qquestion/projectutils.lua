--[[ renderinfo.lua
    utility code, necessary for rendering html books
    and keeping global variables updated  
    read and update metadata about book chapters
   solves the problem that book rendering in previews does not 
   follow the sequence of chapters.
--]]
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


local dumpfile = ""
local defaulttmpdirname = "_renderinginfo"

local str = pandoc.utils.stringify
local pout = quarto.log.output


--- file system tools ----
--- Check if a file or directory exists in this path
--- see so: https://stackoverflow.com/questions/1340230/check-if-directory-exists-in-lua
local function exists(file)
    local ok, err, code = os.rename(file, file)
    if not ok then
       if code == 13 then
          -- Permission denied, but it exists
          return true
       end
    end
    return ok, err
  end
  
  --- Check if a directory exists in this path
  local function isdir(path)
    -- "/" works on both Unix and Windows
    return exists(path.."/")
  end
  
  local function providedir(parent, newpath)
    local path = pandoc.path.join({parent, newpath})
    if isdir(path) then return path 
    elseif exists(path) then
      pout("Problem: "..path.." exists but is not a directory")
      return(nil)
    else  pandoc.system.make_directory(path)
      return(path)
    end  
  end
  -- =========================== --

  local function get_tmpfile (meta, tmpdirname)
    local isbook = meta.book ~= nil
    local ishtmlbook = meta.book ~= nil and not quarto.doc.is_format("pdf")
  
    local qdir = quarto.project.directory
    if not qdir then qdir = pandoc.path.directory(quarto.doc.input_file) end
    
    -- make name for temporary render and xref information file, for book processing and perhaps for caching
    local qprofile = os.getenv("QUARTO_PROFILE")
    local tmpfilename = ""
    if isbook then
      if ishtmlbook then tmpfilename = "htmlbook" else tmpfilename ="pdfbook" end
      if qprofile then tmpfilename = tmpfilename.."-"..qprofile end
    else  
      tmpfilename = pandoc.path.split_extension(pandoc.path.filename(quarto.doc.input_file))
    end
    
    tmpfile = pandoc.path.join({qdir, tmpdirname, "_"..tmpfilename..".json"})
    --pout("temppath is "..tmpfile)
    
    tmpdir = providedir(qdir, tmpdirname)
    if not tmpdir then pout ("Kracho grosso") end
     
    return(tmpfile)
  end



-- rendering information

local function read_info()
    local file = io.open(dumpfile,"r")
    pout("try to read "..dumpfile)
    if file then 
        pout("dumpinfo found "..dumpfile)
      local nyrinfraw = file:read "*a"
      nyrinf = quarto.json.decode(nyrinfraw)
      pout(nyrinf.rendr)
      file:close()
    --   if nyrinf
    --     then pout("======== I read that from last file "..nyrinf.processedfile)
     -- end
    else pout("nix dumpfile")
    end  
    return(nyrinf)
  end;  
  
local function save_info(renderinfo)
    local rjson = quarto.json.encode(renderinfo)
    local file = io.open(dumpfile,"w")
    if file ~= nil then 
      -- pout ("dumping render info to "..dumpfile)
      file:write(rjson) 
      file:close()
    end
end

local function update_otherchapinfo(rinfo, newinfo)
    local oldchap = rinfo.rendr
    local newchap = newinfo.rendr
    local OK = true
    if rinfo.isbook then
        --pout(newchap)
        iexclude = rinfo.currentindex
        -- pout("update all but "..iexclude)
    -- double check if chapter lists are compatible, otherwise overwrite and quit
        for i, v in ipairs(oldchap) do
           if OK  then
      --        pout("checking chap "..i)
      --        pout("names: old "..v.file.." - new: "..newchap[i].file)
              OK = v.file == newchap[i].file
           end 
        end
        if not OK then 
            pout("there have been changes in chapters. Overwriting render information now.")
            save_info(rinfo)
        else -- update other information
            for i, v in ipairs(oldchap) do
                if i ~= iexclude  then
           --        pout("checking chap "..i)
           --        pout("names: old "..v.file.." - new: "..newchap[i].file)
                   oldchap[i] = newchap[i]
                end 
             end 
            -- pout("updated info")
            -- pout(rinfo) 
        end   
    end    
end    

local function Meta_projectfiles(meta)
    local processedfile = pandoc.path.split_extension(PANDOC_STATE.output_file)
    local rinfo={}
    local fname=""
    local file = ""
    local ir = 0
    local chapno = ""
    -- pout("here we go")
    rinfo.ispdf = quarto.doc.is_format("pdf")
    rinfo.ishtml = quarto.doc.is_format("html")
    rinfo.isbook = meta.book ~=nil
    rinfo.ishtmlbook = rinfo.isbook and rinfo.ishtml
    rinfo.processedfile = processedfile
    rinfo.output_file = PANDOC_STATE.output_file
    rinfo.isfirst = true
    rinfo.islast = true
    -- get all chapter files that are relevant for crossref etc
    if rinfo.isbook then
       -- rinfo.first = ""
       -- rinfo.last = ""
        rinfo.rendr = {}
        rinfo.currentindex = 0    
        for _, v in pairs(meta.book.render) do    
            if str(v.type) == "chapter" then
                ir = ir+1  
                -- pout("setup chapter "..ir.." file "..str(v.file))
                if v.number then chapno = str(v.number) end;
                -- else chapno = "" end
                file = str(v.file)
                fname = pandoc.path.filename(pandoc.path.split_extension(file))
                -- pout("process "..processedfile.." fname "..fname)
                if fname == processedfile then rinfo.currentindex = ir end
                -- rinfo.last = fname
                -- if rinfo.first == "" then rinfo.first = fname end
                rinfo.rendr[ir] ={
                    file = file,
                    chapno = chapno,
                    fname = fname
                }
            end
        end
        rinfo.isfirst = rinfo.currentindex == 1
        rinfo.islast = rinfo.currentindex == #rinfo.rendr
    end   
    rinfo.chapno = ""
    if rinfo.isbook then
        -- pout("current "..rinfo.currentindex.." chapno "..rinfo.chapno)      
        if rinfo.currentindex > 0 then
            if meta.chapno then  
               rinfo.chapno = str(meta.chapno)
               rinfo.rendr[rinfo.currentindex].chapno = rinfo.chapno 
            else
               rinfo.chapno = rinfo.rendr[rinfo.currentindex].chapno
            end
--        else rinfo.chapno = ""  
    end end
    return(rinfo)
 end;    



local function Meta_getinfo(meta, tmpdirname)
  local thetmpdir  
  if tmpdirname == nil then -- pout (defaulttmpdirname)
      thetmpdir = defaulttmpdirname 
  else thetmpdir = tmpdirname 
  end

  local rinfo={}
  --  pout("temp dir: ",thetmpdir)
  dumpfile = get_tmpfile(meta, thetmpdir)
    
  pout("the dumpfile is "..dumpfile)
  local oldinfo=read_info()
    
  rinfo = Meta_projectfiles(meta) 
    -- pout(oldinfo)
  if oldinfo 
  then
    pout("old info found")  
    if rinfo.chapno -- is chapter
    then
        pout("is chapter "..rinfo.chapno)
        update_otherchapinfo(rinfo, oldinfo) 
    end
  else pout ("no old chapter info available ") 
  end
  return(rinfo)
end


--[[ 
--]]
return {
    Meta_getinfo = Meta_getinfo,
    save_info = save_info,
    read_info = read_info
}  
--[[ 
--]]