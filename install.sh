#! /bin/bash
# Programming and idea by : E2MA3N [Iman Homayouni]
# Github : https://github.com/e2ma3n
# Email : e2ma3n@Gmail.com
# Website : http://OSLearn.ir
# License : GPL v3.0
# mikro-rc v1.0 [ mikrotik load balancing and default route control ]
# ------------------------------------------------------------------ #


# check root privilege
[ "`whoami`" != "root" ] && echo -e '[-] Please use root user or sudo' && exit 1


# help function
function help_f {
	echo 'Usage: '
	echo '	sudo ./install.sh -i [install program]'
	echo '	sudo ./install.sh -u [help to uninstall program]'
	echo '	sudo ./install.sh -c [check dependencies]'
}


# install program on system
function install_f {
	[ ! -d /opt/mikro-rc_v1/ ] && mkdir -p /opt/mikro-rc_v1/ && echo "[+] Directory created" || echo "[-] Error: /opt/mikro-rc_v1/ exist"
	sleep 1
	[ ! -f /opt/mikro-rc_v1/mikro-rc.sh ] && cp mikro-rc.sh /opt/mikro-rc_v1/ && chmod 755 /opt/mikro-rc_v1/mikro-rc.sh && echo "[+] mikro-rc.sh copied" || echo "[-] Error: /opt/mikro-rc_v1/mikro-rc.sh exist"
	sleep 1
	[ ! -f /opt/mikro-rc_v1/mikro-rc.database.en ] && cp mikro-rc.database.en /opt/mikro-rc_v1/mikro-rc.database.en && chown root:root /opt/mikro-rc_v1/mikro-rc.database.en && chmod 700 /opt/mikro-rc_v1/mikro-rc.database.en && echo "[+] mikro-rc.database.en copied" || echo "[-] Error: /opt/mikro-rc_v1/mikro-rc.database.en exist"
	sleep 1
	[ -f /opt/mikro-rc_v1/mikro-rc.sh ] && ln -s /opt/mikro-rc_v1/mikro-rc.sh /usr/bin/mikro-rc && echo "[+] Symbolic link created" || echo "[-] Error: symbolic link not created"
	sleep 1
	[ ! -f /opt/mikro-rc_v1/README ] && cp README /opt/mikro-rc_v1/README && chmod 644 /opt/mikro-rc_v1/README && echo "[+] README copied" || echo "[-] Error: /opt/mikro-rc_v1/README exist"
	sleep 1

	echo "[+] Please see README"
	sleep 0.5
	echo "[!] Warning: run program and edit your database."
	sleep 0.5
	echo "[!] Warning: defaul password is 'mikro-rc'"
	sleep 0.5
	echo "[+] Done"
}


# uninstall program from system
function uninstall_f {
	echo 'For uninstall program:'
	echo '	sudo rm -rf /opt/mikro-rc_v1/'
	echo '	sudo rm -f /usr/bin/mikro-rc'
}


# check dependencies on system
function check_f {
	echo "[+] check dependencies on system:  "
	for program in whoami sleep cat head tail cut nano openssl sshpass expr grep
	do
		if [ ! -z `which $program 2> /dev/null` ] ; then
			echo -e "[+] $program found"
		else
			echo -e "[-] Error: $program not found"
		fi
		sleep 0.5
	done
}


case $1 in
	-i) install_f ;;
	-u) uninstall_f ;;
	-c) check_f ;;
	*) help_f ;;
esac
