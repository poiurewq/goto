# goto: your command-line shortcuts manager

**goto** is a command-line shortcuts manager that lets users quickly go to files, directories, and links to websites. The program is entirely contained within a single large script, `goto.sh`. **goto** keeps track of shortcuts internally as keywords linked in a tree-like data structure. This way, you can define shortcuts nested inside other shortcuts, allowing for the grouping of shortcuts by topic. You can go to any shortcut by specifying a sequence of keywords along the tree branch leading to that shortcut. More simply, if a deeply-nested shortcut has a unique name, say, 'aardvark', you can also simply type `goto aardvark` to go there.

For a quick overview of goto, [check out this demo video](https://youtu.be/Vr2zBbkXY30).

To view the public API, set up goto on your computer, then type `goto --help` for all options.

## Setting up goto

The only dependency for goto is a command called `jq`, which processes JSON files. If you are a Mac user, an easy way to get `jq` is to install it via Homebrew (`brew install jq`). Here are [some more ways](https://stedolan.github.io/jq/download/) for installing `jq` to your computer.

Of course, you'll also need the script `goto.sh`. You can get it by downloading this GitHub repo, although, as goto is a command-line utility anyways, I recommend using the command line for a smooth workflow.

Open Terminal anywhere and type the following three lines. When prompted, type 'y' to install goto at the default location on your computer.

```bash
curl https://raw.githubusercontent.com/poiurewq/goto/main/goto.sh > goto.sh
. goto.sh
rm goto.sh
```

That's it! You're ready to use goto now.

## Core features


Each shortcut consists of a keyword, a description, a type (file, directory, or link), and a destination. To go to the destination specified by a shortcut, simply type `goto` followed by a sequence of keywords that can uniquely identify the shortcut. If a shortcut lives in the tree along the branch `A -> B -> C`, then typing `goto A B C` will open up the destination stored at that shortcut. If the keyword is unique, you do not have to specify the full path along the tree branch to the shortcut. For instance, if the keyword `journal`, storing a shortcut to your journal, appears only once in the entire tree, then even if `journal` is buried deep in the tree (such as `personal -> writings -> journal`), you only need to type `goto journal` in order to open your journal. This allows for very quick access to destinations without your having to remember the intermediate keywords along the way.

A large portion of the underlying script is devoted to the user interface for creating, reading, updating, and deleting (CRUD) shortcuts. As with many CLI programs, **goto** is able to take commands interactively, allowing for an intuitive CRUD experience. Additionally, all CRUD commands are able to be invoked non-interactively, allowing **goto** to be incorporated into user-defined scripts. The most intuitive CRUD command is the browse command. It allows you to interactively CRUD any shortcut in the shortcuts tree.

There are also settings that the user can modify to change the behavior of the program itself. A nice feature of **goto** is that, at first invocation anywhere in the file system, it "bootstraps" itself into the user's system and initializes its internal storage of shortcuts and settings, allowing for quick and painless installation.

The only requirement for this script to run, other than having a UNIX terminal, is the `jq` command by stedolan for JSON manipulation. **goto** detects whether `jq` is present and lets the user know if they need to install `jq` first.

## Initialization and Internal Representation

To install this utility to any UNIX system (I have tested it on several Macbooks, but have not confirmed compatibility with other POSIX-compliant systems), simply download the script named `goto.sh` anywhere in your file system, then call `source goto.sh` in the same folder. **goto** will "bootstrap" itself into the system, creating the necessary files under a hidden directory at `~/.goto/` and adding a **goto** alias in `~/.bash_profile` that simply calls `source ~/.goto/goto.sh`. Then, after restarting the shell, the user can invoke `goto` on the command line to directly use it. (If the user has a non-bash shell, they have the option to change the shell profile destination so that their shell can read in the **goto** alias.)

**goto** stores all settings and shortcuts in the file `goto.json`, placed by default under `~/.goto/`.
All settings and all shortcuts are stored inside the first and second objects, respectively, of the top-level array in the JSON file. All settings are created as children under a root setting with the keyword `settings`, while all shortcuts are created as children under a root shortcut with the keyword `root`.

At first invocation, **goto** sets up a few settings as well as example shortcuts, including a shortcut (`goto`) to the `goto.sh` script itself and a shortcut (`keys`) to the `goto.json` file. So, after first invocation, you can test whether the setup worked by restarting the shell, then typing `goto goto` to open the script, and `goto keys` to open the JSON file.

## CRUD operations
Currently, my script supports the four main CRUD operations: create, read, update, and delete. All of these operations have a non-interactive mode, which is reached when you pass in the appropriate command-line arguments. Create and update also have an interactive mode, which is reached when you don't pass in certain arguments. The details for usage are specified in the help messages, which can be read by calling `goto`, or `goto --help` for more details.

### Browse
`goto -b` is perhaps the most useful CRUD command. It allows you to interactively traverse the full shortcuts tree (`goto -b`), adding new shortcuts, updating shortcuts, and deleting shortcuts wherever you please. This is also the best way to update settings, as you can see what their keywords are.

### Create directory shortcut
`goto -cd -under parent` is another useful command. It automatically reads the current directory's path, then creates a shortcut based on this directory, under a parent shortcut specified by `parent`. This can be used to conveniently add directory shortcuts to **goto**.

## Recursive JSON search algorithm (rcjs)

This is the main algorithm underlying all of the CRUD as well as the main goto functionality of **goto**. It takes in a sequence of keywords. For each keyword in order, rcjs searches under the last matched shortcut (which begins at the root shortcut `root`), looking for any shortcut that matches the keyword at *any* level of depth from the starting shortcut. If it finds a unique match, it sets that as the starting shortcut for the next keyword, and so on, until all keywords are exhausted. If it encounters multiple matches, it prints out the paths to all matches. If it encounters no match for keyword, but there was a match before this keyword, it returns the partial match (if jsonPartialMatch=on).

In the main goto function, if the given keywords are not exhauted by the rcjs matching, the unmatched keywords are sent to an analogous algorithm (recursive filesystem search, or rcfs) that recursively searches the filesystem for keyword match, starting at the directory specified by the partially matched shortcut.

### Relevant settings
- The multipath setting determines whether rcjs returns a single match when it encounters multiple matches, or prints all of them and quits. A setting of 'always' would always print out all matches. A setting of 'depth >= n', where n is a number, returns a single match if that is the only one at a depth of less than n from its parent match, otherwise it prints out all matches and quits.
- The jsonPartialMatch=on setting allows for the rcjs algorithm to return the match early if it finds a match only for a part of the given keyword sequence (rcjs will still try its best to first completely match the given keywords). When this is off, then in the main goto function, if rcjs matches partially, then rcfs takes over and searches in the file system with the rest of the (unmatched) keywords.
- Similarly, the filesystemPartialMatch=on setting allows for the rcfs algorithm to go the match if it finds a match only for a part of the rest of the keyword sequence (rcfs will still try its best to first completely match the given keywords).

## Destination types
There are four types of shortcuts: topic, file, directory, and link.
- The topic shortcut does not have a destination, as it is only used for grouping sub-shortcuts.
- The file shortcut is opened via the system's `open` command, so its behavior is system-dependent.
- The directory shortcut is opened via `cd` command by default. You can also change it to open by `open` by changing the `directoryOpener` setting.
- The link shortcut is opened via the system's `open` command. I also have another option to open via a custom reading list script I built called `rlist`, though this is not yet available to other users.
