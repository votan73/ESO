local strings = {
    SI_HARVEN_CMP_EDIT_PIN = "Редактировать",
    SI_HARVEN_CMP_SHOW_IN_POPUP = "Открыть в окне",
    SI_HARVEN_CMP_SHARE_PIN = "Отправить в чат",
    SI_HARVEN_CMP_DELETE_PIN = "Удалить",
    SI_HARVEN_CMP_PLACE_CUSTOM_PIN = "Поставить метку",
    SI_HARVEN_CMP_NO_IMPORT_SECTION = "Отсутствует раздел импорта в файле SavedVariable-Data. Выйдите из системы и убедитесь, что раздел существует.",
    SI_HARVEN_CMP_PIN_MALFORMED = "Метка '<<1>>' видимо вызывает ошибки, игнорируем",
    SI_HARVEN_CMP_IMPORTED_PIN = "Импортирована метка '<<1>>' на карте '<<2>>' положение <<3>>, <<4>>",
    SI_HARVEN_CMP_PIN_ALREADY_PRESENT = "В этом месте уже имеется метка: <<1>>, <<2>> <<3>>",
    SI_HARVEN_CMP_IMPORT_COMPLETED = "Импорт завершен!",
    SI_HARVEN_CMP_PIN_SIZE = "Рзмер метки",
    SI_HARVEN_CMP_PIN_DRAW_LEVEL = "Уровень слоя метки",
    SI_HARVEN_CMP_PIN_DRAW_LEVEL_TOOLTIP = "Чем выше число, тем выше уровень слоя метки.",
    SI_HARVEN_CMP_SPREAD_PIN_RENDERING = "Распределенный рендеринг",
    SI_HARVEN_CMP_SPREAD_PIN_RENDERING_TOOLTIP = "Распределение рендеринга с течением времени для уменьшения нагрузки на CPU",
    SI_HARVEN_CMP_ALLOW_PIN_SUB_FILTER = "Разрешить подфильтры меток",
    SI_HARVEN_CMP_ALLOW_PIN_SUB_FILTER_TOOLTIP = "Разрешить отображение/скрытие предварительных определений (Вкладка фильтров карты). UI будет перезапущен!",
    SI_HARVEN_CMP_ENTER_PIN_DESCRIPTION = "Описание:",
    SI_HARVEN_CMP_TITLE_REPLACE = "Метка (Замена)",
    SI_HARVEN_CMP_TITLE_EDIT = "Метка (Редактирование)",
    SI_HARVEN_CMP_TITLE_NEW = "Метка (Создание)",
    SI_HARVEN_CMP_ADVANCED_OPTIONS = "Расширенные настройки",
    SI_HARVEN_CMP_SELECT_ICON = "Иконка:",
    SI_HARVEN_CMP_SELECT_COLOR = "Цвет:",
    SI_HARVEN_CMP_APPLY_PREDEFINED = "Группа меток:",
    SI_HARVEN_CMP_PREDEFINED_NAME = "Новая группа:"
}

for stringId, stringValue in pairs(strings) do
	SafeAddString(_G[stringId], stringValue, 2)
end