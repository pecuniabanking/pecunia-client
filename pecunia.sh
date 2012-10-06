#!/bin/bash
folder="`dirname "$0"`"
echo $folder
export DYLD_LIBRARY_PATH="$folder/lib"
echo $DYLD_LIBRARY_PATH
"$folder"/MacOS/Pecunia
