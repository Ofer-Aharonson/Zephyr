# Soul

How to build Zephyr for World of Warcraft: Forever.

Forever is a permanent home in original Azeroth. Blizzard’s line for it is: the world takes center stage, community comes first, and the journey matters as much as the destination. It sits after Warcraft III Reforged: Forsaken Kingdom and before Molten Core. The level cap stays at 60. It is not a season, and it is not a ladder of expansions that throw away what you earned.

Zephyr is a road companion for that world. It clears a click the player has already decided to make. It leaves the road, the story, the campfire, and the coin alone.

This file is the test for a new feature. If a change fails the test, it does not go in.

## The four pillars

Blizzard measures every addition against these. So do we.

**Approachable and familiar.** The world should still feel like Classic. A new thing earns its place when it feels as if it could have always been there. New, and flashy, are not reasons.

**The world is the main character.** Leveling matters as much as the endgame. Roads, camps, dungeons, and the people you pass are the content. Local stories matter. Saving the planet is not the daily job.

**Journey before destination.** Effort keeps mattering. Professions, routes, gear, and the friends you made are not replaced by a higher level cap. There is no flying, and zones do not scale to you.

**Protect the social moments.** A lot of Classic memory is another player: someone who helped finish a quest, a stranger who joined the group, a dungeon that turned into a guild. Convenience is allowed, and it is dangerous, because every shortcut changes who you meet.

## What that asks of an addon

Blizzard said they are careful with convenience, because a quality-of-life choice changes how people gather. Zephyr lives inside that sentence.

A good Zephyr action is a pebble in the boot: the loot you were going to take, the poor item you were going to sell, the repair you were going to pay for with your own coin, the finished quest you were going to hand in, the letter that already belongs to you.

A bad Zephyr action chooses for the player. It accepts a quest they have not read, spends their gold on a skill, rolls their loot, stands them up from a campfire, skips the first sight of a new land, or plays the game in a way that means they never needed anyone else.

When a feature is in doubt, leave the window up. Shift already means “Zephyr waits.” That is the whole philosophy in one key.

## The world we are building for

Facts below come from Blizzard’s What’s Next and Deep Dive recaps at BlizzCon 2026. Beta will move details. The pillars will not. When the client disagrees with this list, trust the client, then update this file.

The place is Eastern Kingdoms and Kalimdor, looked at more closely: Hyjal after Archimonde, Shen'dralas, the Riverglades, Zephras Isle, and more than a thousand new quests from 1 to 60. Nine new dungeons. Raids at Hyjal Summit (20) and the Barrow Deeps (10). A 15v15 battleground, the Darkspear Islands. The Skyborne start on Zephras and choose Horde or Alliance. New race and class pairs include the undead paladin and the dwarf shaman. Classes stay distinct on purpose. Gaps in a kit are part of the class. A normal creature still takes about ten to fifteen seconds. Crowd control and threat still matter in a dungeon.

You do not pick a realm from a long list. You pick a ruleset: Normal, PvP, Roleplaying, or Hardcore after launch. Each ruleset is its own crowd. Horde and Alliance still do not group. Names have two parts, so a person can be recognized in a larger world. The aim is that strangers become regulars.

Camping turns a cooking fire into a place. People can rest there, repair, use a vendor, work a profession, and share a one-hour buff. The buff asks you to sit. Some ground is a bad place to sleep. A camp is a reason to stop for someone, not a button that replaces a city.

Legacy points are earned on the account and spent per character, in small trees, with a low cap so a new player is not already behind. The extra points buy prestige, not power. Alts are encouraged. Skipping the walk to 60 is not.

Transmog is a choice. Classic Mode starts with it off. A player who turns it off should be able to pretend it is not in the game. Gear still tells the truth for them: helm and cloak toggles included. Dungeon uncommon and rare appearances are learned by everyone eligible when the item is looted, so a roll is about the item, not the look. Epic raid looks stay with the person the item binds to. Plate looks like plate. Cloth looks like cloth.

The first login also chooses a visual preset: the older presentation, or a clearer one, including HD or SD models. Rivers, mist, and moonlight can be richer. The shapes of Azeroth stay the old ones. Zephyr’s windows use the client’s own parchment, gold borders, and quest fonts, so they follow that choice instead of bringing in a later game’s chrome.

Riding works the later Classic way: you pay the trainer, and the mount comes with the skill.

Hardcore, when it arrives, is a separate life. Death there is the point. Zephyr does not release, accept a spirit, or confirm a destroy for a Hardcore character.

## How Zephyr should feel

The voice is a tooltip, not a product page.

“Loots what is yours.”
“Sells poor wares. Keeps what you have marked.”
“Mends your armor with your own coin.”
“Takes the coin and the parcels. Leaves letters that demand payment.”
“Hands in a quest you have finished.”
“Hold Shift, and Zephyr waits.”

If Zephyr speaks, it is one chat line. Coin uses the game’s coin icons. No toast. No scoreboard.

A settings page, when we paint one, is a ledger on quest parchment. Morpheus for the title, Friz Quadrata for the lines, gold for the headings. A round icon in the corner. Keep-lists and sell-lists live on that page as item links. The modern options screen is only the door this client gives us. The room inside is paper.

Bags are the backpack, four bags, and the keyring. Repair comes from the player’s purse, in town or at a camp. A camp vendor is a merchant. Sitting at a fire is rest, and Zephyr stands the player only when the game refused an action because they were seated.

## The test

Before adding a feature, answer these. A no on the first three, or a yes on the last two, means it waits.

1. Would a traveler in this Azeroth recognize the action as something they were about to do anyway?
2. Does it still leave a reason to talk to someone, sit at a fire, or walk into town?
3. Does it leave unread quests, unspent trainers, unchosen loot, and unsold gear of real value on the screen?
4. Does it hide a new place, a cinematic, or a story gossip the player has not chosen to skip?
5. Could it kill a Hardcore character, or throw away a life they meant to keep?

Group loot that is already unlocked is yours to take. A locked roll is a conversation. A single gossip line is safe when it is a vendor, a binder, a flight, a trainer, or a bank. A single line of story stays closed. A finished quest can be handed in. A new quest stays open until it is read. Party-shared quests are opt-in.

## What we leave alone

These belong to the player, or to a later version of Warcraft.

- Flying, summoning the player across the world, or shrinking a trip that was supposed to be a ride.
- Choosing talents, Legacy points, trainers, or repairs from a guild vault.
- Rolling, ninja-looting, or selling uncommon-and-better gear on a first command. Dungeon looks are learned on loot. Quest rewards and crafted pieces are still decisions.
- A transmog hider. The game already has that choice.
- Auto-learning recipes, auto-camping, or standing up someone who sat down to earn a buff.
- Treating retail systems as if they were here: reagent bags, warbands, covenants, a dungeon browser, talking-head popups as a core feature. If a frame exists on this client, hook it gently. Do not build the addon around it.
- Anything that makes a class gap, a threat mistake, or a crowd-control moment irrelevant. Those are the dungeon.

## Where this came from

Written September 2026, for the Forever beta (`Interface 16001`).

- Blizzard, “World of Warcraft: Forever What’s Next Panel Recap”
- Blizzard, “World of Warcraft: Forever Deep Dive Panel Recap”
- Blizzard, “World of Warcraft at BlizzCon 2026 News Round-Up”

When a beta build changes a system, change this file in the same change as the code.
