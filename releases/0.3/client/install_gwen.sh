prefix="/temp/relinstall"
ex_dir="@executable_path/../lib"

	
install_name_tool -id $ex_dir/libgwenhywfar.47.dylib $prefix/lib/libgwenhywfar.dylib
install_name_tool -change $prefix/lib/libgwenhywfar.47.dylib $ex_dir/libgwenhywfar.47.dylib $prefix/lib/gwenhywfar/plugins/47/dbio/xmldb.so
install_name_tool -change $prefix/lib/libgwenhywfar.47.dylib $ex_dir/libgwenhywfar.47.dylib $prefix/lib/gwenhywfar/plugins/47/dbio/olddb.so
install_name_tool -change $prefix/lib/libgwenhywfar.47.dylib $ex_dir/libgwenhywfar.47.dylib $prefix/lib/gwenhywfar/plugins/47/dbio/csv.so

install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/gwenhywfar/plugins/47/dbio/swift.so
install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/gwenhywfar/plugins/47/dbio/dtaus.so

install_name_tool -change $prefix/lib/libgwenhywfar.47.dylib $ex_dir/libgwenhywfar.47.dylib $prefix/lib/gwenhywfar/plugins/47/ct/ohbci.so
install_name_tool -change $prefix/lib/libgwenhywfar.47.dylib $ex_dir/libgwenhywfar.47.dylib $prefix/lib/gwenhywfar/plugins/47/configmgr/dir.so
