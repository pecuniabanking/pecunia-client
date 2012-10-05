#!/bin/bash
lib_dir="/temp/relinstall/lib"
ex_dir="@executable_path/../lib"
source_dir="/temp/relinstall/lib"

install_name_tool -id $ex_dir/libgnutls.12.dylib $source_dir/libgnutls.dylib

install_name_tool -id $ex_dir/libgnutls-extra.12.dylib $source_dir/libgnutls-extra.dylib
install_name_tool -change $lib_dir/libgnutls.12.dylib $ex_dir/libgnutls.12.dylib $source_dir/libgnutls-extra.dylib

install_name_tool -id $ex_dir/libgnutls-openssl.12.dylib $source_dir/libgnutls-openssl.dylib
install_name_tool -change $lib_dir/libgnutls.12.dylib $ex_dir/libgnutls.12.dylib $source_dir/libgnutls-openssl.dylib







