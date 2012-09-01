#!/bin/sh
# -------
# Usage sh unusedImages.sh (jpg|png|gif)
# -------
# Caveats
# 1 - This script would incorrectly list these images as unreferenced. For example, you might have
#     NSString *imageName = [NSString stringWithFormat:@"image_%d.png", 1];
#     This script will incorrectly think image_1.png is unreferenced.
# 2 - If you have a method, or variable with the same name as the image it won't pick it up

PROJ=`find . -name '*.xib' -o -name '*.[mh]' -o -name '*.storyboard' -o -name '*.plist'`

for imageName in `find . -name '*.'$1`
do
   name=`basename -s .$1 $imageName`
   name=`basename -s @2x $name`
   name=`basename -s ~ipad $name`
   name=`basename -s @iPad $name`

   if ! grep -q $name $PROJ; then
        echo "$imageName"
   fi
done
