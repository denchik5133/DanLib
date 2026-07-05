/***
 *   @addon         DanLib
 *   @component     Table
 *   @license       MIT License
 *   @version       2.0.2
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   The file provides a comprehensive interface for handling table operations in the project,
 *                  ensuring efficient data management and manipulation.
 *
 *   @functions
 *                  - Adding a single value to a table (Add).
 *                  - Appending all sequential values from one table into another (Append).
 *                  - Clearing keys and creating a new sequential table (ClearKeys).
 *                  - Collapsing a key-value structure table (CollapseKeyValue).
 *                  - Concatenating table contents into a string (Concat).
 *                  - Creating a deep copy of a table (DeepCopy).
 *                  - Merging values from one table into another (CopyFromTo).
 *                  - Checking the number of keys in a table (Count).
 *                  - DeSanitizing a table (DeSanitise).
 *                  - Emptying a table (Empty).
 *                  - Finding the next value in a table (FindNext).
 *                  - Finding the previous value in a table (FindPrev).
 *                  - Flipping key-value pairs in a table (Flip).
 *                  - Iterating over key-value pairs in a table (Foreach).
 *                  - Retrieving all keys from a table (GetKeys).
 *                  - Getting the first key and value from a table (GetFirst).
 *                  - Getting the last key and value from a table (GetLast).
 *                  - Checking if a table has a specific value (HasValue).
 *                  - Inheriting values from one table to another (Inherit).
 *                  - Inserting a value into a table at a specific index (InsertAt).
 *                  - Checking if a table is empty (IsEmpty).
 *                  - Checking if a table's keys are sequential (IsSequential).
 *                  - Getting a key from a table based on the value (KeyFromValue).
 *                  - Getting all keys from a table based on a value (KeysFromValue).
 *                  - Lowercasing all string keys in a table (LowerKeyNames).
 *                  - Finding the highest numerical key in a table (MaxN).
 *                  - Merging two tables recursively (Merge).
 *                  - Moving elements within a table (Move).
 *                  - Packing multiple items into a table (Pack).
 *                  - Getting a random value from a table (Random).
 *                  - Removing a value from a table by key (Remove).
 *                  - Removing a value by its first instance (RemoveByValue).
 *                  - Reversing a table (Reverse).
 *                  - Sanitizing a table for key-value conversion (Sanitise).
 *                  - Shuffling a table randomly (Shuffle).
 *                  - Sorting a table (Sort).
 *                  - Sorting keys based on their values (SortByKey).
 *                  - Sorting a table by a specific member (SortByMember).
 *                  - Sorting a table in descending order (SortDesc).
 *                  - Converting a table to a string (ToString).
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



DanLib.Table = DanLib.Table or { }
local DTable = DanLib.Table

local table = table
local _print = print
local _error = error
local _type = type
local _pairs = pairs
local _tostring = tostring
local _ipairs = ipairs
local _stringrep = string.rep
local _mathrandom = math.random
local _setmetatable = setmetatable
local _getmetatable = getmetatable


--- Function to check if the argument is a table
-- @param arg: The argument to check.
-- @param funcName: The name of the function for error reporting.
-- @return: true if the argument is a table, false otherwise.
local function checkTable(arg, funcName)
    if (_type(arg) ~= 'table') then
        _print('Error in ' .. funcName .. ': Argument must be a table.')
        return false
    end
    return true
end

--- Full implementation matching table.insert behavior
-- @param target: The target table
-- @param position: Position (if 3 args) OR value (if 2 args)
-- @param value: The value (only if position specified)
-- @return: The index where value was inserted
function DTable:Add(target, position, value)
    if (not checkTable(target, 'Add')) then
        return
    end
    
    if (value ~= nil) then
        -- 3 arguments: Add(tbl, position, value)
        table.insert(target, position, value)
        return position
    else
        -- 2 arguments: Add(tbl, value) - insert at end
        table.insert(target, position)
        return #target
    end
end

--- Function to add multiple values from the source table into the target table
-- @param target: The target table to which values will be added.
-- @param source: The source table from which values will be taken.
-- @return: The target table with added values.
function DTable:AddMultiple(target, source)
    if (not checkTable(target, 'AddMultiple') or not checkTable(source, 'AddMultiple')) then
        return
    end

    for _, value in _ipairs(source) do
        self:Add(target, value)
    end

    return target
end

--- Function to get the first or last key/value from a table
function DTable:GetElement(tbl, isFirst, isKey)
    if (not checkTable(tbl, 'GetElement')) then
        return nil
    end

    if isFirst then
        for key, value in _pairs(tbl) do
            return isKey and key or value
        end
    else
        local lastKey, lastValue
        for key, value in _pairs(tbl) do
            lastKey, lastValue = key, value
        end

        return isKey and lastKey or lastValue
    end
end

--- Function to collapse a key-value structure table
-- @param input: The table to be collapsed.
-- @return: A collapsed version of the input table.
function DTable:CollapseKeyValue(input)
    if (not checkTable(input, 'CollapseKeyValue')) then
        return { }
    end

    local collapsed = { }
    for key, value in _pairs(input) do
        if (_type(value) == 'table') then
            for subKey, subValue in _pairs(value) do
                collapsed[subKey] = subValue
            end
        else
            collapsed[key] = value
        end
    end

    return collapsed
end

--- Function to concatenate the contents of a table into a string
-- @param tbl: The table to concatenate.
-- @param concatenator: The string used to concatenate values (default is '').
-- @param startPos: The starting position for concatenation (default is 1).
-- @param endPos: The ending position for concatenation (default is #tbl).
-- @return: A concatenated string of table contents.
function DTable:Concat(tbl, concatenator, startPos, endPos)
    if (not checkTable(tbl, 'Concat')) then
        return ''
    end
    return table.concat(tbl, concatenator, startPos or 1, endPos or #tbl)
end

--- Function to create a deep copy of a table
-- @param originalDTable: The table to be copied.
-- @return: A deep copy of the original table.
function DTable:Copy(originalTable)
    if (not checkTable(originalTable, 'Copy')) then
        return { }
    end

    local copy = { }
    for key, value in _pairs(originalTable) do
        if (_type(value) == 'table') then
            copy[key] = self:Copy(value)
        else
            copy[key] = value
        end
    end

    return copy
end

--- Function to merge values from the source table into the target table
-- @param source: The source table from which values will be merged.
-- @param target: The target table to which values will be merged.
-- @return: The target table with merged values.
function DTable:CopyFromTo(source, target)
    if (not checkTable(source, 'CopyFromTo') or not checkTable(target, 'CopyFromTo')) then
        return target
    end

    self:Empty(target) -- Empty the target table first
    for key, value in _pairs(source) do
        target[key] = value
    end

    return target
end

--- Function to count the number of keys in a table
-- @param tbl: The table to count keys.
-- @return: The number of keys in the table.
function DTable:Count(tbl)
    if (not checkTable(tbl, 'Count')) then
        return 0
    end

    local count = 0
    for _ in _pairs(tbl) do
        count = count + 1
    end

    return count
end

--- Function to de-sanitize a table
-- @param tbl: The sanitized table to convert back.
-- @return: The original form of the table.
function DTable:DeSanitise(tbl)
    if (not checkTable(tbl, 'DeSanitise')) then
        return { }
    end
    -- Example implementation, customize as needed
    return tbl
end

--- Function to empty a table
-- @param tbl: The table to be emptied.
function DTable:Empty(tbl)
    if (not checkTable(tbl, 'Empty')) then
        return
    end

    for k in _pairs(tbl) do
        tbl[k] = nil
    end
end

--- Function to flip key-value pairs in a table
-- @param input: The table to flip.
-- @return: A new table with flipped key-value pairs.
function DTable:Flip(input)
    if (not checkTable(input, 'Flip')) then
        return { }
    end

    local flipped = { }
    for key, value in _pairs(input) do
        -- Prevent data loss when duplicate values are present
        if (flipped[value] == nil) then
            flipped[value] = key
        else
            _print('Warning: Duplicate value found for key "' .. key .. '"; data loss may occur.')
        end
    end

    return flipped
end

--- Function to iterate over key-value pairs in a table
-- @param tbl: The table to iterate over.
-- @param callback: The function to call for each key-value pair.
function DTable:Foreach(tbl, callback)
    if (not checkTable(tbl, 'Foreach')) then
        return
    end

    for key, value in _pairs(tbl) do
        callback(key, value)
    end
end

--- Function to retrieve all keys from a table
-- @param tabl: The table to get keys from.
-- @return: A table of keys.
function DTable:GetKeys(tabl)
    if (not checkTable(tabl, 'GetKeys')) then
        return { }
    end

    local keys = { }
    for key in _pairs(tabl) do
        self:Add(keys, key)
    end

    return keys
end

--- Function to find a key with the highest value in a table
-- @param inputDTable: The table to search.
-- @return: A key with the highest number value.
function DTable:GetWinningKey(inputTable)
    if (not checkTable(inputTable, 'GetWinningKey')) then
        return nil
    end

    local winningKey
    local highestValue = -math.huge

    for key, value in _pairs(inputTable) do
        if (value > highestValue) then
            highestValue = value
            winningKey = key
        end
    end

    return winningKey
end

--- Function to check if a table has a specific value
-- @param tbl: The table to check.
-- @param value: The value to search for.
-- @return: true if the value is found, otherwise false.
function DTable:HasValue(tbl, value)
    if (not checkTable(tbl, 'HasValue')) then
        return false
    end

    for _, v in _pairs(tbl) do
        if (v == value) then
            return true
        end
    end

    return false
end

--- Function to inherit values from one table to another
-- @param target: The target table to inherit values into.
-- @param base: The base table from which to inherit values.
-- @return: The target table with inherited values.
function DTable:Inherit(target, base)
    if (not checkTable(target, 'Inherit') or not checkTable(base, 'Inherit')) then
        return target
    end

    for key, value in _pairs(base) do
        if (target[key] == nil) then
            target[key] = value
        end
    end

    target.BaseClass = base
    return target
end

--- Function to insert a value into a table at a specific position
-- @param tab: The table to insert into.
-- @param position: The position at which to insert the value.
-- @param value: The value to insert.
-- @return: The modified table.
function DTable:InsertAt(tab, position, value)
    if (not checkTable(tab, 'InsertAt')) then
        return
    end

    tab = tab or { }
    self:Add(tab, position or #tab + 1, value)
    return tab
end

--- Function to merge two tables
-- @param tbl1: The first table.
-- @param tbl2: The second table to merge into the first.
-- @return: A new table containing merged values from both tables.
function DTable:Merge(tbl1, tbl2)
    if (not checkTable(tbl1, 'Merge') or not checkTable(tbl2, 'Merge')) then
        return { }
    end

    local merged = { }
    for k, v in _pairs(tbl1) do
        merged[k] = v
    end

    for k, v in _pairs(tbl2) do
        merged[k] = v
    end

    return merged
end

--- Function to move elements within a table
-- @param tbl: The table to move elements in.
-- @param fromIndex: The index to move from.
-- @param toIndex: The index to move to.
function DTable:Move(tbl, fromIndex, toIndex)
    if (not checkTable(tbl, 'Move')) then
        return
    end

    if (fromIndex < 1 or fromIndex > #tbl or toIndex < 1 or toIndex > #tbl) then
        _print('Error in Move: Indexes must be within the bounds of the table.')
        return
    end

    local value = tbl[fromIndex]
    self:Remove(tbl, fromIndex)
    self:Add(tbl, toIndex, value)
end

--- Function to pack multiple items into a table
-- @param ...: The items to pack.
-- @return: A table containing the packed items.
function DTable:Pack(...)
    local packed = { }

    for _, value in _ipairs({ ... }) do
        self:Add(packed, value)
    end

    return packed
end

--- Function to shuffle a table randomly
-- @param tbl: The table to shuffle.
function DTable:Shuffle(tbl)
    if (not checkTable(tbl, 'Shuffle')) then
        return
    end

    local n = #tbl
    for i = n, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
end

--- Function to sort a table
-- @param tbl: The table to sort.
-- @param sorter: Optional comparator function for sorting.
function DTable:Sort(tbl, sorter)
    if (not checkTable(tbl, 'Sort')) then
        return
    end
    table.sort(tbl, sorter)
end

--- Function to sort a table by a specific member
-- @param tbl: The table to sort.
-- @param member: The member to sort by.
-- @param descending: If true, sort in descending order; otherwise, sort in ascending order.
-- @return: The sorted table.
function DTable:SortByMember(tbl, member, descending)
    if (not checkTable(tbl, 'SortByMember')) then
        return
    end

    -- Checking for the presence of a member in each element
    for _, item in _ipairs(tbl) do
        if (item[member] == nil) then
            _error('Member "' .. member .. '" does not exist in one of the table elements.')
        end
    end

    -- Define the comparison function depending on the sorting order
    local compareFunction
    if descending then
        compareFunction = function(a, b)
            return a[member] > b[member] -- Descending order
        end
    else
        compareFunction = function(a, b)
            return a[member] < b[member] -- Ascending order
        end
    end

    self:Sort(tbl, compareFunction)
    return tbl
end

--- Function to sort a table in descending order
-- @param tbl: The table to sort.
-- @param comparator: Optional comparator function for sorting.
function DTable:SortDesc(tbl, comparator)
    if (not checkTable(tbl, 'SortDesc')) then
        return
    end
    
    if comparator then
        self:Sort(tbl, function(a, b)
            return not comparator(a, b)
        end)
    else
        self:Sort(tbl, function(a, b)
            return a > b
        end)
    end
end

--- Function to convert a table to a string
-- @param tbl: The table to convert.
-- @return: A string representation of the table.
function DTable:ToString(tbl)
    if (not checkTable(tbl, 'ToString')) then
        return '{ }'
    end

    local str = '{'
    for k, v in _pairs(tbl) do
        str = str .. _tostring(k) .. ': ' .. _tostring(v) .. ', '
    end

    if (#str > 1) then
        str = str:sub(1, -3) -- Remove last comma and space
    end

    str = str .. '}'
    return str
end

--- Function to deep copy a table
-- @param orig: The table to deep copy.
-- @return: A new table that is a deep copy of the original.
function DTable:DeepCopy(orig)
    if (not checkTable(orig, 'DeepCopy')) then
        return { }
    end

    local orig_type = _type(orig)
    local copy

    if (orig_type == 'table') then
        copy = { }
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end

        _setmetatable(copy, self:DeepCopy(_getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end

    return copy
end

--- Function to get the values of a table as an array
-- @param tbl: The table to convert.
-- @return: An array of values.
function DTable:GetValues(tbl)
    if (not checkTable(tbl, 'GetValues')) then
        return { }
    end

    local values = { }
    for _, v in _pairs(tbl) do
        self:Add(values, v)
    end

    return values
end

--- Function to remove a value from a table by key
-- @param tbl: The table to modify.
-- @param key: The key to remove.
-- @return: The removed value.
function DTable:Remove(tbl, key)
    if (not checkTable(tbl, 'Remove')) then
        return
    end
    return table.remove(tbl, key)
end

--- Function to merge multiple tables
-- @param ...: The tables to merge.
-- @return: A new table containing merged values from all tables.
function DTable:MergeMultiple(...)
    local merged = { }

    for _, tbl in _ipairs({ ... }) do
        if (_type(tbl) == 'table') then
            merged = self:Merge(merged, tbl)
        else
            _print('Warning: Ignoring non-table argument during merge.')
        end
    end

    return merged
end

--- Function to remove a value from a table by its value
-- @param tbl: The table to remove from.
-- @param value: The value to remove.
function DTable:RemoveByValue(tbl, value)
    for key, v in _pairs(tbl) do
        if (v == value) then
            tbl[key] = nil
            break
        end
    end
end

--- Function to print the contents of a table
-- @param tbl: The table to print.
-- @param indent: Optional indentation level for nested tables.
function DTable:Print(tbl, indent)
    indent = indent or 0
    for key, value in _pairs(tbl) do
        local prefix = _stringrep('  ', indent) .. _tostring(key) .. ': '

        if (_type(value) == 'table') then
            _print(prefix)
            self:Print(value, indent + 1)
        else
            _print(prefix .. _tostring(value))
        end
    end
end

--- Function to get a deep count of all values in a nested table
-- @param tbl: The table to count.
-- @return: Total count of values in the table.
function DTable:DeepCount(tbl)
    if (not checkTable(tbl, 'DeepCount')) then
        return 0
    end

    local count = 0
    local function countValues(t)
        for _, value in _pairs(t) do
            if (_type(value) == 'table') then
                countValues(value)
            else
                count = count + 1
            end
        end
    end

    countValues(tbl)
    return count
end

--- Function to create a new table with a specified size
-- @param size: The desired size of the new table.
-- @return: A new table with the specified size.
function DTable:CreateWithSize(size)
    if (_type(size) ~= 'number' or size < 0) then
        _print('Error in CreateWithSize: Size must be a non-negative number.')
        return { }
    end

    local newTable = { }
    for i = 1, size do
        newTable[i] = nil
    end

    return newTable
end

--- Function to get a random key from a table
-- @param tbl: The table to get a random key from.
-- @return: A random key from the table.
function DTable:GetRandomKey(tbl)
    if (not checkTable(tbl, 'GetRandomKey')) then
        return nil
    end

    local keys = self:GetKeys(tbl)
    if (#keys == 0) then
        return nil
    end

    return keys[_mathrandom(#keys)]
end

--- Function to get a random value from a table
-- @param tbl: The table to get a random value from.
-- @return: A random value from the table.
function DTable:GetRandomValue(tbl)
    if (not checkTable(tbl, 'GetRandomValue')) then
        return nil
    end

    local randomIndex = _mathrandom(1, #tbl)
    return tbl[randomIndex] -- Return a random element from the table
end

--- Function to check if a table is empty (has no keys)
-- @param tbl: The table to check.
-- @return: true if the table has no keys, false otherwise.
function DTable:IsEmpty(tbl)
    if (not checkTable(tbl, 'IsEmpty')) then
        return true
    end

    return next(tbl) == nil
end

--- Function to find the highest numerical key in a table
-- Named MaxN to avoid conflict with the reserved table.maxn name.
-- @param tbl: The table to search.
-- @return: The highest numerical key, or 0 if none found.
function DTable:MaxN(tbl)
    if (not checkTable(tbl, 'MaxN')) then
        return 0
    end

    local max = 0
    for k in _pairs(tbl) do
        if (_type(k) == 'number' and k > max) then
            max = k
        end
    end

    return max
end

--- Function to append all sequential values from source into target (equivalent to GMod table.Add)
-- Named Append to avoid conflict with the existing Add (single-insert) function.
-- @param target: The table to append values into.
-- @param source: The table whose sequential values will be appended.
-- @return: The target table.
function DTable:Append(target, source)
    if (not checkTable(target, 'Append') or not checkTable(source, 'Append')) then
        return target
    end

    for _, value in _ipairs(source) do
        target[#target + 1] = value
    end

    return target
end

--- Function to clear all keys and return a new sequential table from the values
-- @param tbl: The table to clear keys from.
-- @return: A new sequential table containing only the values.
function DTable:ClearKeys(tbl)
    if (not checkTable(tbl, 'ClearKeys')) then
        return { }
    end

    local sequential = { }
    for _, value in _pairs(tbl) do
        sequential[#sequential + 1] = value
    end

    return sequential
end

--- Function to find the next value in a table after the given value
-- @param tbl: The table to search.
-- @param value: The reference value.
-- @param loop: If true, wraps around to the first element after the last.
-- @return: The next value, or nil if not found.
function DTable:FindNext(tbl, value, loop)
    if (not checkTable(tbl, 'FindNext')) then
        return nil
    end

    local found = false
    for _, v in _ipairs(tbl) do
        if found then
            return v
        end
        if (v == value) then
            found = true
        end
    end

    if (found and loop) then
        return tbl[1]
    end

    return nil
end

--- Function to find the previous value in a table before the given value
-- @param tbl: The table to search.
-- @param value: The reference value.
-- @param loop: If true, wraps around to the last element before the first.
-- @return: The previous value, or nil if not found.
function DTable:FindPrev(tbl, value, loop)
    if (not checkTable(tbl, 'FindPrev')) then
        return nil
    end

    local prev = nil
    for _, v in _ipairs(tbl) do
        if (v == value) then
            if (prev ~= nil) then
                return prev
            elseif loop then
                return tbl[#tbl]
            else
                return nil
            end
        end
        prev = v
    end

    return nil
end

--- Function to get the first value from a table
-- @param tbl: The table to retrieve from.
-- @return: The first value found.
function DTable:GetFirst(tbl)
    return self:GetElement(tbl, true, false)
end

--- Function to get the last value from a table
-- @param tbl: The table to retrieve from.
-- @return: The last value found.
function DTable:GetLast(tbl)
    return self:GetElement(tbl, false, false)
end

--- Function to check if a table's keys are sequential (1, 2, 3, … #tbl with no gaps)
-- @param tbl: The table to check.
-- @return: true if all keys are sequential integers starting at 1.
function DTable:IsSequential(tbl)
    if (not checkTable(tbl, 'IsSequential')) then
        return false
    end

    local count = 0
    for _ in _pairs(tbl) do
        count = count + 1
    end

    for i = 1, count do
        if (tbl[i] == nil) then
            return false
        end
    end

    return true
end

--- Function to get the first key in a table that holds the given value
-- @param tbl: The table to search.
-- @param value: The value to find.
-- @return: The key associated with the value, or nil if not found.
function DTable:KeyFromValue(tbl, value)
    if (not checkTable(tbl, 'KeyFromValue')) then
        return nil
    end

    for k, v in _pairs(tbl) do
        if (v == value) then
            return k
        end
    end

    return nil
end

--- Function to get all keys in a table that hold the given value
-- @param tbl: The table to search.
-- @param value: The value to find.
-- @return: A sequential table of all matching keys.
function DTable:KeysFromValue(tbl, value)
    if (not checkTable(tbl, 'KeysFromValue')) then
        return { }
    end

    local keys = { }
    for k, v in _pairs(tbl) do
        if (v == value) then
            keys[#keys + 1] = k
        end
    end

    return keys
end

--- Function to lowercase all string keys in a table
-- @param tbl: The table whose string keys will be lowercased.
-- @return: A new table with all string keys converted to lowercase.
function DTable:LowerKeyNames(tbl)
    if (not checkTable(tbl, 'LowerKeyNames')) then
        return { }
    end

    local result = { }
    for k, v in _pairs(tbl) do
        if (_type(k) == 'string') then
            result[k:lower()] = v
        else
            result[k] = v
        end
    end

    return result
end

--- Function to get a random value from a table (alias matching GMod table.Random)
-- @param tbl: The table to pick from.
-- @return: A random value from the table.
function DTable:Random(tbl)
    if (not checkTable(tbl, 'Random')) then
        return nil
    end

    local keys = self:GetKeys(tbl)
    if (#keys == 0) then
        return nil
    end

    return tbl[keys[_mathrandom(#keys)]]
end

--- Function to reverse a sequential table in-place
-- @param tbl: The table to reverse.
-- @return: The reversed table.
function DTable:Reverse(tbl)
    if (not checkTable(tbl, 'Reverse')) then
        return { }
    end

    local n = #tbl
    for i = 1, math.floor(n / 2) do
        tbl[i], tbl[n - i + 1] = tbl[n - i + 1], tbl[i]
    end

    return tbl
end

--- Function to sanitize a table by converting all keys and values to strings
-- @param tbl: The table to sanitize.
-- @return: A sanitized version of the table.
function DTable:Sanitise(tbl)
    if (not checkTable(tbl, 'Sanitise')) then
        return { }
    end

    local sanitised = { }
    for k, v in _pairs(tbl) do
        if (_type(v) == 'table') then
            sanitised[_tostring(k)] = self:Sanitise(v)
        else
            sanitised[_tostring(k)] = _tostring(v)
        end
    end

    return sanitised
end

--- Function to sort a table by its keys and return sorted {key, value} pairs
-- @param tbl: The table to sort by keys.
-- @param descending: If true, sort keys in descending order.
-- @return: A sequential table of {key, value} pairs sorted by key.
function DTable:SortByKey(tbl, descending)
    if (not checkTable(tbl, 'SortByKey')) then
        return { }
    end

    local sorted = { }
    for k, v in _pairs(tbl) do
        sorted[#sorted + 1] = {
            key = k,
            value = v
        }
    end

    self:Sort(sorted, function(a, b)
        if descending then
            return a.key > b.key
        end
        return a.key < b.key
    end)

    return sorted
end
