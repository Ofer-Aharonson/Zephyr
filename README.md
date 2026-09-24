# Zephyr

Quality-of-life clicks for World of Warcraft Classic. Zephyr takes the obvious action: loot, sell junk, repair, open mail, hand in a finished quest, and a few combat and travel confirms.

Most options start on. Hold **Shift** to skip the current window.

Tested on Classic Beta (`Interface 16001`).

## Features

- **Faster autoloot** — takes coin, quest items, and free loot that fits. Shift and a locked roll leave the window up
- **Sell junk** — sells coin-marked junk at a merchant
- **Repair** — repairs your gear with your own gold
- **Mark always-sell** — puts a coin on items you added to the always-sell list
- **Open mail** — takes gold and attachments; leaves COD mail
- **Quests** — hands in a finished quest, including one reward. A new quest or a party-shared quest stays on screen
- **Single gossip** — clicks a lone vendor, binder, flight master, trainer, bank, or inn. A story line stays up. A flight master opens the map and does not pick the destination
- **Release in PvP** — releases your spirit in battlegrounds; keeps soulstones
- **Accept resurrections** — accepts a res outside battlegrounds
- **Skip combat res** — ignores a res from someone who is in combat
- **Skip cinematics** — starts off for a new character. Stops in-game movies and talking-head popups. Shift leaves a talking head up
- **Dismount and stand** — stands when loot, a flight, or an interact was refused. Camp rest keeps you seated
- **Confirm grey deletes** — clicks OK when you destroy a poor-quality item

## Settings

Open **Options → AddOns → Zephyr**, or type `/zephyr settings`.

The options screen is the door. The page inside is a ledger on quest parchment. Each option has a short summary next to the checkbox. Keep and sell lists are item links on that page: drop an item to add it, right-click a link to remove it.

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

## CurseForge listing copy

**Summary**

Fast loot, vendors, mail, quests, and other obvious-click quality of life. Hold Shift to skip.

**Description**

Zephyr clicks the obvious button so you do not have to.

It loots coin, quest items, and free loot that fits, sells junk, and repairs with your own coin, opens mail (COD is left alone), hands in a finished quest (a new quest stays on screen), and clicks a lone vendor, binder, flight master, trainer, bank, or inn.

It can also release in battlegrounds, accept resurrections, skip combat resurrections, skip cinematics, dismount or stand when the game requires it, and confirm poor-quality item deletes.

Most options start on. Hold Shift to skip the current window. Toggle anything from Options → AddOns → Zephyr, or with `/zephyr`.

Always-sell and never-sell lists:

- `/zephyr sellitem [link or id]`
- `/zephyr keep [link or id]`

This project is not affiliated with Blizzard Entertainment.

## License

MIT. See [LICENSE](LICENSE).

World of Warcraft and related marks are trademarks of Blizzard Entertainment.
