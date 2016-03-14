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

# check config file
[ ! -f /opt/mikro-rc_v1/mikro-rc.database.en ] && echo -e "\e[91m[-]\e[0m Error: can not find config file" && exit 1

# data base location, Don not change this form
database_en="/opt/mikro-rc_v1/mikro-rc.database.en"

# print header on terminal
reset
echo '[+] ------------------------------------------------------------------- [+]'
echo -e "[+] Programming and idea by : \e[1mE2MA3N [Iman Homayouni]\e[0m"
echo '[+] License : GPL v3.0'
echo -e '[+] mikro-rc v1.0 \n'


# decrypt database
echo -en "[+] Enter password: " ; read -s pass
database_de=`openssl aes-256-cbc -pass pass:$pass -d -a -in $database_en 2> /dev/null`
if [ "$?" != "0" ] ; then
	echo -e "\n[-] Error: Database can not decrypted."
	echo '[+] ------------------------------------------------------------------- [+]'
	exit 1
else
	echo
fi


# print server's informations on terminal
echo -e "\n 0) Edite Database"
var0=`echo "$database_de" | wc -l`
var0=`expr $var0 - 12`
for (( i=1 ; i <= $var0 ; i++ )) ; do
	echo -ne " $i) " ; echo "$database_de" | tail -n $i | head -n 1 | cut -d " " -f 1,2 | tr " " @
done


# edite database function
function edit_db {
	echo "$database_de" > /opt/mikro-rc_v1/mikro-rc.database.de
	nano /opt/mikro-rc_v1/mikro-rc.database.de
	echo -en "[+] encrypt new database, Please type your password: " ; read -s pass
	openssl aes-256-cbc -pass pass:$pass -a -salt -in /opt/mikro-rc_v1/mikro-rc.database.de -out $database_en
	rm -f /opt/mikro-rc_v1/mikro-rc.database.de &> /dev/null
	echo -e "\n[+] Done, New database saved and encrypted"
	echo '[+] ------------------------------------------------------------------- [+]'
	exit 0
}


# select server for continue
while :; do
	echo -en '\e[0m\n[+] Select your server/option or type exit for quit: ' ; read q1

	if [ "$q1" = "0" ] ; then
		edit_db
	fi

	if [ "$q1" -le "$var0" ] 2> /dev/null ; then
		break
	elif [ "$q1" = "exit" ] ; then
		echo "[+] Done"
		echo '[+] ------------------------------------------------------------------- [+]'
		exit 0
	else
		echo "[-] Error: bad input"
		echo '[+] ------------------------------------------------------------------- [+]'
		exit 1
	fi
done


# router information
password=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 4`
username=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 1`
ip_address=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 2`
ssh_port=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 3`
WAN1=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 5`
WAN2=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 6`
RM1=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 7`
RM2=`echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 8`


# status, checking up or down
sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port 'ip firewall mangle print count-only' > /tmp/01 2> /dev/null
if [ "$?" = "0" ] ; then
	echo -ne "\n You selected: \e[92m" ; echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 2
else
	echo -ne "\n You selected: \e[91m" ; echo "$database_de" | tail -n $q1 | head -n 1 | cut -d " " -f 2
	echo -e '\e[0m Can not connect to router\n'
	echo '[+] ------------------------------------------------------------------- [+]'
	exit 1
fi


# get data from router
number=`cat -A /tmp/01 | tr -d '^M$'`
sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port 'ip firewall mangle print' > /tmp/mikro-rc.out2 2> /dev/null
sed '1d' /tmp/mikro-rc.out2 > /tmp/mikro-rc.out3
sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port 'ip route print terse' > /tmp/mikro-rc.out1 2> /dev/null
m=`cat /tmp/mikro-rc.out1 | grep routing-mark | grep -o X | wc -l`


# print option 0 on terminal
echo -en '\e[0m 0) Manage load balancing, '

# check status for option 0
n=`cat /tmp/mikro-rc.out3 | grep -o X | wc -l`
if [ "$n" = "8" ] && [ "$m" = "2" ] ; then
		echo -e "\e[91minactive\e[0m"
	elif [ "$n" = "0" ] && [ "$m" = "0" ] ; then
		if [ "`cat /tmp/mikro-rc.out1 | grep routing-mark | wc -l`" = "0" ] ; then
			echo -e "\e[93mproblem\e[0m"
		elif [ "`cat /tmp/mikro-rc.out3 | wc -l`" = "0" ] ; then
			echo -e "\e[93mproblem\e[0m"
		else
			echo -e "\e[92mactive\e[0m"
		fi
	else
		echo -e "\e[93mproblem\e[0m"
	fi


# check connection on WAN 1
cat /tmp/mikro-rc.out1 | grep $WAN1 | awk "! /$RM1/" | grep X &> /dev/null
[ "$?" = "0" ] && j=1

# check connection on WAN 2
cat /tmp/mikro-rc.out1 | grep $WAN2 | awk "! /$RM2/" | grep X &> /dev/null
[ "$?" = "0" ] && k=2

[ -z $j ] && [ -z $k ] && j=0
[ ! -z $j ] && [ ! -z $k ] && j=2

if [ "$j" = "0" ] ; then
	isp="$WAN1 and $WAN2"

elif [ "$j" = "2" ] ; then
	isp='nowhere'

elif [ "$j" = "1" ] ; then
	isp="$WAN2"

elif [ "$k" = "2" ] ; then
	isp="$WAN1"
fi


# check status for option 1
if [ "$isp" = "$WAN1" ] ; then
	echo -e " 1) Default gateway is $isp,\e[93m Change to $WAN2\e[0m"
elif [ "$isp" = "$WAN2" ] ; then
	echo -e " 1) Default gateway is $isp,\e[93m Change to $WAN1\e[0m"
elif [ "$isp" = "$WAN1 and $WAN2" ] ; then
	echo -e " 1) Default gateway is $isp,\e[93m Change it\e[0m"
elif [ "$isp" = "nowhere" ] ; then
	echo -e " 1) Default gateway is $isp,\e[93m Change it\e[0m"
fi

# print option 2 on terminal
echo ' 2) Disable all gateways'

# print option 3 on terminal
echo -e ' 3) Exit\n'

# Which option ? select... 
echo -en "[+] Select your option: " ; read q2

# if user select option 0 ...
if [ "$q2" = "0" ]  ; then
	echo -e '\n 1) Active'
	echo ' 2) Inactive'
	echo -e ' 3) Exit\n'
	echo -en '[+] Select: ' ; read q3

	if [ "$q3" = "1" ] ; then
		cmd=`for (( i=0 ; i < $number ; i++ )) ; do
		echo -n ",$i" ; done`
		cmd=`echo $cmd | cut -c 2-`

		# Enable mangle rules
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip firewall mangle enable numbers=$cmd" &> /dev/null
		
		# Enable load balancing routes
		for i in `cat /tmp/mikro-rc.out1 | grep routing-mark | cut -d ' ' -f 2` ; do
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route enable numbers=$i" &> /dev/null
		done

		if [ "$?" = "0" ] ; then
			echo "[+] Done"
		else
			echo "[-] Error: command not executed"
		fi
		echo '[+] ------------------------------------------------------------------- [+]'
		exit 0

	elif [ "$q3" = "2" ] ; then
		cmd=`for (( i=0 ; i < $number ; i++ )) ; do
		echo -n ",$i" ; done`
		cmd=`echo $cmd | cut -c 2-`

		# Disable mangle rules
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip firewall mangle disable numbers=$cmd" &> /dev/null
		
		# Disable load balancing routes
		for i in `cat /tmp/mikro-rc.out1 | grep routing-mark | cut -d ' ' -f 2` ; do
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
        done

        if [ "$?" = "0" ] ; then
			echo "[+] Done"
		else
			echo "[-] Error: command not executed"
		fi
		echo '[+] ------------------------------------------------------------------- [+]'
		exit 0

	# clear exit
    elif [ "$q3" = "3" ] ; then
    	echo '[+] Done'
    	echo '[+] ------------------------------------------------------------------- [+]'
    	exit 0

    # if user insert bad input ...
    else
    	echo '[+] Error: Bad input'
    	echo '[+] ------------------------------------------------------------------- [+]'
    	exit 1
    fi

# if user select option 1 ...
elif [ "$q2" = "1" ] ; then
	if [ "$isp" = "$WAN1" ] ; then

		# set default gateway on WAN2
		i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN2" | awk "! /$RM2/" | cut -d ' ' -f 2`
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route enable numbers=$i" &> /dev/null
		
		if [ "$?" = "0" ] ; then
			echo "[+] $WAN2 gw was enable successfully"
		else
			echo "[-] Error: we have problem to enable $WAN2"
		fi
		

		# unset default gateway on WAN1
		i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN1" | awk "! /$RM1/" | cut -d ' ' -f 2`
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
		
		if [ "$?" = "0" ] ; then
			echo "[+] $WAN1 gw was disable successfully"
		else
			echo "[-] Error: we have problem to disable $WAN1"
		fi

		echo '[+] ------------------------------------------------------------------- [+]'
		exit 0

	elif [ "$isp" = "$WAN2" ] ; then

		# set default gateway on WAN1
		i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN1" | awk "! /$RM1/" | cut -d ' ' -f 2`
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route enable numbers=$i" &> /dev/null
		
		if [ "$?" = "0" ] ; then
			echo "[+] $WAN1 gw was enable successfully"
		else
			echo "[-] Error: we have problem to enable $WAN1"
		fi


		# unset default gateway on WAN2
		i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN2" | awk "! /$RM2/" | cut -d ' ' -f 2`
		sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
		
		if [ "$?" = "0" ] ; then
			echo "[+] $WAN2 gw disable successfully"
		else
			echo "[-] Error: we have problem to disable $WAN2"
		fi

		echo '[+] ------------------------------------------------------------------- [+]'
		exit 0

	elif [ "$isp" = "$WAN1 and $WAN2" ] ; then
		echo -e "\n 1) Disable $WAN1"
		echo " 2) Disable $WAN2"
		echo ' 3) Disable both'
		echo -e ' 4) Exit\n'
		echo -en '[+] Select your option: ' ; read gw

		if [ "$gw" = "1" ] ; then

			# unset default gateway on WAN1
			i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN1" | awk "! /$RM1/" | cut -d ' ' -f 2`
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
			
			if [ "$?" = "0" ] ; then
				echo "[+] Done"
			else
				echo "[-] Error: command not executed"
			fi

			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		elif [ "$gw" = "2" ] ; then

			# unset default gateway on WAN2
			i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN2" | awk "! /$RM2/" | cut -d ' ' -f 2`
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
			
			if [ "$?" = "0" ] ; then
				echo "[+] Done"
			else
				echo "[-] Error: command not executed"
			fi
			
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		elif [ "$gw" = "3" ] ; then

			# unset default gateway on WAN2
			i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN2" | awk "! /$RM2/" | cut -d ' ' -f 2`
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
			
			if [ "$?" = "0" ] ; then
				echo "[+] $WAN2 gw was disable successfully"
			else
				echo "[-] Error: we have problem to disable $WAN2"
			fi

			# unset default gateway on WAN1
			i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN1" | awk "! /$RM1/" | cut -d ' ' -f 2`
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
			
			if [ "$?" = "0" ] ; then
				echo "[+] $WAN1 gw disable successfully"
			else
				echo "[-] Error: we have problem to disable $WAN1"
			fi

			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		# clear exit
		elif [ "$gw" = "4" ] ; then
			echo "[+] Done"
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		# if user insert bad input ...
		else
			echo '[+] Error: Bad input'
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 1
		fi

	elif [ "$isp" = "nowhere" ] ; then
		echo -e "\n 1) Change gateway to $WAN1"
		echo " 2) Change gateway to $WAN2"
		echo -e ' 3) Exit\n'
		echo -en '[+] Select gateway: ' ; read gw

		if [ "$gw" = "1" ] ; then

			# set default gateway on WAN1
			i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN1" | awk "! /$RM1/" | cut -d ' ' -f 2`
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route enable numbers=$i" &> /dev/null
			
			if [ "$?" = "0" ] ; then
				echo "[+] Done"
			else
				echo "[-] Error: command not executed"
			fi
			
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		elif [ "$gw" = "2" ] ; then

			# set default gateway on WAN2
			i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN2" | awk "! /$RM2/" | cut -d ' ' -f 2`
			sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route enable numbers=$i" &> /dev/null
			
			if [ "$?" = "0" ] ; then
				echo "[+] Done"
			else
				echo "[-] Error: command not executed"
			fi
			
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		# clear exit
		elif [ "$gw" = "3" ] ; then
			echo "[+] Done"
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 0

		# if user insert bad input ...
		else
			echo '[+] Error: Bad input'
			echo '[+] ------------------------------------------------------------------- [+]'
			exit 1
		fi
	fi

# if user select option 2 ...
elif [ "$q2" = "2" ] ; then

	# unset default gateway on WAN1
	i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN1" | awk "! /$RM1/" | cut -d ' ' -f 2`
	sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
	
	if [ "$?" = "0" ] ; then
		echo "[+] $WAN1 gw disable successfully"
	else
		echo "[-] Error: we have problem to disable $WAN2"
	fi

	# unset default gateway on WAN2
	i=`cat /tmp/mikro-rc.out1 | grep 'dst-address=0.0.0.0/0' | grep "gateway=$WAN2" | awk "! /$RM2/" | cut -d ' ' -f 2`
	sshpass -p "$password" ssh -o StrictHostKeyChecking=no -l $username $ip_address -p $ssh_port "ip route disable numbers=$i" &> /dev/null
	
	if [ "$?" = "0" ] ; then
		echo "[+] $WAN2 gw disable successfully"
	else
		echo "[-] Error: we have problem to disable $WAN2"
	fi

	echo '[+] ------------------------------------------------------------------- [+]'
	exit 0

# if user select option 3 ...
elif [ "$q2" = "3" ] ; then
	echo "[+] Done"
	echo '[+] ------------------------------------------------------------------- [+]'
	exit 0

# if user insert bad input ...
else
	echo '[+] Error: Bad input'
	echo '[+] ------------------------------------------------------------------- [+]'
	exit 1
fi
