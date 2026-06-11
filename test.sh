#!/usr/bin/env bash
set -e

gas=false
verbose=false

while getopts d:g:p:t:v flag; do
	case "${flag}" in
	d) directory=${OPTARG} ;;
	g) gas=true ;;
	p) profile=${OPTARG} ;;
	t) test=${OPTARG} ;;
	v) verbose=true ;;
	esac
done

export FOUNDRY_PROFILE=$profile

# Use the Seismic-flavored forge for the seismic profile (mercury EVM, ssolc).
# Stock forge can't parse shielded types like suint256.
if [ "$FOUNDRY_PROFILE" = "seismic" ]; then
	forge_bin=sforge
else
	forge_bin=forge
fi

echo Using profile: $FOUNDRY_PROFILE
echo Forge binary: $forge_bin
echo Higher verbosity: $verbose
echo Gas report: $gas
echo Test Match pattern: $test

if [ "$verbose" = false ]; then
	verbosity="-vv"
else
	verbosity="-vvvv"
fi

if [ "$gas" = false ]; then
	gasReport=""
else
	gasReport="--gas-report"
fi

if [ -z "$test" ]; then
	if [ -z "$directory" ]; then
		"$forge_bin" test --match-path "test/*" $gasReport $verbosity --force
	else
		"$forge_bin" test --match-path "$directory/*.t.sol" $gasReport $verbosity --force
	fi
else
	"$forge_bin" test --match-test "$test" $gasReport $verbosity --force
fi
