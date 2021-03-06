#! /bin/bash
function die {
	echo "Fatal error: $1"
	exit 255
}

function promptnum
{
	ANSWER=""
	while [ -z $ANSWER  ] || [[ ! $ANSWER =~ [0-9]{1,}$ ]]
	do
        	echo -n "$1: "
        	read ANSWER
	done
}

function promptstr
{
	ANSWER=""
	while [ -z $ANSWER  ] || [[ ! $ANSWER =~ [\/,0-9,a-z,A-Z]{3,}$ ]]
	do
        	echo -n "$1: "
        	read ANSWER
	done
}

function promptpswd
{
	ANSWER=""
	while [ -z $ANSWER  ] || [[ ! $ANSWER =~ [\/,0-9,a-z,A-Z]{3,}$ ]]
	do
        	echo -n "$1: "
        	read -s ANSWER
	done
	echo ""
}

function promptyn
{
        echo -n "$1 [y/N]? "
        read ANSWER
	if [ ! -z $ANSWER ]
	then
       		if [ $ANSWER = Y ] || [ $ANSWER = y ]
      		then
                	ANSWER=Y
        	else
                	ANSWER=N
        	fi
	else
		ANSWER=N
	fi
}

function promptny
{
        echo -n "$1 [Y/n]? "
        read ANSWER
	if [ ! -z $ANSWER ]
	then
       		if [ $ANSWER = N ] || [ $ANSWER = n ]
      		then
                	ANSWER=N
        	else
                	ANSWER=Y
        	fi
	else
		ANSWER=Y
	fi
}

echo "STAGE 1: update system files"
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
echo "Removing cdrom from sources.list"
sed -i -e "s/deb cdrom/# deb cdrom/g" /etc/apt/sources.list
echo "Updating System Packages..."
apt-get -qq update 
if [ $? -gt 0 ]
then
	die "Unable to update Debian sources"
fi
apt-get -qq -y install ntp
if [ $? -gt 0 ]
then
        die "Unable to install newt"
fi
apt-get -qq -y install ntp
if [ $? -gt 0 ]
then
        die "Unable to install ntp"
fi
apt-get -qq -y install screen
if [ $? -gt 0 ]
then
        die "Unable to install screen"
fi
apt-get -qq -y install sox
if [ $? -gt 0 ]
then
        die "Unable to install sox"
fi
apt-get -qq -y install gawk
if [ $? -gt 0 ]
then
        die "Unable to install misc tools"
fi
apt-get -qq -y install curl
if [ $? -gt 0 ]
then
        die "Unable to install curl"
fi

apt-get -qq -y install libcurl4-openssl-dev
if [ $? -gt 0 ]
then
        die "Unable to install libcurl"
fi

apt-get -qq -y install openssh-server
if [ $? -gt 0 ]
then
        die "Unable to install openssh-server"
fi


apt-get -qq -y install build-essential linux-headers-`uname -r`
if [ $? -gt 0 ]
then
	die "Unable install Build Enviornment"
	sleep 30
	exit 255
fi
apt-get -qq -y install zlib1g-dev libasound2-dev libnewt-dev libssl-dev libusb-dev  libncurses5-dev
if [ $? -gt 0 ]
then
	die "Unable install development library headers"
	sleep 30
	exit 255
fi
apt-get -qq -y install zsync
if [ $? -gt 0 ]
then
	die "Unable install ZSync"
	sleep 30
	exit 255
fi
echo "STAGE 2: zaptel"
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
cd /usr/src/squeezeterisk/zaptel
./configure
if [ $? -gt 0 ]
then
	echo "Failure: Unable to configure zaptel"
	exit 255
fi
if [ $? -gt 0 ]
then
	echo "Failure: Unable to compile zaptel"
	exit 255
fi
make install
if [ $? -gt 0 ]
then
	echo "Failure: Unable to install zaptel"
	exit 255
fi
make config
if [ $? -gt 0 ]
then
	echo "Failure: Unable to install zaptel configs"
	exit 255
fi
/etc/init.d/zaptel start

echo "STAGE 3: libpri"
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
cd libpri
make
if [ $? -gt 0 ]
then
	echo "Failure: Unable to compile libpri"
	exit 255
fi
make install
if [ $? -gt 0 ]
then
	echo "Failure: Unable to install LibPRI 2"
	exit 255
fi
cd ..

echo "STAGE 4: asterisk"
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
cd asterisk
./configure
if [ $? -gt 0 ]
then
	echo "Failure: Unable to configure asterisk"
	exit 255
fi
make
if [ $? -gt 0 ]
then
	echo "Failure: Unable to compile asterisk"
	exit 255
fi
make install
if [ $? -gt 0 ]
then
	echo "Failure: Unable to install asterisk"
	exit 255
fi
make config
if [ $? -gt 0 ]
then
	echo "Failure: Unable to install asterisk configs" 
	exit 255
fi
echo "STAGE 5: audio files"
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
echo "Copying rpt sounds..."
cp -a sounds/* /var/lib/asterisk/sounds
if [ $? -gt 0 ]
then
	echo "Failure: Unable to copy rpt sounds"
	exit 255
fi
cd ..





