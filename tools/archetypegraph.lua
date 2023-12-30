function generateGraphviz(elements)
    -- Helper function to generate combinations of a certain length
    local function combinations(elements, length)
        local combis = {}
        local function combi(index, progress)
            if #progress == length then
                table.insert(combis, table.concat(progress))
                return
            end
            for i = index, #elements do
                table.insert(progress, elements[i])
                combi(i + 1, progress)
                table.remove(progress)
            end
        end
        combi(1, {})
        return combis
    end

    -- Check if the combination contains a specific element
    local function contains(combination, element)
        return combination:find(element) ~= nil
    end

    -- Generate the final combination
    local finalCombination = #elements > 1 and table.concat(elements) or nil

    -- Generate Graphviz code
    print('digraph G {\n\trankdir = LR')

    -- Add an empty node pointing to all single-letter nodes
    for _, e in ipairs(elements) do
        print('    "" -> "' .. e .. '"')
    end

    -- Connect each element and combination to its negations
    for length = 1, #elements do
        local currentCombis = combinations(elements, length)
        for _, combi in ipairs(currentCombis) do
            for _, elem in ipairs(elements) do
                if not contains(combi, elem) then
                    print('    "' .. combi .. '" -> "' .. combi .. '!' .. elem .. '"')
                end
            end
        end
    end

    -- Generate and connect combinations of different lengths, avoiding duplicates
    local alreadyConnected = {}
    for length = 1, #elements - 1 do
        local currentCombis = combinations(elements, length)
        for _, current in ipairs(currentCombis) do
            for _, nextCombi in ipairs(combinations(elements, length + 1)) do
                if contains(nextCombi, current) and not alreadyConnected[current .. "->" .. nextCombi] then
                    print('    "' .. current .. '" -> "' .. nextCombi .. '"')
                    alreadyConnected[current .. "->" .. nextCombi] = true
                end
            end
        end
    end

    -- Connect the penultimate combinations to the final combination, if applicable
    if finalCombination then
        local penultimateCombis = combinations(elements, #elements - 1)
        for _, combi in ipairs(penultimateCombis) do
            if not alreadyConnected[combi .. "->" .. finalCombination] then
                print('    "' .. combi .. '" -> "' .. finalCombination .. '"')
            end
        end
    end

    print('}')
end

generateGraphviz({"A", "B", "C", "D", "E", "F", "G", "H"})
