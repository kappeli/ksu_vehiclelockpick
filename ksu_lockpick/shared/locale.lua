Locales = {}

local function loadLocale(locale)
    local selected = Locales[locale]
    if selected then
        return selected
    end

    return Locales.en or {}
end

function Lang(key, ...)
    local locale = loadLocale(Config.Locale)
    local text = locale[key] or key

    if select('#', ...) > 0 then
        return text:format(...)
    end

    return text
end
