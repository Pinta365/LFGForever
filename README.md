# LFGForever - World of Warcraft Addon

Tired of hovering over every listing to find out who's actually in a group? **LFGForever** puts it all right on the Looking For Group list in WoW Forever!

## Description

LFGForever is a lightweight addon that enhances Blizzard's Looking For Group finder. It doesn't replace anything – it adds the information you'd otherwise have to dig out of tooltips. It will:

* Show every group member as a class icon with their role badge, leader first.
* Show the leader's level next to their name and the group's level range when members differ.
* Highlight groups with an open spot for the roles you've selected, with a pulsing role icon for each spot you could fill and a green edge on the row.
* Show the listing comment on Quests & Zones rows instead of hiding it in the tooltip.
* List the actual zones instead of "12 activities", best fit for your level first.
* Colour zones by your level, in both the browse list and the listing tab: white when it fits you, grey when you've outgrown it, red when it's too high.
* Show class name, class icon and selected roles on solo player rows.
* Add class icons, class coloured names and level difficulty colours to the Who list.

Hover over a member icon to see their name, level, class and zone.

## Slash Commands

LFGForever offers the following slash commands:

* `/lfgf debug`: Toggles debug mode.
* `/lfgf help`: Displays a help message with usage instructions.

## For Addon Developers

LFGForever uses the `Group Finder` addon category, because in Forever the group finder is so much more than dungeons and raids. If you make a group finder addon, use the exact same line in your TOC so we all end up together in the addon list:

```
## Category: Group Finder
```

## Troubleshooting

If you encounter any issues, try these steps:

* **Reload your UI:** Type `/reload` in the chat frame.
* **Check for error messages:** Pay attention to any error messages in the chat frame. Install BugSack and BugGrabber to get better error reporting.

## Reporting Issues

If something goes wrong while LFGForever draws the group finder, the error is reported once and that part of the addon turns itself off until your next `/reload`, so the rest of your group finder keeps working. Install BugSack and BugGrabber to capture the full error.

`/lfgf debug` shows which parts of the group finder LFGForever has attached to, which helps if an enhancement doesn't show up at all.

If you're still unable to resolve the issue, please open an issue on the [GitHub repository](https://github.com/Pinta365/LFGForever/issues) and include the following information:

* A description of the issue.
* Steps to reproduce the error.
* Any relevant error messages. (Use BugSack and BugGrabber)
* A screenshot of the group finder, if it's a visual issue.

By providing this information, you'll help me identify and fix bugs more efficiently, making LFGForever even better!
