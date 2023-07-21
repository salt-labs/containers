##################################################
# Name: shopt
# Description: Contains the bash shell options configurations
# Reference: https://www.gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html
##################################################

function shell_options() {

	# Confirm bash is actually running
	if ! type shopt > /dev/null 2>&1; then
		echo "ERROR: This function: ${FUNCNAME[0]} needs to be called from within Bash"
		return 1
	fi

	if [ "${BASH_VERSINFO:-0}" -ge 5 ]; then

		# assoc_expand_once
		# If set, the shell suppresses multiple evaluation of associative array subscripts during arithmetic expression evaluation, while executing builtins that can perform variable assignments, and while executing builtins that perform array dereferencing.
		shopt -q -u assoc_expand_once

	fi

	# autocd
	# If set, a command name that is the name of a directory is executed as if it were the argument to the cd command. This option is only used by interactive shells.
	shopt -q -s autocd

	# cdable_vars
	# If this is set, an argument to the cd builtin command that is not a directory is assumed to be the name of a variable whose value is the directory to change to.
	shopt -q -s cdable_vars

	# cdspell
	# If set, minor errors in the spelling of a directory component in a cd command will be corrected. The errors checked for are transposed characters, a missing character, and a character too many. If a correction is found, the corrected path is printed, and the command proceeds. This option is only used by interactive shells.
	shopt -q -s cdspell

	# checkhash
	# If this is set, Bash checks that a command found in the hash table exists before trying to execute it. If a hashed command no longer exists, a normal path search is performed.
	shopt -q -u checkhash

	# checkjobs
	# If set, Bash lists the status of any stopped and running jobs before exiting an interactive shell. If any jobs are running, this causes the exit to be deferred until a second exit is attempted without an intervening command (see Job Control). The shell always postpones exiting if any jobs are stopped.
	shopt -q -s checkjobs

	# checkwinsize
	# If set, Bash checks the window size after each external (non-builtin) command and, if necessary, updates the values of LINES and COLUMNS. This option is enabled by default.
	shopt -q -s checkwinsize

	# cmdhist
	# If set, Bash attempts to save all lines of a multiple-line command in the same history entry. This allows easy re-editing of multi-line commands. This option is enabled by default, but only has an effect if command history is enabled (see Bash History Facilities).
	shopt -q -s cmdhist

	# compat31
	# If set, Bash changes its behavior to that of version 3.1 with respect to quoted arguments to the conditional command's '=~' operator and with respect to locale-specific string comparison when using the [[ conditional command's '<' and '>' operators. Bash versions prior to bash-4.1 use ASCII collation and strcmp(3); bash-4.1 and later use the current locales collation sequence and strcoll(3).
	shopt -q -u compat31

	# compat32
	# If set, Bash changes its behavior to that of version 3.2 with respect to locale-specific string comparison when using the [[ conditional command's '<' and '>' operators (see previous item) and the effect of interrupting a command list. Bash versions 3.2 and earlier continue with the next command in the list after one terminates due to an interrupt.
	shopt -q -u compat32

	# compat40
	# If set, Bash changes its behavior to that of version 4.0 with respect to locale-specific string comparison when using the [[ conditional command's '<' and '>' operators (see description of compat31) and the effect of interrupting a command list. Bash versions 4.0 and later interrupt the list as if the shell received the interrupt; previous versions continue with the next command in the list.
	shopt -q -u compat40

	# compat41
	# If set, Bash, when in POSIX mode, treats a single quote in a double-quoted parameter expansion as a special character. The single quotes must match (an even number) and the characters between the single quotes are considered quoted. This is the behavior of POSIX mode through version 4.1. The default Bash behavior remains as in previous versions.
	shopt -q -u compat41

	# compat42
	# If set, Bash does not process the replacement string in the pattern substitution word expansion using quote removal.
	shopt -q -u compat42

	# compat43
	# If set, Bash does not print a warning message if an attempt is made to use a quoted compound array assignment as an argument to declare, makes word expansion errors non-fatal errors that cause the current command to fail (the default behavior is to make them fatal errors that cause the shell to exit), and does not reset the loop state when a shell function is executed (this allows break or continue in a shell function to affect loops in the caller's context).
	shopt -q -u compat43

	if [ "${BASH_VERSINFO:-0}" -ge 5 ]; then

		# compat44
		# If set, Bash saves the positional parameters to BASH_ARGV and BASH_ARGC before they are used, regardless of whether or not extended debugging mode is enabled.
		shopt -q -u compat44

	fi

	# complete_fullquote
	# If set, Bash quotes all shell metacharacters in filenames and directory names when performing completion. If not set, Bash removes metacharacters such as the dollar sign from the set of characters that will be quoted in completed filenames when these metacharacters appear in shell variable references in words to be completed. This means that dollar signs in variable names that expand to directories will not be quoted; however, any dollar signs appearing in filenames will not be quoted, either. This is active only when bash is using backslashes to quote completed filenames. This variable is set by default, which is the default Bash behavior in versions through 4.2.
	shopt -q -s complete_fullquote

	# direxpand
	# If set, Bash replaces directory names with the results of word expansion when performing filename completion. This changes the contents of the readline editing buffer. If not set, Bash attempts to preserve what the user typed.
	shopt -q -u direxpand

	# dirspell
	# If set, Bash attempts spelling correction on directory names during word completion if the directory name initially supplied does not exist.
	shopt -q -s direxpand

	# dotglob
	# If set, Bash includes filenames beginning with a '.' in the results of filename expansion. The filenames '.' and '..' must always be matched explicitly, even if dotglob is set.
	shopt -q -s dotglob

	# execfail
	# If this is set, a non-interactive shell will not exit if it cannot execute the file specified as an argument to the exec builtin command. An interactive shell does not exit if exec fails.
	shopt -q -u execfail

	# expand_aliases
	# If set, aliases are expanded as described below under Aliases, Aliases. This option is enabled by default for interactive shells.
	shopt -q -s expand_aliases

	# extdebug
	# If set at shell invocation, or in a shell startup file, arrange to execute the debugger profile before the shell starts, identical to the --debugger option. If set after invocation, behavior intended for use by debuggers is enabled:
	shopt -q -u extdebug

	# extglob
	# If set, the extended pattern matching features described above (see Pattern Matching) are enabled.
	shopt -q -s extglob

	# extquote
	# If set, $'string' and $"string" quoting is performed within ${parameter} expansions enclosed in double quotes. This option is enabled by default.
	shopt -q -s extquote

	# failglob
	# If set, patterns which fail to match filenames during filename expansion result in an expansion error.
	shopt -q -u failglob

	# force_fignore
	# If set, the suffixes specified by the FIGNORE shell variable cause words to be ignored when performing word completion even if the ignored words are the only possible completions. See Bash Variables, for a description of FIGNORE. This option is enabled by default.
	shopt -q -s force_fignore

	# globasciiranges
	# If set, range expressions used in pattern matching bracket expressions (see Pattern Matching) behave as if in the traditional C locale when performing comparisons. That is, the current locale's collating sequence is not taken into account, so 'b' will not collate between 'A' and 'B', and upper-case and lower-case ASCII characters will collate together.
	shopt -q -s globasciiranges

	# globstar
	# If set, the pattern '**' used in a filename expansion context will match all files and zero or more directories and subdirectories. If the pattern is followed by a '/', only directories and subdirectories match.
	shopt -q -s globstar

	# gnu_errfmt
	# If set, shell error messages are written in the standard GNU error message format.
	shopt -q -s gnu_errfmt

	# histappend
	# If set, the history list is appended to the file named by the value of the HISTFILE variable when the shell exits, rather than overwriting the file.
	shopt -q -s histappend

	# histreedit
	# If set, and Readline is being used, a user is given the opportunity to re-edit a failed history substitution.
	shopt -q -s histreedit

	# histverify
	# If set, and Readline is being used, the results of history substitution are not immediately passed to the shell parser. Instead, the resulting line is loaded into the Readline editing buffer, allowing further modification.
	shopt -q -u histverify

	# hostcomplete
	# If set, and Readline is being used, Bash will attempt to perform hostname completion when a word containing a '@' is being completed (see Commands For Completion). This option is enabled by default.
	shopt -q -s hostcomplete

	# huponexit
	# If set, Bash will send SIGHUP to all jobs when an interactive login shell exits (see Signals).
	shopt -q -s huponexit

	# inherit_errexit
	# If set, command substitution inherits the value of the errexit option, instead of unsetting it in the subshell environment. This option is enabled when POSIX mode is enabled.
	shopt -q -u inherit_errexit

	# interactive_comments
	# Allow a word beginning with '#' to cause that word and all remaining characters on that line to be ignored in an interactive shell. This option is enabled by default.
	shopt -q -s interactive_comments

	# lastpipe
	# If set, and job control is not active, the shell runs the last command of a pipeline not executed in the background in the current shell environment.
	shopt -q -u lastpipe

	# lithist
	# If enabled, and the cmdhist option is enabled, multi-line commands are saved to the history with embedded newlines rather than using semicolon separators where possible.
	shopt -q -u lithist

	if [ "${BASH_VERSINFO:-0}" -ge 5 ]; then

		# localvar_inherit
		# If set, local variables inherit the value and attributes of a variable of the same name that exists at a previous scope before any new value is assigned. The nameref attribute is not inherited.
		shopt -q -u localvar_inherit

		# localvar_unset
		# If set, calling unset on local variables in previous function scopes marks them so subsequent lookups find them unset until that function returns. This is identical to the behavior of unsetting local variables at the current function scope.
		shopt -q -u localvar_unset

	fi

	# login_shell
	# The shell sets this option if it is started as a login shell (see Invoking Bash). The value may not be changed.
	shopt -q -s login_shell

	# mailwarn
	# If set, and a file that Bash is checking for mail has been accessed since the last time it was checked, the message "The mail in mailfile has been read" is displayed.
	shopt -q -s mailwarn

	# no_empty_cmd_completion
	# If set, and Readline is being used, Bash will not attempt to search the PATH for possible completions when completion is attempted on an empty line.
	shopt -q -u no_empty_cmd_completion

	# nocaseglob
	# If set, Bash matches filenames in a case-insensitive fashion when performing filename expansion.
	shopt -q -u nocaseglob

	# nocasematch
	# If set, Bash matches patterns in a case-insensitive fashion when performing matching while executing case or [[ conditional commands, when performing pattern substitution word expansions, or when filtering possible completions as part of programmable completion.
	shopt -q -u nocasematch

	# nullglob
	# If set, Bash allows filename patterns which match no files to expand to a null string, rather than themselves.
	# This can do some bad things, like with ls '*.xyz'
	shopt -q -u nullglob

	# progcomp
	# If set, the programmable completion facilities (see Programmable Completion) are enabled. This option is enabled by default.
	shopt -q -s progcomp

	if [ "${BASH_VERSINFO:-0}" -ge 5 ]; then

		#progcomp_alias
		#If set, and programmable completion is enabled, Bash treats a command name that doesn't have any completions as a possible alias and attempts alias expansion. If it has an alias, Bash attempts programmable completion using the command word resulting from the expanded alias.
		shopt -q -u progcomp_alias

	fi

	#promptvars
	#If set, prompt strings undergo parameter expansion, command substitution, arithmetic expansion, and quote removal after being expanded as described below (see Controlling the Prompt). This option is enabled by default.
	shopt -q -s promptvars

	#restricted_shell
	#The shell sets this option if it is started in restricted mode (see The Restricted Shell). The value may not be changed. This is not reset when the startup files are executed, allowing the startup files to discover whether or not a shell is restricted.
	shopt -q -u restricted_shell

	#shift_verbose
	#If this is set, the shift builtin prints an error message when the shift count exceeds the number of positional parameters.
	shopt -q -s shift_verbose

	#sourcepath
	#If set, the source builtin uses the value of PATH to find the directory containing the file supplied as an argument. This option is enabled by default.
	shopt -q -s sourcepath

	if [ "${BASH_VERSINFO:-0}" -ge 5 ]; then

		#xpg_echo
		#If set, the echo builtin expands backslash-escape sequences by default.
		shopt -q -u xpg_echo

	fi

	return 0

}

shell_options || {
	echo "ERROR: Failed to set one or more Shell Options for Bash using shopt!"
}
