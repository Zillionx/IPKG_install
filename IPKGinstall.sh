#!/bin/sh
# Synology ipkg installer
reboot=0
if [ -d "/volume1/@optware" ]; then
	reboot=1
	rm -rf /volume1/@optware
fi
if [ -d "/usr/lib/ipkg" ]; then
	reboot=1
	rm -rf /usr/lib/ipkg
fi
if [ -d "/opt/etc/ipkg.conf" ]; then
	rm -f /opt/etc/ipkg.conf
fi
if [ -d "/root/ipkgtmp" ]; then
	reboot=1
	rm -rf /root/ipkgtmp
fi

proc=$(cat /proc/cpuinfo | grep -m 1 'model name' | cut -d ":" -f 2 | cut -d "@" -f 1 )
echo ""
echo "================================================================================"
echo "According to cpuinfo, your processor is a:$proc"
echo ""
echo "1) Intel XScale FW IXP420 BB ARM"
echo "2) Intel Atom D410 x86"
echo "3) PPC 8241"
echo "4) PPC 8533 PPC et 8543"
echo "5) ARM mv5281"
echo "6) ARM Marvel Kirkwood mv6281"
echo "7) ARM Marvel Kirkwood mv6282"
echo ""
read -p "Please type the number here above matching of your processor (1-7):" CHOICE

case "$CHOICE" in
   1) packUri="http://ipkg.nslu2-linux.org/feeds/optware/ds101/cross/unstable/"
	  pack="ds101-bootstrap_1.0-4_armeb.xsh"
   ;;
   2) packUri="http://ipkg.nslu2-linux.org/feeds/optware/syno-i686/cross/unstable/"
	  pack="syno-i686-bootstrap_1.2-7_i686.xsh"
   ;;
   3) packUri="http://ipkg.nslu2-linux.org/feeds/optware/ds101g/cross/stable/"
	  pack="ds101-bootstrap_1.0-4_powerpc.xsh"
   ;;
   4) packUri="http://ipkg.nslu2-linux.org/feeds/optware/syno-e500/cross/unstable/"
	  pack="syno-e500-bootstrap_1.2-7_powerpc.xsh"
   ;;
   5) packUri="http://ipkg.nslu2-linux.org/feeds/optware/syno-x07/cross/unstable/"
	  pack="syno-x07-bootstrap_1.2-7_arm.xsh"
   ;;
   6) packUri="http://ipkg.nslu2-linux.org/feeds/optware/cs08q1armel/cross/unstable/"
	  pack="syno-mvkw-bootstrap_1.2-7_arm.xsh"
   ;;
   7) packUri="http://wizjos.endofinternet.net/synology/archief/"
	  pack="syno-mvkw-bootstrap_1.2-7_arm-ds111.xsh"
   ;;
   *) echo "you didn't pick a valid number"
	  pack=""
   ;;
esac
echo ""
echo ""
if [ "$pack" != "" ]; then
	Uri=$packUri$pack
	mkdir /root/ipkgtmp/
	wget -P /root/ipkgtmp/ $Uri

	echo ""
	echo "================================================================================"
	echo ""

	echo "[$(date)] Installing IPKG..." > /root/ipkg.log
	echo "sh /root/ipkgtmp/$pack >> /root/ipkg.log &" > /root/ipkgtmp/installIpkg
	echo "until grep -q \"Setup complete\" /root/ipkg.log; do sleep 1; done" >> /root/ipkgtmp/installIpkg
	echo "if [ -f '/etc/rc.local.bkp' ]; then"  >> /root/ipkgtmp/installIpkg
	echo "	mv /etc/rc.local.bkp /etc/rc.local" >> /root/ipkgtmp/installIpkg
	echo "fi"  >> /root/ipkgtmp/installIpkg
	echo "rm -rf /root/ipkgtmp" >> /root/ipkgtmp/installIpkg
	echo "ipkg update" >> /root/ipkgtmp/installIpkg
	echo "ipkg upgrade" >> /root/ipkgtmp/installIpkg

	if ! grep -q '/opt/bin:/opt/sbin' "/root/.profile"; then
		echo "PATH=/opt/bin:/opt/sbin:\$PATH" >> /root/.profile
		echo "export PATH" >> /root/.profile
	fi

	if [ "$reboot" == "1" ]; then
		echo ""
		read -p "May I reboot before proceeding further with the setup (y/n)? " CHOICE
		if [ "$CHOICE" == "y" ] || [ "$CHOICE" == "Y" ]; then
			echo "sh /root/ipkgtmp/installIpkg" >> /etc/crontab
			if [ -f "/etc/rc.local" ]; then
				if ! grep -q 'Ipkg setup' "/etc/rc.local"; then
					echo "" > /etc/ipkg.local
					echo "# Ipkg setup" >> /etc/ipkg.local
					echo "[ -x /root/ipkgtmp/installIpkg ] && /root/ipkgtmp/installIpkg" >> /etc/ipkg.local

					cp /etc/rc.local /etc/rc.local.bkp
					sed -i '/.!.bin.sh/r /etc/ipkg.local' /etc/rc.local
					rm /etc/ipkg.local
				fi
				chmod 775 /root/ipkgtmp/installIpkg
				reboot
			else
				echo "Missing /etc/rc.local."
				echo "Reboot manually and then run: sh /root/ipkgtmp/installIpkg"
			fi
		else
			echo ""
			echo ""
			echo "Reboot manually and then run: sh /root/ipkgtmp/installIpkg"
			exit
		fi
	else
		sh /root/ipkgtmp/installIpkg
	fi
fi
