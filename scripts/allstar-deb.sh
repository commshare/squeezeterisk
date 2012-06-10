#! /bin/bash

HWTYPE=usbradio #HWTYPE=pciradio


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

echo "Updating System Packages..."
apt-get -qq update 
if [ $? -gt 0 ]
then
	die "Unable to update Debian sources"
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

echo "Downling allstar source code..."
echo "3 Seconds to press CTRL-C to abort . . ."
sleep 3

if [ -e /usr/src/astsrc ]
then
	echo "Local Archive Folder Already Exists"
fi
mkdir -p /usr/src/astsrc
cd /usr/src/astsrc

echo "Checking if archive file already exists..."
if [ -f /usr/src/astsrc.tar.gz ]
then
    echo "Archive file exists. Checking SHA"
    oldsha=$(shasum -a 256 "/usr/src/astsrc.tar.gz" |awk '{print $1}')
    wget -q http://stats.allstarlink.org/dl/installcd/files.tar.gz.sha256sum -O /usr/src/astsrc.tar.gz.sha256sum
    newsha=$(head -n 1 /usr/src/astsrc.tar.gz.sha256sum)
    if [ "$oldsha" == "$newsha" ]
    then   
        echo "Local archice file is validated..."
    else
        echo "Local archive is corrupt"
        echo "Getting files.tar.gz from http://dl.allstarlink.org..."
        wget -q http://dl.allstarlink.org/installcd/files.tar.gz -O /usr/src/astsrc.tar.gz
    fi
else
    echo "Local archive not found"
    echo "Getting files.tar.gz from http://dl.allstarlink.org..."
    wget -q http://dl.allstarlink.org/installcd/files.tar.gz -O /usr/src/astsrc.tar.gz
fi

if [ $? -gt 0 ]
then
	die "Unable to download files.tar.gz"
fi
echo "Unpacking files.tar.gz..."
cd /usr/src/astsrc
tar xfz ../astsrc.tar.gz 

if [ $? -gt 0 ]
then
	echo "Failure: Unable unpack files.tar.gz"
	exit 255
fi

echo "Downloading and Installing patches..."
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
wget -q https://digitalham.info/apprpt/zaptel-newer-kernels.patch -O /usr/src/astsrc/zaptel/zaptel-newer-kernels.patch
cd  /usr/src/astsrc/zaptel/
patch -p1 < /usr/src/astsrc/zaptel/zaptel-newer-kernels.patch
wget -q http://www.kd0eav.info/dl/chan_usbradio-newer-kernels.patch  -O /usr/src/astsrc/asterisk/chan_usbradio-newer-kernels.patch
cd /usr/src/astsrc/asterisk/
patch -p1 < /usr/src/astsrc/asterisk/chan_usbradio-newer-kernels.patch
rm -f /usr/src/astsrc/asterisk/menuselect.makeopts
rm -f /usr/src/astsrc/zaptel/menuselect.makeopts
rm -f /usr/src/astsrc/Makefile

echo "Installing zapta..."
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
make distclean clean uninstall-modules

echo "MENUSELECT_MODULES=ztdummy" > /etc/zaptel.makeopts
echo "MENUSELECT_UTILS=" >> /etc/zaptel.makeopts
echo "MENUSELECT_FIRMWARE=" >> /etc/zaptel.makeopts
echo "MENUSELECT_BUILD_DEPS=" >> /etc/zaptel.makeopts

 
cd /usr/src/astsrc/zaptel
./configure
make menuselect.makeopts


make
if [ $? -gt 0 ]
then
	echo "Failure: Unable to compile Zaptel 2"
	exit 255
fi
make install
if [ $? -gt 0 ]
then
	echo "Failure: Unable to compile Zaptel 3"
	exit 255
fi
make config
if [ $? -gt 0 ]
then
	echo "Failure: Unable to compile Zaptel 4"
	exit 255
fi
cd ..
