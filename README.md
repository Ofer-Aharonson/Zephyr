# Zephyr

Quality-of-life clicks for World of Warcraft: Forever. Zephyr takes the click you were already going to make.

Most options start on.

Tested on Classic Beta (`Interface 16001`).

## Features

- **Faster autoloot** — takes coin, quest items, and free loot that fits. Shift and a locked roll leave the window up
- **Sell junk** — sells coin-marked junk at a merchant
- **Repair** — repairs your gear with your own gold
- **Mark always-sell** — puts a coin on items you added to the always-sell list
- **Open mail** — takes gold and attachments; leaves COD mail
- **Quests** — hands in a finished quest, including one reward. A new quest or a party-shared quest stays on screen
- **Single gossip** — clicks a lone vendor, binder, flight master, trainer, bank, or inn. A story line stays up. A flight master opens the map and does not pick the destination
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
/zephyr loot|sell|repair|mail|quest|gossip|cinematic|stand|delete
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

Fast loot, vendors, mail, quests, and other obvious-click quality of life.

**Description**

Zephyr takes the obvious click and leaves the real choices up.

What it does

- Finished quests turn in, including a single reward. New quests stay up. That was the whole idea.
- A turn-in that costs gold stays up. Your last copper stays yours.
- A lone vendor, binder, trainer, bank, or inn is opened. A story line stays up.
- The flight master stays up. I can't read your mind.
- Coin, quest items, and free loot that fits are taken. A locked roll stays up.
- Poor junk is sold. A poor item you marked to keep is not sold with it.
- Repair uses your own coin. Restock buys the amount you are still short, in one purchase.
- Mail takes gold and attachments. COD mail stays.
- Welcoming Campfire keeps you seated. Loot, a flight, or a refused interact still stands you.
- A poor item is confirmed when you delete it.
- Zephyr does not release a corpse, and does not accept a resurrection, summon, duel, trade, or party invite.
- Train all sits beside Train and buys what you can afford when you press it. Be ready.

Settings

Options → AddOns → Zephyr. The Zephyr row is the about page. The plus opens one page per feature.

Commands

- `/zephyr` prints the commands.
- `/zephyr settings`
- `/zephyr keep [link or id]`
- `/zephyr unkeep [link or id]`
- `/zephyr sellitem [link or id]`
- `/zephyr unsell [link or id]`

Known issue

WoW Forever beta does not load saved settings after a reload. They work for the current session. Repair, Restock, Lists, and Profiles say so on the page. Please read this.

## License

MIT. See [LICENSE](LICENSE).

World of Warcraft and related marks are trademarks of Blizzard Entertainment.
