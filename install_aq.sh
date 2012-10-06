prefix="/temp/relinstall"
ex_dir="@executable_path/../lib"

	
        install_name_tool -id $ex_dir/libaqbanking.20.dylib $prefix/lib/libaqbanking.dylib

        install_name_tool -id $ex_dir/libaqhbci.13.dylib $prefix/lib/libaqhbci.dylib
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/libaqhbci.dylib

        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/bankinfo/at.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/bankinfo/ca.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/bankinfo/ch.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/bankinfo/de.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/bankinfo/us.so

        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/csv.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/dtaus.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/eri2.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/ofx.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/openhbci1.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/sepa.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/swift.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/xmldb.so
        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/imexporters/yellownet.so

        install_name_tool -change $prefix/lib/libaqbanking.20.dylib $ex_dir/libaqbanking.20.dylib $prefix/lib/aqbanking/plugins/20/providers/aqhbci.so
        install_name_tool -change $prefix/lib/libaqhbci.13.dylib $ex_dir/libaqhbci.13.dylib $prefix/lib/aqbanking/plugins/20/providers/aqhbci.so
