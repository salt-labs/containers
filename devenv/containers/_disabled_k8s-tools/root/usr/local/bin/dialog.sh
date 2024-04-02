#!/usr/bin/env bash

##################################################
# Name: dialog
# Description: Contains the dialog menu related functions
##################################################

# Common options:
#  [--ascii-lines] [--aspect <ratio>] [--backtitle <backtitle>] [--beep]
#  [--beep-after] [--begin <y> <x>] [--cancel-label <str>] [--clear]
#  [--colors] [--column-separator <str>] [--cr-wrap] [--date-format <str>]
#  [--default-button <str>] [--default-item <str>] [--defaultno]
#  [--exit-label <str>] [--extra-button] [--extra-label <str>]
#  [--help-button] [--help-label <str>] [--help-status] [--help-tags]
#  [--hfile <str>] [--hline <str>] [--ignore] [--input-fd <fd>]
#  [--insecure] [--item-help] [--keep-tite] [--keep-window] [--last-key]
#  [--max-input <n>] [--no-cancel] [--no-collapse] [--no-cr-wrap]
#  [--no-items] [--no-kill] [--no-label <str>] [--no-lines] [--no-mouse]
#  [--no-nl-expand] [--no-ok] [--no-shadow] [--no-tags] [--nook]
#  [--ok-label <str>] [--output-fd <fd>] [--output-separator <str>]
#  [--print-maxsize] [--print-size]
#  [--print-text-only <text> <height> <width>]
#  [--print-text-size <text> <height> <width>] [--print-version] [--quoted]
#  [--reorder] [--scrollbar] [--separate-output] [--separate-widget <str>]
#  [--shadow] [--single-quoted] [--size-err] [--sleep <secs>] [--stderr]
#  [--stdout] [--tab-correct] [--tab-len <n>] [--time-format <str>]
#  [--timeout <secs>] [--title <title>] [--trace <file>] [--trim]
#  [--version] [--visit-items] [--week-start <str>] [--yes-label <str>]

# Box options:
#  --buildlist    <text> <height> <width> <list-height> <tag1> <item1> <status1>...
#  --calendar     <text> <height> <width> <day> <month> <year>
#  --checklist    <text> <height> <width> <list height> <tag1> <item1> <status1>...
#  --dselect      <directory> <height> <width>
#  --editbox      <file> <height> <width>
#  --form         <text> <height> <width> <form height> <label1> <l_y1> <l_x1> <item1> <i_y1> <i_x1> <flen1> <ilen1>...
#  --fselect      <filepath> <height> <width>
#  --gauge        <text> <height> <width> [<percent>]
#  --infobox      <text> <height> <width>
#  --inputbox     <text> <height> <width> [<init>]
#  --inputmenu    <text> <height> <width> <menu height> <tag1> <item1>...
#  --menu         <text> <height> <width> <menu height> <tag1> <item1>...
#  --mixedform    <text> <height> <width> <form height> <label1> <l_y1> <l_x1> <item1> <i_y1> <i_x1> <flen1> <ilen1> <itype>...
#  --mixedgauge   <text> <height> <width> <percent> <tag1> <item1>...
#  --msgbox       <text> <height> <width>
#  --passwordbox  <text> <height> <width> [<init>]
#  --passwordform <text> <height> <width> <form height> <label1> <l_y1> <l_x1> <item1> <i_y1> <i_x1> <flen1> <ilen1>...
#  --pause        <text> <height> <width> <seconds>
#  --prgbox       <text> <command> <height> <width>
#  --programbox   <text> <height> <width>
#  --progressbox  <text> <height> <width>
#  --radiolist    <text> <height> <width> <list height> <tag1> <item1> <status1>...
#  --rangebox     <text> <height> <width> <min-value> <max-value> <default-value>
#  --tailbox      <file> <height> <width>
#  --tailboxbg    <file> <height> <width>
#  --textbox      <file> <height> <width>
#  --timebox      <text> <height> <width> <hour> <minute> <second>
#  --treeview     <text> <height> <width> <list-height> <tag1> <item1> <status1> <depth1>...
#  --yesno        <text> <height> <width>

# Examples
# 	https://github.com/tolik-punkoff/dialog-examples

function dialogDefaults() {

	# Configures dialog with consistent defaults

	local SCRIPT=${SCRIPT:-DIALOG}
	local TITLE=${1:-TITLE}

	checkBin dialog || {
		writeLog "ERROR" "dialog is not available"
		return 1
	}

	# The dialog box configuration
	# https://linux.die.net/man/1/dialog
	CMD=(
		dialog
		--stderr
		--backtitle "${SCRIPT}"
		--cancel-label "Cancel"
		--colors
		--exit-label "Exit"
		--help-label "Help"
		--ok-label "OK"
		--timeout 60
		--title "${TITLE}"
	)

	return 0

}

function dialogProgress() {

	# Increments a fake progress bar

	local TITLE="${1:-TITLE}" # The dialog box title
	local PERCENT="${2:-0}"   # The progress bar percent
	local HEIGHT="${3:-25}"   # Height for dialog boxes
	local WIDTH="${4:-50}"    # Width for dialog boxes

	# Configure common dialog options
	dialogDefaults "${TITLE}" || return 1

	# Box options
	BOX_OPTIONS=(
		# text - height - width - list-height
		--guage
		"${TITLE}"
		"${HEIGHT}"
		"${WIDTH}"
		"${PERCENT}"
	)

	echo "${PERCENT}" | "${CMD[@]}" "${BOX_OPTIONS[@]}"
	sleep 0.1

	return 0

}

function dialogChecklist() {

	# Creates a checklist menu with the provided options

	local TITLE=${1:-TITLE}    # The dialog box title
	local TEXT=${2:-TEXT}      # The text for the checklist
	local HEIGHT=${3:-25}      # Height for dialog boxes
	local WIDTH=${4:-50}       # Width for dialog boxes
	local LINE_HEIGHT=${5:-10} # Line height for dialog boxes

	# Configure common dialog options
	dialogDefaults "${TITLE}" || return 1

	# Box options
	BOX_OPTIONS=(
		# text - height - width - list-height
		--checklist
		"${TEXT}"
		"${HEIGHT}"
		"${WIDTH}"
		"${LINE_HEIGHT}"
	)

	return 0

}

function dialogForm() {

	# Creates a form with the provided options

	local TITLE=${1:-TITLE}    # The dialog box title
	local TEXT=${2:-FORM}      # The actual form with variables
	local HEIGHT=${3:-25}      # Height for dialog boxes
	local WIDTH=${4:-50}       # Width for dialog boxes
	local FORM_HEIGHT=${5:-10} # Form height

	# Configure common dialog options
	dialogDefaults "${TITLE}" || return 1

	# Box options
	BOX_OPTIONS=(
		# text - height - width - list-height
		--form
		"${TEXT}"
		"${HEIGHT}"
		"${WIDTH}"
		"${FORM_HEIGHT}"
	)

	return 0

}

function dialogYesNo() {

	# Creates a form with the provided options

	# Once the box is created the expected return code are
	# 0     = YES
	# 1     = NO
	# 255   = ESC

	local TITLE=${1:-TITLE}    # The dialog box title
	local TEXT=${2:-FORM}      # The actual form with variables
	local HEIGHT=${3:-25}      # Height for dialog boxes
	local WIDTH=${4:-50}       # Width for dialog boxes
	local LINE_HEIGHT=${5:-10} # Line height for dialog boxes

	# Configure common dialog options
	dialogDefaults "${TITLE}" || return 1

	# Box options
	# --yesno <text> <height> <width>
	BOX_OPTIONS=(
		--yesno
		"${TEXT}"
		"${HEIGHT}"
		"${WIDTH}"
	)

	return 0

}

function dialogMenu() {

	# Creates a Menu with the provided options

	local TITLE=${1:-TITLE}    # The dialog box title
	local TEXT=${2:-FORM}      # The actual form with variables
	local HEIGHT=${3:-25}      # Height for dialog boxes
	local WIDTH=${4:-50}       # Width for dialog boxes
	local LINE_HEIGHT=${5:-10} # Line height for dialog boxes

	# Configure common dialog options
	dialogDefaults "${TITLE}" || return 1

	# Box options
	BOX_OPTIONS=(
		# text - height - width - list-height
		--menu
		"${TEXT}"
		"${HEIGHT}"
		"${WIDTH}"
		"${LINE_HEIGHT}"
	)

	return 0

}

function dialogMsgBox() {

	# Creates a message box with the provided options

	# Once the box is created the expected return code are
	# 0     = YES
	# 1     = NO
	# 255   = ESC

	local TITLE=${1:-TITLE}    # The dialog box title
	local TEXT=${2:-FORM}      # The actual form with variables
	local HEIGHT=${3:-25}      # Height for dialog boxes
	local WIDTH=${4:-50}       # Width for dialog boxes
	local LINE_HEIGHT=${5:-10} # Line height for dialog boxes

	# Configure common dialog options
	dialogDefaults "${TITLE}" || return 1

	# Box options
	# --msgbox <text> <height> <width>
	BOX_OPTIONS=(
		--msgbox
		"${TEXT}"
		"${HEIGHT}"
		"${WIDTH}"
	)

	"${CMD[@]}" "${BOX_OPTIONS[@]}"

	return 0

}

function _test_dialogs() {

	local USER_NAME=""
	local USER_SHELL=""
	local USER_GROUPS=""
	local USER_HOME=""

	#########################
	# Progress
	#########################

	dialogProgress "Something is happening" "25"
	sleep 0.5

	dialogProgress "Something is happening" "50"
	sleep 0.5

	dialogProgress "Something is happening" "75"
	sleep 0.5

	dialogProgress "Something is happening" "100"
	sleep 0.5

	#########################
	# Checklist
	#########################

	dialogChecklist "Title" "Select one or more options from the checklist:"

	OPTIONS=(
		1 "This menu is terrible" off
		2 "This menu is awesome" on
	)

	"${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}"

	#########################
	# Form
	#########################

	dialogForm "Title" "Fill in this form"

	# [ Label - y x item y x flen ilen ]
	OPTIONS=(
		"Username:" 1 1 "$USER_NAME" 1 10 10 0
		"Shell:" 2 1 "$USER_SHELL" 2 10 15 0
		"Group:" 3 1 "$USER_GROUPS" 3 10 8 0
		"HOME:" 4 1 "$USER_HOME" 4 10 40 0
	)

	"${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}"

	#########################
	# Yes or No
	#########################

	dialogYesNo "Title" "What is the meaning of life?"

	"${CMD[@]}" "${BOX_OPTIONS[@]}"

	#########################
	# Menu
	#########################

	dialogMenu "Title" "Select one option from the menu:"

	OPTIONS=(
		1 "This menu is terrible"
		2 "This menu is awesome"
	)

	"${CMD[@]}" "${BOX_OPTIONS[@]}" "${OPTIONS[@]}"

	#########################
	# Message Box
	#########################

	dialogMsgBox "Title" "This is a message box!"

	#########################
	# End
	#########################

	tput clear

	echo "Test complete!"

	return 0

}

export -f dialogProgress dialogForm dialogYesNo dialogMenu
