local ns = select(2, ...)

ns.pets = {
    [50813] = { name = "噩兆", nameEN = "Portent", zone = "锦绣谷", mapID = 390 },
    [50821] = { name = "萨维奇", nameEN = "Savage", zone = "翡翠林", mapID = 371 },
    [50822] = { name = "微光之蛾", nameEN = "Glimmer", zone = "翡翠林", mapID = 371 },
    [50811] = { name = "重蹄", nameEN = "Stompy", zone = "昆莱山", mapID = 379 },
    [50816] = { name = "刺脊", nameEN = "Bristlespine", zone = "昆莱山", mapID = 379 },
    [50818] = { name = "赫克萨波斯", nameEN = "Hexapos", zone = "恐惧废土", mapID = 422 },
    [50812] = { name = "帕特兰纳克", nameEN = "Patrannache", zone = "四风谷", mapID = 376 },
    [50817] = { name = "血牙", nameEN = "Bloodtooth", zone = "卡桑琅丛林", mapID = 418 },
    [50820] = { name = "洛克海德", nameEN = "Rockhide", zone = "螳螂高原", mapID = 388 },
    [66522] = { name = "邦比", nameEN = "Bombyx", zone = "卡桑琅丛林", mapID = 418 },
}

function ns.GetSortedPetIDs()
    local ids = {}
    for id in pairs(ns.pets) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    return ids
end
