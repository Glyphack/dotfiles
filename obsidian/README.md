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

Handling images is tricky. To make it simpler I bundle a note and all of it's attachments into one folder.
So a `my-post.md` becomes `my-post/index.md` and attachments can be inside the folder.

## Keep Text in the Middle

This feature mimics the `scrolloff=999` setting in vim.
Run the `Toggle typewriter mode` command to turn it on or off.
The state is saved, so it stays on across restarts.

When on, the line you are typing stays vertically centered.
Notes still start from the top of the screen.
Centering only kicks in once the cursor moves past the middle of the view.
Clicking with the mouse does not recenter, only typing and keyboard movement do.
