/***
 *   @script        DDIDB
 *   @author        DDI Scripts
 *   @version       1.0.2
 *   @description   Core functionality for the DDIDB library.
 *   @license       MIT License
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */


DDIDB = DDIDB or { }
DDIDB.Version = '1.0.2'

-- Initialize local variables
local initialized = false
local config = { }
local inTransaction = false
local transactionQueue = { }
local logEnabled = false
local reconnectAttempts = 0
local maxReconnectAttempts = 5
local mysqloo_available = false
local tmysql_available = false
local mysql_module = nil
local db_connection = nil

local _tableinsert = table.insert
local _timerSimple = timer.Simple
local _stringformat = string.format
local _tonumber = tonumber
local _tostring = tostring
local _mathmin = math.min
local _SysTime = SysTime
local _IsValid = IsValid
local _ipairs = ipairs
local _pairs = pairs
local _pcall = pcall

-- Log function for debug output
local function log(message)
    if logEnabled then
        print('[DDIDB] ' .. message)
    end
end

-- Function to check for available MySQL modules
local function checkMySQLModules()
    -- Reset availability flags
    mysqloo_available = false
    tmysql_available = false
    
    -- Check system information for appropriate module selection
    local IsWindows = system.IsWindows()
    local IsLinux = system.IsLinux()
    local arch = jit.arch
    
    -- Determine appropriate module filenames based on OS and architecture
    local _windows = (IsWindows and (arch == 'x64' and 'win64' or 'win32'))
    local _linux = (IsLinux and (arch == 'x64' and 'linux64' or 'linux'))
    local _filename_mysqloo = 'gmsv_mysqloo_' .. (_windows or _linux)
    local _filename_tmysql4 = 'gmsv_tmysql4_' .. (_windows or _linux)
    
    -- Check if modules exist in the binary directory
    local has_mysqloo_bin = file.Exists('bin/' .. _filename_mysqloo .. '.dll', 'LUA')
    local has_tmysql4_bin = file.Exists('bin/' .. _filename_tmysql4 .. '.dll', 'LUA')
    
    log('Checking for MySQL modules')
    
    if (config.PreferredModule == 'mysqloo') then
        -- Try to load MySQLOO first (preferred)
        if has_mysqloo_bin then
            log('Found MySQLOO binary')
            mysqloo_available = _pcall(function()
                require('mysqloo')
            end)

            if mysqloo_available then
                log('MySQLOO module loaded successfully')
            else
                log('Failed to load MySQLOO module, trying TMySQL4')
                -- Try TMySQL as fallback
                if has_tmysql4_bin then
                    tmysql_available = _pcall(function()
                        require('tmysql4')
                    end)

                    if tmysql_available then
                        log('TMySQL4 module loaded successfully as fallback')
                    else
                        log('Failed to load TMySQL4 module')
                    end
                end
            end
        else
            log('MySQLOO binary not found, trying TMySQL4')
            -- Try TMySQL as fallback
            if has_tmysql4_bin then
                tmysql_available = _pcall(function()
                    require('tmysql4')
                end)

                if tmysql_available then
                    log('TMySQL4 module loaded successfully')
                else
                    log('Failed to load TMySQL4 module')
                end
            end
        end
    else
        -- Try to load TMySQL4 first (preferred)
        if has_tmysql4_bin then
            log('Found TMySQL4 binary')
            tmysql_available = _pcall(function()
                require('tmysql4')
            end)

            if tmysql_available then
                log('TMySQL4 module loaded successfully')
            else
                log('Failed to load TMySQL4 module, trying MySQLOO')
                -- Try MySQLOO as fallback
                if has_mysqloo_bin then
                    mysqloo_available = _pcall(function()
                        require('mysqloo')
                    end)

                    if mysqloo_available then
                        log('MySQLOO module loaded successfully as fallback')
                    else
                        log('Failed to load MySQLOO module')
                    end
                end
            end
        else
            log('TMySQL4 binary not found, trying MySQLOO')
            -- Try MySQLOO as fallback
            if has_mysqloo_bin then
                mysqloo_available = _pcall(function()
                    require('mysqloo')
                end)

                if mysqloo_available then
                    log('MySQLOO module loaded successfully')
                else
                    log('Failed to load MySQLOO module')
                end
            end
        end
    end
    
    -- If neither module is available but binaries exist, log error
    if (not mysqloo_available and not tmysql_available) then
        if (has_mysqloo_bin or has_tmysql4_bin) then
            log('Error: MySQL modules found but could not be loaded')
        else
            log('No MySQL modules found in binary directory')
        end
    end
    
    return mysqloo_available or tmysql_available
end
checkMySQLModules()


-- Error handler function
local function handleError(errorMessage, query, errorCallback)
    local fullError = 'SQL Error: ' .. errorMessage .. (query and (' in query: ' .. query) or '')
    log(fullError)
    
    if errorCallback then
        errorCallback(fullError)
    else
        ErrorNoHalt(fullError .. '\n')
    end
    
    return false
end

-- Initialize the database connection
function DDIDB:Initialize(cfg)
    config = cfg or { }
    
    -- Set default values for config
    config.Prefix = config.Prefix or ''
    config.Debug = config.Debug or false
    config.AutoReconnect = config.AutoReconnect or true
    logEnabled = config.Debug
    
    log('Initializing database connection')
    
    -- Determine which database to use
    if config.Enable then
        -- MySQL
        log('Using MySQL database')
        
        -- Check for available modules first
        if (not checkMySQLModules()) then
            log('No MySQL modules available, falling back to SQLite')
            config.Enable = false
            initialized = true
            return true
        end
        
        -- Choose MySQL module
        if mysqloo_available then
            mysql_module = 'mysqloo'
            log('Using MySQLOO module')
            
            -- Connect to MySQL
            db_connection = mysqloo.connect(
                config.Host or 'localhost',
                config.User or 'root',
                config.Password or '',
                config.Database or 'gmod',
                config.Port or 3306
            )
            
            -- IMPORTANT: Setting initialized = false before connecting
            initialized = false
            
            -- Set up connection callbacks
            db_connection.onConnected = function()
                log('Successfully connected to MySQL database!')
                reconnectAttempts = 0
                initialized = true  -- We install it only HERE after successful connection.
            end
            
            db_connection.onConnectionFailed = function(_, err)
                initialized = false
                handleError('MySQL connection failed: ' .. err)
                
                -- Try to reconnect if enabled
                if (config.AutoReconnect and reconnectAttempts < maxReconnectAttempts) then
                    reconnectAttempts = reconnectAttempts + 1
                    log('Attempting to reconnect (' .. reconnectAttempts .. '/' .. maxReconnectAttempts .. ')')
                    _timerSimple(_mathmin(reconnectAttempts * 5, 30), function()
                        if _IsValid(db_connection) then
                            db_connection:connect()
                        end
                    end)
                end
            end
            
            -- Start connection
            db_connection:connect()
            -- We return true because the initialization process has started.
            -- But the actual connection will happen asynchronously.
            return true
            
        elseif tmysql_available then
            mysql_module = 'tmysql4'
            log('Using TMySQL4 module')
            
            -- Connect to MySQL with TMySQL4
            local success, result = tmysql.initialize(config.Host or 'localhost', config.User or 'root', config.Password or '', config.Database or 'gmod', config.Port or 3306, nil, --[[ socket ]] nil, --[[ flags ]] nil --[[ charset ]])
            if success then
                log('Successfully connected to MySQL database!')
                db_connection = result
                initialized = true
                reconnectAttempts = 0
                return true
            else
                initialized = false
                handleError('TMySQL4 connection failed: ' .. (result or 'Unknown error'))
                
                -- Try to reconnect if enabled
                if (config.AutoReconnect and reconnectAttempts < maxReconnectAttempts) then
                    reconnectAttempts = reconnectAttempts + 1
                    log('Attempting to reconnect (' .. reconnectAttempts .. '/' .. maxReconnectAttempts .. ')')
                    _timerSimple(_mathmin(reconnectAttempts * 5, 30), function()
                        DDIDB:Initialize(config)
                    end)
                end
                
                return false
            end
        else
            -- No MySQL module available, fall back to SQLite
            log('No MySQL modules available, falling back to SQLite')
            config.Enable = false
        end
    end
    
    -- If not using MySQL or no MySQL module is available, use SQLite
    if (not config.Enable) then
        log('Using SQLite database')
        initialized = true
        return true
    end
    
    return false
end

-- Check if database is connected and ready
function DDIDB:IsConnected()
    return initialized
end

-- Wait for database connection (with callback)
function DDIDB:WaitForConnection(callback, timeout)
    timeout = timeout or 60
    local startTime = _SysTime()
    local timerName = 'DDIDB_WaitConnection_' .. math.random(1000000)
    local lastLogTime = 0
    
    timer.Create(timerName, 0.5, timeout * 2, function()
        local elapsed = _SysTime() - startTime
        
        -- We log the progress every 5 seconds
        if (elapsed - lastLogTime >= 5) then
            lastLogTime = elapsed
            if (not initialized) then
                log(_stringformat('Waiting for connection... (%.0f/%.0f seconds)\n', elapsed, timeout))
            end
        end
        
        if initialized then
            timer.Remove(timerName)
            log(_stringformat('Connection is set for %.1f seconds\n', elapsed))
            if callback then
                callback(true)
            end
        elseif (elapsed >= timeout) then
            timer.Remove(timerName)
            log(_stringformat('Waiting time exceeded (%.0f seconds)\n', timeout))
            if callback then
                callback(false)
            end
        end
    end)
end

-- Check if using MySQL
function DDIDB:IsMySQL()
    return config.Enable or false
end

-- Get table name with prefix
function DDIDB:TableName(name)
    return name
end

-- Escape a string for SQL
function DDIDB:Escape(str)
    if (not initialized) then
        error('Database not initialized')
        return str
    end
    
    if self:IsMySQL() then
        if (mysql_module == 'mysqloo' and db_connection) then
            return db_connection:escape(_tostring(str))
        elseif (mysql_module == 'tmysql4' and db_connection) then
            return db_connection:Escape(_tostring(str))
        end
    end
    
    -- SQLite escape (basic)
    return sql.SQLStr(_tostring(str), true)
end

-- Replace placeholders with escaped values
local function processSQLWithParams(sqlQuery, params)
    if (not params or #params == 0) then
        return sqlQuery
    end
    
    local index = 1
    local newQuery = sqlQuery:gsub('?', function()
        local value = params[index]
        index = index + 1
        
        if (value == nil) then
            return 'NULL'
        elseif (type(value) == 'string') then
            return '"' .. DDIDB:Escape(value) .. '"'
        elseif (type(value) == 'boolean') then
            return value and '1' or '0'
        else
            return _tostring(value)
        end
    end)
    
    return newQuery
end

-- Execute a query with parameters
function DDIDB:Query(sqlQuery, params, callback, errorCallback)
    if (not initialized) then
        return handleError('Database not initialized', sqlQuery, errorCallback)
    end
    
    local processedQuery = processSQLWithParams(sqlQuery, params)
    log('Executing query: ' .. processedQuery)
    
    -- Handle transaction queue
    if inTransaction and not (processedQuery:match('^BEGIN') or processedQuery:match('^COMMIT') or processedQuery:match('^ROLLBACK')) then
        _tableinsert(transactionQueue, {
            query = processedQuery,
            callback = callback,
            errorCallback = errorCallback
        })
        log('Query added to transaction queue')
        return true
    end
    
    -- Execute the query based on database type
    if self:IsMySQL() then
        if (mysql_module == 'mysqloo' and db_connection) then
            local query = db_connection:query(processedQuery)
            
            query.onSuccess = function(_, data)
                if callback then
                    local result = {
                        status = true,
                        affected = query:affectedRows(),
                        lastID = query:lastInsert(),
                        results = data
                    }
                    callback(result)
                end
            end
            
            query.onError = function(_, err)
                return handleError(err, processedQuery, errorCallback)
            end
            
            query:start()
            return true
            
        elseif (mysql_module == 'tmysql4' and db_connection) then
            db_connection:Query(processedQuery, function(_, status, data, lastID, affected, err)
                if status then
                    if callback then
                        local result = {
                            status = true,
                            affected = affected,
                            lastID = lastID,
                            results = data
                        }
                        callback(result)
                    end
                else
                    return handleError(err, processedQuery, errorCallback)
                end
            end)
            return true
        else
            return handleError('No MySQL connection available', processedQuery, errorCallback)
        end
    else
        -- SQLite execution
        local success, result = _pcall(function()
            if processedQuery:match('^BEGIN') or processedQuery:match('^COMMIT') or processedQuery:match('^ROLLBACK') then
                sql.Query(processedQuery)
                return {
                    status = true,
                    affected = 0,
                    lastID = 0,
                    results = { }
                }
            else
                local queryResult = sql.Query(processedQuery)
                local queryError = sql.LastError()
                
                if (queryError and queryError ~= '') then
                    error(queryError)
                end
                
                -- Get last insert ID for SQLite
                local lastID = 0
                if processedQuery:match('^INSERT') then
                    local lastIDResult = sql.Query('SELECT last_insert_rowid() as id')
                    if (lastIDResult and lastIDResult[1] and lastIDResult[1].id) then
                        lastID = _tonumber(lastIDResult[1].id) or 0
                    end
                end
                
                -- Get actual affected rows count from SQLite (changes() returns
                -- the number of rows changed by the last INSERT/UPDATE/DELETE).
                local affected = 0
                if processedQuery:match('^INSERT') or processedQuery:match('^UPDATE') or processedQuery:match('^DELETE') then
                    local changesResult = sql.Query('SELECT changes() as c')
                    if (changesResult and changesResult[1]) then
                        affected = _tonumber(changesResult[1].c) or 0
                    end
                end
                
                return {
                    status = true,
                    affected = affected,
                    lastID = lastID,
                    results = queryResult or { }
                }
            end
        end)
        
        if success and callback then
            callback(result)
            return true
        elseif not success then
            return handleError(result, processedQuery, errorCallback)
        end
        
        return success
    end
end

-- Check if a table exists
function DDIDB:TableExists(name, callback)
    local tableName = self:TableName(name)
    
    if self:IsMySQL() then
        local query = 'SHOW TABLES LIKE "' .. tableName .. '"'
        self:Query(query, nil, function(data)
            local exists = data.results and #data.results > 0
            if callback then
                callback(exists)
            end
        end, function(err)
            if callback then
                callback(false)
            end
        end)
    else
        local query = 'SELECT name FROM sqlite_master WHERE type="table" AND name="' .. tableName .. '"'
        self:Query(query, nil, function(data)
            local exists = data.results and #data.results > 0
            if callback then
                callback(exists)
            end
        end, function(err)
            if callback then
                callback(false)
            end
        end)
    end
end

-- Create a table if it doesn't exist
function DDIDB:CreateTable(name, schema, callback)
    local tableName = self:TableName(name)
    
    -- Modify schema for SQLite if needed
    local finalSchema = schema
    if (not self:IsMySQL()) then
        -- Replace MySQL-specific types and keywords for SQLite compatibility
        finalSchema = finalSchema:gsub('AUTO_INCREMENT', 'AUTOINCREMENT')
        finalSchema = finalSchema:gsub('VARCHAR%((%d+)%)', 'TEXT')
        finalSchema = finalSchema:gsub('TEXT%((%d+)%)', 'TEXT')
        finalSchema = finalSchema:gsub('TINYINT%(%d+%)', 'INTEGER')
        finalSchema = finalSchema:gsub('SMALLINT%(%d+%)', 'INTEGER')
        finalSchema = finalSchema:gsub('MEDIUMINT%(%d+%)', 'INTEGER')
        finalSchema = finalSchema:gsub('INT%(%d+%)', 'INTEGER')
        finalSchema = finalSchema:gsub('BIGINT%(%d+%)', 'INTEGER')
        finalSchema = finalSchema:gsub('DATETIME', 'TEXT')
        finalSchema = finalSchema:gsub('TIMESTAMP', 'TEXT')
    end
    
    local query = 'CREATE TABLE IF NOT EXISTS ' .. tableName .. ' (' .. finalSchema .. ')'
    
    self:Query(query, nil, function(data)
        if callback then
            callback(data.status)
        end
    end, function(err)
        if callback then
            callback(false)
        end
    end)
end

-- Add a column to a table if it doesn't exist
function DDIDB:AddColumn(tableName, columnName, columnDef, callback)
    local fullTableName = self:TableName(tableName)
    
    -- First check if the column exists
    local checkColumnQuery = ''
    if self:IsMySQL() then
        checkColumnQuery = 'SHOW COLUMNS FROM ' .. fullTableName .. ' LIKE "' .. columnName .. '"'
    else
        checkColumnQuery = 'PRAGMA table_info(' .. fullTableName .. ')'
    end
    
    self:Query(checkColumnQuery, nil, function(data)
        local columnExists = false
        
        if self:IsMySQL() then
            columnExists = data.results and #data.results > 0
        else
            if data.results then
                for _, column in _ipairs(data.results) do
                    if (column.name == columnName) then
                        columnExists = true
                        break
                    end
                end
            end
        end
        
        if (not columnExists) then
            -- Modify column definition for SQLite if needed
            local finalColumnDef = columnDef
            if (not self:IsMySQL()) then
                finalColumnDef = finalColumnDef:gsub('VARCHAR%((%d+)%)', 'TEXT')
                finalColumnDef = finalColumnDef:gsub('TEXT%((%d+)%)', 'TEXT')
                finalColumnDef = finalColumnDef:gsub('TINYINT%(%d+%)', 'INTEGER')
                finalColumnDef = finalColumnDef:gsub('SMALLINT%(%d+%)', 'INTEGER')
                finalColumnDef = finalColumnDef:gsub('MEDIUMINT%(%d+%)', 'INTEGER')
                finalColumnDef = finalColumnDef:gsub('INT%(%d+%)', 'INTEGER')
                finalColumnDef = finalColumnDef:gsub('BIGINT%(%d+%)', 'INTEGER')
                finalColumnDef = finalColumnDef:gsub('DATETIME', 'TEXT')
                finalColumnDef = finalColumnDef:gsub('TIMESTAMP', 'TEXT')
            end
            
            local query = 'ALTER TABLE ' .. fullTableName .. ' ADD COLUMN ' .. columnName .. ' ' .. finalColumnDef
            self:Query(query, nil, function(alterData)
                if callback then
                    callback(alterData.status)
                end
            end, function(err)
                if callback then
                    callback(false)
                end
            end)
        else
            if callback then
                callback(true)
            end -- Column already exists
        end
    end, function(err)
        if callback then
            callback(false)
        end
    end)
end

-- Insert data into a table
function DDIDB:Insert(tableName, data, callback, errorCallback)
    if (type(data) ~= 'table' or table.IsEmpty(data)) then
        return handleError('Invalid data for insert', nil, errorCallback)
    end
    
    local fullTableName = self:TableName(tableName)
    local columns = { }
    local placeholders = { }
    local values = { }
    
    for col, val in _pairs(data) do
        _tableinsert(columns, col)
        _tableinsert(placeholders, '?')
        _tableinsert(values, val)
    end
    
    local query = 'INSERT INTO ' .. fullTableName ..  ' (' .. table.concat(columns, ', ') .. ') ' ..  'VALUES (' .. table.concat(placeholders, ', ') .. ')'
    
    return self:Query(query, values, callback, errorCallback)
end

-- Update data in a table
function DDIDB:Update(tableName, data, whereClause, whereParams, callback, errorCallback)
    if (type(data) ~= 'table' or table.IsEmpty(data)) then
        return handleError('Invalid data for update', nil, errorCallback)
    end
    
    local fullTableName = self:TableName(tableName)
    local setParts = { }
    local values = { }
    
    for col, val in _pairs(data) do
        _tableinsert(setParts, col .. ' = ?')
        _tableinsert(values, val)
    end
    
    local query = 'UPDATE ' .. fullTableName ..  ' SET ' .. table.concat(setParts, ', ')
    
    if (whereClause and whereClause ~= '') then
        query = query .. ' WHERE ' .. whereClause
        if whereParams then
            for _, val in _ipairs(whereParams) do
                _tableinsert(values, val)
            end
        end
    end
    
    return self:Query(query, values, callback, errorCallback)
end

-- Delete data from a table
function DDIDB:Delete(tableName, whereClause, whereParams, callback, errorCallback)
    local fullTableName = self:TableName(tableName)
    local query = 'DELETE FROM ' .. fullTableName
    
    if (whereClause and whereClause ~= '') then
        query = query .. ' WHERE ' .. whereClause
    end
    
    return self:Query(query, whereParams, callback, errorCallback)
end

-- Select data from a table
function DDIDB:Select(tableName, columns, whereClause, whereParams, orderBy, limit, callback, errorCallback)
    local fullTableName = self:TableName(tableName)
    local columnStr = '*'
    
    if (columns and type(columns) == 'table' and #columns > 0) then
        columnStr = table.concat(columns, ', ')
    end
    
    local query = 'SELECT ' .. columnStr .. ' FROM ' .. fullTableName
    
    if (whereClause and whereClause ~= '') then
        query = query .. ' WHERE ' .. whereClause
    end
    
    if (orderBy and orderBy ~= '') then
        query = query .. ' ORDER BY ' .. orderBy
    end
    
    if (limit and _tonumber(limit)) then
        query = query .. ' LIMIT ' .. _tonumber(limit)
    end
    
    return self:Query(query, whereParams, callback, errorCallback)
end

-- Count rows in a table
function DDIDB:Count(tableName, whereClause, whereParams, callback, errorCallback)
    local fullTableName = self:TableName(tableName)
    local query = 'SELECT COUNT(*) as count FROM ' .. fullTableName
    
    if (whereClause and whereClause ~= '') then
        query = query .. ' WHERE ' .. whereClause
    end
    
    return self:Query(query, whereParams, function(data)
        if (data.status and data.results and data.results[1]) then
            local countResult = {
                status = true,
                count = _tonumber(data.results[1].count) or 0
            }

            if callback then
                callback(countResult)
            end
        else
            if callback then
                callback({
                    status = false,
                    count = 0
                })
            end
        end
    end, errorCallback)
end

-- Find a record by ID
function DDIDB:FindByID(tableName, id, idColumn, callback, errorCallback)
    idColumn = idColumn or 'id'
    
    return self:Select(tableName, nil, idColumn .. ' = ?', { id }, nil, 1, function(data)
        if (data.status and data.results and data.results[1]) then
            if callback then
                callback(data.results[1])
            end
        else
            if callback then
                callback(nil)
            end
        end
    end, errorCallback)
end

-- Begin a transaction
function DDIDB:BeginTransaction()
    if inTransaction then
        log('Transaction already in progress')
        return false
    end
    
    inTransaction = true
    transactionQueue = { }
    
    return self:Query('BEGIN', nil, function()
        log('Transaction begun')
    end)
end

-- Commit a transaction
function DDIDB:CommitTransaction(callback)
    if (not inTransaction) then
        log('No transaction in progress')
        if callback then
            callback(false)
        end
        return false
    end
    
    local allSuccess = true
    local results = { }
    local completedQueries = 0
    
    -- If no queries in queue, just commit
    if (#transactionQueue == 0) then
        inTransaction = false
        return self:Query('COMMIT', nil, function(data)
            log('Empty transaction committed')
            if callback then
                callback(true)
            end
        end)
    end
    
    -- Execute all queries in the queue
    for i, queryData in _ipairs(transactionQueue) do
        self:Query(queryData.query, nil, function(data)
            results[i] = data
            completedQueries = completedQueries + 1
            
            if queryData.callback then
                queryData.callback(data)
            end
            
            -- If all queries complete, commit the transaction
            if (completedQueries == #transactionQueue) then
                inTransaction = false
                transactionQueue = { }
                
                self:Query('COMMIT', nil, function(commitData)
                    log('Transaction committed with ' .. completedQueries .. ' queries')
                    if callback then
                        callback(allSuccess, results)
                    end
                end)
            end
        end, function(err)
            allSuccess = false
            completedQueries = completedQueries + 1
            
            if queryData.errorCallback then
                queryData.errorCallback(err)
            end
            
            -- If all queries complete, check if we should commit or rollback
            if (completedQueries == #transactionQueue) then
                inTransaction = false
                transactionQueue = { }
                
                if allSuccess then
                    self:Query('COMMIT', nil, function()
                        log('Transaction committed despite errors')
                        if callback then
                            callback(false, results)
                        end
                    end)
                else
                    self:Query('ROLLBACK', nil, function()
                        log('Transaction rolled back due to errors')
                        if callback then
                            callback(false, results)
                        end
                    end)
                end
            end
        end)
    end
    
    return true
end

-- Rollback a transaction
function DDIDB:RollbackTransaction()
    if (not inTransaction) then
        log('No transaction in progress')
        return false
    end
    
    inTransaction = false
    transactionQueue = { }
    
    return self:Query('ROLLBACK', nil, function()
        log('Transaction rolled back')
    end)
end

-- Queue a query in a transaction
function DDIDB:QueueQuery(query, params, callback, errorCallback)
    if (not inTransaction) then
        log('No transaction in progress, executing query directly')
        return self:Query(query, params, callback, errorCallback)
    end
    
    local processedQuery = processSQLWithParams(query, params)
    _tableinsert(transactionQueue, {
        query = processedQuery,
        callback = callback,
        errorCallback = errorCallback
    })
    
    log('Query added to transaction queue')
    return true
end

-- Direct SQL query without processing (for advanced use)
function DDIDB:RawQuery(query, callback, errorCallback)
    return self:Query(query, nil, callback, errorCallback)
end

return DDIDB
