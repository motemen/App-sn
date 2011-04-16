sn.pl - CLI simplenote client
========================================

DESCRIPTION
-----------

A command-line [Simplenote][sn] client. Invokes `EDITOR` (e.g. vim) to edit notes.

SYNOPSIS
--------

	sn.pl help

COMMANDS
--------

### list

List notes.

	sn.pl list

### new

Start editing new note. Starts `EDITOR` with temporary file.
While editing, update the file to send note to server.

	sn.pl new

### edit

Edit existing note.

	sn.pl edit {note-key}

### help

Show help.

	sn.pl help [{command}]

SEE ALSO
--------

[Simplenote][sn]

[sn]: http://simplenoteapp.com/

AUTHOR
------

motemen <motemen@gmail.com>
