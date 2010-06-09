#!/bin/bash
ex_dir="@executable_path/../lib"
lib_dir="/temp/relinstall/lib"
source_dir="/temp/relinstall/lib"

install_name_tool -id $ex_dir/libintl.3.dylib $source_dir/libintl.dylib

install_name_tool -id $ex_dir/libgettextsrc-0.14.5.dylib $source_dir/libgettextsrc.dylib
install_name_tool -change $lib_dir/libgettextlib-0.14.5.dylib $ex_dir/libgettextlib-0.14.5.dylib $source_dir/libgettextsrc.dylib
install_name_tool -change $lib_dir/libintl.3.dylib $ex_dir/libintl.3.dylib $source_dir/libgettextsrc.dylib

install_name_tool -id $ex_dir/libgettextpo.0.dylib $source_dir/libgettextpo.dylib
install_name_tool -change $lib_dir/libgettextsrc-0.14.5.dylib $ex_dir/libgettextsrc-0.14.5.dylib $source_dir/libgettextpo.dylib
install_name_tool -change $lib_dir/libgettextlib-0.14.5.dylib $ex_dir/libgettextlib-0.14.5.dylib $source_dir/libgettextpo.dylib
install_name_tool -change $lib_dir/libintl.3.dylib $ex_dir/libintl.3.dylib $source_dir/libgettextpo.dylib

install_name_tool -id $ex_dir/libgettextlib-0.14.5.dylib $source_dir/libgettextlib.dylib
install_name_tool -change $lib_dir/libintl.3.dylib $ex_dir/libintl.3.dylib $source_dir/libgettextlib.dylib



