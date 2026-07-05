/***
 *   @addon         DanLib
 *   @component     Gamemode Blank
 *   @license       MIT License
 *   @version       1.0.1
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   This is a blank template for creating a new gamemode integration with DanLib.
 *                  Copy this file to 'danlib/gamemodes/' directory and customize it for your gamemode.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



-- Create a new gamemode instance with a unique ID
local gamemode = DanLib.Func.CreateGamemode('Blank')

-- Set gamemode metadata
gamemode:SetName('Blank')
gamemode:SetAuthor('Your Name')
gamemode:SetVersion('1.0.0')
gamemode:SetDescription('A blank template for gamemode integration')
gamemode:SetLicense('MIT')

-- Optional: Set a function to be called when gamemode is loaded
gamemode:SetOnLoadFunction(function()
    print('Blank gamemode loaded!')
end)

-- REQUIRED: Define how to get player's money
-- @param player (Player): The player entity
-- @return (number): The player's current balance
gamemode:SetGetMoneyFunction(function(player)
    -- Example implementations for different gamemodes:
    
    -- For DarkRP:
    -- return player:getDarkRPVar('money') or 0
    
    -- For Sandbox (using PData):
    -- return player:GetPData('money', 0)
    
    -- For custom economy system:
    -- return player.CustomMoney or 0
    
    -- Default implementation:
    return 0
end)

-- REQUIRED: Define how to check if player can afford something
-- @param player (Player): The player entity
-- @param amount (number): The amount to check
-- @return (boolean): true if player can afford, false otherwise
gamemode:SetCanAffordFunction(function(player, amount)
    -- Example implementations:
    
    -- For DarkRP:
    -- return player:canAfford(amount)
    
    -- Default implementation using GetMoney:
    return gamemode:GetMoney(player) >= amount
end)

-- REQUIRED: Define how to add money to player
-- @param player (Player): The player entity
-- @param amount (number): The amount to add
gamemode:SetAddMoneyFunction(function(player, amount)
    -- Example implementations:
    
    -- For DarkRP:
    -- player:addMoney(amount)
    
    -- For Sandbox (using PData):
    -- local current = player:GetPData('money', 0)
    -- player:SetPData('money', current + amount)
    
    -- For custom economy system:
    -- player.CustomMoney = (player.CustomMoney or 0) + amount
    
    -- Default implementation:
    -- Implement your money adding logic here
end)

-- REQUIRED: Define how to take money from player
-- @param player (Player): The player entity
-- @param amount (number): The amount to take
gamemode:SetTakeMoneyFunction(function(player, amount)
    -- Example implementations:
    
    -- For DarkRP:
    -- player:addMoney(-amount)
    
    -- For Sandbox (using PData):
    -- local current = player:GetPData('money', 0)
    -- player:SetPData('money', current - amount)
    
    -- For custom economy system:
    -- player.CustomMoney = (player.CustomMoney or 0) - amount
    
    -- Default implementation:
    -- Implement your money taking logic here
end)

-- OPTIONAL: Define how to format money for display
-- @param player (Player): The player entity
-- @param amount (number): The amount to format
-- @return (string): Formatted money string
gamemode:SetFormatMoneyFunction(function(player, amount)
    -- Example implementations:
    
    -- For DarkRP:
    -- return DarkRP.formatMoney(amount)
    
    -- Custom formatting with currency symbol:
    -- return '$' .. string.Comma(amount)
    
    -- Default implementation:
    return '$' .. tostring(amount)
end)

-- Register the gamemode (REQUIRED - must be called at the end)
gamemode:Register()
