# goto: go to an oft-used directory, a file, or a website, with the help of keyword mappings.
#
# author: QZ
# version: type 'goto' to see
# built: 2022-12-26 ~
# maintained: 2022-12-24 ~

#####################
## Description dsc ##
#####################
 
# == Menu ==
# In Vim, use * to jump.
# In VSCode, use Cmd-D to jump.
# -- non-code notes --
# dsc
#   ntt
#     jsnfmt
#     nptfmt
# -- general helpers --
# shdf
#   vrdefs
#     cddefs
#   shfdefs
#     otenv
#     otpt
#     vbotpt
#     simusg
#     dtusg
#     opvsn
#     opttl
# -- bootstrapping --
# ftbtdf
#   ssbtvdef
#     plpvdef
#     alsvdef
#   ftbtconf
# evbtdf
#   fcst
#   atplp
#     plpfdef
#     plpalg
#   alsalg
#   chkdep
#     chkjq
#     chkrl
#   gtstvrs
#   stjs
#   gtsts
# -- checkpoint --
# chkinv
#   chkft
#   chkargs
#   chkjsn
#     chkfj
#     chkvj
# -- crud and goto helpers --
# hcrdgtof
#   gtnst
#   ppth
#   rcsjs
#   hgtalg
#     opdest
#     opabsp
# hcrui
#   ovwjsn
#   hlpc
#   hlpr
#   hlpu
#   hlpd
#   hlpm
#   hlpf
# -- crud ui --
# cruduif
#   crui
#   reui
#   upui
#   deui
#   rdui
#   moui
#   hib
#     hbsc
#     hbst
#   brui
# cruduix
# -- goto ui --
# gtui
#   gtuf
#   rngt

# == Notes ntt ==
# iteration note: 
#   v0.1.0: combines & generalizes the functionality of goto and course from before 2022-12-24. the aim is ease-of-use and ease-of-keyword-definition.
#   v0.2.0: improve jq invocations. add settings so that usage is non-interactive. only bootstrap algorithms remain obligatorily interactive.
#   v0.3.0: add goto.json crud: both non-interactive and interactive.
#   v0.4.0: add goto.json browse.
#   future: add move operation.
# file note: this is a sourced script. no need for chmod +x. no need for loading definition upon startup. needs insertion of an alias in bash profile.
# dependencies: rlist (and its dependencies), jq

# -- json format jsnfmt --
# There are two major sections to goto.json
#   settings, shortcuts
#   settings are where the settings are updated and stored.
#   shortcuts are where the shortcuts are crud-ed.
# Understanding shortcuts & settings:
#   Each setting is specified by a unique "keyword" string. This string should be simple for the user to type and remember.
#   Each shortcut is specified by a "keyword" string (not necessarily unique). This string should be simple for the user to type and remember.
#   Each setting/shortcut has a "description" field. This explains to the user what this setting/shortcut represents. You should strive for description to be descriptive. But it doesn't have to be unique.
#   Each setting has an optional "content": contains instructions for how the program behaves. 
#   Each shortcut has an optional "destination": contains the path or link to the desired destination. 
#   Each setting has a "type":
#     t = topic (content: null)
#     s = setting (content: setting string)
#   Each shortcut has a "type":
#     t = topic (destination: null)
#     d = directory (destination: always full path!)
#     f = file (destination: full filename)
#     l = link (destination: rlist id)
# Every setting, except for the main setting topic, does not have a list.
# Every shortcut is optionally recursive, with recursion indicated by whether its "list" is null.
#   Therefore, every shortcut can have a list of sub-shortcuts.

# -- input format nptfmt --
# $@ = keyword path: could be a course, a topic like 'learn', etc. if it's a unique keyword or if it's a unique keyword path, go there following the keyword's hierarchical path. if it's not unique, require clarification.

#########################################################
## shared definitions for both bootstrap and goto shdf ##
#########################################################

# == variable definitions vrdefs ==
# -- version number gtvsn --
# see semver.org
# prerelease version is -[a|b].[0-9]
# build-metadata is +yyyymmddhhmm: run $date '+%Y%m%d%H%M%S'
gotov_semver="v0.5.0-a.0+20230102210001"

# -- general error codes cddefs --
gotocode_success=0
gotocode_partial_success=1
gotocode_unknown=2
gotocode_var_empty=3
gotocode_invalid_arg=4
gotocode_file_not_found=5
gotocode_invalid_json=6
gotocode_overwrite_failed=7
gotocode_print_path_failed=8
gotocode_no_unique_match=10
gotocode_no_match_at_all=11
gotocode_multiple_matches_json=12
gotocode_multiple_matches_filesystem=13
gotocode_missing_dependency=14
gotocode_impossible_match_count_json=15
gotocode_impossible_match_count_filesystem=16
gotocode_wrong_type=17
gotocode_unknown_type=18
gotocode_cannot_goto_topic=19
gotocode_cannot_set_topic=20
gotocode_cannot_search_further_in_filesystem=21
gotocode_weird_file_type=30
gotocode_partial_quit=31
gotocode_interactive_operation_cancelled=32
gotocode_cannot_delete_node_with_children=33
gotocode_ui_operation_failed=34
gotocode_quit_from_browse=35
gotocode_multiple_matches_among_siblings=36
gotocode_reset_cancelled=37

# == shared helper functions definitions shfdefs ==
# -- calling function environment variable otenv --
export GOTO_CALLING_FUNCTION=''
export GOTO_VERBOSE_SETTING='on'
export GOTO_FLAG_COUNTER=0

# Output vs Verbose output:
#   By convention, all bootstrap outputs should be unconditionally output.

# -- otpt --
# Input
#   sentences as input tokens
# Output
#   a nicely indented set of sentences
# Notes
#   The output is sent to stderr so as not to conflict with the echo-return of functions
#   By convention, often called from gotoui_* functions, since they are used to inform the user of the program status.
gotoh_output() {
	# nicely print the sentence tokens
	local sentence
	for sentence in "$@"; do
		>&2 echo -e "  $sentence"
	done
}

# -- vbotpt --
# Input
#   sentences as input tokens
# Output
#   Only when the verbose setting is on do you output.
#   The name of the caller function only if it is not the same calling function as the previous one
#   followed by a nicely indented set of sentences
# Notes
#   the output is sent to stderr so as not to conflict with the echo-return of functions
gotoh_verbose() {
	if [ "$GOTO_VERBOSE_SETTING" = "on" ]
	then
		local calling_function
		calling_function="${FUNCNAME[1]}"
		# if the calling function isn't the same as before, then print it. Else don't.
		if [ "${GOTO_CALLING_FUNCTION}" != "${calling_function}" ]
		then 
			if [ "$calling_function" != "source" ]; then
				>&2 echo "$calling_function:"
			else
				>&2 echo "$gotov_filename:"
			fi
		fi
		# nicely print the sentence tokens
		local sentence
		for sentence in "$@"; do
			>&2 echo -e "  $sentence"
		done
		GOTO_CALLING_FUNCTION="${calling_function}"
	fi
}

# -- flgr --
# Simple flagger for debugging.
# Input: nothing
# Output: a simple flag with count, output to stderr
gotoh_flagger() {
	>&2 echo "Flag ${GOTO_FLAG_COUNTER}: ${@}"
	GOTO_FLAG_COUNTER=$(( GOTO_FLAG_COUNTER + 1 ))
}

# -- opvsn --
# output goto version and build
gotoh_version() { 
	>&2 echo "${gotov_semver%%+*}"
	>&2 echo "build metadata: ${gotov_semver##*+}"
}

# -- opttl --
# output goto title screen
gotoh_title() {
	title='goto: a command-line shortcuts manager'
	author='by Q Zhang'
	location='Washington, D.C., USA'
	repo='repo: github.com/poiurewq/goto'
	cols=$( tput cols )
	clear
	echo; echo; echo
	printf "%*s\n" $(( (${#title} + cols ) / 2 )) "${title}"
	echo; echo; echo
	printf "%*s\n" $(( (${#author} + cols ) / 2 )) "${author}"
	echo; echo; echo
	printf "%*s\n" $(( (${#location} + cols ) / 2 )) "${location}"
	echo; echo; echo
	printf "%*s\n" $(( (${#repo} + cols ) / 2 )) "${repo}"
	echo; echo; echo
}


# -- simusg --
# simple usage output
gotoh_usage() {
	>&2 cat <<GOTO_USAGE

goto: shortcuts to files, directories, and links.

version: ${gotov_semver%%-*}

usage: goto [keywords]

  examples: 
    goto goto   # goes to goto.sh
    goto keys   # goes to goto.json

usage: goto -b

for more details, see 'goto --help'

GOTO_USAGE
}

# -- dtusg --
# detailed usage output
gotoh_detailed_usage() {
	less <<GOTO_DETAILED_USAGE

goto: maintain and open shortcuts to files, directories, and links.

version: ${gotov_semver%%-*}
author:  Q Zhang

normal usage: goto [keywords]

  examples: 
    goto goto   # opens goto.sh
    goto keys   # opens goto.json

  normal usage is non-interactive

CRUD usage: goto [options]

  convention:
    shortcut = a keyword sequence leading to a shortcut
    setting  = a keyword leading to a setting
    keywords = multiple keywords separated by the '|' character
    parent   = 'root' | shortcut
               'root' is the default root of all shortcuts.

  non-interactive options:
    -c | --create  -k 'keywords' -d 'description' -t 'type' -n 'destination' -under parent
    -cd| --create-directory -k 'keywords' -d 'description' -under parent
    -r | --read   [-sc] shortcut
		-r | --read    -st  setting
    -u | --update  -k 'keyword'     -of shortcut
    -u | --update  -d 'description' -of shortcut
    -u | --update  -t 'type'        -of shortcut
    -u | --update  -n 'destination' -of shortcut
    -d | --delete  shortcut
    -dr| --delete-recursive  shortcut
    -m | --move    shortcut -under parent (upcoming feature)
  
    examples:
      # create a shortcut to a journal folder with multiple keywords: j, J, and journal
        goto -c -k 'j|J|journal' -d 'Personal journal folder' -t d -n '/Users/demo/Documents/journals' -under shortcuts
      
      # delete the shortcut represented by the keyword 'keys' as well as its children.
        goto -dr 'keys'
  
  interactive options:
    -b | --browse [-sc]
    -b | --browse  -st
    -c | --create  -under  parent
    -cd| --create-directory  -under  parent
    -u | --update [-sc] shortcut
    -u | --update  -st  setting

    examples:
      # browse shortcuts. allows for interactive CRUD-ing.
        goto -b

other usage:
  goto --version         # display version and build   (non-interactive)
  goto --factory-setting # reset to factory setting    (interactive)
  goto --title           # display a nice title screen (non-interactive)

GOTO_DETAILED_USAGE
}

# == extracting delimited strings xtrs ==
# Input
#   $1 = a string
#   $2 = the delimiter by which to chop up the string
#   $3 = 0-based index of the substring to extract
# Output
#   echo: the appropriate substring
gotoh_extract_substring() {
	local string="$1"
	IFS="$2"
	local index="$3"
	local substring_array
	read -r -a substring_array <<< "$string"
	unset IFS
	echo "${substring_array[index]}"
}

#################################################
## definitions for first-time bootstrap ftbtdf ##
#################################################

# == session bootstrap variable definitions ssbtvdef ==
# -- plpvdef --
# autoplop variable definitions
gotov_current_filepath="${BASH_SOURCE[0]}"
gotov_filename="$( basename ${gotov_current_filepath} )"
if [ -z "$gotov_filename" ]
then
	return $gotocode_var_empty
fi

gotov_dest_dirpath=~/".goto"
gotov_dest_filepath="$gotov_dest_dirpath/$gotov_filename"

# -- alsvdef --
# alias setting variable definitions
gotov_alias_filepath=~/".bash_profile"
gotov_alias_description="# define an alias for the goto.sh custom script"
gotov_alias_definition="alias goto='source ${gotov_dest_filepath}'"

# == first-time bootstrap confirmation ftbtconf ==
# FIRSTTIME=TRUE
# Check for first time.
#   If first time, ask user for confirmations, then set first time to false. Else skip.
# This subroutine is obligatorily interactive.
gotov_firsttime_status=false
gotov_firsttime_line="$( grep -n "[F]IRSTTIME=TRUE" "${gotov_current_filepath}" )"
if [ $? -eq 0 ]
then
	# Set first-time flag to true, so normal goto proper won't be carried out.
	gotov_firsttime_status=true
	# Ask user for confirmations
	# Confirmation for destination directory
	gotoh_output "The destination directory for this script and its settings is set to '$gotov_dest_dirpath'." "  If you'd like to change it, type 'n', then go into the script and change the variable named '\$gotov_dest_dirpath'" "  Otherwise, type 'y' to leave it as-is."
	read -p "y/n: " gotolv_confirm_dest_dirpath
	if [ "$gotolv_confirm_dest_dirpath" = "y" ]
	then
		:
	else
		gotoh_output "goto.sh execution ended. Please edit the field and try again."
		return
	fi

	# Confirmation for alias settings file
	gotoh_output "The file where you define aliases is set to '$gotov_alias_filepath." "  If you'd like to change it, type 'n', then go into the script and change the variable named '\$gotov_alias_filepath'" "  Otherwise, type 'y' to leave it as-is."
	read -p "y/n: " gotov_confirm_alias_filepath
	if [ "$gotov_confirm_alias_filepath" = "y" ]
	then
		:
	else
		gotoh_output "goto.sh execution ended. Please edit the field and try again."
		return
	fi

	# Replace first-time encoding field with 'FALSE'
	gotov_firsttime_line="${gotov_firsttime_line%:#*}" # remove the non-line_num portion of the grep result
	gotolv_firsttime_false_string='# FIRST'
	gotolv_firsttime_false_string+='TIME'
	gotolv_firsttime_false_string+='=FALSE'
	sed -i '' "${gotov_firsttime_line}s/.*/${gotolv_firsttime_false_string}/" "${gotov_current_filepath}"
fi
unset -v $( compgen -v | grep "gotolv" )

################################################
## definitions for every-run bootstrap evbtdf ##
################################################

# == reset to factory setting fcst ==
# Input: none
# Output: none
# Behavior: removes goto.json and sets first time to true again.
gotoh_factory_setting() {
	# prompt user for confirmation
	local confirm_reset
	gotoh_output "Resetting goto to its factory setting will destroy all your shortcuts and reset your settings." "Do you confirm?"
	read -p "y/n: " confirm_reset
	# if yes
	if [ "$confirm_reset" = "y" ]
	then
		# get rid of goto.json
		rm "${gotov_json_filepath}"

		# change goto.sh's first time setting back to true
		# identify first time line
		local firsttime_line="$( grep -n "[F]IRSTTIME=FALSE" "${gotov_current_filepath}" )"
		if [ $? -ne 0 ]
		then
			gotoh_output "goto is already at its factory setting." "This is impossible." "Please report this bug to us."
			return $gotocode_unknown
		fi
		# reset to true
		firsttime_line="${firsttime_line%:#*}" # remove the non-line_num portion of the grep result
		local first_time_true_string='# FIRST'
		first_time_true_string+='TIME'
		first_time_true_string+='=TRUE'
		sed -i '' "${firsttime_line}s/.*/${first_time_true_string}/" "${gotov_current_filepath}"
		gotoh_output "This program has been reset to factory setting."
		return $gotocode_success

	# cancel reset.
	else
		gotoh_output "Reset cancelled."
		return $gotocode_reset_cancelled
	fi
}

# == autoplop onto destination directory atplp ==
# -- plpfdef --
# autoplop: script automatically plops itself into a hard-coded destination directory.
gotoh_autoplop() {
	# obtain starting filepath & filename
	local starting_filepath="${BASH_SOURCE[0]}"
	# create hard-coded destination dir
	if ! [ -d "$gotov_dest_dirpath" ]
	then
		mkdir -p "$gotov_dest_dirpath"
	fi
	# copy itself over.
	cat "$starting_filepath" > "$gotov_dest_filepath"
	# notify user
	gotoh_output "$starting_filepath" "  copied to" "$gotov_dest_filepath" "You can now safely delete this file from the current directory."
}

# -- plpalg --
# if destination filepath doesn't exist, autoplop; else, if exists but differentfrom this one, ask user if want to update, and update if so.
# this subroutine is obligatorily interactive
if ! [ -f "$gotov_dest_filepath" ]
then
	gotoh_autoplop
else
	gotolv_starting_filepath="${BASH_SOURCE[0]}"
	cmp -s "$gotolv_starting_filepath" "$gotov_dest_filepath"
	if [ "$?" -ne 0 ]
	then
		gotoh_output "The current script is different from the existing script." "Would you like to replace the destination script?"
		read -p "y/n: " gotolv_replace
		if [ "$gotolv_replace" = y ]
		then
			gotoh_autoplop
		else
			gotoh_output "The current script will not replace the existing script."
		fi
	fi
	# else, they're the same, so don't do anything.
	# unset some 'local' variables
	unset -v $( compgen -v | grep "gotolv" )
fi

# == append alias definition to the alias definition file alsalg ==
# see if bash profile exists. if not, create one.
if ! [ -f "$gotov_alias_filepath" ]
then
	touch "$gotov_alias_filepath"
fi

# search bash profile for the alias definition.
#   if found, then skip. if not found, then add.
tmptrash="$(grep "$gotov_alias_definition" "$gotov_alias_filepath")"
if [ $? -ne 0 ]
then
	echo >> "$gotov_alias_filepath"
	echo "$gotov_alias_description" >> "$gotov_alias_filepath"
	echo "$gotov_alias_definition" >> "$gotov_alias_filepath"
	# notify user
	gotoh_output "The alias 'goto' has been added to $gotov_alias_filepath" "Restart the shell for this alias to take effect."
fi 
unset tmptrash

# == check dependencies chkdep ==
# -- check that we have jq chkjq --
tmptrash="$(type jq)"
if [ $? -ne 0 ]
then
	gotoh_output "You do not yet have jq installed. Please install jq." \
		"If you are on a Mac, Homebrew is a great way to install it."
	return $gotocode_missing_dependency
fi
unset tmptrash

# -- check that we have rlist chkrl --
# tmptrash="$(type rlist)"
# if [ $? -ne 0 ]
# then
	# gotoh_output "You do not yet have rlist installed. Please install rlist."
	# return $gotocode_missing_dependency
# fi
# unset tmptrash

# == set up variables for settings gtstvrs ==
# an array of settings keywords, descriptions, and contents
gotov_settings_keywords=()
gotov_settings_descriptions=()
# each setting has its own semicolon-delimited string for its options
gotov_settings_options=()
# this is the array for the actual contents to initial each setting to
gotov_settings_contents=()

# set up individual settings indices
#   a bunch of settings keyword indices: used in keywords array and in actual settings json

# multipath: setting for when to display the paths when a search returns multiple paths.
#   always: always show the paths and go no further.
#   depth >= n: if all matches have a depth greater than or equal to n (with parent-child being depth of 1), then show the paths and go no further. 
#     the simultaneous assumption is that, if there is exactly one match with depth less than n, then go there. if there are multiple matches with depth less than n, then still display the paths.
#   default is 'depth >= 2', which means if we have a single [depth = 1] match, we go there. else we show paths and quit.
gotov_multipath=0
gotov_settings_options[gotov_multipath]="always;depth >= [n]"
gotov_settings_keywords[gotov_multipath]="multipath"
gotov_settings_descriptions[gotov_multipath]="When multiple matches are found, this setting determines whether to display all matches and quit, or pick one match and go. 'depth >= n' means: if there is a single match at depth < n, pick it and go; else display all matches and quit. 'always' is effectively 'depth >= n' where n is infinity."
# default: depth >= 2
gotolv_multipath_initial_content="$( gotoh_extract_substring "${gotov_settings_options[gotov_multipath]}" ';' "1" )"
gotov_settings_contents[gotov_multipath]="${gotolv_multipath_initial_content/\[n\]/2}"

# jsonPartialMatch: setting for whether to directly go if only a part of the keyword sequence matches in keywords tree
#   on means go to match even for partial match. if there's no match at all, then quit and don't continue to find.
# 	off implies continue to find if no match or partial match.
#   default is 'off', so we continue to find if no match.
gotov_jsonPartialMatch=1
gotov_settings_options[gotov_jsonPartialMatch]="on;off"
gotov_settings_keywords[gotov_jsonPartialMatch]="jsonPartialMatch"
gotov_settings_descriptions[gotov_jsonPartialMatch]="Whether to go to the match if only a part of the keyword sequence matches in the keywords tree, or to continue to find() with the rest of the keywords."
# default: off
gotov_settings_contents[gotov_jsonPartialMatch]="$( gotoh_extract_substring "${gotov_settings_options[gotov_jsonPartialMatch]}" ';' "1" )"

# filesystemPartialMatch: setting for whether to directly go if only a part of the keyword sequence matches when calling find() in filesystem
# 	on means goto match even for partial match (of any filetype), or for a find match that is a file (since it's terminal).
# 	off means quit if only partial match
#   default is 'on', so we go to partial match.
# default: on
gotov_filesystemPartialMatch=2
gotov_settings_options[gotov_filesystemPartialMatch]="on;off"
gotov_settings_keywords[gotov_filesystemPartialMatch]="filesystemPartialMatch"
gotov_settings_descriptions[gotov_filesystemPartialMatch]="Whether to go if only a part of the keyword sequence matches when calling find() in filesystem, or directly quit."
gotov_settings_contents[gotov_filesystemPartialMatch]="$( gotoh_extract_substring "${gotov_settings_options[gotov_filesystemPartialMatch]}" ';' "0" )"

# verboseOutput: setting for whether to output in a verbose manner to stderr. helpful for debugging.
#   on means turn on gotoh_output
#   off means turn off gotoh_output
#   default is 'off'
gotov_verboseOutput=3
gotov_settings_options[gotov_verboseOutput]="on;off"
gotov_settings_keywords[gotov_verboseOutput]="verboseOutput"
gotov_settings_descriptions[gotov_verboseOutput]="Whether to output details of the program to stderr. Helpful for debugging."
gotov_settings_contents[gotov_verboseOutput]="$( gotoh_extract_substring "${gotov_settings_options[gotov_verboseOutput]}" ';' "1" )"

# directoryOpener: setting for how to open directories.
#   cd: calls 'cd', so simply changes the directory.
#   system: calls the 'open' command, so the opener is system-dependent
#   default is 'cd'
gotov_directoryOpener=4
gotov_settings_options[gotov_directoryOpener]="cd;system"
gotov_settings_keywords[gotov_directoryOpener]="directoryOpener"
gotov_settings_descriptions[gotov_directoryOpener]="Determines how directories are opened."
gotov_settings_contents[gotov_directoryOpener]="$( gotoh_extract_substring "${gotov_settings_options[gotov_directoryOpener]}" ';' "0" )"


# linkOpener: setting for how to open links.
#   system: calls the 'open' command, so the opener is system-dependent
#   rlist: calls 'rlist', which is a custom script I use for tracking links.
#   default is 'system'
gotov_linkOpener=5
gotov_settings_options[gotov_linkOpener]="system;rlist"
gotov_settings_keywords[gotov_linkOpener]="linkOpener"
gotov_settings_descriptions[gotov_linkOpener]="Determines how links are opened."
gotov_settings_contents[gotov_linkOpener]="$( gotoh_extract_substring "${gotov_settings_options[gotov_linkOpener]}" ';' "0" )"

# == set up goto.json, also in destination directory stjs ==
gotov_json_filename="goto.json"
gotov_json_filepath="$gotov_dest_dirpath/$gotov_json_filename"

unset -v gotolv_multipath_initial_content

# if the json file exists, don't do anything. else, create one.
if ! [ -f "$gotov_json_filepath" ]
then
	# here, do some shenanigans to initialize the json file
	#   here we build the jq input string for the settings object
	gotolv_jq_init_settings='{keyword: "settings", description: "goto.sh settings", type: "t", content: null, list: ['
	gotolv_number_of_settings="${#gotov_settings_keywords[@]}"
	gotolv_last_setting_index=$(( gotolv_number_of_settings - 1 ))
	gotolv_jq_init_settings_separator=''
	for gotolv_each_setting_index in $( seq 0 ${gotolv_last_setting_index} )
	do
		gotolv_jq_init_settings+="${gotolv_jq_init_settings_separator}"
		gotolv_jq_init_settings+='{ keyword: '
		gotolv_jq_init_settings+="\"${gotov_settings_keywords[gotolv_each_setting_index]}\", "
		gotolv_jq_init_settings+='description: '
		gotolv_jq_init_settings+="\"${gotov_settings_descriptions[gotolv_each_setting_index]}\", "
		gotolv_jq_init_settings+='type: "s", '
		gotolv_jq_init_settings+='content: '
		gotolv_jq_init_settings+="\"${gotov_settings_contents[gotolv_each_setting_index]}\", "
		gotolv_jq_init_settings+='list: []}'
		gotolv_jq_init_settings_separator=","
	done
	gotolv_jq_init_settings+=']}'

	#   here we build the jq input string for the shortcuts object
	read -r -d '' gotolv_jq_init_shortcuts <<'EOF'
	{ keyword: "root", description: "root of all shortcuts", type: "t", destination: null, list: 
		[{ keyword: "goto", description: "The goto.sh file", type: "f", destination: $gtv_dest_filepath, list: 
			[{ keyword: "keys", description: "The goto.json file for keywords", type: "f", destination: $gtv_json_filepath, list: [] }]
		}]
	}
EOF

	#   here we assemble the final json format for the jq to read.
	gotolv_jq_init_input='['
	gotolv_jq_init_input+="${gotolv_jq_init_settings},"
	gotolv_jq_init_input+="${gotolv_jq_init_shortcuts}"
	gotolv_jq_init_input+=']'
	#   here we use jq -n --tab to construct json data, since it's built for json and easier to maintain.
	#     the $vars are jq vars, not bash vars (see jq command --arg to understand).
	gotov_json_init="$( jq -n --tab \
		--arg gtv_dest_filepath $gotov_dest_filepath \
		--arg gtv_json_filepath $gotov_json_filepath \
		"$gotolv_jq_init_input" )"
	echo "$gotov_json_init" >> "$gotov_json_filepath"
fi

# == set settings gtsts ==
# initialize individual settings
# obtain the settings object
gotov_settings_filter='.[0].list'
gotov_settings_array="$( jq -c "$gotov_settings_filter" "$gotov_json_filepath" )"

# obtain individual settings
gotov_multipath_setting="$( jq -nr "${gotov_settings_array}|.[]|select(.keyword==\"${gotov_settings_keywords[gotov_multipath]}\")|.content" )"
gotov_jsonPartialMatch_setting="$( jq -nr "${gotov_settings_array}|.[]|select(.keyword==\"${gotov_settings_keywords[gotov_jsonPartialMatch]}\")|.content" )"
gotov_filesystemPartialMatch_setting="$( jq -nr "${gotov_settings_array}|.[]|select(.keyword==\"${gotov_settings_keywords[gotov_filesystemPartialMatch]}\")|.content" )"
gotov_verboseOutput_setting="$( jq -nr "${gotov_settings_array}|.[]|select(.keyword==\"${gotov_settings_keywords[gotov_verboseOutput]}\")|.content" )"
gotov_directoryOpener_setting="$( jq -nr "${gotov_settings_array}|.[]|select(.keyword==\"${gotov_settings_keywords[gotov_directoryOpener]}\")|.content" )"
gotov_linkOpener_setting="$( jq -nr "${gotov_settings_array}|.[]|select(.keyword==\"${gotov_settings_keywords[gotov_linkOpener]}\")|.content" )"

# make necessary variable updates
GOTO_VERBOSE_SETTING="${gotov_verboseOutput_setting}"

######################################################
## check invariants before CRUD or goto main chkinv ##
######################################################
# == chkft ==
# check if it's the first time. only if not first time, continue.
if [ "$gotov_firsttime_status" = true ]
then
	gotoh_output "goto.sh first-time set-up complete." "Please restart the shell to use goto.sh."
	return $gotocode_success
fi

# == chkargs ==
# check arguments: we need at least one keyword
if [ $# -lt 1 ]
then
	gotoh_usage
	return $gotocode_success
fi
# some special options
case "$1" in
	--help)
		gotoh_detailed_usage
		return $gotocode_success
		;;
	--factory-setting)
		gotoh_factory_setting
		return $gotocode_success
		;;
	--version)
		gotoh_version
		return $gotocode_success
		;;
	--title)
		gotoh_title
		return $gotocode_success
		;;
esac

# == chkjsn ==
# -- chkfj --
# check that goto.json is found.
if ! [ -f "$gotov_json_filepath" ]
then
	gotoh_output "goto.json is not found." "Please follow these steps to fix:" "  Open goto.sh." "  On line ${gotov_firsttime_line}, change the value of 'FIRSTTIME' to 'TRUE'" "  Source goto.sh again."
	return $gotocode_file_not_found
fi

# -- chkvj --
# check that goto.json is valid json
tmptrash=$( jq '.' ${gotov_json_filepath} >/dev/null 2>&1 )
if [ $? -ne 0 ]
then
	gotoh_output "goto.json is invalid." "Please find goto.json in '${gotov_dest_dirpath}' and fix its syntax."
	return $gotocode_invalid_json
fi
unset -v tmptrash

###########################################################
## helpers used for both CRUD and goto functions hcrdgtof #
###########################################################

# == unset a single group of names nstnm ==
# Input
#   $1 = -v / -f
#     -v means variables
#     -f means functions
#   $2 = grep pattern used to match names
gotoh_unset() {
	# input vars
	local compgen_switch="$1"
	local grep_pattern="$2"
	# get names string and set unset command
	local names_string unset_command
	if [ "${compgen_switch}" = "-v" ]
	then
		names_string=$(compgen -v | grep "${grep_pattern}" | xargs)
		unset_command='unset -v'
	elif [ "${compgen_switch}" = "-f" ]
	then
		names_string=$(compgen -A function | grep "${grep_pattern}" | xargs)
		unset_command='unset -f'
	else 
		gotoh_verbose "Unknown compgen switch '${compgen_switch}'"
		return $gotocode_invalid_arg
	fi
	# parse names string as array
	local names names_last_index
	IFS=' '
	read -r -a names <<< "$names_string"
	unset IFS
	# iterate through names array to unset
	names_last_index="${#names[@]}"
	(( names_last_index -- ))
	local index
	for index in $(seq 0 ${names_last_index})
	do
		${unset_command} ${names[index]}
	done
	# unset -v $( compgen -v | grep "gotov" | xargs )
	# unset -f $( compgen -A function | grep "gotoh" | xargs )
}

# == minimize namespace pollution gtnst ==
# Input: none
# Output: none
# Behavior
#   unsets all potential namespace polluters from goto.sh
gotoh_unset_all() {
	gotoh_unset '-v' 'gotocode'
	# gotoh_unset '-v' 'gotolv' # don't unset this. make sure to unset these where they are used.
	gotoh_unset '-v' 'gotov'
	gotoh_unset '-f' 'gotoui'
	# make sure this is the last unset
	gotoh_unset '-f' 'gotoh'
}

# == print path ppth ==
# Input
#   $1: absolute path to a node
# Output
#   echo: a string of the form 'A -> B -> C' for the node, to stderr, NOT stdout
#   code: the length of the path
# Behavior
#   steps through starting from the respective root to the end, getting the .keyword for the nodes on the path.
# Invariants:
#   must be the absolute path, starting from the very root of goto.json
# Dependencies: none
gotoh_print_path() {

	# set input variable
	local absolute_path="$1"

	# step through the path and build the path string

	# get the length of the path
	#   build path length filter and get path length
	path_length="$( jq -n "${absolute_path}|length" )"
	# echo "Path length: ${path_length}" # diagnostic

	local path_display_string each_step_separator each_step
	# construct the path by following from root
	path_display_string=''
	#   separator
	each_step_separator=''
	#   increment two steps at a time through the path
	#     we start off at 1, because jq syntax .[:1] means up to but not including 1.
	for each_step in $(seq 1 2 ${path_length})
	do
		local each_step_keyword_filter each_step_keyword
		# get each step's keyword
		#   build filter for each step
		#   build filter for each step's keyword
		each_step_keyword_filter="getpath(${absolute_path}|.[:${each_step}])|.keyword"
		#   get the keyword & quit if encounter error
		each_step_keyword="$( jq -r "$each_step_keyword_filter" "${gotov_json_filepath}" )"
		if [ $? -ne 0 ]
		then
			gotoh_verbose "Failed to get the keyword using the filter '${each_step_keyword_filter}'"
			return $gotocode_print_path_failed
		fi
		# add the keyword to the path display string
		path_display_string+="${each_step_separator}"
		path_display_string+="${each_step_keyword}"
		each_step_separator=' -> '
	done
	# output the path
	echo "$path_display_string"
	# return the path length
	return $path_length
}

# == recursive json search rcsjs ==
# Input
#   $1: -st / -sc
#     -st means search in settings
#     -sc means search in shortcuts
#   ${@:2}: list of keywords
# Output
#   echo: 
#     If fully matched, then absolute path to the located node in goto.json
#     If partially matched with keywords, then regardless of partial setting, echo absolute path.
#     If first keyword not found, then nada
#     If multiple matches, then returns the string 'multiple'
#   code:
#     If fully, partially (regardless of partial setting), or not matched, then return the (0-based) index 
#     of the last unmatched keyword in the input keywords array ${@:2}. 
#       In other words, if given 5 keywords and all matched, 
#       then the code is 5. If 4 matched, then the code is 4 as that is
#       the index of the last unmatched keyword in the keywords array.
#     If multiple matches, return the number of matches.
# Invariants
#   has access to a properly initialized gotov_json_filepath
#   has access to a properly initialized gotov_multipath_setting
#   the -st/-sc input is always in the first position.
# Dependencies
#   gotoh_output
# Behavior
#   searches for a particular node in settings or shortcuts that matches
#   the given keyword sequence A B C such that the path
#   A (-> ...) -> B (-> ...) -> C goes to the shortcut.
#   returns according to Output specified above
gotoh_recursive_json_search() {

	# set up input variables
	local subset_option="$1"
	
	# process the subset option and build initial filter
	local current_objects_filter=''
	if [ "$subset_option" = "-st" ]
	then
		current_objects_filter+='.[0]'
	elif [ "$subset_option" = "-sc" ]
	then
		current_objects_filter+='.[1]'
	else
		gotoh_verbose "Unknown subset option '${subset_option}'"
		return $gotocode_invalid_arg
	fi

	# set up variables for the json recursive search loop
	local keywords=( "${@:2}" )
	local number_of_keywords=${#keywords[@]}
	local current_unmatched_keyword_index=0
	local last_match_absolute_path=''
	local keywords_examined=0

	# loop over the keywords
	while [ $current_unmatched_keyword_index -lt $number_of_keywords ]
	do
		# = count matches jscm =
		# grab current keyword
		local current_keyword="${keywords[current_unmatched_keyword_index]}"

		# jq search for object(s) matching keyword
		#   build (inner) object filter
		#     note that \\\\ becomes \\ in the regex, which is then used to escape the pipe: \\|
		current_objects_filter+="|recurse(.list[]?)|select(.keyword|test(\"^(.*\\\\|)?${current_keyword}(\\\\|.*)?$\"))"
		# echo "${current_objects_filter}" # checkpoint

		# count number of matches
		#   count matches
		local current_number_of_matches="$( jq "[${current_objects_filter}]|length" "${gotov_json_filepath}" )"

		# = if-else over match count jsmc =
		# - 0 matches jsnm -
		# if no match, then check
		#   if there was a match in the previous sequence, decide whether to go to partial match according to
		#   jsonPartialMatch setting or quit.
		if [ "${current_number_of_matches}" -eq 0 ]
		then
			keywords_examined=$((current_unmatched_keyword_index + 1))
			local current_keyword_sequence="${keywords[@]:0:${keywords_examined}}"
			gotoh_verbose "We did not find any match for the keyword sequence '${current_keyword_sequence// / -> }' in goto.json" # diagnostic
			
			# if keyword sequence is longer than 1, that means we had a partial match up to the previous keyword.
			# as long as there's a partial match, regardless of jsonPartialMatch setting, we'll echo the partially matched path.
			if [ $current_unmatched_keyword_index -gt 0 ]
			then
				# always return absolute path and unmatched keyword index.
				local current_unmatched_keyword_sequence="${keywords[@]:0:${current_unmatched_keyword_index}}"
				gotoh_verbose "However, we were able to match up to '${current_unmatched_keyword_sequence// / -> }'." # diagnostic
				echo "${last_match_absolute_path}"
				return $current_unmatched_keyword_index
			fi
			
			# else, this means even the first keyword wasn't matched, so we return unmatched index without echoing an absolute path
			return $current_unmatched_keyword_index

		# - single match jssm -
		# elif single match, update absolute path and let the loop continue building the filter on the next iteration.
		elif [ "${current_number_of_matches}" -eq 1 ]
		then
			# get object for future use
			#   get absolute path
			# >&2 echo "path(${current_objects_filter})|.[0]" # diagnostic
			last_match_absolute_path="$( jq "path(${current_objects_filter})" "${gotov_json_filepath}" )"

		# - multiple matches jsmm -
		# elif multiple matches, depending on multipath setting, directly return absolute path or print all paths and quit.
		#   also, no matter what, we MUST echo either 'multiple' or an absolute path from any exit under this condition
		elif [ "${current_number_of_matches}" -gt 1 ]
		then
			# check multipath setting
			local print_all_paths=false

			#   if always, then show
			if [ "$gotov_multipath_setting" = "always" ]
			then
				echo 'multiple'
				print_all_paths=true
			#   else, examine the depths according to the rule (see multipath setting description)
			else
				# process the depth setting
				local multipath_setting_depth="${gotov_multipath_setting/depth >= /}"
				local path_length_threshold=$(( multipath_setting_depth * 2 ))

				# count the number of paths that are below threshold
				#   build a jq filter that determines the number of paths of length < 2n (depth = n)
				local under_threshold_path_count_filter="[path(${current_objects_filter})]|map(select(length<${path_length_threshold}))|length"
				# echo "$under_threshold_path_count_filter" # diagnostic
				#   count the number of paths (matches) that are below the depth threshold
				local under_threshold_path_count="$( jq "${under_threshold_path_count_filter}" "${gotov_json_filepath}" )"

				# if-else condition over the number of paths under the threshold (candidate paths to return)
				# if no match, display all paths
				if [ "$under_threshold_path_count" -eq 0 ]
				then
					echo 'multiple'
					print_all_paths=true

				# elif exactly one match, return it
				elif [ "$under_threshold_path_count" -eq 1 ]
				then
					local under_threshold_single_match_path_filter="[path(${current_objects_filter})]|map(select(length<${path_length_threshold}))|.[0]"
					local under_threshold_single_match_path="$( jq "${under_threshold_single_match_path_filter}" "${gotov_json_filepath}" )"
					echo "${under_threshold_single_match_path}"
					return $current_unmatched_keyword_index

				# elif more than one match, display all paths
				elif [ "$under_threshold_path_count" -gt 1 ]
				then
					echo 'multiple'
					print_all_paths=true

				# else, impossible match count
				else
					keywords_examined=$((current_unmatched_keyword_index + 1))
					local current_keyword_sequence="${keywords[@]:0:${keywords_examined}}"
					gotoh_verbose "Impossible number of under-threshold matches '${under_threshold_path_count}' reached for the keyword sequence '${current_keyword_sequence// / -> }.'" "Please report this bug to us."
					echo 'multiple'
					return $current_number_of_matches
				
				# end if-else condition on number of paths within threshold, under the multipath condition
				fi 
			
			# end if-else condition on multipath setting being "always" or not
			fi

			# note that we are still under the multipath setting right now.
			# if we confirm that multiple paths satisfy the criteria in the multipath setting, we display the paths and quit.
			if [ "$print_all_paths" = true ]
			then
				# display keyword sequence thus far.
				keywords_examined=$((current_unmatched_keyword_index + 1))
				current_keyword_sequence="${keywords[@]:0:${keywords_examined}}"
				gotoh_verbose "We found multiple matches for the keyword sequence '${current_keyword_sequence// / -> }'" "The path to each match is shown below."

				# for each match, output its path
				local each_match
				for each_match in $(seq $current_number_of_matches)
				do
					# build path filter
					local each_match_index each_path_filter each_path_length
					#   get the index number of each match
					each_match_index=$((each_match - 1))
					#   build path filter
					each_path_filter="[path(${current_objects_filter})]|.[${each_match_index}]"
					local each_absolute_path each_path_display_string
					#   get each absolute path
					each_absolute_path="$( jq "${each_path_filter}" "${gotov_json_filepath}" )"
					each_path_display_string="$( gotoh_print_path "${each_absolute_path}" )"
					# output the path
					gotoh_output "Match ${each_match}:" "  ${each_path_display_string}"
				done
				# suggest what to do next.
				gotoh_verbose "Please improve your query to narrow down to a unique match."
				# return
				return $current_number_of_matches

			# else, show paths remains false, yet we haven't processed it
			else
				gotoh_verbose "For some reason, we are told not to show the paths, yet we also haven't returned some single path." "This shouldn't happen." "Please report this bug to us."
				return $gotocode_unknown
			
			# end display paths condition
			fi 
		# else, we have a negative number of matches of the keyword sequence.
		else
			gotoh_verbose "For some reason, we found '${current_number_of_matches}' matches, which shouldn't happen."
			return $gotocode_impossible_match_count_json
		fi

		# as the last step of our keyword sequence loop, increment keyword index
		(( current_unmatched_keyword_index ++ ))
	done

	# if all keywords have been successfully matched, return the absolute path
	if [ "$current_unmatched_keyword_index" -ge "$number_of_keywords" ]
	then
		echo "$last_match_absolute_path"
		return $current_unmatched_keyword_index
	fi
}

# == helpers for main goto ui algorithm hgtalg ==
# These guys are used in browse, so come before the CRUD helpers.

# -- open the specified destination opdest --
# helper doesn't check for proper input. maintain good calling etiquette.
# Input
#   $1 = type code: consistent with the .type field (all except 't')
#     d = directory
#     f = file
#     l = link
#   $2 = destination: consistent with the .destination field
# Output: none
# Behavior
#   goes to the destination specified by the inputs
#   certain settings can change how the destinations are opened.
# Invariants
#   the inputs are properly given
# Dependencies: none
gotoh_go() {
	local type="$1"
	local destination="$2"
	case "$type" in
		d)
			if ! [ -d "$destination" ]
			then
				gotoh_verbose "Destination dir '$destination' not found."
			fi
			case "$gotov_directoryOpener_setting" in
				cd) cd "$destination" ;;
				system) open "$destination" ;;
				*) gotoh_output "Unknown directory opener setting '${gotov_directoryOpener_setting}'" ;;
			esac
			;;
		f)
			if ! [ -f "$destination" ]
			then
				gotoh_verbose "Destination file '$destination' not found."
			fi
			case "$destination" in
				*.md|*.json|*.sh) vim "$destination" ;;
				*) open "$destination" ;;
			esac
			;;
		l) 
			case "$gotov_linkOpener_setting" in
				system)
					local link_regex='^https?://' link_prefix='https://'
					# if the destination isn't linked, add a prefix
					if ! [[ "$destination" =~ $link_regex ]]
					then
						destination="${link_prefix}${destination}"
					fi
					# open the link
					open "${destination}"
					;;
				rlist)
					rlist go "$destination" 
					;;
			esac
			;;
		*)
			gotoh_verbose "Unknown type '$type'. We do not know how to open corresponding destination."
			return $gotocode_unknown_type
			;;
	esac
	# Do not use gotoh_verbose for this. This is so that verbose setting doesn't affect this.
	echo "$destination"
}

# -- open the destination at the end of the absolute path opabsp --
# Input
#   $1 = jq-style absolute path to access the shortcut to open
# Output: none
# Behavior
#   opens the destination specified at the absolute path in goto.json
# Invariants
#   assumes that the absolute path is a valid shortcut
#   assumes ability to access gotov_json_filepath
# Dependencies
#   gotoh_go
gotoh_open_path() {
	# get the input path
	local absolute_path="$1"

	# get the object
	local object_to_open="$( jq -c "getpath(${absolute_path})" "${gotov_json_filepath}" )"

	# obtain the last match's relevant fields
	local description="$( jq -nr "${object_to_open}|.description" )"
	local type="$( jq -nr "${object_to_open}|.type" )"
	local destination="$( jq -nr "${object_to_open}|.destination" )"
	
	# if type is topic, stop here. else continue to open destination.
	if [ "$type" = "t" ]
	then
		gotoh_verbose \
			"The topic '${description}'" \
			"has no associated destination."
		gotoh_output "Cannot open a topic."
		return $gotocode_cannot_goto_topic
	fi

	# display the last match's description
	echo "${description}"

	# based on the type and destination, go there
	gotoh_go "$type" "$destination"
}


######################################################
## helpers for CRUD user interface functions hcrui ##
######################################################

# These are all basic helpers for CRUD json editing. 
# They are non-interactive.

# == overwrite json ovwjsn ==
# Input
#   $1 = a string representing the jq command that updates the goto.json. 
#   $2 = an optional number to set as the threshold for change being too large
# Output
#   echo: nothing
#   code: 0 for success; 1 for jq error; 2 for change being too dramatic.
# Behavior
#   Performs in-place editing of the goto.json file.
#   Also performs a sanity check (line number difference no greater than 6) to make sure the edit isn't too dramatic.
gotoh_overwrite_json() {
	# set up input variable
	local update_instruction="$1"
	local optional_threshold="$2"
	
	# update threshold if optional is given
	local difference_too_large_threshold=8
	if ! [ -z "$optional_threshold" ]
	then
		difference_too_large_threshold="$optional_threshold"
	fi
	
	# make the updates
	local tmp_json=$(mktemp)
	jq "$update_instruction" "${gotov_json_filepath}" > "$tmp_json" || return 1
	# count the lines
	local original_wcl original_line_count new_wcl new_line_count difference
	original_wcl="$( wc -l "${gotov_json_filepath}" | tr -d ' ' )"
	original_line_count="${original_wcl%%/*}"

	new_wcl="$( wc -l "${tmp_json}" | tr -d ' ' )"
	new_line_count="${new_wcl%%/*}"
	
	# calculate the absolute difference
	difference="$(( original_line_count - new_line_count ))"
	difference="${difference#-}" 

	# perform difference check: if > 8, then abort.
	if [ "$difference" -gt "$difference_too_large_threshold" ]
	then
		gotoh_verbose \
			"The jq edit, with a line count difference of ${difference}, was too dramatic." \
			"Aborting goto.json update."
		return 2
	fi

	# if difference check passed, update the actual file using mv,
	#   which is (possibly?) better than cat because it's atomic.
	mv "$tmp_json" "$gotov_json_filepath"
}

# == helper to create node hlpc ==
# Input
#   absolute path to parent
#   new node's keyword, description, type, and destination
# Output: none
# Behavior
#   Defaults to working with shortcuts, since you can only create shortcuts, not settings.
#   Creates a new shortcut node as a child of the parent
# Invariants
#   This function makes no assumptions about whether we're creating a new node under a shortcut or a setting.
# Dependencies
#   gotoh_overwrite_json, gotoh_output, gotoh_verbose
# This is a non-interactive helper function
# 'getpath([1, "list", 0, "list", 0, "list"])+=[{keyword:"fun",description:"fun things happened",type:"d",destination:"~",list:[]}]'
gotoh_create() {
	# set up input variables
	local absolute_path="$1"
	local keyword="$2"
	local description="$3"
	local object_type="$4"
	local destination="$5"

	# check that all inputs are provided
	if [ -z "$absolute_path" ] || 
		[ -z "$keyword" ] || 
		[ -z "$description" ] || 
		[ -z "$object_type" ] || 
		[ -z "$destination" ]
	then
		gotoh_verbose "Missing argument(s)."
		return $gotocode_invalid_arg
	fi

	# build a json object for the new node. remember to include the list.
	#   if destination is "null", we make it unquoted, so it's a json null.
	local new_node_object
	if [ "$destination" = "null" ]
	then
		new_node_object="{keyword:\"${keyword}\",description:\"${description}\",type:\"${object_type}\",destination:${destination},list:[]}"
	else
		new_node_object="{keyword:\"${keyword}\",description:\"${description}\",type:\"${object_type}\",destination:\"${destination}\",list:[]}"
	fi
	
	# augment the absolute path with "list" to access the parent's list
	# this is an important technique
	local list_absolute_path="$( jq -c '.+=["list"]' <<< "$absolute_path" )"

	# build a filter to append the new json object to the parent's list
	local append_object_to_list="getpath(${list_absolute_path})+=[${new_node_object}]"

	# send the filter to the overwrite command to update the json.
	local overwrite_code
	gotoh_overwrite_json "${append_object_to_list}"
	overwrite_code=$?
	if [ $overwrite_code -eq 2 ]
	then
		gotoh_output "Failed to overwrite json due to change being too large."
		return $gotocode_overwrite_failed
	elif [ $overwrite_code -ne 0 ]
	then
		gotoh_output "Failed to overwrite json."
		return $gotocode_overwrite_failed
	# if successful, return success
	else
		return $gotocode_success
	fi
}

# == helper to read node hlpr ==
# This is a non-interactive helper function
# Input
#   $1 = -sc / -st
#   $2 = absolute path to node
# Output
#   neat print of node's information.
# Behavior
#   grabs object at path
#   prints information 
#     shortcuts and settings have the same fields besides content/destination
# Invariants
#   assumes absolute path is valid (doesn't check)
#   the object has the correct keys
# Dependencies: none
gotoh_read() { 
	# set up input variables
	local subset_option="$1"
	local absolute_path="$2"

	# make sure subset option is valid
	if [ "$subset_option" != "-sc" ] && [ "$subset_option" != "-st" ]
	then
		gotoh_verbose "Invalid subset option '${subset_option}'"
		return $gotocode_invalid_arg
	fi

	# grab object at path
	local object_to_read
	object_to_read="$( jq -c "getpath(${absolute_path})" "${gotov_json_filepath}" )"

	# = print object nicely =
	# get keyword, description, type
	local keyword="$( jq -nr "${object_to_read}|.keyword" )"
	local description="$( jq -nr "${object_to_read}|.description" )"
	local object_type="$( jq -nr "${object_to_read}|.type" )"
	#   update description to encompass the type
	description="<${object_type}> ${description}"
	# get destination / content. note we're leaving these guys quoted.
	local content
	if [ "$subset_option" = "-sc" ]
	then
		content="$( jq -n "${object_to_read}|.destination" )"
	else # -st
		content="$( jq -n "${object_to_read}|.content" )"
	fi

	# prepare the lines to print
	#   first get the number of columns
	local columns="$( tput cols )"
	#   next center-print the keyword line
	#     credit to https://superuser.com/questions/823883/how-to-justify-and-center-text-in-bash
	printf "%*s\n" $(( (${#keyword} + columns) / 2)) "$keyword"
	#   next center-print each segment of the description, with each segment no wider than columns - 8
	local total_description_length=${#description}
	local description_width=$(( columns - 8 ))
	local current_description_segment=''
	local current_description_segment_starting_index=0
	while [ $current_description_segment_starting_index -lt $total_description_length ]
	do
		current_description_segment="${description:${current_description_segment_starting_index}:${description_width}}"
		printf "%*s\n" $(( (${#current_description_segment} + columns) / 2)) "$current_description_segment"
		current_description_segment_starting_index=$(( current_description_segment_starting_index + description_width ))
	done
	#   finally center-print the destination / content, if it's not null of course.
	if [ "$content" != "null" ]
	then
		printf "%*s\n" $(( (${#content} + columns) / 2)) "$content"
	fi
}

# == helper to update node hlpu ==
# This is a non-interactive helper function
# Input
#   $1 = -sc / -st
#   $2 = absolute path
#   $3 = -k / -d / -t / -n
#   $4 = field content
# Output: none
# Behavior
#   Depending on the subset option, updates one of 
#     keyword (-k), description (-d), type (-t), or destination / content (-n)
#     of the node specified by the absolute path.
# Invariants
#   Takes exactly four arguments.
#   Assumes that the provided k/d/t/n is of the correct format and content 
#     (i.e., gotoui_update has checked them already)
#   Assumes that the node specified by the absolute path has the appropriate field.
# Dependencies
#   gotoh_overwrite_json
# 'setpath([1, "list", 0, "list", 0, "keyword"]; "keyss")'
gotoh_update() {
	# check invariant
	if [ $# -ne 4 ]
	then
		gotoh_verbose "Provide exactly 4 arguments."
		return $gotocode_invalid_arg
	fi
	# set input variables
	local subset_option="$1"
	local absolute_path="$2"
	local field_specifier="$3"
	local field_content="$4"
	# check invariant over the subset option
	if [ "$subset_option" != "-sc" ] && [ "$subset_option" != "-st" ]
	then
		gotoh_verbose "Invalid subset option '${subset_option}'"
		return $gotocode_invalid_arg
	fi
	# construct the path_to_field
	local path_to_field
	#   if-else on the field_specifier to build the path_to_field
	case "$field_specifier" in
		-k) 
			path_to_field="$( jq -c '.+=["keyword"]' <<< "$absolute_path" )"
			;;
		-d) 
			path_to_field="$( jq -c '.+=["description"]' <<< "$absolute_path" )"
			;;
		-t) 
			path_to_field="$( jq -c '.+=["type"]' <<< "$absolute_path" )"
			;;
		-n) 
			# for the destination / content, if-else on the subset option
			# -sc: destination
			if [ "$subset_option" = "-sc" ]
			then
				path_to_field="$( jq -c '.+=["destination"]' <<< "$absolute_path" )"
			# -st: content
			else
				path_to_field="$( jq -c '.+=["content"]' <<< "$absolute_path" )"
			fi
			;;
		*) 
			gotoh_verbose "Unknown field specifier '$field_specifier'"
			return $gotocode_unknown
			;;
	esac
	# construct the update command
	local update_command
	#   if field_content is 'null', then don't quote null. 
	if [ "${field_content}" = "null" ]
	then
		update_command="setpath( ${path_to_field}; null )"
	#   else quote the content.
	else
		update_command="setpath( ${path_to_field}; \"${field_content}\" )"
	fi
	# run update command
	local overwrite_code
	gotoh_overwrite_json "${update_command}"
	overwrite_code=$?
	if [ $overwrite_code -eq 2 ]
	then
		gotoh_output "Failed to overwrite json due to change being too large."
		return $gotocode_overwrite_failed
	elif [ $overwrite_code -ne 0 ]
	then
		gotoh_output "Failed to overwrite json."
		return $gotocode_overwrite_failed
	# if successful, return success
	else
		return $gotocode_success
	fi
}

# == helper to delete node hlpd ==
# This is a non-interactive helper function
# Input
#   $1 = absolue path to node to delete
# Output: none
# Behavior:
#   Regardless of whether the object has children, deletes it from json.
#   Determines the threshold for overwrite based on the size of the object to be deleted.
# Invariants
#   assumes the deletion is of a shortcut, not a setting
# Dependencies
#   gotoh_overwrite_json gotoh_verbose
gotoh_delete() {
	# set input variables
	local absolute_path="$1"
	# construct a deletion filter
	local deletion_filter="getpath(${absolute_path})|=empty"
	# count the expected number of lines to be deleted
	local expected_deleted_lines="$( jq "getpath(${absolute_path})" "${gotov_json_filepath}" | wc -l | tr -d ' ' )"
	(( expected_deleted_lines ++ ))
	# call overwrite to delete & process its return code
	local overwrite_code
	gotoh_overwrite_json "${deletion_filter}" "$expected_deleted_lines"
	overwrite_code=$?
	if [ $overwrite_code -eq 2 ]
	then
		gotoh_output "Failed to overwrite json due to change being too large."
		return $gotocode_overwrite_failed
	elif [ $overwrite_code -ne 0 ]
	then
		gotoh_output "Failed to overwrite json."
		return $gotocode_overwrite_failed
	else
		return $gotocode_success
	fi
}

# == helper to move node hlpm ==
# This is a non-interactive helper function
gotoh_move() { :; }

# == helper to print family (node and children) hlpf ==
# This is a non-interactive helper function
# Input
#   $1 = -sc / -st
#   $2 = absolute path to node
# Output
#   neat print of node's information as well as its children's keywords
# Behavior
#   grabs object at path
#   prints information of the node using gotoh_read
#   prints children keywords in a simple list
# Invariants
#   assumes absolute path exists
#   assumes object has the correct keys
# Dependencies
#   gotoh_read
# Useful for browse.
gotoh_print_family() { 
	# set up input variables
	local subset_option="$1"
	local absolute_path="$2"

	# make sure subset option is valid
	if [ "$subset_option" != "-sc" ] && [ "$subset_option" != "-st" ]
	then
		gotoh_verbose "Invalid subset option '${subset_option}'"
		return $gotocode_invalid_arg
	fi

	# calls read helper to print node
	gotoh_read "${subset_option}" "${absolute_path}"

	# get the children keywords in a single variable
	local children_keywords_filter="getpath(${absolute_path})|.list[]|.keyword"
	local children_keywords="$( jq -cr "${children_keywords_filter}" "${gotov_json_filepath}" | tr '\n' ';' )"

	# now children_keywords is multi-line. break it down into an array.
	local children_keywords_array=()
	IFS=';'
	read -r -a children_keywords_array <<< "${children_keywords}"
	unset IFS

	# count number of children
	local children_count="${#children_keywords_array[@]}"
	local children_count_string="< ${children_count} children >"
	
	# next, convert the array into a string for easier printing
	local children_keywords_string="${children_keywords_array[*]}"
	children_keywords_string="${children_keywords_string// /  }"

	# center-print the children keywords
	#   first get the number of columns
	local columns="$( tput cols )"
	#   center-print children count
	printf "%*s\n" $(( (${#children_count_string} + columns) / 2)) "${children_count_string}"
	#   next center-print the keywords
	printf "%*s\n" $(( (${#children_keywords_string} + columns) / 2)) "${children_keywords_string}"
}

###########################################
## CRUD user interface functions cruduif ##
###########################################

# == user interface function for creating a node crui ==
# create is a facultatively interactive function. it can be non-interactive as well.
# Input (interactive)
#   auto-directory mode
#     -dunder parent_keywords
#       in this option, auto-directory mode is turned on: automatically sets 
#       t = d and n = current working directory path
#   command-line mode
#     -under parent_keywords
#   browse mode
#     -browse absolute_path
#       in this option, browse mode is turned on: automatically sets 
#       the absolute path
# Input (non-interactive)
#   auto-directory mode
#     -dk keyword -d description -under parent_keywords
#       in this option, auto-directory mode is turned on: automatically sets 
#       t = d and n = current working directory path
#   command-line mode
#     -k keyword -d description -t type -n destination -under parent_keywords
# Output
#   nothing
# Behavior
#   creates the specified shortcut under a parent shortcut specified by parent_keywords
# Invariants
#   checks that all options are provided
#   assumes that the new node is under shortcuts, not settings
# Dependencies
#   gotoh_create, rcjs, gotoh_output, gotoh_verbose
gotoui_create() { 
	# check that we have first argument
	# parse arguments to determine whether we're in interactive mode
	local parent_keywords
	local space=' ' pipe_symbol='\|'
	# if nothing, then invalid
	if [ $# -lt 1 ]
	then
		gotoh_output "Not enough arguments for goto create." "Type 'goto --help' to check."
		return $gotocode_invalid_arg

	# elif -under or -dir or -browse, we're in interactive mode
	# = interactive mode =
	elif [ "$1" = "-under" ] || [ "$1" = "-dunder" ] || [ "$1" = "-browse" ]
	then
		# get some variables initialized outside of browse-mode if-else condition
		local auto_directory_mode
		local matched_absolute_path
	  
		# first process browse-interactive mode to see if rcjs can be skipped
		local absolute_path_is_ready
		#   if browse-interactive mode, then directly get the absolute path
		if [ "$1" = "-browse" ]
		then
			# arguments checkpoint: we need exactly 2 arguments
			if [ $# -ne 2 ]
			then
				gotoh_output "Incorrect number of arguments for browse-interactive creation." "The -browse option should not be entered from the command line."
				return $gotocode_invalid_arg
			fi
			matched_absolute_path="${2}"
			# check that the absolute path is jq-valid
			local tmptrash
			tmptrash="$( 2>&1 jq '.' <<< "${matched_absolute_path}" )"
			if [ $? -ne 0 ]
			then
				gotoh_verbose "Provided absolute path '${matched_absolute_path}' is not jq-compatible."
				gotoh_output "The -browse option should not be entered from the command line."
				return $gotocode_invalid_arg
			fi
			absolute_path_is_ready=true
		
		#   else, we're in command-line-interactive mode
		else
			# detect auto-directory mode
			#   if auto-directory mode, then set mode
			if [ "$1" = "-dunder" ]
			then
				auto_directory_mode=true
			#   if not auto-directory mode, then set mode
			else
				auto_directory_mode=false
			fi

			# arguments checkpoint: we need at least 2 arguments
			if [ $# -lt 2 ]
			then
				gotoh_output "Not enough arguments for interactive create." "Type 'goto --help' to check."
				return $gotocode_invalid_arg
			fi

			# set parent keywords
			parent_keywords=( "${@:2}" )

			# obtain rcjs outputs
			#   if parent shortcut isn't unique, quit. else continue to user input & creation.
			matched_absolute_path="$( gotoh_recursive_json_search -sc ${parent_keywords[@]} )"
			if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
			then
				gotoh_output "No unique match found for parent."
				return $gotocode_no_unique_match
			fi

			# get ready for absolute path
			absolute_path_is_ready=true
		# end if-else on browse-interactive mode
		fi
		
		# if absolute path ready from unique match or browse mode, then user input & create.
		if [ "$absolute_path_is_ready" = true ]
		then
			# begin user-facing prompting
			local keyword description object_type destination
			# let user now what they're doing
			local parent_keyword="$( jq -r "getpath(${matched_absolute_path})|.keyword" "${gotov_json_filepath}" )"
			local parent_description="$( jq -r "getpath(${matched_absolute_path})|.description" "${gotov_json_filepath}" )"
			if [ "$auto_directory_mode" = true ]
			then
				gotoh_output "Creating a new directory shortcut under ${parent_keyword}: ${parent_description}."
			else
				gotoh_output "Creating a new shortcut under ${parent_keyword}: ${parent_description}."
			fi
			
			# continually prompt user for more keywords
			local more_keywords=true
			local keyword_is_valid
			local pipe_separated_keywords='' keyword_separator=''
			while [ "$more_keywords" = "true" ]
			do
				# for each new keyword, make sure that it's valid before adding it
				keyword_is_valid=false
				while [ "$keyword_is_valid" = false ]
				do
					gotoh_output "Type a keyword, then [Enter]"
					read -p "Keyword: " keyword
					# if keyword is empty, it's not valid
					if [ -z "$keyword" ]
					then
						gotoh_output "This keyword is empty, so it's not valid."
					# elif keyword has a space or pipe in it, it's not valid.
					elif [[ "$keyword" =~ $space ]]
					then
						gotoh_output "This keyword has a space in it, so it's not valid."
					elif [[ "$keyword" =~ $pipe_symbol ]]
					then
						gotoh_output "This keyword has a pipe in it, so it's not valid."
					else
						# if keyword is duplicative, it's not valid
						local keywords_array keyword_occurrences
						IFS='|'
						read -a keywords_array <<< "$pipe_separated_keywords"
						unset IFS
						keyword_occurrences="$( echo "${keywords_array[@]}" | tr ' ' '\n' | grep -c "^${keyword}$" )"
						if [ "$keyword_occurrences" -gt 0 ]
						then
							gotoh_output "This keyword is duplicative, so it's not valid."
						else
							keyword_is_valid=true
						fi
					fi
				done
				pipe_separated_keywords+="${keyword_separator}"
				pipe_separated_keywords+="${keyword}"
				gotoh_output "Would you like to add another keyword?"
				read -p "y/n: " confirm_another_keyword
				# if anything but y, don't add another
				if [ "$confirm_another_keyword" != "y" ]
				then
					more_keywords=false
				fi
				keyword_separator='|'
			done
	
			# prompt for description
			gotoh_output "Type a description, then [Enter]"
			read -p "Description: " description

			# depending on auto-directory mode, either prompt for type & destination or directly set them
			# set type & destination
			if [ "$auto_directory_mode" = true ]
			then
				object_type='d'
				destination="$( pwd | tr -d '\n' )"

			# prompt for type & destination
			else
				# prompt for type code
				local type_is_valid=false
				while [ "$type_is_valid" = false ]
				do
					gotoh_output "Type a type code, then [Enter]"
					gotoh_output "Type codes:" \
						"  t = topic" \
						"  d = directory (or folder)" \
						"  f = file" \
						"  l = link"
					read -p "Type code: " object_type
					# only if it's valid do we change boolean to valid
					if [ "$object_type" = "t" ] || \
						[ "$object_type" = "d" ] || \
						[ "$object_type" = "f" ] || \
						[ "$object_type" = "l" ]
					then
						type_is_valid=true
					else
						gotoh_output "'${object_type}' is not a valid type code."
					fi
				done

				# prompt for destination
				if [ "$object_type" = "t" ]
				then
					gotoh_output "Since this is a topic, there is no associated destination."
					destination="null"
				else
					gotoh_output "Type a destination, then [Enter]"
					read -p "Destination: " destination
				fi
			# end if-else on auto-directory mode
			fi

			# confirm creation
			gotoh_output "Here are your fields:" \
				"Keyword(s):  ${pipe_separated_keywords}" \
				"Description: ${description}" \
				"Type code:   ${object_type}" \
				"Destination: ${destination}" \
				"Type y to confirm, anything else to cancel."
			local confirm_creation
			read -p "Confirm? " confirm_creation
			# actual creation
			if [ "$confirm_creation" = "y" ]
			then
				# create shortcut 
				gotoh_create "$matched_absolute_path" "$pipe_separated_keywords" "$description" "$object_type" "$destination" \
					&& gotoh_output "Successfully created shortcut '${pipe_separated_keywords}' under '${parent_keyword}'"
				return $gotocode_success
			else
				gotoh_output "Shortcut creation cancelled."
				return $gotocode_interactive_operation_cancelled
			fi
		fi

	# if not true, we're in non-interactive mode
	# = non-interactive mode =
	else
		# set up variables for later creation
		local keyword description object_type destination

		# check for auto-directory non-interactive mode and set variables
		# auto-directory mode
		if [ "$1" = "-dk" ]
		then
			# arguments checkpoint: we need at least 6 arguments and some of them need to be the right ones.
			if [ $# -lt 6 ]
			then
				gotoh_output "Not enough arguments for non-interactive create-directory." "Type 'goto --help' to check."
				return $gotocode_invalid_arg
			elif [ "$3" != "-d" ] || [ "$5" != "-under" ]
			then
				gotoh_output "Incorrect arguments for non-interactive create-directory." "Type 'goto --help' to check."
			fi
			# set input variables
			keyword="$2"
			description="$4"
			object_type='d'
			destination="$( pwd | tr -d '\n' )"
			parent_keywords=( "${@:6}" )

		# command-line mode
		else
			# arguments checkpoint: we need at least 10 arguments and some of them need to be the right ones.
			if [ $# -lt 10 ]
			then
				gotoh_output "Not enough arguments for non-interactive create." "Type 'goto --help' to check."
				return $gotocode_invalid_arg
			elif [ "$1" != "-k" ] || [ "$3" != "-d" ] || [ "$5" != "-t" ] || [ "$7" != "-n" ] || [ "$9" != "-under" ]
			then
				gotoh_output "Incorrect arguments for non-interactive create." "Type 'goto --help' to check."
			fi
			
			# set input variables
			keyword="$2"
			description="$4"
			object_type="$6"
			destination="$8"
			parent_keywords=( "${@:10}" )
		# end if-else on auto-directory check
		fi

		# do a keyword validity check.
		#   make sure keyword doesn't have space in it
		if [[ "$keyword" =~ $space ]]
		then
			gotoh_output "This keyword has a space in it, so it's not valid."
			return $gotocode_invalid_arg
		fi
		#   make sure keywords separated by pipes aren't duplicative
		IFS='|'
		local possibly_multiple_keywords number_of_keywords last_keyword_index
		read -a possibly_multiple_keywords <<< "$keyword"
		unset IFS
		number_of_keywords="${#possibly_multiple_keywords[@]}"
		last_keyword_index=$(( number_of_keywords - 1 ))
		local each_keyword_index each_keyword each_keyword_occurrences
		for each_keyword_index in $(seq 0 ${last_keyword_index} )
		do
			each_keyword="${possibly_multiple_keywords[each_keyword_index]}"
			each_keyword_occurrences="$( echo "${possibly_multiple_keywords[@]}" | tr ' ' '\n' | grep -c "^${each_keyword}$" )"
			if [ "$each_keyword_occurrences" -gt 1 ]
			then
				gotoh_output "The keyword '${each_keyword}' is duplicative," "so the overall keyword is not valid."
				return $gotocode_invalid_arg
			fi
		done

		#   make sure object_type is valid
		case "$object_type" in
			t|d|f|l) : ;;
			*) 
				gotoh_output "'${object_type}' is not a valid type code." 
				return $gotocode_invalid_arg
				;;
		esac

		# if type is t, then description is auto-set to null.
		if [ "$object_type" = "t" ]
		then
			gotoh_verbose "Since this is a topic, there is no associated destination."
			destination="null"
		fi
		
		# run rcjs to find parent shortcut.
		#   if parent shortcut isn't unique, quit. else continue to create.
		local matched_absolute_path
		matched_absolute_path="$( gotoh_recursive_json_search -sc ${parent_keywords[@]} )"
		if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
		then
			gotoh_output "No unique match found for parent."
			return $gotocode_no_unique_match
		
		# else, unique match, then create.
		else
			local matched_keyword_path="$( gotoh_print_path "${matched_absolute_path}" )"
			gotoh_create "$matched_absolute_path" "$keyword" "$description" "$object_type" "$destination" \
					&& gotoh_output "Successfully created shortcut '${matched_keyword_path} -> ${keyword}"
			return $gotocode_success
		fi
	
	# end if-else on interactive/non-interactive mode
	fi
}

# == user interface function for reading a node reui ==
# read is a non-interactive function
# Input
#   -sc / -st
#   keywords
# Output
#   if keywords don't match anything, let user know no match found.
#   if keywords match multiple, let user know multiple matches found.
#   if keywords match, print neatly formatted information of match
# Behavior
#   uses rcjs to search for match
#   output according to Output rules above
# Invariants
#   input must contain -sc / -st at the start
#   input must have at least one keyword
# Dependencies
#   rcjs, gotoh_read, gotoh_output, gotoh_verbose
gotoui_read() { 
	# set up input variable
	local subset_option="$1"

	# check subset_option invariants
	if [ -z "$subset_option" ]
	then
		gotoh_verbose "Missing option -sc / -st."
		return $gotocode_invalid_arg
	elif [ "$subset_option" != "-sc" ] && [ "$subset_option" != "-st" ]
	then
		gotoh_output "Invalid option '${subset_option}' for read." "Type 'goto --help' to check."
		gotoh_verbose "Option '${subset_option}' is neither -sc nor -st."
		return $gotocode_invalid_arg
	fi

	# check presence of at least a keyword
	if [ -z "$2" ]
	then
		gotoh_verbose "Missing keywords."
		return $gotocode_invalid_arg
	fi

	# obtain the keywords
	local keywords=( "${@:2}" )

	# send the keywords into rcjs to process
	local matched_absolute_path
	matched_absolute_path="$( gotoh_recursive_json_search "${subset_option}" "${keywords[@]}" )"

	# process the rcjs results
	# if not single match, then cannot read.
	if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
	then
		gotoh_output "No unique match found."
		return $gotocode_no_unique_match
	
	# else, single match, then read.
	else
		gotoh_read "${subset_option}" "$matched_absolute_path"
	fi
}

# == user interface function for updating a node upui ==
# update is a non-interactive function
# Input (interactive from command line)
#   $1       = [-sc] / -st
#   $2+      = keywords
# Input (interactive from browse)
#   $1       = -bsc / -bst
#   $2       = absolute path
# Input (non-interactive): only for shortcuts
#   $1       = field specifier: -k / -d / -t / -n
#   $2       = field content
#   $3       = -of
#   $4+      = keywords
# Output: none
# Behavior
#   If input starts with subset option, it's interactive. 
#     Search keywords and, if unique match, then interactively update content.
#       For shortcuts, user can type destination.
#       For settings, user must select from a set of predefined options.
#   If input starts with field specifier, it's non-interactive.
#     In this mode, user is assumed to be updating a shortcut specified by the keywords.
# Invariants
#   Non-interactive input
# Dependencies
#   gotoh_update, gotoh_recursive_json_search, gotoh_print_path
gotoui_update() {
	# check if input has at least one argument.
	if [ $# -lt 1 ]
	then
		gotoh_output "Provide at least one argument after '-u' for update." "Type 'goto --help' to check."
		return $gotocode_invalid_arg
	fi

	# basic requirement
	local dash_option='^-'
	# check if input is pure keywords or has a -option
	local pure_keywords_mode=false
	if [[ "$1" =~ $dash_option ]]
	then
		if [ $# -lt 2 ]
		then
			gotoh_output "Provide at least two arguments after '-u' for update." "Type 'goto --help' to check."
			return $gotocode_invalid_arg
		fi
	else
		pure_keywords_mode=true
	fi

	# determine whether we're in interactive or non-interactive mode.
	# interactive mode
	if [ "$1" = "-sc" ] || [ "$1" = "-st" ] || [ "$1" = "-bsc" ] || [ "$1" = "-bst" ] || [ "$pure_keywords_mode" = "true" ]
	then
		# determine whether we're in command-line-interactive or browse-interactive mode
		local absolute_path_is_ready
		local matched_absolute_path
		local subset_option
		# if browse-interactive mode, directly read in absolute path and send to current match
		if [ "$1" = "-bsc" ] || [ "$1" = "-bst" ]
		then
			absolute_path_is_ready=true
			matched_absolute_path="${2}"
			# check that the absolute path is jq-valid
			local tmptrash
			tmptrash="$( 2>&1 jq '.' <<< "${matched_absolute_path}" )"
			if [ $? -ne 0 ]
			then
				gotoh_verbose "Provided absolute path '${matched_absolute_path}' is not jq-compatible."
				gotoh_output "The -bsc / -bst option should not be entered from the command line."
				return $gotocode_invalid_arg
			fi
			# set the subset option
			# -bsc means -sc
			if [ "$1" = "-bsc" ]
			then
				subset_option="-sc"
			# else -bst means -st
			else
				subset_option="-st"
			fi
		# if command-line interactive mode, then set the subset option accordingly
		else
			# set up input variables
			local keywords
			if [ "$pure_keywords_mode" = "true" ]
			then
				subset_option="-sc"
				keywords=( "${@}" )
			else
				subset_option="$1"
				keywords=( "${@:2}" )
			fi

			# invoke rcjs to find unique match under shortcuts or settings
			matched_absolute_path="$( gotoh_recursive_json_search "${subset_option}" "${keywords[@]}" )"

			# process the rcjs results
			#   if not unique match, then cannot read.
			if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
			then
				gotoh_output "No unique match found."
				return $gotocode_no_unique_match
			fi

			# get ready for absolute path
			absolute_path_is_ready=true
		fi
		
		# if unique match or absolute path is ready, then prompt user to update, depending on subset option.
		if [ "$absolute_path_is_ready" = true ]
		then
			# first display the current match
			gotoh_output "Current match:"
			gotoh_read "${subset_option}" "${matched_absolute_path}"

			# if-else on subset option
			# if shortcut, prompt accordingly
			if [ "$subset_option" = "-sc" ]
			then
				# interactively prompt for field type, then content.
				local field_type 
				# continue prompting until field type is valid
				local field_type_is_valid=false
				while [ "$field_type_is_valid" = false ]
				do
					gotoh_output "Type the code for the field type you want to update," \
						"then [Enter]." \
						"Field type codes:" \
						"  k = keyword" \
						"  d = description" \
						"  t = type" \
						"  n = destination" \
						"  q = quit"
					read -p "Field type: " field_type
					case "$field_type" in
						k|d|t|n) field_type_is_valid=true ;;
						q) 
							gotoh_output "Update cancelled."
							return $gotocode_interactive_operation_cancelled
							;;
						*) gotoh_output "'${field_type}' is not a valid field type." ;;
					esac
				done
				# based on field type, prompt for content and check for validity
				local field_content field_specifier_word
				case "$field_type" in
					# prompt for keyword in the same way as ui create
					k) 
						field_specifier_word="keyword"
						local space=' ' pipe_symbol='\|'
						local keyword
						local more_keywords=true
						local keyword_is_valid
						local pipe_separated_keywords='' keyword_separator=''
						# continually prompt user for more keywords
						while [ "$more_keywords" = "true" ]
						do
							# for each new keyword, make sure that it's valid before adding it
							keyword_is_valid=false
							while [ "$keyword_is_valid" = false ]
							do
								gotoh_output "Type a new keyword, then [Enter]"
								read -p "Keyword: " keyword
								# if keyword has a space or pipe in it, it's not valid.
								if [[ "$keyword" =~ $space ]]
								then
									gotoh_output "This keyword has a space in it, so it's not valid."
								elif [[ "$keyword" =~ $pipe_symbol ]]
								then
									gotoh_output "This keyword has a pipe in it, so it's not valid."
								else
									# if keyword is duplicative, it's not valid
									local keywords_array keyword_occurrences
									IFS='|'
									read -a keywords_array <<< "$pipe_separated_keywords"
									unset IFS
									keyword_occurrences="$( echo "${keywords_array[@]}" | tr ' ' '\n' | grep -c "^${keyword}$" )"
									if [ "$keyword_occurrences" -gt 0 ]
									then
										gotoh_output "This keyword is duplicative, so it's not valid."
									else
										keyword_is_valid=true
									fi
								fi
							done
							pipe_separated_keywords+="${keyword_separator}"
							pipe_separated_keywords+="${keyword}"
							gotoh_output "Would you like to add another keyword?"
							read -p "y/n: " confirm_another_keyword
							# if anything but y, don't add another
							if [ "$confirm_another_keyword" != "y" ]
							then
								more_keywords=false
							fi
							keyword_separator='|'
						done
						# assign keyword(s) to field content
						field_content="${pipe_separated_keywords}"
						;;
					d)
						field_specifier_word="description"
						# prompt for description
						gotoh_output "Type a new description, then [Enter]"
						read -p "Description: " field_content
						;;
					t)
						field_specifier_word="type"
						# prompt for type code
						local type_is_valid=false object_type
						while [ "$type_is_valid" = false ]
						do
							gotoh_output "Type a new type code, then [Enter]"
							gotoh_output "Type codes:" \
								"  t = topic" \
								"  d = directory (or folder)" \
								"  f = file" \
								"  l = link"
							read -p "Type code: " object_type
							# only if it's valid do we change boolean to valid
							if [ "$object_type" = "t" ] || \
								[ "$object_type" = "d" ] || \
								[ "$object_type" = "f" ] || \
								[ "$object_type" = "l" ]
							then
								type_is_valid=true
							else
								gotoh_output "'${object_type}' is not a valid type code."
							fi
						done
						# if type code is 't', then also update the description field to null
						if [ "${object_type}" = "t" ]
						then
							gotoh_output "Since the new type is a topic, the destination field will be deleted." "Confirm?"
							local confirm_delete
							read -p "y/n: " confirm_delete
							if [ "$confirm_delete" = "y" ]
							then
								gotoh_update "-sc" "${matched_absolute_path}" "-n" "null"
							else
								gotoh_output "Update cancelled."
								return $gotocode_interactive_operation_cancelled
							fi
						fi
						# assign type code to field content
						field_content="${object_type}"
						;;
					n) 
						field_specifier_word="destination"
						# first check that type isn't 't'.
						local type_filter="getpath(${matched_absolute_path})|.type"
						local object_type="$( jq -r "${type_filter}" "${gotov_json_filepath}" )"
						#   if it is 't', you can't change destination.
						if [ "${object_type}" = "t" ]
						then
							gotoh_output "This shortcut is a topic, so its destination cannot be updated."
							return $gotocode_cannot_set_topic
						fi
						# else, prompt for destination
						gotoh_output "Type a new destination, then [Enter]"
						read -p "Destination: " field_content
						;;
				esac

				# now that the field_content has been prompted, we'll update the json
				#   confirm the update
				local matched_keyword="$( jq -r "getpath(${matched_absolute_path})|.keyword" "${gotov_json_filepath}" )"
				gotoh_output "About to update shortcut '${matched_keyword}'" \
					"with new ${field_specifier_word} '${field_content}'" "Confirm?"
				local confirm_update
				read -p "y/n: " confirm_update
				if [ "$confirm_update" != "y" ]
				then
					gotoh_output "Update cancelled."
					return $gotocode_interactive_operation_cancelled
				fi
				#   call the update helper & update accordingly
				gotoh_update "-sc" "${matched_absolute_path}" "-${field_type}" "${field_content}" \
					&& gotoh_output "Successfully updated shortcut '${matched_keyword}'"
				return $gotocode_success

			# if settings, prompt according to the possible options for the particular setting
			elif [ "$subset_option" = "-st" ]
			then
				# based on the absolute path, detect the 0-based index of the setting. 
				# since settings aren't hierarchical, that index is always at index 2 of the absolute path.
				local setting_index="$( jq -n "${matched_absolute_path}|.[2]" )"
				# based on the setting index, collect all the options in a single array
				#   don't use the extract substring function, as it's less efficient than directly extracting here.
				local setting_options_string="${gotov_settings_options[setting_index]}"
				local setting_options_array
				IFS=";"
				read -r -a setting_options_array <<< "${setting_options_string}"
				unset IFS
				local setting_options_count="${#setting_options_array[@]}"

				# display all of the options for the user to pick.
				local valid_selection=false number_regex='^[0-9]+$'
				local selected_option_number
				# repeatedly ask for selection until it's a valid number.
				while [ "$valid_selection" = false ]
				do
					gotoh_output "Here are all the options for the setting." \
						"Type the number corresponding to the desired option."
					local option_index option_position
					for option_position in $(seq ${setting_options_count} )
					do
						option_index=$(( option_position - 1 ))
						# display option
						gotoh_output "${option_position}: ${setting_options_array[option_index]}"
					done
					read -p "Number: " selected_option_number
					# make sure that the number is a valid number and within the options range
					if [[ "$selected_option_number" =~ $number_regex ]] && \
						[ "$selected_option_number" -le "$setting_options_count" ]
					then
						valid_selection=true
					else
						gotoh_output "Invalid selection: '${selected_option_number}' is not a number."
					fi
				done

				# now that we have the valid selection, we obtain the corresponding option string
				option_index=$(( selected_option_number - 1 ))
				local selected_option_string="${setting_options_array[option_index]}"
				# if option contains a '[n]', prompt user for number. else directly set the option.
				local variable_option_regex='\[n\]'
				if [[ "$selected_option_string" =~ $variable_option_regex ]]
				then
					# repeatedly prompt user until valid number is input
					local valid_number=false number_input
					while [ "$valid_number" = false ]
					do
						gotoh_output "Type a number to replace '[n]' in the option '${selected_option_string}'"
						read -p "Number: " number_input
						if [[ "$number_input" =~ $number_regex ]]
						then
							valid_number=true
						else
							gotoh_output "Input needs to be a number."
						fi
					done
					# after number is obtained, replace '[n]' with the number
					selected_option_string="${selected_option_string//\[n\]/${number_input}}"
				fi

				# time to set the option
				local setting_name="$( jq -r "getpath(${matched_absolute_path})|.keyword" "${gotov_json_filepath}" )"
				gotoh_update "-st" "${matched_absolute_path}" "-n" "${selected_option_string}" \
					&& gotoh_output "Successfully updated setting '${setting_name}'" \
					"with new content '${selected_option_string}'"
				return $gotocode_success
			# end if-else on subset option
			fi
		# end if-else on absolute path readiness
		fi

	# non-interactive mode
	#   check for at least 4 arguments for non-interactive mode
	elif [ $# -lt 4 ]
		then
			gotoh_output "Provide at least four arguments after '-u' for non-interactive update." "Check 'goto --help' for proper invocation."
			return $gotocode_invalid_arg

	# non-interactive mode after argument check
	else
		# check for proper first argument
		case "$1" in
			# perform proper non-interactive update
			-k|-d|-t|-n)
				# check whether 3rd specifier is '-of'
				if [ "$3" != "-of" ]
				then
					gotoh_output "The third positional argument is not '-of'." "Check 'goto --help' for proper invocation."
					return $gotocode_invalid_arg
				fi
				# set up input variables
				local field_specifier="$1"
				local field_content="$2"
				local keywords="${@:4}"
				# set up field specifier word
				local field_specifier_word=''
				# check validity of field content
			  # if -k, then make sure keywords separated by pipes aren't duplicative
				if [ "$field_specifier" = "-k" ]
				then
					field_specifier_word="keyword"
					# check for valid keyword. same alg. as in gotoui_create non-interactive.
					IFS='|'
					local possibly_multiple_keywords number_of_keywords last_keyword_index
					read -a possibly_multiple_keywords <<< "$field_content"
					unset IFS
					number_of_keywords="${#possibly_multiple_keywords[@]}"
					last_keyword_index=$(( number_of_keywords - 1 ))
					local each_keyword_index each_keyword each_keyword_occurrences
					for each_keyword_index in $(seq 0 ${last_keyword_index} )
					do
						each_keyword="${possibly_multiple_keywords[each_keyword_index]}"
						each_keyword_occurrences="$( echo "${possibly_multiple_keywords[@]}" | tr ' ' '\n' | grep -c "^${each_keyword}$" )"
						if [ "$each_keyword_occurrences" -gt 1 ]
						then
							gotoh_output "The keyword '${each_keyword}' is duplicative," "so the overall keyword is not valid."
							return $gotocode_invalid_arg
						fi
					done
				# if -t, then make sure field_content is a valid type code
				elif [ "$field_specifier" = "-t" ]
				then
					field_specifier_word="type"
					case "$field_content" in
						t|d|f|l) : ;;
						*) 
							gotoh_output "'${field_content}' is not a valid type code." 
							return $gotocode_invalid_arg
							;;
					esac
				# set the other field specifier words
				elif [ "$field_specifier" = "-d" ]
				then
					field_specifier_word="description"
				elif [ "$field_specifier" = "-n" ]
				then
					field_specifier_word="destination"
				fi
				# invoke rcjs to find unique match under shortcuts
				local matched_absolute_path
				matched_absolute_path="$( gotoh_recursive_json_search "-sc" "${keywords[@]}" )"

				# process the rcjs results
				# if not single match, then cannot read.
				if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
				then
					gotoh_output "No unique match found."
					return $gotocode_no_unique_match
				
				# else, single match, then update.
				else
					local matched_keyword_path="$( gotoh_print_path "${matched_absolute_path}" )"
					gotoh_update "-sc" "$matched_absolute_path" "$field_specifier" "$field_content" \
						&& gotoh_output "Successfully updated shortcut '${matched_keyword_path}'" \
						"with new ${field_specifier_word} '${field_content}'"
					return $gotocode_success
				fi
				;;
			*)
				gotoh_output "Invalid field specifier '$1' for non-interactive update." "Check 'goto --help' for proper invocation."
				return $gotocode_invalid_arg
				;;
		esac
	
	# end if-else on argument number checks
	fi

}

# == user interface function for deleting a node deui ==
# delete is a non-interactive function
# Input (non-interactive)
#   $@ = keywords
# Outpu (browse-non-interactive)
#   $1 = -browse
#   $2 = absolute path
# Output: none
# Behavior:
#   Searches rcjs for a single match for the keywords
#   If the single match is found, only deletes it if it doesn't have children.
# Invariants
#   assumes the deletion is of a shortcut, not a setting
# Dependencies
#   gotoh_overwrite_json gotoh_output gotoh_recursive_json_search
gotoui_delete() {
	# check that you have at least one keyword
	if [ $# -lt 1 ]
	then
		gotoh_output "Provide at least one keyword."
		return $gotocode_invalid_arg
	fi
	# check for browse mode
	local matched_absolute_path absolute_path_is_ready
	#   if browse mode, absolute path is ready
	if [ "$1" = "-browse" ]
	then
		# arguments checkpoint: we need exactly 2 arguments
		if [ $# -ne 2 ]
		then
			gotoh_output "Incorrect number of arguments for browse-mode deletion." "The -browse option should not be entered from the command line."
			return $gotocode_invalid_arg
		fi
		matched_absolute_path="${2}"
		# check that the absolute path is jq-valid
		local tmptrash
		tmptrash="$( 2>&1 jq '.' <<< "${matched_absolute_path}" )"
		if [ $? -ne 0 ]
		then
			gotoh_verbose "Provided absolute path '${matched_absolute_path}' is not jq-compatible."
			gotoh_output "The -browse option should not be entered from the command line."
			return $gotocode_invalid_arg
		fi
		absolute_path_is_ready=true

	#   else, we're in command-line mode, use keywords to find absolute path
	else
		# set input variables
		local keywords=( "$@" )
		# search rcjs and get outputs
		matched_absolute_path="$( gotoh_recursive_json_search "-sc" "${keywords[@]}" )"
		# if-else condition to process the rcjs results
		# if not single match, then cannot read.
		if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
		then
			gotoh_output "No unique match found."
			return $gotocode_no_unique_match
		fi
		# get ready for absolute path
		absolute_path_is_ready=true
		
	# end if-else on browse mode
	fi

	# if absolute path ready from unique match or browse mode, then process deletion.
	if [ "$absolute_path_is_ready" = true ]
	then
		# check whether the match has children
		local children_count_filter="getpath(${matched_absolute_path})|.list|length"
		local children_count="$( jq "${children_count_filter}" "${gotov_json_filepath}" )"
		# get the match path for precise display
		local match_path="$( gotoh_print_path "${matched_absolute_path}" )"
		# if match has children, don't delete. else do.
		if [ "$children_count" -gt 0 ]
		then
			gotoh_output "The shortcut '${match_path}' has children." "Use 'goto --delete-recursive' instead."
			return $gotocode_cannot_delete_node_with_children
		else
			gotoh_delete "${matched_absolute_path}"
			if [ $? -eq $gotocode_overwrite_failed ]
			then
				gotoh_output "Failed to delete the shortcut '${match_path}'"
				return $gotocode_ui_operation_failed
			else
				gotoh_output "Successfully deleted the shortcut '${match_path}'"
				return $gotocode_success
			fi
		fi
	fi
}


# == user interface function for recursively deleting a node rdui ==
# delete recursive is a non-interactive function
# Input
#   $@ = keywords
# Output: none
# Behavior:
#   Searches rcjs for a single match for the keywords
#   If the single match is found, regardless of how many children it has.
# Invariants
#   assumes the deletion is of a shortcut, not a setting
# Dependencies
#   gotoh_overwrite_json gotoh_output gotoh_recursive_json_search
gotoui_delete_recursive() {
	# check that you have at least one keyword
	if [ $# -lt 1 ]
	then
		gotoh_output "Provide at least one keyword."
		return $gotocode_invalid_arg
	fi
	# set input variables
	local keywords=( "$@" )
	# search rcjs and get outputs
	local matched_absolute_path
	matched_absolute_path="$( gotoh_recursive_json_search "-sc" "${keywords[@]}" )"
	# if-else condition to process the rcjs results
	# if not single match, then cannot read.
	if [ -z "$matched_absolute_path" ] || [ "$matched_absolute_path" = "multiple" ]
	then
		gotoh_output "No unique match found."
		return $gotocode_no_unique_match
	
	# else, single match, then process the deletion.
	else
		# get the match path for precise display
		local match_path="$( gotoh_print_path "${matched_absolute_path}" )"
		# no need to check whether the match has children, just straight up delete
		gotoh_delete "${matched_absolute_path}"
		if [ $? -eq $gotocode_overwrite_failed ]
		then
			gotoh_output "Failed to delete the shortcut '${match_path}'"
			return $gotocode_ui_operation_failed
		else
			gotoh_output "Successfully deleted the shortcut '${match_path}' and its children."
			return $gotocode_success
		fi
	fi
}

# == user interface function for moving a node moui ==
# move is a non-interactive function
gotoui_move() { :; }

# == user interface function for browsing all nodes brui ==
# browse is an interactive function
# Input
#   $1 = -sc / -st
# Output
#   A nice user interface for browsing shortcuts or settings
# Behavior
#   Starting at the appropriate root, display the node's family, then have several options for editing & traversing:
#     for shortcuts: 
#       create (interactive)
#       delete (non-interactive, non-recursive, moves to the parent)
#     for both shortcuts and settings:
#       update (interactive)
#       go back to the parent
#       type a child keyword to visit
#       'q' to quit
# Invariants
#   goto.json exists
# Dependencies
#   gotoui_create, gotoui_delete, gotoui_update, 
gotoui_browse() {
	# argument check
	if [ $# -ne 1 ]
	then
		gotoh_output "Provide exactly one argument to browse."
		return $gotocode_invalid_arg
	elif [ "$1" != "-sc" ] && [ "$1" != "-st" ] 
	then
		gotoh_output "Invalid subset option. Check 'goto --help' for proper invocation."
		return $gotocode_invalid_arg
	fi

	# set input variable
	local subset_option="$1"
	
	# set up current absolute path to keep track of current node
	local current_absolute_path
	if [ "$subset_option" = "-st" ]
	then
		current_absolute_path='[0]'
	else
		current_absolute_path='[1]'
	fi

	# initialize some variables to be used in while loop
	local user_choice
	local user_choice_is_valid
	local tmptrash

	# while loop continually until quit
	while :
	do
		# display the node family
		gotoh_print_family "$subset_option" "${current_absolute_path}"

		# display options based on subset
		echo # aesthetic newline
		#   display shortcut-compatible options
		if [ "$subset_option" = "-sc" ]
		then
			gotoh_output "Type one of the following options, then [Enter]." \
				"  [-c] create shortcut" \
				"  [-d] delete shortcut" \
				"  [-u] update shortcut" \
				"  [-p] back to parent" \
				"  [a child keyword]" \
				"  [-q] quit"
		#   display setting-compatible options
		else
			gotoh_output "Type one of the following options, then [Enter]." \
				"  [-u] update setting" \
				"  [-p] back to parent" \
				"  [a child keyword]" \
				"  [-q] quit"
		fi
		
		# obtain & process user options
		# prompt until valid
		user_choice_is_valid=false
		while [ "$user_choice_is_valid" = false ]
		do
			read -p "Your choice: " user_choice
			# process user choice on a case-by-case basis
			case "$user_choice" in
				# create
				-c) 
					# determine user choice validity
					if [ "$subset_option" != "-sc" ]
					then
						gotoh_output "Invalid option."
					else
						user_choice_is_valid=true
					fi
					# call create ui from browse
					gotoui_create -browse "${current_absolute_path}"
					;;

				# delete
				-d) 
					# determine user choice validity
					if [ "$subset_option" != "-sc" ]
					then
						gotoh_output "Invalid option."
					else
						user_choice_is_valid=true
					fi
					# call delete ui (because it checks for children count) from browse
					local delete_return_code
				  gotoui_delete -browse "${current_absolute_path}"
					delete_return_code=$?
					if [ $delete_return_code -eq $gotocode_cannot_delete_node_with_children ]
					then
						gotoh_output "Cannot delete a shortcut that has children."
						read -p "[Enter] to continue." tmptrash
					elif [ $delete_return_code -ne 0 ]
					then
						gotoh_output "Shortcut deletion failed."
						read -p "[Enter] to continue." tmptrash
					# if shortcut deletion succeeded, then you must backtrack the filter to the parent
					#   in the exact same way as in -p option
					else
						current_absolute_path="$( jq '.[:(length-2)]' <<< "$current_absolute_path" )"
					fi
					;;

				# update
				-u) 
					# determine user choice validity: it's always valid
					user_choice_is_valid=true
					# set the subset option to pass to ui update
					local subset_option_for_update
					if [ "$subset_option" = "-sc" ]
					then
						subset_option_for_update='-bsc'
					else
						subset_option_for_update='-bst'
					fi
					# call update ui from browse
					gotoui_update "$subset_option_for_update" "${current_absolute_path}"
					;;

				# parent
				-p) 
					# determine user choice validity: it's always valid
					user_choice_is_valid=true
					# update the absolute path if possible
					local current_path_length="$( jq -n "${current_absolute_path}|length" )"
					# if current length is less than or equal to 2, cannot go up.
					if [ $current_path_length -le 2 ]
					then
						gotoh_output "This is the root, cannot go up."
						read -p "[Enter] to continue." tmptrash
					# else (if current length is greater than 2), update absolute path
					#   in the exact same way as after successful deletion
					else
						current_absolute_path="$( jq '.[:(length-2)]' <<< "$current_absolute_path" )"
					fi
					;;

				# quit
				-q) 
					# determine user choice validity: it's always valid
					user_choice_is_valid=true
					# quit
					return $gotocode_quit_from_browse
					;;

				# child keyword
				*) 
					# determine user choice validity: it's always valid
					user_choice_is_valid=true
					# look for the child from among the children list
					local matched_nodes_filter="getpath(${current_absolute_path})|.list[]?|select(.keyword|test(\"^(.*\\\\|)?${user_choice}(\\\\|.*)?$\"))"
					local matched_count="$( jq "[${matched_nodes_filter}]|length" "${gotov_json_filepath}" )"
					# if-else on matched count to determine what to do
					# if no match, let user know
					if [ "$matched_count" -eq 0 ]
					then
						gotoh_output "No match for the keyword '${user_choice}' was found."
						read -p "[Enter] to continue." tmptrash

					# elif single match, update current absolute path.
					elif [ "$matched_count" -eq 1 ]
					then
						current_absolute_path="$( jq "path(${matched_nodes_filter})" "${gotov_json_filepath}" )"

					# elif multiple matches, let user know
					elif [ "$matched_count" -gt 1 ]
					then
						gotoh_output "Multiple matches for the keyword '${user_choice}' were found." \
							"Please manually edit the JSON file to fix this issue." \
							"In a future version, we'll make sure this cannot happen."
						return $gotocode_multiple_matches_among_siblings

					# else not possible, quit.
					else
						gotoh_output "There were negative matches found for the keyword '${user_choice}'" \
							"This should be impossible." "Quitting."
						return $gotocode_impossible_match_count_json
					fi
					;;
			esac
			# end while loop for validty
		done

	echo # another aesthetic newline

	# end while loop for browse
	done
}

################################################
## main CRUD user interface execution cruduix ##
################################################
case "$1" in
-b|--browse|-c|--create|-cd|--create-directory|-r|--read|-u|--update|-d|--delete|-dr|--delete-recursive|-m|--move)
	# process CRUD options here TODO
	#   We do NOT process return codes here, but leave them inside their originating functions 
	#   for easier identification of problem functions, thereby helping with debugging
	case "$1" in
		-c|--create) gotoui_create "${@:2}" ;;
		-cd|--create-directory) 
			# if empty, invalid.
			if [ -z "$2" ]
			then
				gotoh_output "Missing arguments for create directory." "Check 'goto --help' for proper invocation."
			# elif interactive, "$2" is -under. convert to auto-directory mode.
			elif [ "$2" = "-under" ]
			then
				gotoui_create '-dunder' "${@:3}" 
			# if non-interactive, "$2" is -k. convert to auto-directory mode.
			elif [ "$2" = "-k" ]
			then
				gotoui_create '-dk' "${@:3}" 
			# else wrong option
			else
				gotoh_output "Invalid option '$2'." "Check 'goto --help' for proper invocation."
			fi
			;;
		-r|--read) 
			# if no -sc, then assume it's shortcuts.
			if [ "$2" != "-sc" ]
			then
				gotoui_read -sc "${@:2}" 
			else
				gotoui_read "${@:2}" 
			fi
			;;
		-u|--update) gotoui_update "${@:2}" ;;
		-d|--delete) gotoui_delete "${@:2}" ;;
		-dr|--delete-recursive) gotoui_delete_recursive "${@:2}" ;;
		-b|--browse) 
			# if -b or --browse only, then assume it's shortcuts.
			if [ -z "$2" ]
			then
				gotoui_browse -sc
			else
				gotoui_browse "${@:2}"
			fi
			;;
	esac
	# end this case with unsets and a success code
	gotoh_unset_all
	return $gotocode_success
	;;
# else let it pass through to process the keywords.
esac

###################################
## main goto user interface gtui ##
###################################

# == goto main user interface function gtuf == 
# gotoui_goto
# Input
#   keywords
# Output
#   either message indicating shortcut found, or messages indicating not found.
# Behavior
#   Recursively looks for a match to the given keyword sequence under shortcuts
#   using gotoh_recursive_json_search (rcjs) with -sc option.
#     If rcjs echoes nada, then there's no match for the first keyword. Depending on jsonPartialMatch, decide whether to continue searching in filesystem.
#     Elif rcjs echoes 'multiple', then the multiple paths have already been displayed. The error code is irrelevant in that case as well.
#     Else rcjs echoes anything else, that should be an absolute path. Then the return code matters.
#       If return code is the same as the number of keywords, that means all keywords have been consumed, so we go.
#       Elif return code is less than number of keywords, then depends on jsonPartialMatch setting
#         If jsonPartialMatch is on, then go.
#         Else jsonPartialMatch isn't on, then process the rest of the unmatched keywords using recursive filesystem search.
#   Recursively looks for a match to the unmatched keyword sequence under filesystem (rcfs).
#     Invariant: If provided destination is not a dir, quit.
#     Search for keyword until all keywords are exhausted or we quit early...
#       If it matches a single destination...
#         If that destination is a file...
#           If filesystemPartialMatch is on, then open the file.
#           If filesystemPartialMatch is off, then quit.
#         If that destination is a dir, continue searching.
#       If it matches multiple destinations, just display them and quit.
#       If it matches no destination at all...
#         If it's the first keyword, then quit.
#         If it's not the first keyword, then...
#           If filesystemPartialMatch is on, then open the dir.
#           If filesystemPartialMatch is off, then quit.
#     After all keywords are exhausted, open the final matched destination.
# Invariants
#   input is not a CRUD option
#   input contains at least one keyword
#   has access to a properly initialized gotov_jsonPartialMatch_setting
#   has access to a properly initialized gotov_filesystemPartialMatch_setting
# Dependencies
#   gotoh_output
#   gotoh_recursive_json_search
#   gotoh_open_path, gotoh_go
gotoui_goto() {
	# create input variables
	local keywords=( "$@" )
	local number_of_keywords=$#

	# Call rcjs and obtain its echo output and return code.
	local unmatched_keyword_index matched_absolute_path
	matched_absolute_path="$( gotoh_recursive_json_search -sc ${keywords[@]} )"
	unmatched_keyword_index=$?
	# gotoh_output "MAP: $matched_absolute_path" "UKI: $unmatched_keyword_index" # diagnostic

	# if-else the rcjs echo output.
	# if nada, then no match or a partial match when jsonPartialMatch = off
	if [ -z "$matched_absolute_path" ]
	then
		# if jsonPartialMatch is off, then fall through to continue to file system search.
		if [ "$gotov_jsonPartialMatch_setting" = "off" ]
		then
			:
		# else, jsonPartialMatch is on, so quit.
		else
			gotoh_output "No full match found."
			return $gotocode_no_match_at_all
		fi
		
	# elif 'multiple', then the multiple paths have been displayed. quit.
	elif [ "$matched_absolute_path" = "multiple" ]
	then
		gotoh_output "No unique match found."
		return $gotocode_multiple_matches_json

	# else: it should be a path. a single match.
	else 
		# check invariant: a valid json path
		local tmptrash
		tmptrash="$( jq -n "${matched_absolute_path}" )"
		if [ $? -ne 0 ]
		then
			gotoh_verbose "Recursive json search returned an invalid output" "'${matched_absolute_path}'" "This should not happen." "Please report this bug to us."
			return $gotocode_unknown
		fi
	
		# now, the return code matters. process it appropriately using an if-else.
		# if we've matched all keywords, then go to the path.
		if [ "$unmatched_keyword_index" -ge "$number_of_keywords" ]
		then
			gotoh_open_path "${matched_absolute_path}"
			return $gotocode_success
		
		# elif we have a partial match, follow jsonPartialMatch setting.
		elif [ "$unmatched_keyword_index" -lt "$number_of_keywords" ]
		then
			# if-else on the jsonPartialMatch setting.
			# if partial match is on, go to the absolute path.
			if [ "$gotov_jsonPartialMatch_setting" = "on" ]
			then
				gotoh_verbose "Because jsonPartialMatch = on, we will go there now."
				gotoh_open_path "${matched_absolute_path}"
				return $gotocode_partial_success
			
			# elif partial match is off, let it fall through to search the file system after this.
			elif [ "$gotov_jsonPartialMatch_setting" = "off" ]
			then
				gotoh_verbose "Because jsonPartialMatch = off, we will use the unmatched keywords to search in the file system."

			# else partial match setting is wrong.
			else
				gotoh_verbose "Unknown jsonPartialMatch setting '$gotov_jsonPartialMatch_setting'." "This should not occur." "Please report this bug to us."
				return $gotocode_unknown
			fi
		fi
	fi

	# == recursive filesystem search rcfss ==
	# At this point, there are still unmatched keywords left.
	#   we either have all keywords still unmatched (from the first fall-through above), 
	#   or a partial list of keywords (from the second fall-through above).
	
	# set up variables for the recursive filesystem search
	local dir_in_which_to_look=''
	local number_of_keywords_examined_by_find=0

	# file hierarchy search invariant checkpoint: 
	#   the recursive search can only operate on a directory
	
	# if-else over the number of keywords not yet matched, to decide in which directory to search.
	# if no keyword matched in json, then set '.' as the dir in which to look next.
	if [ $unmatched_keyword_index -eq 0 ]
	then
		dir_in_which_to_look="."
	
	# else (if at least one keyword matched in json), check the type at the absolute path.
	else
		local destination_filetype="$( jq -r "getpath(${matched_absolute_path})|.type" "${gotov_json_filepath}" )"
		
		# if the shortcut is a dir, then set the content at the absolute path as the dir and fall through to the recursive filesystem search.
		if [ "$destination_filetype" = "d" ]
		then
			dir_in_which_to_look="$( jq -r "getpath(${matched_absolute_path})|.destination" "${gotov_json_filepath}" )"
		
		# else (if the type is not a directory), we quit.
		else
			gotoh_verbose "The match is not a directory, so we cannot search further in the file system."
			return $gotocode_cannot_search_further_in_filesystem
		fi
	# end if-else to set directory to search.
	fi
	# At this point, we should have the directory in which to search.

	# Let user know which keywords we've matched in json.
	if [ $unmatched_keyword_index -eq 0 ]
	then
		gotoh_verbose "We found no keyword match in goto.json"
	else
		local matched_keyword_sequence="${keywords[@]:0:${unmatched_keyword_index}}"
		gotoh_verbose "We matched the keyword sequence '${matched_keyword_sequence// / -> }' in goto.json"
	fi
	
	# Let user know which keywords we're still searching for.
	local number_of_unmatched_keywords=$(( number_of_keywords - unmatched_keyword_index ))
	local unmatched_keyword_sequence="${keywords[@]:${unmatched_keyword_index}:${number_of_unmatched_keywords}}"
	gotoh_verbose "Looking for the keyword sequence '${unmatched_keyword_sequence// / -> }' in '${dir_in_which_to_look}'"

	# while there's still a keyword, recursively search the current filesystem starting at $dir_in_which_to_look
	local current_keyword current_find_wcl_output current_find_count current_find_result
	while [ $unmatched_keyword_index -lt $number_of_keywords ]
	do
		# = count matches from find fscm =
		# grab current keyword
		current_keyword="${keywords[unmatched_keyword_index]}"

		# build find command
		gotolf_current_find_command() { 
			find "${dir_in_which_to_look}" -name "${current_keyword}"
		}

		# count number of finds
		current_find_wcl_output="$( gotolf_current_find_command | wc -l )"
		current_find_count="$( echo "${current_find_wcl_output}" | tr -d ' ' )"

		# increment number examined
		(( number_of_keywords_examined_by_find ++ ))

		# get the found filepath result
		current_find_result="$( gotolf_current_find_command )"

		# = if-else on the filesystem search match count fsmc =
		# - fsnm -
		# if no match, let user know, then either go or quit.
		if [ "$current_find_count" -eq 0 ]
		then
			gotoh_output \
				"Both goto.json and the file system have been searched," \
				"but we could not match the exact keyword sequence."
			
			# However, if we have examined more than one keyword already, that means the previous find output was a valid destination.
			if [ "$number_of_keywords_examined_by_find" -gt 1 ]
			then
				# based on filesystemPartialMatch setting, either directly go to the partial result or quit.
				gotoh_verbose "However, we were able to match up to '${keywords[@]:0:${unmatched_keyword_index}}'" "with the directory '$dir_in_which_to_look'"
				
				# if-else on the filesystemPartialMatch setting.
				# if filesystemPartialMatch is on, go to the destination.
				if [ "$gotov_filesystemPartialMatch_setting" = "on" ]
				then
					gotoh_verbose "Because filesystemPartialMatch = on, we will now go there."
					# due to the case in the next if-else group, we are guaranteed to have a previous match that was a directory.
					gotoh_go "d" "$dir_in_which_to_look"
					return $gotocode_partial_success
				
				# elif filesystemPartialMatch is off, quit.
				elif [ "$gotov_filesystemPartialMatch_setting" = "off" ]
				then
					gotoh_verbose "Because filesystemPartialMatch = off, we will not go there directly." "Feel free to open it yourself."
					# this falls through to the quit line at the end of the no match condition.
				# else unknown setting
				else
					gotoh_verbose "Unknown filesystemPartialMatch setting '${gotov_filesystemPartialMatch_setting}'." "This should not occur." "Please report this bug to us."
					return $gotocode_unknown
				fi
			fi

			# quit
			return $gotocode_cannot_search_further_in_filesystem

		# - fssm -
		# elif a single match, update the directory in which to look and let the loop continue.
		elif [ "$current_find_count" -eq 1 ]
		then
			# if it's a file, it's a terminal path. 
			if [ -f "$current_find_result" ]
			then
				gotoh_verbose "We found a file at '$current_find_result'"
				
				# depending on filesystemPartialMatch, either go there or not.
				# if on, go.
				if [ "$gotov_filesystemPartialMatch_setting" = "on" ]
				then
					gotoh_go "f" "$current_find_result"
					return $gotocode_partial_success
				
				# elif off, quit.
				elif [ "$gotov_filesystemPartialMatch_setting" = "off" ]
				then
					gotoh_verbose "Because filesystemPartialMatch = off, we will not go there directly." "Feel free to open it yourself."
					return $gotocode_cannot_search_further_in_filesystem

				# else unknown setting
				else
					gotoh_verbose "Unknown filesystemPartialMatch setting '${gotov_filesystemPartialMatch_setting}'." "This should not occur." "Please report this bug to us."
					return $gotocode_unknown
				fi

			# elif it's a dir, set the next iteration's directory in which to look.
			elif [ -d "$current_find_result" ]
			then
				dir_in_which_to_look="${current_find_result}"

			# else it's not a currently process-able file type. quit.
			else
				gotoh_verbose \
					"Encountered weird file type at '${current_find_result}'" \
					"goto quits."
				return $gotocode_weird_file_type
			fi

		# - fsmm -
		# elif multiple matches, print out all paths and quit.
		elif [ "$current_find_count" -gt 1 ]
		then
			# let the user know
			gotoh_verbose \
				"We found multiple matches for the keyword '${current_keyword}'" \
				"The path to each match is shown below."
			
			# turn the found paths into an array
			local found_paths_array each_found_path
			found_paths_array=()
			while read -r each_found_path
			do
				found_paths_array+=("$each_found_path")
			done <<< "$current_find_result"

			# display the paths neatly
			local each_found_path_num each_found_path_index
			for each_found_path_num in $(seq $current_find_count)
			do
				each_found_path_index=$(( each_found_path_num - 1 ))
				gotoh_output \
					"Match ${each_found_path_num}:" \
					"  ${found_paths_array[each_found_path_index]}"
			done

			# suggest to the user what to do next.
			gotoh_verbose \
				"You can follow one of these paths above" \
				"or improve your query to narrow down to a single result."
			
			# quit
			return $gotocode_multiple_matches_filesystem

		# else, it's not possible to have negative matches
		else
			gotoh_verbose "For some reason, we found ${current_find_count} matches, which shouldn't happen."
			return $gotocode_impossible_match_count_filesystem
		fi

		# increment the keyword index
		(( unmatched_keyword_index ++))
	done

	# After exhausting the keywords and triggering neither no-match nor multi-match, 
	#   we can know that the dir we have now is openable.
	# Apologies for the misnomer in the case in which dir_in_which_to_look can be a file.
	gotoh_output "Successfully matched all given keywords. Going there."
	if [ -f "${dir_in_which_to_look}" ]
	then
		gotoh_go "f" "${dir_in_which_to_look}"
	elif [ -d "${dir_in_which_to_look}" ]
	then
		gotoh_go "d" "${dir_in_which_to_look}"
	else
		gotoh_verbose \
			"Encountered weird file type at '${current_find_result}'" \
			"goto quits."
		return $gotocode_weird_file_type
	fi

	# Yes, we've finally processed a full match. So we quit.
	return $gotocode_success
}

# == We actually run the goto UI function rngt ==
gotoui_goto "$@"
gotoh_unset_all
return $gotocode_success
