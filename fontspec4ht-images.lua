local M = {}
local hlist_id = node.id "hlist"
local vlist_id = node.id "vlist"
local whatsit_id = node.id "whatsit"
local glyph_id = node.id "glyph"
-- get the special subtype
local whatsits = node.whatsits()
local special_id  

local pagelist = {}


local utfchar = unicode.utf8.char
local function execute_tex4ht(head, n)
  local was_tex4ht = false
  local t4ht, data = n.data:match("(t4ht)(.+)")
  if t4ht == "t4ht" then was_tex4ht = true end
  if was_tex4ht then
    if data:match("@%+") then
      -- detect unicode characters
      local char = data:match("%{35%}x([0-9a-fA-F]+)%{59%}")
      if char then 
        -- we must replace the next glyph char with contents of this special
        local nextnode = n.next
        if nextnode.id == glyph_id then
          nextnode.char = tonumber(char, 16)
        end
      end
    elseif data:match("%+%+") then
      local picture_name = data:match("%+%+(.+)")
      -- sometimes we match something different than filename
      -- so try to detect that it is really a filename (we check that it ends
      -- with extension)
      if picture_name:match("%.[a-zA-Z]-$") then
        pagelist[picture_name] = tex.count[ "c@page" ]
      end
    end
  end
  return head, was_tex4ht
end

local function process(head)
  for n in node.traverse(head) do
    local id = n.id
    if id == hlist_id or id == vlist_id then
      n.head = process(n.head)
    elseif id == whatsit_id and (n.subtype == special_id or whatsits[n.subtype] == "special")  then
      special_id = n.subtype
      -- act on the special node and detect if it was tex4ht special
      local was_tex4ht 
      head, was_tex4ht= execute_tex4ht(head, n)
      if was_tex4ht then
        -- remove the special node
        head = node.remove(head, n)
      end
    end
  end
  return head
end

local function save_pages()
  local pagefile = tex.jobname .. "-pagelist.lua"
  local f = io.open(pagefile, "w")
  -- we will write the page list as Lua module consisting only from table
  local t = {"return {"}
  for k,v in pairs(pagelist) do
    t[#t+1] = string.format("[%s] = '%s',", v, k)
    -- print("save page", k, v)
  end
  t[#t+1] = "}"
  f:write(table.concat(t, "\n"))
  f:close()
end

M.process = process
M.pagelist = pagelist
M.save_pages = save_pages

return M