# Dots

Opinionated dotfile style obsidian customizations.

This repo is generated from obsidian plugin template and is vibe coded. The features are simple enough to verify it works.


## Weekly Note

Created from a template in `Templates/Weekly Note Template.md`.
Placed into `Weekly/yyyy-ww.md` where `ww` is the week number.
First day of the week is Monday.


## Daily Note

Automatically creates daily note when you open Obsidian.
On mobile where typing a date is hard this makes it easier.
Whenever you want to link to current date you can just type `[[202...]]` and link it easily.


## Log

Run the `Log` command to open a modal and write a timestamped line into the current weekly note.
The line goes under a header for the current day, creating the header if it is missing.

The modal has these fields:

- Message: what happened. Required.
- Place: an optional location tag.
- From: an optional start time like `09:30` or `0930`. When set the line shows a start and end range.


## Track time

Run the `Track time` command to start a focus session and log it to the weekly note.
It writes the same kind of timestamped line as `Log`, tagged with `#focus-session` and the goal.

On desktop it also opens a Raycast focus session for the goal and duration, and sets the goal in One Thing.

If the ntfy topic is set then it will also send a push notification when the session ends.
Useful to create a reminder when I'm on the phone and track time with the same action.


## Links

Scripts outside Obsidian use these links. They only pass the arguments and the plugin does the rest.

- `obsidian://dots-log?message=...&place=...&from=...` works like `Log`.
- `obsidian://dots-track-time?category=...&duration=...&message=...` works like `Track time`.
- `obsidian://dots-continue-focus` starts the last focus session of today again.

Add `background=1` to hide Obsidian again when it is done.


## Sync to Blog

I build my blog using a static site generator.
To emulate obsidian publish I am exporting notes from obsidian to my blog repository.
The site generator picks up the notes and generates pages for them.

You need to set your blog `content` directory in settings.
It can start with `~` or `$HOME`, so the same setting works on machines with different usernames.
This means the blog must be on the same machine. So publishing from mobile is no possible.

Front matter keys:

- `share: true`: publish this note.
- `dest`: the folder inside `content` where the note goes. It is used as is. `blog/my-post` ends up in `content/blog/my-post` and `my-note` ends up in `content/my-note`.

hugo keys are also supported:
- `url` to specify what URL to use.
- `layout` to customize how the page will render.

Run `publish-notes` command and the notes are copied to blog folder.
Turn on auto publish in settings and you don't have to run the command at all.

A `.dots-synced` is created after publish to keep track what was created.
Keep it with the blog, it is how an unpublished note gets removed later.

The path is checked before anything is written, so a wrong path gives you one clear message instead of one failure per note.

Handling images is tricky.
To make it simpler I bundle a note and all of it's attachments into one folder.
So a `my-post.md` becomes `my-post/index.md` and attachments can be inside the folder.

Note links are transformed so they work on the blog too, here are the rules:

- A wiki link that starts with `[[` or `![[` is always transformed.
- A markdown link is transformed only when it resolves to a note in the vault. Anything else, like a web address or a `#heading` link, is kept as is.
- A link that resolves to a note gets its address this way.
	- If the other note is published the link is constructed based on the `dest` so on the website the link works.
	- If the other note is not published and has no `source` then the link becomes normal text.
	- If the other note is not published bu has a `source` then the link is the source.
- The text for the link is either the text or the alias text. `[[text|alias]]` shows alias but `[[text]]` shows text. `[text](note.md)` shows text.
- `[[other-note#heading]]` links will end up as `(other-note)[/path/to/note]` so the heading information is dropped.
- Attachments live next to not so `![a chart](attachments/chart.png)` becomes  `![a chart](chart.png)`
- The front matter links are untouched and just unwrapped.

Dataview blocks are removed before publishing.


### Image metadata

Publishing needs `exiftool` installed (`brew install exiftool`).

This is for removing exif metadata like location from the image before publishing.

Two commands clean images without publishing:

- `Remove EXIF data`: cleans the images embedded in the current note.
- `Remove EXIF data from all files`: checks every file in the vault and cleans all images.

## Post to X

Run the `Post to X` command to send the selection, or the note without its front matter, to Typefully.
Typefully makes a draft for X. Review it there and post it.
Set the Typefully API key in Dots settings first. It is kept in Obsidian's secret storage.

## Todo

- Remove all traces of `sync-manifest.json`, the old record of published notes. The plugin still deletes a leftover one from the vault config folder on startup.

## Keep Text in the Middle

This feature mimics the `scrolloff=999` setting in vim.
Turn it on with the `Typewriter mode` toggle in Dots settings, or run the `Toggle typewriter mode` command.
