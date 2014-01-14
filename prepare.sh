#! /bin/sh

MYPWD=`pwd`

sudo gem install cocoapods

if [ ! -f /usr/bin/gas-preprocessor.pl ];then
	echo "Installing gas-preprocessor ..."
	sudo cp gas-preprocessor/gas-preprocessor.pl /usr/bin
	sudo chmod a+x gas-preprocessor/gas-preprocessor.pl
	sudo chmod a+w gas-preprocessor/gas-preprocessor.pl
fi

cd ffmpeg
echo "Install ffmpeg ..."
chmod a+x build-ffmpeg.sh
./build-ffmpeg.sh

cd $MYPWD
echo "Link the libs ..."
rm -rf "./ffmpeg/libs"
rm -rf "./ffmpeg/include"
ln -s "$MYPWD/ffmpeg/build/built/universal/lib" "./ffmpeg/libs"
ln -s "$MYPWD/ffmpeg/build/built/universal/include" "./ffmpeg/include"
