# goto: your command-line shortcuts manager

For a quick overview of goto, [check out this video](https://youtu.be/Vr2zBbkXY30).

## How to install goto

The only dependency for goto is a command called `jq`, which processes JSON files. If you are a Mac user, an easy way to get `jq` is to install it via Homebrew (`brew install jq`). Here are [some more ways](https://stedolan.github.io/jq/download/) for installing `jq` to your computer.

Of course, you'll also need the script `goto.sh`. You can get it by downloading this GitHub repo, although, as goto is a command-line utility anyways, I recommend using the command line for a smooth workflow.

Open Terminal and type the following three lines. When prompted, type 'y' to install goto at the default location on your computer.
```bash
curl https://raw.githubusercontent.com/poiurewq/goto/main/goto.sh > goto.sh
. goto.sh
rm goto.sh
```

That's it! You're ready to use goto now.

