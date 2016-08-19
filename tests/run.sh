#!/bin/bash

scriptdir=$(cd $(dirname $0) && pwd)

while [ $# -gt 0 ] ; do
	case "$1" in
		--coverage) coverage=true ;;
		--coverage=*) coverage=${1##--coverage=} ;;
		*) exit 1 ;;
	esac
	shift
done

luvit_args=()
if [[ "${coverage}" ]] ; then
	luvit_args+=(-e 'jit.off(); jit.flush(); require("luacov");')
	if [[ "${coverage}" != *append* ]] ; then
		echo "Purging coverage stats ..."
		rm -f luacov.*.out
	fi
fi

luvit "${luvit_args[@]}" "${scriptdir}"/run.lua "${run_args[@]}"

if [[ "${coverage}" = *report* ]] ; then
	echo "Generating coverage report ..."
	luacov
fi
