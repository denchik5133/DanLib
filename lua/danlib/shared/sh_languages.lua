/***
 *   @addon         DanLib
 *   @component     Languages
 *   @license       MIT License
 *   @version       1.1.0
 *   @release_date  05/07/2026
 *   @author        denchik, CastleKeeper
 *
 *   @contact
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *
 *   @description   Localisation and internationalisation system for DanLib.
 *                  Manages all language string tables and provides the lookup
 *                  API used across every DanLib component and external module.
 *
 *   @functions
 *                  DanLib.Language.Options
 *                      Table of supported language codes → names (e.g. 'ru' → 'Russian').
 *
 *                  DanLib.Language.Icon(name)
 *                      Returns the Material for a given language name.
 *
 *                  DanLib.Func:L(id [, params])
 *                      Retrieves the localised string for id in the currently
 *                      active language. Falls back to English, then to
 *                      '#langmissing'. Supports {key} token substitution via params.
 *
 *                  DanLib.Func.RegisterLanguage(langName, stringTable)
 *                      Merges stringTable into DanLib.Temp.Languages[langName].
 *                      Used internally by language files under danlib/languages/.
 *
 *                  DanLib.Func.LoadLanguages()
 *                      Scans danlib/languages/*.lua and includes every file,
 *                      which calls RegisterLanguage internally.
 *
 *                  DanLib.Func.ExtendLanguage(sourceID, contributions)
 *                      Registers language keys from an external addon or removable
 *                      module. contributions = { [langName] = { key = value } }.
 *                      Keys are merged into the live language tables immediately
 *                      and stored under sourceID for later removal.
 *                      If the same key exists in a base file, the extension wins.
 *
 *                  DanLib.Func.RemoveLanguageExtension(sourceID)
 *                      Removes all keys contributed by sourceID, then rebuilds
 *                      the full language tables from base files + remaining
 *                      extensions. Keys from other sources are not affected.
 *
 *                  DanLib.Func.GetLanguageExtension(sourceID)
 *                      Returns the contributions table for sourceID, or nil.
 *
 *   @example
 *                  -- Add keys from a removable chat module
 *                  DanLib.Func.ExtendLanguage('CHAT_MODULE', {
 *                      ['English'] = { chat_muted = 'You are muted.' },
 *                      ['Russian'] = { chat_muted = 'Вы замьючены.' },
 *                  })
 *
 *                  -- When the module is unloaded:
 *                  DanLib.Func.RemoveLanguageExtension('CHAT_MODULE')
 *
 *                  -- Classic one-off registration (no removal support):
 *                  DanLib.Func.RegisterLanguage('English', { greeting = 'Hello' })
 *
 *                  -- Retrieve a string:
 *                  local s = DanLib.Func:L('chat_muted')
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         Language names used in ExtendLanguage must match the names in
 *                  DanLib.Temp.Languages (e.g. 'English', 'Russian'), not the
 *                  two-letter codes in DanLib.Language.Options ('en', 'ru').
 */



local DBase = DanLib.Func
local DFileUtil = DanLib.FileUtil

local _type = type
local _pairs = pairs
local _assert = assert
local _tostring = tostring
local _Material = Material

DanLib.Language = DanLib.Language or { }
local DLanguage = DanLib.Language

DanLib.Temp.Languages = DanLib.Temp.Languages or { }
local DTemp = DanLib.Temp.Languages

-- List of supported languages and their codes
DLanguage.Options = { 
    ['af'] = 'Afrikaans',
    ['ga'] = 'Irish',
    ['sq'] = 'Albanian',
    ['it'] = 'Italian',
    ['ja'] = 'Japanese',
    ['az'] = 'Azerbaijani',
    ['kn'] = 'Kannada',
    ['eu'] = 'Basque',
    ['ko'] = 'Korean',
    ['bn'] = 'Bengali',
    ['la'] = 'Latin',
    ['be'] = 'Belarusian',
    ['lv'] = 'Latvian',
    ['bg'] = 'Bulgarian',
    ['ca'] = 'Catalan',
    ['mk'] = 'Macedonian',
    ['zh-CN'] = 'Chinese Simplified',
    ['ms'] = 'Malay',
    ['zh-TW'] = 'Chinese Traditional',
    ['mt'] = 'Maltese',
    ['hr'] = 'Croatian',
    ['no'] = 'Norwegian',
    ['cs'] = 'Czech',
    ['fa'] = 'Persian',
    ['da'] = 'Danish',
    ['pl'] = 'Polish',
    ['nl'] = 'Dutch',
    ['ro'] = 'Romanian',
    ['eo'] = 'Esperanto',
    ['ru'] = 'Russian',
    ['et'] = 'Estonian',
    ['sr'] = 'Serbian',
    ['tl'] = 'Filipino',
    ['sk'] = 'Slovak',
    ['fi'] = 'Finnish',
    ['sl'] = 'Slovenian',
    ['fr'] = 'French',
    ['es'] = 'Spanish',
    ['gl'] = 'Galician',
    ['sw'] = 'Swahili',
    ['ka'] = 'Georgian',
    ['de'] = 'German',
    ['ta'] = 'Tamil',
    ['el'] = 'Greek',
    ['te'] = 'Telugu',
    ['gu'] = 'Gujarati',
    ['th'] = 'Thai',
    ['ht'] = 'Haitian Creole',
    ['tr'] = 'Turkish',
    ['iw'] = 'Hebrew',
    ['uk'] = 'Ukrainian',
    ['hi'] = 'Hindi',
    ['ur'] = 'Urdu',
    ['hu'] = 'Hungarian',
    ['vi'] = 'Vietnamese',
    ['is'] = 'Icelandic',
    ['cy'] = 'Welsh',
    ['id'] = 'Indonesian',
    ['yi'] = 'Yiddish'
}

-- Table containing language icons
local LanguageIcon = { 
	['Afrikaans'] = _Material('danlib/language/afrikaans.png'),
	['Irish'] = _Material('danlib/language/irish.png'),
	['Albanian'] = _Material('danlib/language/albanian.png'),
	['Italian'] = _Material('danlib/language/italian.png'),
	['Japan'] = _Material('danlib/language/japan.png'),
	['Austria'] = _Material('danlib/language/austria.png'),
	['Azerbaijani'] = _Material('danlib/language/azerbaijani.png'),
	['Kannada'] = _Material('danlib/language/kannada.png'),
	['Basque'] = _Material('danlib/language/basque.png'),
	['Korea'] = _Material('danlib/language/korea.png'),
	['Bengali'] = _Material('danlib/language/bengali.png'),
	['Latin'] = _Material('danlib/language/latin.png'),
	['Belarusian'] = _Material('danlib/language/belarusian.png'),
	['Latvian'] = _Material('danlib/language/latvian.png'),
	['Bulgaria'] = _Material('danlib/language/bulgaria.png'),
	['Catalan'] = _Material('danlib/language/catalan.png'),
	['Macedonian'] = _Material('danlib/language/macedonian.png'),
	['China'] = _Material('danlib/language/china.png'),
	['Malay'] = _Material('danlib/language/malay.png'),
	['Maltese'] = _Material('danlib/language/maltese.png'),
	['Croatian'] = _Material('danlib/language/croatian.png'),
	['Czech'] = _Material('danlib/language/czech.png'),
	['Persian'] = _Material('danlib/language/persian.png'),
	['Danish'] = _Material('danlib/language/danish.png'),
	['Finland'] = _Material('danlib/language/finland.png'),
	['Polish'] = _Material('danlib/language/polish.png'),
	['Dutch'] = _Material('danlib/language/dutch.png'),
	['France'] = _Material('danlib/language/france.png'),
	['Spain'] = _Material('danlib/language/spain.png'),
	['Romania'] = _Material('danlib/language/romania.png'),
	['English'] = _Material('danlib/language/english.png'),
	['Esperanto'] = _Material('danlib/language/esperanto.png'),
	['Italy'] = _Material('danlib/language/italy.png'),
	['Sweden'] = _Material('danlib/language/sweden.png'),
	['Russian'] = _Material('danlib/language/russian.png'),
	['Estonian'] = _Material('danlib/language/estonian.png'),
	['Serbian'] = _Material('danlib/language/serbian.png'),
	['Filipino'] = _Material('danlib/language/filipino.png'),
	['Slovak'] = _Material('danlib/language/slovak.png'),
	['Finnish'] = _Material('danlib/language/finnish.png'),
	['Slovenian'] = _Material('danlib/language/slovenian.png'),
	['French'] = _Material('danlib/language/french.png'),
	['Spanish'] = _Material('danlib/language/spanish.png'),
	['Galician'] = _Material('danlib/language/galician.png'),
	['Swahili'] = _Material('danlib/language/swahili.png'),
	['Georgian'] = _Material('danlib/language/georgian.png'),
	['German'] = _Material('danlib/language/german.png'),
	['Tamil'] = _Material('danlib/language/tamil.png'),
	['Greek'] = _Material('danlib/language/greek.png'),
	['Telugu'] = _Material('danlib/language/telugu.png'),
	['Gujarati'] = _Material('danlib/language/gujarati.png'),
	['Thai'] = _Material('danlib/language/thai.png'),
	['Haitian'] = _Material('danlib/language/haitian.png'),
	['Turkish'] = _Material('danlib/language/turkish.png'),
	['Portugal'] = _Material('danlib/language/portugal.png'),
	['Hebrew'] = _Material('danlib/language/hebrew.png'),
	['Ukrainian'] = _Material('danlib/language/ukrainian.png'),
	['Hindi'] = _Material('danlib/language/hindi.png'),
	['Urdu'] = _Material('danlib/language/urdu.png'),
	['Hungarian'] = _Material('danlib/language/hungarian.png'),
	['Vietnamese'] = _Material('danlib/language/vietnamese.png'),
	['Icelandic'] = _Material('danlib/language/icelandic.png'),
	['Welsh'] = _Material('danlib/language/welsh.png'),
	['Indonesian'] = _Material('danlib/language/indonesian.png'),
	['Yiddish'] = _Material('danlib/language/yiddish.png'),
	['Ethiopia'] = _Material('danlib/language/ethiopia.png'),
	['Norway'] = _Material('danlib/language/norway.png'),
	['Gibraltar'] = _Material('danlib/language/gibraltar.png'),
	['Salvador'] = _Material('danlib/language/salvador.png')
}

--- Function to get the icon of a language
-- @param icon: The name of the language for which you want to get an icon.
-- @return: Language icon if found, otherwise returns an error icon.
DLanguage.Icon = function(icon)
	return LanguageIcon[icon] or LanguageIcon[_Material('Error')]
end

--- Retrieves a localized string based on the provided ID.
-- @param id: The identifier for the string to retrieve.
-- @param ...: Additional parameters for string formatting.
-- @return: The localized string, or a default "langmissing" message if not found.
function DBase:L(ID, params)
    local tbl = DTemp[DanLib.CONFIG.BASE.Languages or 'English'] or DTemp['English']
    local String = ((tbl or { })[ID] or DTemp['English'][ID]) or (DTemp['English']['#langmissing'] or '[lang missing]')
    local configTable = (DanLib.CONFIG.BASE.Languages or { })[DanLib.CONFIG.BASE.Languages or 'English']

    if (configTable and configTable[2] and configTable[2][ID]) then
        String = configTable[2][ID]
    end

    -- Replacing variables from params
    if params then
        for key, value in _pairs(params) do
            local safe = _tostring(value):gsub('%%', '%%%%')
            String = String:gsub('{' .. key .. '}', safe)
        end
    end

    return String
end

--- Adds or merges language strings into the specified language key.
-- @param langKey: The key of the language to which strings should be added.
-- @param stringTable: A table of strings to add.
function DBase.RegisterLanguage(langKey, stringTable)
	if (not DTemp[langKey]) then
		DTemp[langKey] = stringTable
	else
		table.Merge(DTemp[langKey], stringTable)
	end
end

local LangFile = 'danlib/languages/'
-- Loads language files from the specified directory.
function DBase.LoadLanguages()
	DanLib.Temp.Languages = DanLib.Temp.Languages or { }
	local files, directories = DFileUtil:Find(LangFile .. '*', 'LUA')

	for k, v in _pairs(directories) do
		for key, val in _pairs(DFileUtil:Find(LangFile .. v .. '/*', 'LUA')) do
			AddCSLuaFile(LangFile .. v .. '/' .. val)
			include(LangFile .. v .. '/' .. val)
		end
	end
end


-- Registry of language contributions keyed by source ID.
-- Key: sourceID (string)  Value: { [langName] = { key = value, ... }, ... }
-- Never cleared — RemoveLanguageExtension sets the entry to nil.
DanLib._languageExtensions = DanLib._languageExtensions or { }

--- Injects language strings from an external addon or removable module.
-- Contributions are stored under sourceID so they can be cleanly removed
-- via DBase.RemoveLanguageExtension without touching other sources' keys.
-- Safe to call at any time — merges immediately into DanLib.Temp.Languages.
-- If the same key is contributed by multiple sources, last call wins
-- (same as table.Merge semantics).
--
-- @param sourceID (string): Unique contributor ID (e.g. 'CHAT_MODULE').
-- @param contributions (table): { [langName] = { key = value, ... }, ... }
--   langName must match the name used in DanLib.Temp.Languages
--   (e.g. 'English', 'Russian') — NOT the language code ('en', 'ru').
--
-- @example
--   DBase.ExtendLanguage('CHAT_MODULE', {
--       ['English'] = { chat_muted = 'You are muted.',  chat_prefix = '[Chat]' },
--       ['Russian'] = { chat_muted = 'Вы замьючены.', chat_prefix = '[Чат]' },
--   })
function DBase.ExtendLanguage(sourceID, contributions)
    _assert(_type(sourceID) == 'string' and #sourceID > 0, 'DanLib.ExtendLanguage — sourceID must be a non-empty string')
    _assert(_type(contributions) == 'table', 'DanLib.ExtendLanguage — contributions must be a table')

    DanLib._languageExtensions[sourceID] = contributions

    for langName, strings in _pairs(contributions) do
        if (not DTemp[langName]) then
            DTemp[langName] = { }
        end
        table.Merge(DTemp[langName], strings)
    end
end

--- Removes all language strings previously registered by the given source.
-- Rebuilds DanLib.Temp.Languages from base files + remaining extensions
-- so keys from other sources are preserved.
-- No-op (silent) if sourceID was never registered.
--
-- @param sourceID (string): Same ID used in DBase.ExtendLanguage.
--
-- @example
--   DBase.RemoveLanguageExtension('CHAT_MODULE')
function DBase.RemoveLanguageExtension(sourceID)
    _assert(_type(sourceID) == 'string' and #sourceID > 0, 'DanLib.RemoveLanguageExtension — sourceID must be a non-empty string')

    if (not DanLib._languageExtensions[sourceID]) then
        return
    end

    DanLib._languageExtensions[sourceID] = nil

    -- Clear DTemp in-place (preserves the local alias set at file load).
    -- Then reload base language files and re-apply remaining extensions.
    for k in _pairs(DTemp) do
        DTemp[k] = nil
    end

    DBase.LoadLanguages()

    for _, langContribs in _pairs(DanLib._languageExtensions) do
        for langName, strings in _pairs(langContribs) do
            if (not DTemp[langName]) then
                DTemp[langName] = { }
            end
            table.Merge(DTemp[langName], strings)
        end
    end
end

--- Returns all language key contributions registered by the given source.
-- Useful for debugging or iterating over what a module contributed.
-- @param sourceID (string): Contributor ID.
-- @return table|nil: The contributions table, or nil if sourceID is not registered.
function DBase.GetLanguageExtension(sourceID)
    return DanLib._languageExtensions[sourceID]
end
