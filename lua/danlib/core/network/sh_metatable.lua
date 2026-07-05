/***
 *   @addon         DanLib
 *   @component     Metatable
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
 *   @description   The file enhances the scripting capabilities by allowing developers
 *                  to  extend the functionality of existing GLua classes through metatables.
 *
 *   @functions
 *                  - Retrieving the metatable for a specified class (GetMetaTable).
 *                  - Accessing metatables for common game entities such as Player, NPC, Panel, Weapon, and Vehicle.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */



--- A metatable for creating and managing user interfaces.
-- Usage: Allows you to create graphical UI elements, manage their behaviour 
-- and interactions with players.
DanLib.MetaPanel = FindMetaTable('Panel')

--- Metatable for all game entities, including NPCs, items, and players.
-- Usage: Allows you to interact with entities, change their behaviour, 
-- properties and perform various actions.
DanLib.MetaEntity = FindMetaTable('Entity')

--- Metatable for all weapons in the game.
-- Usage: Provides methods for controlling weapon behaviour, characteristics 
-- and interactions with players and other objects.
DanLib.MetaWeapon = FindMetaTable('Weapon')

--- A metatable for non-player characters (NPCs).
-- Usage: Allows you to control the behaviour of NPCs, their animations 
-- and interactions with players and the environment.
DanLib.MetaNPC = FindMetaTable('NPC')

--- Metatable for vehicles in the game.
-- Usage: Allows you to control the behaviour of vehicles, such as speed, 
-- steering and interactions with players.
DanLib.MetaVehicle = FindMetaTable('Vehicle')

--- A metatable for players in the game.
-- Usage: Allows you to control the actions, states and interactions of 
-- players with the environment and other players.
DanLib.MetaPlayer = FindMetaTable('Player')
