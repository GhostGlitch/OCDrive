local function parseCSV(s)
  result = {}
  row = {}
  cell = ""
  quoted = false
  prevQuote = false

  for i = 1, #s, 1 do
    c = s:sub(i, i)
    if quoted then
      if c == '"' then
        prevQuote = true
        quoted = false
      else
        cell = cell .. c
      end
    else
      if c == '"' then
        if #cell == 0 then
          quoted = true
        else
          if prevQuote then
            cell = cell .. '"'
            quoted = true
            prevQuote = false
          else
            return false
          end
        end
      elseif c == "," then
        table.insert(row, cell)
        cell = ""
        prevQuote = false
      elseif c == "\n" then
        table.insert(row, cell)
        cell = ""
        table.insert(result, row)
        row = {}
        prevQuote = false
      else
        if prevQuote then
          return false
        end
        cell = cell .. c
      end
    end
  end

  if #cell ~= 0 then
    if quoted then
      return false
    end
    table.insert(row, cell)
    table.insert(result, row)
  end

  return result
end

local function test()
  local p = function(s)
    print(require("serialization").serialize(s))
  end

  p(parseCSV(
[[
aaa,bbb,ccc,ddd
eee,fff,ggg,hhh
]]
  ))
  p(parseCSV(
[[
aaa,bbb,ccc,ddd
eee,fff,ggg,hhh]]
  ))
  p(parseCSV(
[[
aaa,bbb,ccc,"ddd
eee",fff,ggg,hhh]]
  ))
  p(parseCSV(
[[
aaa,bbb,c"cc,ddd
eee,fff,ggg,hhh]]
  ))
  p(parseCSV(
[[
aaa,bbb,"ccc,ddd
eee,fff,ggg,hhh]]
  ))
  p(parseCSV(
[[
aaa,bbb,"cc"c,ddd
eee,fff,ggg,hhh]]
    ))
    p(parseCSV(
[[
aaa,bbb,"cc""c,ddd
eee,fff,ggg,hhh]]
  ))
  p(parseCSV(
[[
ID,Block/Item,Mod,Unlocalised name,Class
1,Block,Minecraft,tile.stone,net.minecraft.block.BlockStone
2,Block,Minecraft,tile.grass,net.minecraft.block.BlockGrass
3,Block,Minecraft,tile.dirt,net.minecraft.block.BlockDirt
4,Block,Minecraft,tile.stonebrick,net.minecraft.block.Block
5,Block,Minecraft,tile.wood,net.minecraft.block.BlockWood
6,Block,Minecraft,tile.sapling,net.minecraft.block.BlockSapling
7,Block,Minecraft,tile.bedrock,net.minecraft.block.Block
8,Block,Minecraft,tile.water,net.minecraft.block.BlockFlowing
9,Block,Minecraft,tile.water,net.minecraft.block.BlockStationary
10,Block,Minecraft,tile.lava,net.minecraft.block.BlockFlowing
11,Block,Minecraft,tile.lava,net.minecraft.block.BlockStationary
12,Block,Minecraft,tile.sand,net.minecraft.block.BlockSand
13,Block,Minecraft,tile.gravel,net.minecraft.block.BlockGravel
14,Block,Minecraft,tile.oreGold,net.minecraft.block.BlockOre
]]
  ))
  p(parseCSV(
[[
aaa,bbb,"cc""c",ddd
eee,fff,ggg,hhh]]
  ))
end

return parseCSV