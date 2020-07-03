#!/bin/bash
mkdir expResult
for i in `seq 1 $1`
    do
        argos3 -c $2
        mv rewards.lua expResult/rewards$i.lua
        mv config.lua expResult/config$i.lua
    done