# Zephyr

Quality-of-life clicks for World of Warcraft Classic. Zephyr takes the obvious action: loot, sell junk, repair, open mail, accept and turn in quests, and a few combat and travel confirms.

Most options start on. Hold **Shift** to skip the current window.

Tested on Classic Beta (`Interface 16001`).

- [CurseForge](https://www.curseforge.com/wow/addons/zephyr)
- [GitHub](https://github.com/Ofer-Aharonson/Zephyr)

## Features

- **Faster autoloot** — takes loot as soon as a corpse or chest opens
- **Sell junk** — sells coin-marked junk at a merchant
- **Repair** — repairs your gear with your own gold
- **Mark always-sell** — puts a coin on items you added to the always-sell list
- **Open mail** — takes gold and attachments; leaves COD mail
- **Quests** — accepts and turns in quests; leaves multi-item rewards
- **Single gossip** — clicks the only chat option, such as an inn or binder
- **Release in PvP** — releases your spirit in battlegrounds; keeps soulstones
- **Accept resurrections** — accepts a res outside battlegrounds
- **Skip combat res** — ignores a res from someone who is in combat
- **Skip cinematics** — stops in-game movies and talking-head popups
- **Dismount and stand** — gets you off a mount or on your feet when the game asks
- **Confirm grey deletes** — clicks OK when you destroy a poor-quality item

## Settings

Open **Options → AddOns → Zephyr**, or type `/zephyr settings`.

Each option has a short summary next to the checkbox.

## Commands

```
/zephyr
/zephyr settings
/zephyr loot|sell|repair|mail|quest|gossip|release|rez|cinematic|stand|delete
/zephyr debug|marks|lists
/zephyr keep [link|id]
/zephyr unkeep [link|id]
/zephyr sellitem [link|id]
/zephyr unsell [link|id]
```

Keep and always-sell lists are per character.

## Install

1. Copy the `Zephyr` folder into `World of Warcraft\_classic_beta_\Interface\AddOns`.
2. Restart the game or type `/reload`.
3. Confirm Zephyr is enabled on the character-select addon list.

The folder name must be `Zephyr`, and it must contain `Zephyr.toc`.

## License

MIT. See [LICENSE](LICENSE).

World of Warcraft and related marks are trademarks of Blizzard Entertainment.
