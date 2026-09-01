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
- From: an optional start time like `09:30`. When set the line shows a start and end range.


## Track time

Run the `Track time` command to start a focus session and log it to the weekly note.
It writes the same kind of timestamped line as `Log`, tagged with `#focus-session` and the goal.

The modal has these fields:

- Category: pick what you are focusing on. Maps to a goal like Writing or Programming.
- Duration: length in minutes. Defaults to 30.
- Message: an optional note about the session.

A preview shows the exact line before you commit.

On desktop it also opens a Raycast focus session for the goal and duration.

It can send a phone notification when the session ends.
This uses ntfy, which delivers the notification on its own after the delay, so Obsidian does not need to stay open.
Set an ntfy server and topic in Dots settings to turn this on.
Leave the topic empty to skip the notification.
Anyone who knows the topic can read messages sent to it, so pick a name that is hard to guess.


## Sync to Blog

I build my blog using a static site generator.
To emulate obsidian publish I am exporting notes from obsidian to my blog repository.
The site generator picks up the notes and generates pages for them.

There are two kinds of notes:

- blogs: These end up in content/blog
- non-blogs: These end up in content/synced

The synced notes have a `layout` property that defines what template is used to render them.
Blogs are rendered as normal posts.

To publish a note:

Add `share: true` property.
Add `dest` property, for a blog it's `blog/my-post` and for a note it's `my-note`. Notes are moved to `synced` because they don't have blog prefix in destination.

Run `publish-notes` command and the notes are copied to blog folder.

Turn on auto publish in settings and you don't have to run the command at all.
A note is published a few seconds after you stop typing in it, as long as it has `share: true` and a `dest`.
A note with no `dest` yet is left alone, and clearing the `dest` of a published note removes its folder from the site.
Nothing is shown when it works. A failure shows a notice and the details go to the console.

Auto publish also keeps removals in sync.
Take `share` off a note or delete it and its folder is removed from the site.
Renaming a note does not change anything on the site, because the address comes from `dest` and not from where the note lives in the vault.

A `.dots-synced` file appears at the top of the content folder listing every folder the plugin created, one per line.
Keep it with the blog, it is how an unpublished note gets removed later.
The plugin only ever deletes folders listed in it, so a hand made folder in the blog is never touched.
Delete the file and the plugin forgets what it made, so nothing is cleaned up until it publishes those folders again.
Hugo ignores it, so it never becomes a page resource on the built site.

Set the content path in Dots settings.
It can start with `~` or `$HOME`, so the same setting works on machines with different usernames.
The path is checked before anything is written, so a wrong path gives you one clear message instead of one failure per note.

Handling images is tricky. To make it simpler I bundle a note and all of it's attachments into one folder.
So a `my-post.md` becomes `my-post/index.md` and attachments can be inside the folder.

A link is rewritten when it points at a note in the vault, whether you wrote it as a wikilink or as a markdown link.
Everything else is left exactly as it is, so an external address and a heading link like `[Introduction](#introduction)` used in a table of contents both survive untouched.
A wikilink is the one exception: it is always rewritten, even when it points at nothing, because it would not render on the site anyway.

A rewritten link is two parts, a text and an address, decided separately.

The text is whatever you typed.
For a markdown link it is the text in the brackets.
For a wikilink a pipe alias is kept as written, otherwise the note name is used.

The address is picked in this order:

- The target is published: the link points at its published page.
- The target is not published but has a `source` property: the link points at that address.
- Neither: the address is dropped and only the text is left behind, as plain words in the sentence.

A published note always links to its own page, even when it also has a `source`.
So publishing a note never starts sending readers away from your site.

Use `source` for notes about something that is already on the web, like a paper, a post you took notes on, or a project with a repository.
A reader following the link lands on that thing instead of a dead end.

The property is called `source` and not `url` on purpose.
Hugo treats `url` as the address the page is served at, so a published note carrying `url` would end up at the wrong path.

Notes are transformed so they render correctly on the website this is the rule:

- A wiki link that starts with `[[` or `![[` is always transformed.
- A markdown link is transformed only when it resolves to a note in the vault. Anything else, like a web address or a `#heading` link, is kept as is.
- A link that resolves to a note gets its address this way.
	- If the other note is published the link is constructed based on the `dest` so on the website the link works.
	- If the other note is not published and has no `source` then the link becomes normal text.
	- If the other note is not published bu has a `source` then the link is the source.
- The text for the link is either the text or the alias text. [[text|alias]] shows alias but [[text]] shows text. `[text](note.md)` shows text.

Attachments live next to not so ![a chart](attachments/chart.png) becomes  ![a chart](chart.png)

The frontmatter links are untouched and just unwrapped.

Links like [[other-note#heading]] will end up as (other-note)[/path/to/note] so the heading information is dropped.

## Todo

- Remove all traces of `sync-manifest.json`, the old record of published notes. The plugin still deletes a leftover one from the vault config folder on startup.

## Keep Text in the Middle

This feature mimics the `scrolloff=999` setting in vim.
Turn it on with the `Typewriter mode` toggle in Dots settings, or run the `Toggle typewriter mode` command.
The state is saved, so it stays on across restarts.

When on, the line you are typing stays vertically centered.
Notes still start from the top of the screen.
Centering only kicks in once the cursor moves past the middle of the view.
Clicking with the mouse does not recenter, only typing and keyboard movement do.
