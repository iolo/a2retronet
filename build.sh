#!/bin/bash
cmake -S . -B build -DPICO_BOARD=pico2 -DPICO_PLATFORM=rp2350
cmake --build build --config Release -j $(nproc)
