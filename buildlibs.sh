cd ~/Desktop/Programmierung

prefix="/temp/install"

export CFLAGS="-I$prefix_lib/include -DHAVE_CARBON" 
export LDFLAGS="-L$prefix_lib/lib -framework Carbon"

lib_dir="/temp/relinstall/lib"
ex_dir="@executable_path/../lib"

install_name_tool -id $ex_dir/libpth.14.dylib $lib_dir/libpth.dylib
install_name_tool -id $ex_dir/libgpg-error.0.dylib $lib_dir/libgpg-error.dylib
install_name_tool -id $ex_dir/libgcrypt.11.dylib $lib_dir/libgcrypt.dylib
install_name_tool -id $ex_dir/libgmp.3.dylib $lib_dir/libgmp.dylib
install_name_tool -id $ex_dir/libktoblzcheck.1.dylib $lib_dir/libktoblzcheck.dylib


cd libiconv-1.12
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd pth-1.4.1
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd libgpg-error-1.6
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd libgcrypt-1.4.0
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd gmp-4.2.2
make clean
./configure --prefix=$prefix ABI=32 || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd gettext-0.14.5
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd gnutls-1.2.11
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install || exit 2;
cd ..

cd ktoblzcheck-1.16
make clean
./configure --prefix=$prefix || exit 2;
make || exit 2;
make install
cd ..






