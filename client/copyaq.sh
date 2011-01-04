#!/bin/sh

# copyaq.sh
# Pecunia
#
# Created by Frank Emminghaus on 20.06.10.
# Copyright 2010 Frank Emminghaus. All rights reserved.
echo "$TARGET_BUILD_DIR/Pecunia.app/Contents/Frameworks/AqBanking"
test -e "$TARGET_BUILD_DIR/Pecunia.app/Contents/Frameworks/AqBanking"
if [ $? -ne 0 ]; then
  echo "copy AqBanking libs"
  rsync -a --exclude '.svn/' 'us/' "$SRCROOT/AqBanking" "$TARGET_BUILD_DIR/Pecunia.app/Contents/Frameworks"
fi

