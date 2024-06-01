# Core Features
See also goto public repo's README.
(TODO: define public API more rigorously and completely.)

# Assigned Features (see actual commit log)
## v0.5
- v0.5.1: title screen
- v0.5.5: filesearch fuzzy regex
- v0.5.10: filesystem search key-symbol
- v0.5.11: In rcfs, if there are multiple matches, use a new maxdepth for filesystem search setting to go if there is a desired maxdepth.
- v0.5.13: Fix bug where depth = 1 isn't found to be unique when overall depth is greater than one
## v0.6
- v0.6.0: relative paths as destinations: if a destination is a directory, and it's a relative path, then it'll look at its parent's destination and build a more complete path, and so on. This makes updating nested directory shortcuts easier.
## v0.7
- v0.7.0: goto move
- 0.7.2: output line for gotoui_update interactive mode should specify not just which shortcut was updated, but which field was updated to which new content (see non-interactive mode output)
- v0.7.1: move inside browse
- v0.7.?
	- prevent any keyword from starting with !, so that you can use that as a signal to search in filesystem. can stack with the fuzzy specifier: !/fuzzy/
	- we're using colon ':' instead
- v0.7.?
	- at this moment, the goto update code correctly processes relative path creation, but goto -cd doesn't seem to do so when adding a directory under a parent that is also a relative path. 
## v0.8
- v0.8.0: goto cross-platform greater compatibility
	- make goto more shell-agnostic
	- sed -i '' option is MacOS-specific. So detect the OS and switch your tacts.

# Common mistakes / bugs during development
- If you want to use jq to extract the content of a field in a json file, remember to specify the -r option so as to avoid the possible double quotes!
- If you want to use jq to produce something that you can then use back in jq, remember not to use -r option. Perhaps use -c wherever possible to save trouble with potential failings of pretty print's newline chars.

# Unassigned Features

## Improving Existing Features
- since goto now uses relative paths, when moving shortcuts of directories, you must first reconstruct their original path before moving, so as to preserve correctness.
- Instead of position option flags, allow for apositional options: use getopts to greatly improve user experience.
- add another option for multipath that is a smart search: for the filesystem one, progressively increases maxdepth until at least one match is found. if only one, then go there. if more than one, then display them all. do analogously for the json one.
- make bash-version json keyword search much faster
	- instead of using jq, use native bash and custom script for the tasks at hand. minimize overhead, increase efficiency, build in room for extensibility via modularity.
- auto-detect the type of a shortcut at creation / update time based on the destination
- for goto link, auto-detect if it's a link or an rlist address.
- make goto possibly faster by allowing for some namespace pollution with helper functions: rememberHelpers; I just checked: this doesn't improve performance; consider using an if-else statement on all function definitions.
- make goto as fast as possible under the framework of bash. if it's still not quite satisfying, gotta consider moving to C. though one determining factor is: are the bugs fixed thus far having to do with language-specific quirks or logical errors? If the latter, then moving to C wouldn't mean losing too much of the gained wisdom from the past two months. But also, since it's still quite early in the project, that can be doable. Might involve learning Autoconf & friends.
- in setting descriptions (and shortcut descriptions), allow for special chars like '\n' to help with desired formatting of description field when printed by goto.
- during browsing, add an option for user to see the full description (or a description preview) of each child, so the user has an idea what the keyword stands for.
- when printing descriptions of a nested shortcut, default to printing the descriptions of its parent shortcuts as well, so that adding a description for a shortcut is as simple as specifying the most local context description, saving time & mental energy.
- Fix bug where if the shortcut keyword is a special regex char, like '+', it doesn't work.
- add to goto update the ability to filter directories to relative paths
- goto <a topic> should just print the topic by default
- improve json search algorithm so that the search time doesn't scale linearly with the json file size
- make goto filesystem search much faster by using locate instead of find, this also requires running updatedb first...
- for increase in speed, completely drop jq and replace it with a tree search based on using find command through a folder hierarchy (deep nesting capability is good for both mac and git; OS-native folder search uses efficient B-tree or faster algorithm written with low-level code; no need for installation of another package, so reduces dependencies; allows for maintenance of bash-based script without needing a language transition if speed can be significantly increased by this method)
- for goto create UI, flip the API from `-c [-k key -d desc -t type -n dest] -under parent` to `-c -under parent [-k key -d desc -t type -n dest]`

## Expand Features (API)
- auto-directory for update: interactive & non-interactive.
- goto inside browse
- add a bootstrap functionality that updates the settings with newly introduced goto settings.
- add a bootstrap functionality that allows for performing update directly without re-running . goto.sh with a new goto.sh
- add directory opener methods: Finder, shell, or both.
- add link opener method: Chrome, Safari, etc.
- based on an aliases setting, goto automatically helps you define aliases in .bash_profile, such as 'j' means 'goto j', etc.
- goto apps: new type. calls 'open -a'
- allow for custom-defined openers for links: e.g., 'chrome --incognito', or a specific profile
- jsonsearch fuzzy regex
- optional preferred openers field for each item.
- allows for fuzzy ordering of keywords in the keyword sequence. this'll need some clever algorithm.
- get rid of the 'type' field and instead use auto-detection for default openers. then add in custom openers that users can define themselves. attach custom openers to any shortcut.
- Add an 'options' field to every shortcut, where the entries are semicolon-delimited, and one option is called 'directoryOpener' and another option is called 'linkOpener', and for the option getter function, each option, if found, is set to the specified value, and if not found, is set to default.
- add option for checking children (or all emanating paths) from a given matched keyword without going there: this helps you know which shortcuts are available.
- quickly open multiple shortcuts at once. create a new shortcut type that is a meta-shortcut, which simply references other shortcut(s) using keywords in its destination.
- Creating a new goto shortcut of type topic does not require the -n 'null' field, which is assumed. In fact, if you put it in, and you have anything other than -n 'null', it's just gonna be rejected.
- Add a non-interactive API for updating settings.
- Display the entire clade of shortcuts under a particular shortcut in an organized way.
- If noclobber is set, then turn it off for the duration of the script run.
- goto can handle shortcuts that go directly to a specific line or search pattern of a file (via vim). super cool.
- goto can open all children under a particular node at once.
- add setting: toggle between typing 'y' to confirm and directly [Enter] to confirm.
- (optional) allow for undo & redo
- goto -cf to create a shortcut to a file, rather than a directory
- build an index that lets going to certain pre-specified shortcuts be as fast as an alias!
- goto -b can now specify keywords in order to jump to the desired keyword context while in browse mode
- add ability to read the direct parent of any matched keyword
- for upgrade and add, allow user to specify as many command line options as they want, in any order, and interactively prompt for the rest.
- add setting for auto-exiting terminal after running a go command
- allow for disabling certain shortcuts & their children, so that the rcjs alg doesn't include them
- after adding directory-based traversal, add a functionality to convert current master directory into a JSON file for portability and syncing purposes, then to convert from JSON back into a master directory.

## Meta
- Add a license to goto
- Rigorously define its API.

## Massive Revamp Considerations
- eventually... turn goto into a C function somehow? but can it still use jq?
	- look into json C libraries: https://www.json.org/json-en.html
	- look into Jansson: https://jansson.readthedocs.io/en/latest/
	- or, even, https://github.com/DaveGamble/cJSON
	- look into Makefile template: http://www.jukie.net/~bart/blog/makefile-template
- Consider turning program into Rust


