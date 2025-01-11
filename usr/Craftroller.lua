local autocraftingItems = {
    {name = "Iron Ingot", id = 1, minCount = 100},
    {name = "Gold Ingot", id = 2, minCount = 50},
    {name = "Redstone Dust", id = 3, minCount = 200},
    {name = "Diamond", id = 4, minCount = 10},
    {name = "Quartz", id = 5, minCount = 150}
}

-- Utility function to display the table (uses the previous `displayTable` function)
local function displayAutocraftingItems(items)
    print("Autocrafting Items Table:")
    for _, item in ipairs(items) do
        print(string.format("Name: %s, ID: %d, Minimum Count: %d", item.name, item.id, item.minCount))
    end
end

-- Example usage
displayAutocraftingItems(autocraftingItems)