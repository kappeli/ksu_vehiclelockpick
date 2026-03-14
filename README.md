# ksu_lockpick

Vehicle lockpicking for locked cars with `ox_target` and `t3_lockpick`.

## Features

- ESX by default
- Switch to QBCore in `config.lua`
- Driver door interaction with `ox_target`
- Uses `t3_lockpick` minigame export

## Dependencies

- `ox_target`
- `t3_lockpick`
- `es_extended` or `qb-core`
- Any supported inventory or framework default inventory

## Supported inventories

- `ox_inventory`
- `qb-inventory`
- `qs-inventory`
- `lj-inventory`
- `ps-inventory`
- `codem-inventory`
- `core_inventory`
- ESX default inventory
- QBCore default inventory

## Installation

1. Put the folder into your resources.
2. Ensure the dependencies are started before this script.
3. Add `start ksu_lockpick` to your server config.

## Config

```lua
Config.Framework = 'esx'
Config.Inventory = 'auto'
Config.Locale = 'en'
Config.RequiredItem = 'lockpick'
Config.RemoveItemOnFail = true
Config.RemoveItemChance = 100

Config.Lockpick = {
    item = nil,
    difficulty = 2,
    pins = 4
}
```

## Item examples

### ox_inventory

```lua
['lockpick'] = {
    label = 'Lockpick',
    weight = 100,
    stack = true,
    close = true,
    description = 'Used for opening locked vehicles.'
}
```

### QBCore shared items

```lua
lockpick = {
    name = 'lockpick',
    label = 'Lockpick',
    weight = 100,
    type = 'item',
    image = 'lockpick.png',
    unique = false,
    useable = false,
    shouldClose = true,
    description = 'Used for opening locked vehicles.'
}
```

### ESX items SQL example

```sql
INSERT INTO items (name, label, weight) VALUES ('lockpick', 'Lockpick', 1);
```
