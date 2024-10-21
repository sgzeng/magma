#!/bin/bash

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
# - env TARGET: path to target work dir
# - env OUT: path to directory where artifacts are stored
# - env SHARED: path to directory shared with host (to store results)
# - env PROGRAM: name of program to run (should be found in $OUT)
# - env ARGS: extra arguments to pass to the program
##

mkdir -p "$SHARED/findings"

export AFL_SKIP_CPUFREQ=1
export AFL_NO_AFFINITY=1
export RUST_LOG=info
"$FUZZER/afl/afl-fuzz" -M afl-master -m 100M -i "$TARGET/corpus/$PROGRAM" \
    -o "$SHARED/findings" \
    -- "$OUT/afl/$PROGRAM" $ARGS 2>&1 &

FUZZER_PID=$!

while ps -p $FUZZER_PID > /dev/null 2>&1 && \
    [[ ! -f "$SHARED/findings/afl-master/fuzzer_stats" ]]; do
    inotifywait -qq -t 1 -e create "$SHARED/findings" &> /dev/null
done

if [[ -f "$SHARED/findings/afl-master/fuzzer_stats" ]]; then
    "$FUZZER/symsan/target/release/fastgen" \
        --sync_afl -i "$TARGET/corpus/$PROGRAM" -t "$OUT/symsantrack/$PROGRAM" -o "$SHARED/findings"  \
        -- "$OUT/symsanfast/$PROGRAM" $ARGS &> "$SHARED/symsan.log"
fi
