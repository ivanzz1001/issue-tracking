#!/bin/bash

ethtool -C eth20 rx-usecs 64 rx-frames 128
ethtool -C eth21 rx-usecs 64 rx-frames 128
