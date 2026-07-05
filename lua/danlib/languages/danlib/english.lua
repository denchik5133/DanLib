/***
 *   @addon         DanLib
 *   @component     Languages English
 *   @license       MIT License
 *   @version       1.6.5
 *   @release_date  10/04/2023
 *   @author        denchik, CastleKeeper
 *
 *   @contact       
 *                  Discord: denchik_gm
 *                  Steam: https://steamcommunity.com/profiles/76561198405398290/
 *                  GitHub: https://github.com/denchik5133
 *                
 *   @description   Universal library for GMod Lua, combining all the necessary features to simplify script development. 
 *                  Avoid code duplication and speed up the creation process with this powerful and convenient library.
 *
 *   @part_of       DanLib v3.0.0 and higher
 *                  https://github.com/denchik5133/danlib
 *
 *   @notes         For feature requests or contributions, please open an issue on GitHub.
 */
 


local ENGLISH = {
    ['#modules'] = 'Modules',
    ['#modules.description'] = 'Displays all active modules on the server.',
    ['#modules.version'] = 'Module version: {version}',

    ['#settings'] = 'Settings',
    ['#settings.description'] = 'Available modules. Customize the configuration to your liking',

    ['#chat.commands'] = 'Chat Commands',
    ['#chat.commands.description'] = 'Displays all chat commands registered by DanLib.',

    ['#profile'] = 'Profile',
    ['#help'] = 'Help',

    ['#credits'] = 'Credits',
    ['#credits.description'] = 'Those who participated in the development are listed here.',

    ['#permission'] = 'Permission',
    ['#permission.description'] = 'List of CAMI rights that have been registered by the base or modules.',

    ['#tutorial'] = 'Tutorial',
    ['#tutorial.description'] = '',
    ['#tutorial.reset'] = 'RESET TUTORIAL',
    ['#tutorial.reset.description'] = 'Do you really want to reset the tutorial and start over?',
    ['#tutorial.welcome'] = '{color: 220, 221, 225}Welcome{/color:} {color: 0, 151, 230}{player_name}{/color:}{color: 220, 221, 225}!{/color:}',
    ['#tutorial.welcome.page1'] = '{color: 0, 151, 230}What{/color:} {color: 220, 221, 225}is this?{/color:}',
    ['#tutorial.welcome.page2'] = '{color: 220, 221, 225}What are the{/color:} {color: 239, 211, 52}peculiarities{/color:}{color: 220, 221, 225}?{/color:}',
    ['#tutorial.welcome.page3'] = '{color: 220, 221, 225}How do I{/color:} {color: 154, 205, 50}open{/color:} {color: 220, 221, 225}the menu?{/color:}',

    ['#basic'] = 'Basic',
    ['#admin.permis'] = 'Admin Permissions',

    ['#discordlink'] = 'Discord',
    ['#githublink'] = 'GitHub',
    ['#websitelink'] = 'Website',
    ['#gotosteam'] = 'Steam',
    ['#vklink'] = 'VK',
    ['#chatcommand'] = 'Chat Command',
    ['#textfont'] = 'Text font',
    
    ['#modules.info'] = 'Modules information',
    ['#info.available.modules'] = 'Information about available modules',
    ['#sub.modules'] = 'Sub Modules {modules}',
    ['#version'] = 'Version: {version}',
    ['#module.version'] = 'Module version: {version}',
    ['#no.data'] = 'No data',

    ['#information.author.updates'] = 'Information about the author and available updates',
    ['#author'] = 'Author: {author}',
    ['#about.theautor'] = 'Information',
    ['#chek.for.updates'] = 'Chel for update',
    ['#w.new.updata'] = "What's new?",
    ['#news'] = 'News',
    ['#priority'] = 'Priority: %s \nPriority means how important this or that news is!',
    ['new#news'] = 'New',

    ['#search'] = 'Search',
    ['#enabled'] = 'Enabled',
    ['#disabled'] = 'Disabled',
    ['#selected'] = 'Selected',
    ['#unselected'] = 'Choose',

    ['#next'] = 'Next',
    ['#back'] = 'Back',

    ['Yes'] = 'Yes',
    ['No'] = 'No',
    ['Adopt'] = 'Adopt',

    ['#delete'] = 'Delete',
    ['SelectAddSound'] = 'Select/Add Sound',
    ['ChooseColor'] = 'Choose a color',

    ['Successfully'] = 'Successfully!',
    ['Attention'] = 'Attention!',
    ['Mistake'] = 'Mistake!',
    ['#Mistake'] = 'MISTAKE',

    ['#She'] = 'She',
    ['#You'] = 'You',
    ['#He'] = 'He',

    ['Spoiler'] = 'Spoiler',

    ['add'] = 'Add',
    ['confirm'] = 'Confirm',
    ['cancel'] = 'Cancel',
    ['save'] = 'Save',
    ['Saved'] = 'Saved',
    ['#open'] = 'Open',
    ['#close'] = 'Close',
    ['Next'] = 'Next',
    ['Minimize/ExtendWindow'] = 'Minimize/expand the window',
    ['Base#CollapseWindow'] = 'Collapse Window',
    ['Press#BackMenu'] = 'Press ESC to go back to the menu',

    ['unsavedChanges'] = 'Unsaved changes',
    ['PlsRememberSaveChanges'] = 'Please remember to save your changes.',

    ['description'] = 'Description',
    ['version'] = 'Version',

    ['#config.saved'] = 'CONFIG SAVE',
    ['#config.all.saved'] = 'All changes have been saved in config!',
    ['#config.save.success'] = 'Configuration saved successfully!\n\nModules saved: {score}\nVariables changed: {score2}\n\nChanges have been applied and broadcasted to all players.',
    ['#config.save.success.simple'] = 'Successfully saved %d module(s)',
    ['#config.save.failed.simple'] = 'Failed to save %s: %s',
    ['#config.save.failed'] = 'Save Failed',
    ['#config.save.rollback'] = 'Configuration save failed!\n\nFailed Module: {module}\nError: {record}\n\nSuccessfully wrote: {writes}/{received} modules\nChanges rolled back: {score} variables\n\nAll changes have been reverted to previous state.',

    -- Debug messages
    ['#config.debug.validator.registered'] = 'Registered validator for {module}.{variable}',
    ['#config.debug.validator.unknown'] = 'Unknown variable: {module}.{variable}',
    ['#config.debug.validator.failed'] = 'Validation failed for {module}.{variable}: {errorMsg}',

    ['#config.debug.file.serialize.failed'] = 'Failed to serialize config data for module: {moduleKey}',
    ['#config.debug.file.write.failed'] = 'File write failed for module: {moduleKey}',
    ['#config.debug.file.verify.failed'] = 'File write verification failed for module: {moduleKey}',
    ['#config.debug.file.write.success'] = 'Successfully wrote config file: {moduleKey}',

    ['#config.debug.dir.created'] = 'Created config directory',
    ['#config.debug.change.log'] = '[{time}] {name} ({id}) changed {module}.{variable}: {old} → (new)',

    ['#config.debug.network.update.sent'] = 'Sent config update to {players} player(s)',
    ['#config.debug.network.send.invalid'] = 'Attempted to send config to invalid player',
    ['#config.debug.network.complete.sent'] = 'Sent complete config to {name}',

    ['#config.debug.save.invalid.player'] = 'Invalid player in HandleConfigSave',
    ['#config.debug.save.no.permission'] = '{name} attempted to save config without permission',
    ['#config.debug.save.initiated'] = '{name} initiated config save',
    ['#config.debug.save.receiving'] = 'Receiving {score} module(s) from {name}',
    ['#config.debug.save.invalid.module'] = '{name} tried to save invalid module: {key}',
    ['#config.debug.save.backup.created'] = 'Created config backup for transaction',

    ['#config.error.module.notfound'] = 'Module "{key}" does not exist in configuration',

    ['#config.error.value.invalid'] = 'Invalid value for "{key}.{variable}"\n\nReason: {validation}\n\nValue: {value}\nType: {type}',
    ['#config.error.variable.notfound'] = 'Variable "{key}.{variable}" does not exist.\n\nModule: {key2}\nVariable: {variable2}\n\nPlease check your configuration metadata.',
    ['#config.error.validation.unknown'] = 'Unknown validation error',

    ['#config.debug.save.changes.applied'] = 'Applied {score} changes to memory',
    ['#config.debug.save.rollback'] = 'ROLLBACK: {name} - Module: {module}, Error: {record}, Rolled back {score} changes',
    ['#config.debug.save.success'] = '{name} successfully saved {score} module(s) with {score2} total changes',

    -- Error messages - File operations
    ['#config.error.unknown'] = 'Unknown error',

    ['SysDebugMode'] = 'The server is in system debugging mode. Something may be unstable!',

    ['#resetting.changes'] = 'Resetting changes',

    ['NewAddTitle'] = 'To create one, click on the ADD button.',
    ['ClickLearnMore'] = 'Click to learn more',

    --// DISCORD LOGS \\--
    ['#webhook.url'] = 'Webhook URL',
    ['#webhook.url.Description'] = 'Copy the URL of your Discord webhook and paste it here.',

    ['#deletion'] = 'DELETION',
    ['#deletion.description'] = 'Are you really sure you want to delete this?',

    ['#webhook.name'] = 'Name Webhook',
    ['#webhook.name.description'] = 'Enter the name of your webhook. This is simply an identifier for the webhook.',
    ['#SelectWebhook'] = 'Select and check the box to be used by this discord webhook.',

    ['player_join'] = 'Player **{player}** [*{steamid}*] ([Profile](https://steamcommunity.com/profiles/{steamid64}/)) is connecting to the server!',
    ['player_disconnect'] = 'Player **{player}** [*{steamid}*] ([Profile](https://steamcommunity.com/profiles/{steamid64}/)) disconnected ({reason})',
    ['save_config'] = 'Player **{player}** [*{steamid}*] ([Profile](https://steamcommunity.com/profiles/{steamid64}/)) changed the config. ```lua\n {table} ```',
    
    ['seconds'] = 'seconds',
    ['second'] = 'second',
    ['minutes'] = 'minutes',
    ['minute'] = 'minute',
    ['hours'] = 'hours',
    ['hour'] = 'hour',
    ['days'] = 'days',
    ['day'] = 'days',

    ['#quickSearch'] = 'For a quick search use the input line',

    ['Preview#'] = 'Preview',
    ['Undefined'] = 'Undefined',

    ['Warning'] = 'Warning',
    ['#Warning'] = 'WARNING',
    
    ['general'] = 'General',
    ['followthelink'] = 'Follow the link',
    ['comingSoon'] = 'Soon!',

    ['#interface'] = 'Interface',
    ['#nlstrings'] = 'Missing "{number}" language strings',

    ['presetBackgrounds'] = 'Ready-made options',

    ['#copy'] = 'Copy',
    ['#command.copy'] = 'Command {cmd} copied!',
    ['#copy_name'] = 'Copy name',
    ['#copy_id'] = 'Copy ID',

    ['colwinelem'] = 'Color of windows and elements',
    ['colorbackg'] = 'Background color',
    ['panelcolor'] = 'Panel Color',
    ['coldecorelem'] = 'Color for decorative elements (materials, closure button, etc)',
    ['coldecorelems'] = 'Color for decorative elements (stripes, dividers, etc)',
    ['colorbutton'] = 'Button color',

    ['languages'] = 'Languages',

    ['#admin'] = 'Admin',
    ['#admin.groups'] = '{admin} Admin Groups',
    ['#admin.online'] = 'Admin(s) online ({admins})',

    ['players'] = 'Players',

    ['create'] = 'Create',
    ['createNew'] = 'Create New',
    ['createNewLang'] = 'Create a new language.',

    ['#notTool'] = 'You do not have the rights to use this tool!',

    ['SelectlangStredit'] = 'Select one of the language strings to edit',

    ['#edit'] = 'Edit',
    ['editlangStrings'] = 'Edit language strings',
    ['editUserGroups'] = 'Edit User Groups',
    ['editColor'] = 'Edit Color',
    ['editName'] = 'Edit Name',
    ['#edit.name'] = 'Edit name',
    ['#edit.rank'] = 'Edit rank',

    ['#access.denied'] = 'ACCESS DENIED',
    ['#access.ver'] = "Sorry, but you don't have proper access to execute this command!",
    ['#wrong.arg'] = 'Wrong argument!',

    ['#user.group.editor'] = 'User Group Editor',
    ['#new.user.group'] = 'What should new user group be?',

    ['#key.bind'] = 'PRESS A KEY',
    ['#key.bind.none'] = 'NONE',
    ['#key.bind.help'] = 'Press the key or press ESC to reset',
    ['#key.bind.forbidden'] = 'TETHERING IS PROHIBITED',
    ['#key.bind.binding'] = 'This key cannot be used for binding!',

    -- RANK
    ['#rank.limit'] = 'You have reached the rank limit of «{limit}»!',
    ['#rank.new'] = 'What should this "Rank" be called?',
    ['#rank.name.exists'] = 'A rank with that name already exists!',
    ['#rank.name'] = 'Enter the name of the rank.',
    ['#rank.changed'] = 'Your "rank" has been changed ',
    ['#rank.log.changed'] = 'Rank Change:',
    ['#rank.list'] = 'Ranks list',
    ['#select.assign.rank'] = 'Select to assign a rank.',
    ['#rank.copy.name'] = 'Copy rank name',
    ['#rank.copy.id'] = 'Copy rank ID',
    ['#rank.no.owner'] = 'There is no owner on the server. Because of this DanLib cannot be configured and it is not possible to grant access rights to other players. To become the owner of the server, click on this message.',

    ['#owner.setup'] = "Owner's rights",
    ['#owner.setup.description'] = 'The owner is an administrator with full access to DanLib. He is responsible for setting up modules and rank distribution, thus creating a comfortable atmosphere for the players. His goal is to make the gameplay fun and promote active interaction. Enjoy the game!',

    ['#view.receive'] = 'Look at the entity to get the model!',
    ['model:'] = 'Model: ',
    ['#model.retrieved'] = ' is retrieved and copied to the clipboard.', 

    ['#update.needed'] = 'An update is needed!',
    ['#versions.cache'] = 'Checking for updates...',
    ['#modules.no.inf'] = 'No information available!',
    ['#latest.version'] = 'Latest version!',
    ['#new.version'] = 'New version "{version}"',

    ['UpdateVersion'] = 'A new version of the addon is available for "{addon}"! Please upgrade to the new version! Your version is "{old_version}".',
    ['NoUpdateVersion'] = 'At the moment, no update is required for "{addon}". You have the latest version of "{new_version}" installed',

    ['#toggle'] = 'Toggle',

    ['#debugging.window.screen'] = "It's a pop-up debugging window on the screen!",
    ['#no.information.available'] = 'No information available',

    ['#thank.you.much'] = 'Thank you so much!',
    ['#langmissing'] = 'The language is missing!',
    ['#loading.languages'] = 'Loading module languages: ',

    ['#copied.clipboard'] = 'Copied to the clipboard!',
    ['#copyright'] = 'Copyright (c) %s denchik',
    
    ['#langpage'] = 'Language Editor',
    ['#langpage.description'] = 'View, edit and export translations for all registered languages.',
    ['#langpage.select'] = 'Select language',
    ['#langpage.pick'] = 'Pick a language from the sidebar to start editing.',
    ['#langpage.export'] = 'Export to file',
    ['#langpage.search'] = 'Search keys...',
    ['#langpage.col.english'] = 'English (reference)',
    ['#langpage.col.translation'] = 'Translation',
    ['#langpage.autotranslate'] = 'Auto-translate',
    ['#langpage.autotranslate.pick'] = 'Select a target language code for auto-translation.',
    ['#langpage.autotranslate.warning'] = 'Google Translate may block server IPs. This is experimental and may stop mid-way. Continue?',
    ['#langpage.exported'] = 'Exported! File: %s',
    ['#langpage.wait'] = 'Translation in progress — please wait.',
    ['#langpage.done'] = 'Translation complete!',
    ['#langpage.error'] = 'Translation failed.',
    ['#langpage.blocked'] = 'Server IP may be blocked by Google. Try again later.',
    ['#langpage.nothing'] = 'All keys are already translated.',
    ['#langpage.noresults'] = 'No keys match the search filter.',

}
DanLib.Func.RegisterLanguage('English', ENGLISH)