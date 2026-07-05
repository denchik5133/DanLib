/***
 *   @addon         DanLib
 *   @component     UI Class
 *   @license       MIT License
 *   @version       1.0.2
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   The file is designed to facilitate the creation and management of user interface classes,
 *                  ensuring ease of use and flexibility in handling UI components in the game environment.
 *
 *   @functions
 *                  - Create: Creates a new class with specified methods and properties.
 *                  - Accessor: Defines a property with getter and setter methods.
 *                  - AccessorList: Defines a list property with methods to get, set, and add values.
 *                  - String: Converts a value to a string.
 *                  - Number: Converts a value to a number.
 *                  - Boolean: Converts a value to a boolean.
 *                  - AssocTable: Creates an associative table from given values.
 *                  - Model: Loads a model from a specified path.
 *                  - Color: Creates a color object.
 *                  - Vector: Creates a vector object.
 *                  - Angle: Creates an angle object.
 *                  - Position: Combines a vector and an angle into a single object.
 *                  - Player: Retrieves a player object by Steam ID.
 *                  - EntityIndex: Returns the entity index of a given entity.
 *
 *   @example:
 *                  - To create a new UI class: local MyClass = DanLib.UiClass:Create()
 *                  - To define a property: MyClass:Accessor('MyProperty', constructorFunction)
 *                  - To create a new instance: local instance = MyClass:new()
 *                  - To set a property value: instance:SetMyProperty('value')
 *                  - To get a property value: local value = instance:GetMyProperty()
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         Ensure that all constructors and properties are correctly defined to avoid errors
 *                  when creating instances of the UI class.
 */



-- Class for managing user interface components
DanLib.UiClass = DanLib.UiClass or { }
local DUiClass = DanLib.UiClass

local helpers = { }

do
    -- Helper functions for type checking
    helpers.unpack = unpack or table.unpack

    --- Checks if the variable is a string
    -- @param (var): The variable to check
    -- @return: true if the variable is a string, otherwise false
    function helpers.isstring(var)
        return type(var) == 'string'
    end

    --- Checks if the variable is a number
    -- @param (var): The variable to check
    -- @return: true if the variable is a number, otherwise false
    function helpers.isnumber(var)
        return type(var) == 'number'
    end

    --- Checks if the variable is a table
    -- @param (var): The variable to check
    -- @return: true if the variable is a table, otherwise false
    function helpers.istable(var)
        return type(var) == 'table'
    end

    --- Checks if the variable is a vector
    -- @param (var): The variable to check
    -- @return: true if the variable is a vector, otherwise false
    if Vector then
        local vector_mt = FindMetaTable('Vector')
        function helpers.isvector(var)
            return getmetatable(var) == vector_mt
        end
    end

    --- Checks if the variable is an angle
    -- @param (var): The variable to check
    -- @return: true if the variable is an angle, otherwise false
    if Angle then
        local angle_mt = FindMetaTable('Angle')
        function helpers.isangle(var)
            return getmetatable(var) == angle_mt
        end
    end

    --- Checks if the variable is a material
    -- @param (var): The variable to check
    -- @return: true if the variable is a material, otherwise false
    if Material then
        local material_mt = FindMetaTable('IMaterial')
        function helpers.ismaterial(var)
            return getmetatable(var) == material_mt
        end
    end

    --- Checks if the variable is a color
    -- @param (var): The variable to check
    -- @return: true if the variable is a color, otherwise false
    if Color then
        local color_mt = FindMetaTable('Color')
        function helpers.iscolor(var)
            return getmetatable(var) == color_mt
        end
    end

    --- Inherits properties from a base table
    -- @param (tbl): The table to inherit properties to
    -- @param (base): The base table to inherit from
    -- @return: The updated table with inherited properties
    function helpers.inherit(tbl, base)
        for k, v in pairs(base) do
            if (tbl[k] == nil) then
                tbl[k] = v
            end
        end
        return tbl
    end
end


local constructor = { }

do
    --- Converts a value to a string
    -- @param self: The current instance
    -- @param str: The value to convert
    -- @return: The converted string
    function constructor.String(self, str)
        return tostring(str)
    end

    --- Converts a value to a number
    -- @param (self): The current instance
    -- @param (num): The value to convert
    -- @return: The converted number
    function constructor.Number(self, num)
        return tonumber(num)
    end

    --- Converts a value to a boolean
    -- @param (self): The current instance
    -- @param (b): The value to convert
    -- @return: The converted boolean
    function constructor.Boolean(self, b)
        return tobool(b)
    end

    --- Creates an associative table from given values
    -- @param self: The current instance
    -- @param ...: Values to include in the associative table
    -- @return: The created associative table
    function constructor.AssocTable(self, ...)
        local data = {...}
        if helpers.istable(data[1]) then
            data = data[1]
        end

        local out = { }
        for i = 1, #data do
            out[data[i]] = true
        end
        return out
    end

    --- Loads a model from a specified path
    -- @param (self): The current instance
    -- @param (path): The path to the model
    -- @return: The loaded model
    if Model then
        function constructor.Model(self, path)
            return Model(path) -- Preload the model
        end
    end

    --- Creates a color object
    -- @param (self): The current instance
    -- @param (r): Red component
    -- @param (g): Green component
    -- @param (b): Blue component
    -- @param (a): Alpha component (optional)
    -- @return: The created color object
    if Color then
        function constructor.Color(self, r, g, b, a)
            if helpers.isnumber(r) then
                return Color(r, g, b, a)
            end
            return r
        end
    end

    --- Creates a vector object
    -- @param (self): The current instance
    -- @param (x): X component
    -- @param (y): Y component
    -- @param (z): Z component
    -- @return: The created vector object
    if Vector then
        function constructor.Vector(self, x, y, z)
            if helpers.isnumber(x) then
                return Vector(x, y, z)
            end
            return x
        end
    end

    --- Creates an angle object
    -- @param (self): The current instance
    -- @param (p): Pitch
    -- @param (y): Yaw
    -- @param (r): Roll
    -- @return: The created angle object
    if Angle then
        function constructor.Angle(self, p, y, r)
            if helpers.isnumber(p) then
                return Angle(p, y, r)
            end
            return p
        end
    end

    --- Combines a vector and an angle into a single object
    -- @param (self): The current instance
    -- @param (vec): The vector object
    -- @param (ang): The angle object
    -- @return: A table containing both the vector and angle
    if (Vector and Angle) then
        function constructor.Position(self, vec, ang)
            if (not helpers.isvector(vec)) then
                local old = vec
                vec = ang
                ang = old
            end

            if (not helpers.isvector(vec)) then
                vec = vector_origin
            end

            if (not helpers.isangle(ang)) then
                ang = angle_zero
            end

            return {
                vec = vec,
                ang = ang
            }
        end
    end

    --- Retrieves a player object by Steam ID
    -- @param (self): The current instance
    -- @param (pPlayer): The Steam ID of the player
    -- @return: The player object
    if Player then
        function constructor.Player(self, pPlayer)
            if helpers.isstring(pPlayer) then
                return player.GetBySteamID64(pPlayer) or player.GetBySteamID(pPlayer)
            else
                return pPlayer
            end
        end
    end

    --- Returns the entity index of a given entity
    -- @param (self): The current instance
    -- @param (ent): The entity to get the index of
    -- @return: The entity index
    if IsEntity then
        function constructor.EntityIndex(self, ent)
            if IsEntity(ent) then
                return ent:EntIndex()
            else
                return ent
            end
        end
    end
end


/***
 *   @description   The `DanLib.UiClass.Create` function is used to create a new class in a DanLib project.
 *                  If the `class` parameter is passed, this class definition will be used. Otherwise a new empty class is created.
 *                  The class supports instance creation, working with accessors and their setters, and data synchronisation between server and client.
 *   
 *   @attributes
 *                  - _isclass: Indicates that this is a class.
 *                  - _accessordefault: Stores default values for accessors.
 *                  - _accessorlist: Stores a list of available accessors for the class.
 *                  - _instances: Stores all instances of the class.
 *
 *   @methods
 *                  - new(obj, metadata): Creates a new instance of a class. Accepts an object and metadata. If no object is specified, a new object is created.
 *                  - Accessor(name, constructor, metadata): Adds an accessor to a class with the specified name. Optionally accepts constructor and metadata for the accessor.
 *                  - AccessorList(name, constructor): Adds a list of accessors to a class with the specified name. Allows you to manage collections of objects.
 *
 *   @notes
 *                  The class supports setters and getters for accessors, as well as the ability to synchronise data between client and server via network messages.
 *                  It also supports the ability to use colbacks to validate and process values before setting them.
 */
function DUiClass.Create(class)
    if (class == nil) then
        class = { }
        class.__index = class
        class._instances = { }

        function class:new(obj, metadata)
            if (obj == nil or helpers.istable(obj)) then
                local instance = setmetatable(obj or { }, self)

                for name in pairs(self._accessorlist) do
                    instance[name] = { }
                end

                for name, default in pairs(self._accessordefault) do
                    instance[name] = default
                end

                local init = self.init or self.Init or self.Initialize
                if init then
                    init(instance, metadata)
                end

                instance._instanceid = #self._instances + 1
                self._instances[instance._instanceid] = instance

                return instance
            else -- userdata support
                return helpers.inherit(obj, self)
            end
        end

        function class.__call(obj, metadata)
            return class:new(obj, metadata)
        end
    end

    class._isclass = true
    class._accessordefault = { }

    function class:Accessor(name, constructor, metadata)
        metadata = metadata or { }

        if metadata.default then
            self._accessordefault[name] = metadata.default
        end

        local netid

        if metadata.network then
            local info = debug.getinfo(2)
            netid = 'class/accessor/' .. info.source .. '-' .. info.currentline .. '/'.. name

            if SERVER then
                util.AddNetworkString(netid)

                local already = { }

                net.Receive(netid, function(_, pPlayer)
                    if already[pPlayer] then
                        return
                    end
                    already[pPlayer] = true

                    for id, instance in ipairs(self._instances) do
                        if instance[name] then
                            net.Start(netid)
                                net.WriteUInt(id, 32)
                                net.WriteType(instance[name])
                            net.Send(pPlayer)
                        end
                    end
                end)
            else
                net.Receive(netid, function()
                    local instance = self._instances[net.ReadUInt(32)]
                    local data = net.ReadType()
                    instance['Set' .. name](instance, data)
                end)

                if iClassInitPostEntity then
                    net.Start(netid)
                    net.SendToServer()
                else
                    hook.Add('InitPostEntity', netid, function()
                        hook.Remove('InitPostEntity', netid)
                        iClassInitPostEntity = true

                        net.Start(netid)
                        net.SendToServer()
                    end)
                end
            end
        end

        local OnChange = 'On' .. name .. 'Change'
        if constructor then
            self['Set' .. name] = function(sl, ...)
                local val
                if metadata.cback then
                    local new = metadata.cback(sl, ...)
                    if (new == nil) then
                        return sl
                    else
                        val = new
                    end
                else
                    val = constructor(sl, ...)
                end

                if (metadata.validate and metadata.validate(sl, val) == false) then
                    return sl
                end

                local old = sl[name]
                sl[name] = val

                if sl[OnChange] then
                    sl[OnChange](sl, val, old)
                end

                if (netid and SERVER and #player.GetHumans() > 0) then
                    net.Start(netid)
                        net.WriteUInt(sl._instanceid, 32)
                        net.WriteType(val)
                    net.Broadcast()
                end
                return sl
            end
        else
            self['Set' .. name] = function(sl, val)
                if metadata.cback then
                    local new = metadata.cback(sl, val)
                    if (new == nil) then
                        return sl
                    else
                        val = new
                    end
                end

                if (metadata.validate and metadata.validate(sl, val) == false) then
                    return sl
                end

                local old = sl[name]
                sl[name] = val

                if sl[OnChange] then
                    sl[OnChange](sl, val, old)
                end

                if (netid and SERVER) then
                    net.Start(netid)
                        net.WriteUInt(sl._instanceid, 32)
                        net.WriteType(val)
                    net.Broadcast()
                end

                return sl
            end
        end

        self['Get' .. name] = function(sl)
            if metadata.getter then
                return sl[name] and metadata.getter(sl[name]) or nil
            else
                return sl[name]
            end
        end

        if (metadata.is == true) then
            self['Is' .. name] = function(sl)
                return sl[name] == true
            end
        end

        if metadata.alias then
            local function AddAlias(alias)
                self['Set' .. alias] = self['Set' .. name]
                self['Get' .. alias] = self['Get' .. name]

                if (metadata.is == true) then
                    self['Is' .. alias] = self['Is' .. name]
                end
            end

            if helpers.istable(metadata.alias) then
                for i, alias in ipairs(metadata.alias) do
                    AddAlias(alias)
                end
            else
                AddAlias(metadata.alias)
            end
        end

        return self
    end

    class._accessorlist = { }

    function class:AccessorList(name, constructor)
        local list_name = name .."s"
        self._accessorlist[list_name] = true

        self['Get' .. list_name] = function(sl)
            return sl[list_name]
        end

        self['Set' .. list_name] = function(sl, ...)
            local value = helpers.istable(...) and ... or {...}
            if constructor then
                local data = { }
                for i, v in ipairs(value) do
                    if helpers.istable(v) then
                        data[i] = constructor(sl, helpers.unpack(v))
                    else
                        data[i] = constructor(sl, v)
                    end
                end

                sl[list_name] = data
            else
                sl[list_name] = value
            end
            return sl
        end

        self['Add' .. name] = function(sl, ...)
            sl[list_name][#sl[list_name] + 1] = constructor and constructor(sl, ...) or ...
            return sl
        end

        return self
    end

    return class, constructor
end
