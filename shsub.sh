#!/bin/sh
#
# the user interface of shsub <https:/github.com/dongyx/shsub>
# piping the output of tc to shell
#
# tokens surrounded by `__`, like `__version__`
# is intended to be substituted at building time
# using a macro processor like m4 .

set -e

cleanup() {
	[ -p "$fifo" ] && rm "$fifo"
	if [ -n $tcpid ]; then
		ppid="$(ps -p$tcpid -oppid | awk 'NR>1{print $1}')"
		[ "$ppid" = $$ ] && kill "$ppid"
	fi
	wait
	exit $1
}

tc="$(dirname "$0")/tc"
sh=/bin/sh

while getopts 's:hv' opt; do
	case $opt in
		s) sh="$OPTARG";;
		h)
			cat <<-'.'
			__usage__
			.
			exit;;
		v)
			cat <<-'.'
			shsub __version__

			__license__
			.
			exit;;
	esac
done
shift $(($OPTIND - 1))

if [ $# -gt 0 ]; then
	fifo=$(mktemp -u)
	mkfifo -m600 "$fifo"
	"$tc" <"$1" >"$fifo" & tcpid=$!
	trap "cleanup 0" EXIT
	trap "cleanup $((128 + 15))" TERM
	trap "cleanup $((128 + 2))" INT
	"$sh" "$fifo"
else
	"$tc" | "$sh"
fi
