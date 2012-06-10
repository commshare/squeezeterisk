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
cd..

echo echo "STAGE 6: generic configuration files"
echo "3 Seconds to press CTRL-C to abort..."
sleep 3
rm -rf /etc/asterisk
mkdir -p /etc/asterisk
cp configs/*.conf /etc/asterisk
cp configs/usbradio/*.conf /etc/asterisk
mv /etc/asterisk/zaptel.conf /etc

echo echo "STAGE 7: node configuration files"
echo "3 Seconds to press CTRL-C to abort..."
if [ -z $USERID ] || [ -z $PSWD ]
then
	promptstr "Enter your Allstar Portal user id"
	USERID=$ANSWER
	promptpswd "Enter your Allstar Portal password"
	PSWD=$ANSWER
fi
curl -sk -m 15 --retry 1 https://config.allstarlink.org/portal/_config/get_available_configs.php?username=$USERID\&password=$PSWD > config.cfg
N=`wc -l config.cfg | awk ' { print $1; } '`
SEL=`cat config.cfg | cut -f2 -d','`
CFGID=`cat config.cfg | cut -f1 -d','`
if [ $N -lt 1 ]
then
	echo "No valid configurations found"
	exit 1
fi
grep \< config.cfg > /dev/null 2>&1
if [ $? -eq 0 ]
then
	echo "Invalid username or password"
	exit 1;
fi
echo "#Allstar Portal Configuration file" > /etc/portal-config.tmp
echo "#Written at "`date` >> /etc/portal-config.tmp
echo "# *** NOTE: THIS FILE IS AUTOMATICALLY GENERATED ***" >> /etc/portal-config.tmp
echo >> /etc/portal-config.tmp
echo "USERID=$USERID" >> /etc/portal-config.tmp
echo "PASSWORD=$PSWD" >> /etc/portal-config.tmp
if [ $N -gt 1 ]
then
	SEL=`grep SERVER $PORTAL_CONFIG | cut -f2 -d=`
	CFGID=`grep CFGID $PORTAL_CONFIG | cut -f2 -d=`
	if [ -z $SEL ] || [ -z $CFGID ]
	   then
	   echo "Unable to determine Server info from preconfiguration file"
	   rm -rf $TMP
	   exit 1
	   GOTANS=1
	fi
    
	while [ $GOTANS -eq 0 ]
	do
		echo "Please select one of the following servers"
		echo
		I=1
		while [ $I -le $N ]
		do
			read LINE
			S=`echo $LINE | cut -f2 -d,`
			echo "$I)  $S"
			let I="$I+1"
		done < config.cfg
		echo
		promptnum "Please make your selection (1-$N)"
		if [ $ANSWER -lt 1 ] || [ $ANSWER -gt $N ]
		then
			echo "Im sorry, that selection is invalid"
			echo
		else
			GOTANS=1
			GOTIT=0
			I=1
			while [ $I -le $ANSWER ]
			do 
				read LINE
				S=`echo $LINE | cut -f2 -d,`
				C=`echo $LINE | cut -f1 -d,`
				let I="$I+1"
			done < config.cfg
			SEL=$S
			CFGID=$C
		fi	
	done
fi






