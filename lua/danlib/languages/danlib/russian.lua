/***
 *   @addon         DanLib
 *   @component     Languages Russian
 *   @license       MIT License
 *   @version       1.6.1
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
 


local RUSSIAN = {
    ['#modules'] = 'Модули',
    ['#modules.description'] = 'Отображает все активные модули на сервере.',
    ['#modules.version'] = 'Версия модуля: {version}',

    ['#settings'] = 'Настройки',
    ['#settings.description'] = 'Доступные модули. Настройте конфигурацию по своему вкусу',

    ['#chat.commands'] = 'Команды чата',
    ['#chat.commands.description'] = 'Отображает все команды чата, зарегистрированные DanLib.',

    ['#profile'] = 'Профиль',
    ['#help'] = 'Помощь',

    ['#credits'] = 'Кредиты',
    ['#credits.description'] = 'Здесь перечислены те, кто принимал участие в разработке.',

    ['#permission'] = 'Разрешение',
    ['#permission.description'] = 'Список прав CAMI, которые были зарегистрированы базой или модулями.',

    ['#tutorial'] = 'Учебное пособие',
    ['#tutorial.description'] = '',
    ['#tutorial.reset'] = 'СБРОС TUTORIAL',
    ['#tutorial.reset.description'] = 'Вы действительно хотите сбросить tutorial и начать все сначала?',
    ['#tutorial.welcome'] = '{color: 220, 221, 225}Добро пожаловать{/color:} {color: 0, 151, 230}{player_name}{/color:}{color: 220, 221, 225}!{/color:}',
    ['#tutorial.welcome.page1'] = '{color: 0, 151, 230}Что{/color:} {color: 220, 221, 225}это?{/color:}',
    ['#tutorial.welcome.page2'] = '{color: 220, 221, 225}Каковы{/color:} {color: 239, 211, 52}особенности{/color:}{color: 220, 221, 225}?{/color:}',
    ['#tutorial.welcome.page3'] = '{color: 220, 221, 225}Как{/color:} {color: 154, 205, 50}открыть{/color:} {color: 220, 221, 225}меню?{/color:}',

    ['#basic'] = 'Основные',
    ['#admin.permis'] = 'Права администратора',

    ['#discordlink'] = 'Discord',
    ['#vklink'] = 'VK',
    ['#githublink'] = 'GitHub',
    ['#gotosteam'] = 'Steam',
    ['#websitelink'] = 'Website',
    ['#chatcommand'] = 'Чат команда',
    ['#textfont'] = 'Шрифт текста',

    ['#modules.info'] = 'Информация о модулях',
    ['#info.available.modules'] = 'Информация о доступных модулях',
    ['#sub.modules'] = 'Вспомогательных модулей {modules}',
    ['#version'] = 'Версия: {version}',
    ['#module.version'] = 'Версия модуля: {version}',
    ['#no.data'] = 'Нет данных',

    ['#information.author.updates'] = 'Информация об авторе и доступных обновлениях',
    ['#author'] = 'Автор: {author}',
    ['#about.theautor'] = 'Информация',
    ['#chek.for.updates'] = 'Проверьте наличие обновлений',
    ['#w.new.updata'] = 'Что нового?',
    ['#news'] = 'Новости',
    ['#priority'] = 'Приоритет: %s \nПриоритет означает, насколько важна та или иная новость!',
    ['new#news'] = 'Новое',

    ['#search'] = 'Поиск',
    ['#enabled'] = 'Включено',
    ['#disabled'] = 'Включить',
    ['#selected'] = 'Выбранный',
    ['#unselected'] = 'Выбрать',

    ['#next'] = 'Следующий',
    ['#back'] = 'Назад',

    ['Successfully'] = 'Успешно!',
    ['Attention'] = 'Внимание!',
    ['Mistake'] = 'Ошибка!',
    ['#Mistake'] = 'ОШИБКА',

    ['#She'] = 'Она',
    ['#You'] = 'Ты',
    ['#He'] = 'Он',

    ['Spoiler'] = 'Спойлер',

    ['Yes'] = 'Да',
    ['No'] = 'Нет',
    ['Adopt'] = 'Принять',

    ['#delete'] = 'Удалить',
    ['SelectAddSound'] = 'Выбрать/Добавить звук',
    ['ChooseColor'] = 'Выбрать цвет',

    ['add'] = 'Добавить',
    ['confirm'] = 'Подтвердить',
    ['cancel'] = 'Отмена',
    ['save'] = 'Сохранить',
    ['Saved'] = 'Сохранено',
    ['#open'] = 'Открыть',
    ['#close'] = 'Закрыть',
    ['Next'] = 'Далее',
    ['Minimize/ExtendWindow'] = 'Свернуть/Развернуть окно',
    ['Base#CollapseWindow'] = 'Свернуть окно',
    ['Press#BackMenu'] = 'Нажмите ESC, чтобы снова перейти в меню',

    ['unsavedChanges'] = 'Несохраненные изменения',
    ['PlsRememberSaveChanges'] = 'Пожалуйста, не забудьте сохранить изменения.',

    ['description'] = 'Описание',
    ['version'] = 'Версия',

    ['#configSave'] = 'СОХРАНЕНИЕ КОНФИГУРАЦИИ',
    ['configSaved'] = 'Все изминения были сохранены в config!',

    ['SysDebugMode'] = 'Сервер в режиме отладки систем. Что-то может работать не стабильно!',

    ['#resetting.changes'] = 'Сброс изменений',
    
    ['NewAddTitle'] = 'Чтобы создать, нажмите на кнопку ДОБАВИТЬ',
    ['ClickLearnMore'] = 'Нажмите, чтобы узнать больше',

    -- DISCORD LOGS \\--
    ['#webhook.url'] = 'Webhook URL',
    ['#webhook.url.Description'] = 'Скопируйте URL-адрес вашего веб-хука Discord и вставьте его сюда.',

    ['#deletion'] = 'УДАЛЕНИЕ',
    ['#deletion.description'] = 'Вы действительно уверены, что хотите удалить это?',

    ['#webhook.name'] = 'Имя Webhook',
    ['#webhook.name.description'] = 'Введите имя вашего веб-хука. Это просто идентификатор для webhook.',
    ['#SelectWebhook'] = 'Выберите и отметьте поле, которое будет использоваться этим webhook discord.',

    ['player_join'] = 'Игрок **{player}* [*{steamid}*] ([Профиль](https://steamcommunity.com/profiles/{steamid64}/)) подключается к серверу!',
    ['player_disconnect'] = 'Игрок **{player}** [*{steamid}*] ([Профиль](https://steamcommunity.com/profiles/{steamid64}/)) отключился ({reason})',
    ['save_config'] = 'Игрок **{player}** [*{steamid}*] ([Профиль](https://steamcommunity.com/profiles/{steamid64}/)) изменил конфигурацию. ```lua\n {table} ```',
    
    ['seconds'] = 'seconds',
    ['second'] = 'second',
    ['minutes'] = 'minutes',
    ['minute'] = 'minute',
    ['hours'] = 'hours',
    ['hour'] = 'hour',
    ['days'] = 'days',
    ['day'] = 'day',

    ['#quickSearch'] = 'Для быстрого поиска используйте строку ввода',

    ['Preview#'] = 'Предварительный просмотр',
    ['Undefined'] = 'Неопределенный',

    ['Warning'] = 'Предупреждение',
    ['#Warning'] = 'ПРЕДУПРЕЖДЕНИЕ',

    ['general'] = 'Основное',
    ['followthelink'] = 'Перейти по ссылке',
    ['comingSoon'] = 'Скоро!',

    ['#interface'] = 'Интерфейс',
    ['#nlstrings'] = 'Отсутствует "{number}" языковых строк',

    ['presetBackgrounds'] = 'Готовые варианты',

    ['#copy'] = 'Копировать',
    ['#command.copy'] = 'Команда {cmd} скопирована!',
    ['#copy_name'] = 'Копировать имя',
    ['#copy_id'] = 'Копировать ID',

    ['colwinelem'] = 'Цвет окон и элементов',
    ['colorbackg'] = 'Цвет фона',
    ['panelcolor'] = 'Цвет панелей',
    ['coldecorelem'] = 'Цвет декоративных элементов (материалы, кнопка закрытия и т.д)',
    ['coldecorelems'] = 'Цвет для декоративных элементов (полосы, разделители и тп)',
    ['colorbutton'] = 'Цвет кнопок',

    ['languages'] = 'Языки',

    ['#admin'] = 'Администратор',
    ['#admin.groups'] = '{admin} Группы администраторов',
    ['#admin.online'] = 'Администратор(ы) онлайн ({admins})',

    ['players'] = 'Игроки',

    ['create'] = 'Создать',
    ['createNew'] = 'Создать новый',
    ['createNewLang'] = 'Создать новый язык.',

    ['#notTool'] = 'У вас нет прав на использование этого инструмента!',

    ['SelectlangStredit'] = 'Выберите одну из языковых строк для редактирования',

    ['#edit'] = 'Редактировать',
    ['editlangStrings'] = 'Редактировать языковые строки',
    ['editUserGroups'] = 'Редактировать Групп пользователей',
    ['editColor'] = 'Редактировать цвет',
    ['editName'] = 'Редактировать имя',
    ['#edit.name'] = 'Редактировать имя',
    ['#edit.rank'] = 'Редактировать ранг',

    ['#access.denied'] = 'ДОСТУП ЗАПРЕЩЕН',
    ['#access.ver'] = 'Извините, но у вас нет надлежащего доступа для выполнения этой команды!',
    ['#wrong.arg'] = 'Неверный аргумент!',
    
    ['#user.group.editor'] = 'Редактор групп пользователей',
    ['#new.user.group'] = 'Какой должна быть новая группа пользователей?',

    ['#key.bind'] = 'НАЖМИТЕ КЛАВИШУ',
    ['#key.bind.none'] = 'НЕТ',
    ['#key.bind.help'] = 'Нажмите клавишу или нажмите ESC, чтобы сбросить',
    ['#key.bind.forbidden'] = 'ПРИВЯЗКА ЗАПРЕЩЕНА',
    ['#key.bind.binding'] = 'Этот ключ нельзя использовать для привязки!',

    -- RANK
    ['#rank.limit'] = 'Вы достигли предела ранга «{limit}»!',
    ['#rank.new'] = 'Как должен называться этот «Ранг»?',
    ['#rank.name.exists'] = 'Ранг с таким именем уже существует!',
    ['#rank.name'] = 'Введите имя ранга.',
    ['#rank.changed'] = 'Ваш ранг был изменен ',
    ['#rank.log.changed'] = 'Изменение ранга:',
    ['#rank.list'] = 'Список рангов',
    ['#select.assign.rank'] = 'Выберите, чтобы присвоить ранг.',
    ['#rank.copy.name'] = 'Копировать имя ранга',
    ['#rank.copy.id'] = 'Копировать ID ранга',
    ['#rank.no.owner'] = 'На сервере нет владельца. Из-за этого DanLib не может быть настроен и невозможно предоставить права доступа другим игрокам. Чтобы стать владельцем сервера, нажмите на это сообщение.',

    ['#owner.setup'] = 'Права собственника',
    ['#owner.setup.description'] = 'Владелец является администратором с полным доступом к DanLib. Он отвечает за настройку модулей и распределение рангов, создавая комфортную атмосферу для игроков. Его цель - сделать игровой процесс увлекательным и способствовать активному взаимодействию. Наслаждайтесь игрой!',

    ['#view.receive'] = 'Посмотрите на сущность, чтобы получить модель!',
    ['model:'] = 'Модель: ',
    ['#model.retrieved'] = ' получена и скопирована в буфер обмена.',

    ['#update.needed'] = 'Необходимо обновление!',
    ['#versions.cache'] = 'Проверяем наличие обновлений...',
    ['#modules.no.inf'] = 'Нет информации!',
    ['#latest.version'] = 'Последняя версия!',
    ['#new.version'] = 'Новая версия "{version}"',

    ['#update.version'] = 'Для "{addon}" доступна новая версия аддона! Пожалуйста, обновите до новой версии! Ваша версия "{old_version}".',
    ['#no.update.version'] = 'На данный момент для "{addon}" обновление не требуется. У вас установлена последняя версия "{new_version}"',

    ['#toggle'] = 'Тумблер',

    ['#debugging.window.screen'] = 'Это всплывающее окно отладки на экране!',
    ['#no.information.available'] = 'Информация отсутствует',

    ['#thank.you.much'] = 'Большое вам спасибо!',
    ['#langmissing'] = 'Язык отсутствует!',
    ['#loading.languages'] = 'Загрузка языков модулей: ',

    ['#copied.clipboard'] = 'Скопировано в буфер обмена!',
    
    ['#langpage'] = 'Редактор языков',
    ['#langpage.description'] = 'Просмотр, редактирование и экспорт переводов для всех зарегистрированных языков.',
    ['#langpage.select'] = 'Выберите язык',
    ['#langpage.pick'] = 'Выберите язык из панели слева, чтобы начать редактирование.',
    ['#langpage.export'] = 'Экспорт в файл',
    ['#langpage.search'] = 'Поиск ключей...',
    ['#langpage.col.english'] = 'English (эталон)',
    ['#langpage.col.translation'] = 'Перевод',
    ['#langpage.autotranslate'] = 'Автоперевод',
    ['#langpage.autotranslate.pick'] = 'Выберите код языка для автоперевода.',
    ['#langpage.autotranslate.warning'] = 'Google Translate может блокировать IP сервера. Это экспериментально. Продолжить?',
    ['#langpage.exported'] = 'Экспортировано! Файл: %s',
    ['#langpage.wait'] = 'Перевод в процессе — подождите.',
    ['#langpage.done'] = 'Перевод завершён!',
    ['#langpage.error'] = 'Ошибка перевода.',
    ['#langpage.blocked'] = 'IP сервера может быть заблокирован Google. Попробуйте позже.',
    ['#langpage.nothing'] = 'Все ключи уже переведены.',
    ['#langpage.noresults'] = 'Ни один ключ не совпадает с фильтром.',


    -- ['setup.description'] = '{font: danlib_font_18}{color: white} Настройки {color: green} успешно {color: Color(0, 255, 0)} сохранены. Успех на {color: Color(0, 0, 255)} {percent}{color: Color(255, 255, 255)}!'
}
DanLib.Func.RegisterLanguage('Russian', RUSSIAN)