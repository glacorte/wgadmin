#!/bin/ksh
#  
# Copyright (c) 2021, Guillermo La Corte <beaterbsd@protonmail.com>
# ------------------------------------------------------------------------------
# Misc functions
# ------------------------------------------------------------------------------

# Print error message to stderr and exit the script.
err_exit() {
	print -u2 -- "$*"
	exit 1
}

# Show usage of the wireguard admin script and exit.
usage() {
	err_exit "usage: ${0##*/} [-ax] [-f filename] [-m adduser | edituser | rmuser | addif | editif | rmif]"
}

# ------------------------------------------------------------------------------
# Utils functions
# ------------------------------------------------------------------------------

# Sort and print unique list of provided arguments.
bsort() {
	local _a=$1 _b _l

	(($#)) && shift || return

	for _b; do
		[[ $_a == "$_b" ]] && continue
		if [[ $_a > $_b ]]; then
			_l="$_a $_l" _a=$_b
		else
			_l="$_b $_l"
		fi
	done

	# Output the smallest value found.
	(($#)) && echo -n "$_a " || echo -n "$_a"

	# Sort remaining values.
	bsort $_l
}

# Test the first argument against the remaining ones, return success on a match.
isin() {
	local _a=$1 _b

	shift
	for _b; do
		[[ $_a == "$_b" ]] && return 0
	done
	return 1
}

# Add first argument to list formed by the remaining arguments.
# Adds to the tail if the element does not already exist.
addel() {
	local _a=$1

	shift
	isin "$_a" $* && echo -n "$*" || echo -n "${*:+$* }$_a"
}

# Remove all occurrences of first argument from list formed by the remaining
# arguments.
rmel() {
	local _a=$1 _b _c

	shift
	for _b; do
		[[ $_a != "$_b" ]] && _c="${_c:+$_c }$_b"
	done
	echo -n "$_c"
}

# If possible, print the timestamp received from the ftplist.cgi output,
# adjusted with the time elapsed since it was received.
http_time() {
	local _sec=$(cat $HTTP_SEC 2>/dev/null)

	[[ -n $_sec && -n $CGI_TIME ]] &&
		echo $((CGI_TIME + SECONDS - _sec))
}

# Prints the supplied parameters properly escaped for future sh/ksh parsing.
# Quotes are added if needed, so you should not do that yourself.
quote() (
	# Since this is a subshell we won't pollute the calling namespace.
	for _a; do
		alias Q=$_a; _a=$(alias Q); print -rn -- " ${_a#Q=}"
	done | sed '1s/ //'
	echo
)

# Show a list of ordered arguments (read line by line from stdin) in column
# output using ls.
show_cols() {
	local _l _cdir=/tmp/i/cdir _clist

	mkdir -p $_cdir
	rm -rf -- $_cdir/*
	while read _l; do
		[[ -n $_l ]] || continue
		mkdir -p /tmp/i/cdir/"$_l"
		_clist[${#_clist[*]}]="$_l"
	done
	(cd $_cdir; ls -Cdf "${_clist[@]}")
	rm -rf -- $_cdir
}

# Echo file $1 to stdout. Skip comment lines. Strip leading and trailing
# whitespace if IFS is set.
stripcom() {
	local _file=$1 _line

	[[ -f $_file ]] || return

	set -o noglob
	while read _line; do
		[[ -n ${_line%%#*} ]] && echo $_line
	done <$_file
	set +o noglob
}

# Create a temporary directory based on the supplied directory name prefix.
tmpdir() {
	local _i=1 _dir

	until _dir="${1?}.$_i.$RANDOM" && mkdir -- "$_dir" 2>/dev/null; do
		((++_i < 10000)) || return 1
	done
	echo "$_dir"
}

# Generate unique filename based on the supplied filename $1.
unique_filename() {
	local _fn=$1 _ufn

	while _ufn=${_fn}.$RANDOM && [[ -e $_ufn ]]; do :; done
	print -- "$_ufn"
}

# Let rc.firsttime feed file $1 using $2 as subject to whatever mail system we
# have at hand by then.
prep_root_mail() {
	local _fn=$1 _subject=$2 _ufn

	[[ -s $_fn ]] || return

	_ufn=$(unique_filename /mnt/var/log/${_fn##*/})
	cp $_fn $_ufn
	chmod 600 $_ufn
	_ufn=${_ufn#/mnt}

	cat <<__EOT >>/mnt/etc/rc.firsttime
( /usr/bin/mail -s '$_subject' root <$_ufn && rm $_ufn ) >/dev/null 2>&1 &
__EOT
}

# Examine the contents of the dhcpleased lease file $1 for a line containing the
# field(s) provided as parameters and return the value of the first field found.
#
# Note that value strings are VIS_SAFE'd.
lease_value() {
	local _lf=$1 _o _opt _val

	[[ -s $_lf ]] || return
	shift

	for _o; do
		while read -r _opt _val; do
			[[ $_opt == ${_o}: ]] && echo "$_val" && return
		done < "$_lf"
	done
}

# Extract one boot's worth of dmesg.
dmesgtail() {
	dmesg | sed -n 'H;/^OpenBSD/h;${g;p;}'
}
