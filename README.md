sn.pl - CLI Simplenote client
=============================

DESCRIPTION
-----------

A command-line [Simplenote][sn] client.

 * Invokes `EDITOR` (e.g. vim) to edit notes.
 * Uses [Config::Pit](http://search.cpan.org/perldoc?Config::Pit) to manage account information.
 * Stores notes and auth information to ~/.sn.pl.yaml .
 * Uses [Growl](http://growl.info/) to notify notes updated while editing.

COMMANDS
--------

### list

List notes. Will download all notes at first, may take some time.

	sn.pl list [--no-data] [--tag={tag}]

 * `--no-data` Do not fetch note contents.
 * `--tag`     Filter notes by tag.

### new

Start editing new note. Starts `EDITOR` with temporary file.
While editing, update the file to send note to server.

	sn.pl new

### edit

Edit existing note.
While editing, update the file to send note to server.

	sn.pl edit {note-key}

### cat

Print note content to stdout.

	sn.pl cat [--local] {note-key}

 * `--local` Show local cached note content.

### grep

Grep note contents. Currently does on local data.

	sn.pl grep {pattern}

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
