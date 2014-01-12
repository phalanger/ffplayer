#! /bin/sh

PWD=`pwd`

if [ !-f /usr/bin/gas-preprocessor.pl ];then
	echo "Installing gas-preprocessor ..."
	sudo cp gas-preprocessor/gas-preprocessor.pl /usr/bin
	sudo chmod a+x gas-preprocessor/gas-preprocessor.pl
	sudo chmod a+w gas-preprocessor/gas-preprocessor.pl
fi

cd ffmpeg
echo "Install ffmpeg ..."
chmod a+x build-ffmpeg.sh
./build-ffmpeg.sh

