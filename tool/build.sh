#!/usr/bin/env bash
EXIT_CODE=0

dartfmt --set-exit-if-changed -n . || EXIT_CODE=$?
dartanalyzer --fatal-infos --fatal-warnings . || EXIT_CODE=$?
tool/coverage.sh || EXIT_CODE=$?

exit $EXIT_CODE