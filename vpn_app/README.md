# VPN App — Flutter Android

BLOOK-style VPN клиент на Xray Core (flutter_v2ray).

## Структура проекта

```
lib/
  main.dart                        # Точка входа
  models/server.dart               # Модель сервера + парсинг URL
  services/
    subscription_service.dart      # Загрузка подписки (base64 / plain text)
    ping_service.dart              # Измерение пинга (TCP)
  providers/vpn_provider.dart      # Вся логика — состояние, подключение
  screens/
    home_screen.dart               # Главный экран
    settings_screen.dart           # Настройки
  theme/app_theme.dart             # Тёмная тема
```

## Категории серверов

Категория определяется автоматически по имени сервера (remark) в подписке:

| Паттерн в имени | Категория      | Назначение                        |
|-----------------|----------------|-----------------------------------|
| содержит `WL`   | Белый список   | Серверы для обхода блокировок РКН |
| содержит `RR`   | Резервные      | Фоллбэк при недоступности основных|
| остальные       | Основные       | Основной VPN трафик               |

**Примеры имён:**
- `RUWL 1, LEDWL` → Белый список (Россия, Санкт-Петербург)
- `NL 6, AMS` → Основные (Нидерланды, Амстердам)
- `SERR 1, ARNRR` → Резервные (Швеция, Стокгольм)

## Быстрый старт

### 1. Установи зависимости

```bash
flutter pub get
```

### 2. Android настройки

Замени содержимое `android/app/src/main/AndroidManifest.xml` содержимым из
файла `android_manifest_example.xml` (или добавь недостающие разрешения).

### 3. Минимальная версия Android SDK

В `android/app/build.gradle` убедись что:

```gradle
android {
    defaultConfig {
        minSdk 21   // минимум для flutter_v2ray
    }
}
```

### 4. Запуск

```bash
flutter run
```

### 5. Формат подписки

Приложение принимает стандартный формат v2ray подписки:
- URL → HTTP GET → base64 encoded список ссылок
- Каждая строка: `vless://...`, `vmess://...`, `trojan://...`, `ss://...`
- Remark задаётся после `#` в URL (URL-encoded)

## Зависимости

```yaml
flutter_v2ray: ^1.2.0   # Xray Core wrapper
provider: ^6.1.1         # State management
http: ^1.2.0             # HTTP запросы
shared_preferences: ^2.2.3  # Сохранение настроек
```

## Кастомизация

- **Название приложения**: измени `title` в `main.dart` и `android:label` в AndroidManifest
- **Цвет акцента**: измени `AppTheme.accent` в `lib/theme/app_theme.dart`
- **Логотип**: замени текст `VPN` в `_Header` в `home_screen.dart`
- **Новые страны/города**: добавь в словари `_countryNames` / `_cityNames` в `server.dart`

## Известные ограничения

- Только Android (flutter_v2ray пока не поддерживает iOS)
- Split tunneling не включён (весь трафик через VPN)
- Пинг измеряется по TCP handshake, а не ICMP
