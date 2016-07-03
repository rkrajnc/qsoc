#!/bin/sh

NAME="OR1200-DIVTEST"

echo "$NAME BENCH : starting ..."

# dirs
echo "$NAME BENCH : making dirs ..."
rm -rf out/
mkdir -p out/{wav,hex,bin,log}

# make model
echo "$NAME BENCH : making C model ..."
gcc -Wall or1200_divtest_model.c -o out/bin/or1200_divtest_model
if (($? != 0)); then
  echo "$NAME : FAILED building C model, exiting."
  exit 1
fi

# run model
echo "$NAME BENCH : running C model ..."
out/bin/or1200_divtest_model > out/hex/model_out.hex

# make or1200 fw
echo "$NAME BENCH : making OR1200 fw ..."
make -C ../../bench/or1200_divtest/fw clean all 1>/dev/null
if (($? != 0)); then
  echo "$NAME : FAILED building OR1200 fw, exiting."
  exit 1
fi

# build sim
echo "$NAME BENCH : building sim ..."
iverilog -g2012 -I ../../rtl/or1200/ ../../bench/or1200_divtest/or1200_divtest_tb.v ../../rtl/or1200/*.v ../../rtl/qmem/qmem_arbiter.v ../../bench/qmem/qmem_slave.v  -o out/bin/or1200_divtest
if (($? != 0)); then
  echo "$NAME : FAILED building sim, exiting."
  exit 1
fi

# run sim
echo "$NAME BENCH : running sim ..."
vvp out/bin/or1200_divtest -fst
if (($? != 0)); then
  echo "$NAME : FAILED running sim, exiting."
  exit 1
fi

# compare outputs
diff -s out/hex/model_out.hex out/hex/sim_out.hex
if (($? == 0)); then
  echo "$NAME : outputs match."
  echo "$NAME : PASSED."
  exit 0
else
  echo "$NAME : outputs mismatch."
  echo "$NAME : FAILED."
  exit 1
fi

