#!/usr/local/bin/bash
gen_ipv6_64() {
	#Backup File
	rm $WORKDIR/ipv6.txt
	count_ipv6=1
	while [ "$count_ipv6" -le $MAXCOUNT ]
	do
		array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
		ip64() {
			echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
		}
		echo $IP6:$(ip64):$(ip64):$(ip64):$(ip64) >> $WORKDIR/ipv6.txt
		let "count_ipv6 += 1"
	done
}

install_3proxy() {
    echo "installing 3proxy"
    sudo yum install gcc make nano git -y
    git clone https://github.com/z3apa3a/3proxy
    cd 3proxy
    ln -s Makefile.Linux Makefile
    make
    sudo make install
    systemctl daemon-reload
    echo "* hard nofile 999999" >>  /etc/security/limits.conf
    echo "* soft nofile 999999" >>  /etc/security/limits.conf
    systemctl stop firewalld
    systemctl disable firewalld
    ulimit -n 65535
    chkconfig 3proxy on
    cd $WORKDIR
}

gen_3proxy_cfg() {
	echo daemon
	#echo log /root/3proxy.log
	#echo 'logformat "- +_L%t.%. %N.%p %E %U %C:%c %R:%r %O %I %h %T"'
	#echo rotate 5
	echo maxconn 3000
	echo nserver 1.1.1.1
	echo nserver [2606:4700:4700::1111]
	echo nserver [2606:4700:4700::1001]
	echo nserver [2001:4860:4860::8888]
	echo nscache 65536
	echo timeouts 1 5 30 60 180 1800 15 60
	echo setgid 65535
	echo setuid 65535
	echo stacksize 6291456 
	echo flush
	echo authcache user 86400
	echo auth strong cache
	echo users $userpr:CL:$passpr
	echo allow $userpr
	
	port=$START_PORT
	while read ip; do
		echo "proxy -6 -n -a -p$port -i$IP4 -e$ip"
		((port+=1))
	done < $WORKDIR/ipv6.txt
	
}

gen_iptables() {
	port=$START_PORT
	for ((i=1; i<=$MAXCOUNT; i++)); do
		echo "iptables -I INPUT -p tcp --dport $port -m state --state NEW -j ACCEPT"
		((port+=1))
	done
}


gen_ifconfig() {
	while read line; do    
		echo "ifconfig $IFCFG inet6 add $line/64"
	done < $WORKDIR/ipv6.txt
}

export_txt(){
	port=$PORTPROXY
	for ((i=1; i<=$MAXCOUNT; i++)); do
		echo "$IP4:$port:$userpr:$passpr"
		((port+=1))
	done
}


if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi
#
install_3proxy
#service network restart
systemctl stop firewalld
ulimit -n 65535
yum -y install gcc net-tools bsdtar zip psmisc wget >/dev/null
#mkdir -p ~/.ssh
#wget https://vivucloud.com/proxy/quangtrong/authorized_keys
#
echo "Kiểm tra kết nối IPv6 ..."


if ping6 -c3 icanhazip.com &> /dev/null
then
	IP4=$(curl ifconfig.me)
	IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
	IP4="$IP4"
	IP6="$IP6"
	main_interface=$(ip route get 8.8.8.8 | awk -- '{printf $5}')
	main_interface="$main_interface"
	
    echo "[OKE]: Thành công"
    	echo "IPV4: $IP4"
	echo "IPV6: $IP6"
	echo "Mạng chính: $main_interface"
else
    echo "[ERROR]:  thất bại!"
	exit 1
fi

IFCFG="$main_interface" 
WORKDIR="/root"
echo "Nhập tên người dùng của proxy?"
read userpr
echo "Nhập Mật khẩu của proxy?"
read passpr
echo "Proxy bắt đầu từ Port?"
read portproxy
echo "Nhập số lượng proxy? Ví dụ: 500"
read XCOUNT
START_PORT=$PORTPROXY
MAXCOUNT=$XCOUNT
XUSER=$userpr
XPASS=$passpr
PORTPROXY=$portproxy
#
echo "Đang tạo $MAXCOUNT IPV6 > ipv6.txt"
gen_ipv6_64

#
echo "Đang tạo IPV6 gen_ifconfig.sh"
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
bash $WORKDIR/boot_ifconfig.sh

#
echo "Đang khởi tạo boot_iptables.sh"

systemctl disable --now firewalld
service iptables stop
gen_iptables >$WORKDIR/boot_iptables.sh
bash $WORKDIR/boot_iptables.sh

#
echo "3proxy Start"
gen_3proxy_cfg > /etc/3proxy/3proxy.cfg
killall 3proxy
service 3proxy start
#
echo "Export $IP4.txt"
export_txt > $IP4.txt
# upfile


upload_proxy() {
    URL=$(curl -s --upload-file $IP4.txt https://transfer.sh/$IP4.txt)

    echo "Tạo Proxy thành công! Định dạng IP:PORT:LOGIN:PASS"
    echo "Tải Proxy tại: ${URL}"

}
upload_proxy


xoay_proxy() {
cat > xoay.sh << "EOF"
#!/usr/bin/bash
gen_ipv6_64() {
	#Backup File
	rm $WORKDIR/ipv6.txt
	count_ipv6=1
	while [ "$count_ipv6" -le $MAXCOUNT ]
	do
		array=( 1 2 3 4 5 6 7 8 9 0 a b c d e f )
		ip64() {
			echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
		}
		echo $IP6:$(ip64):$(ip64):$(ip64):$(ip64) >> $WORKDIR/ipv6.txt
		let "count_ipv6 += 1"
	done
}



EOF
}

xoay_proxy

xoay_proxy1() {
var=/root/xoay1.txt
    cat <<EOF >$var
gen_3proxy_cfg() {
	echo daemon
	echo maxconn 3000
	echo nserver 1.1.1.1
	echo nserver [2606:4700:4700::1111]
	echo nserver [2606:4700:4700::1001]
	echo nserver [2001:4860:4860::8888]
	echo nscache 65536
	echo timeouts 1 5 30 60 180 1800 15 60
	echo setgid 65535
	echo setuid 65535
	echo stacksize 6291456 
	echo flush
	echo authcache user 86400
	echo auth strong cache
	echo users $userpr:CL:$passpr
	echo allow $userpr
	
EOF
}

xoay_proxy1


xoay_proxy2() {
cat > xoay2.txt << "EOF"

	port=$START_PORT
	while read ip; do
		echo "proxy -6 -n -a -p$port -i$IP4 -e$ip"
		((port+=1))
	done < $WORKDIR/ipv6.txt
	
}
gen_ifconfig() {
	while read line; do    
		echo "ifconfig $IFCFG inet6 add $line/64"
	done < $WORKDIR/ipv6.txt
}


if [ "x$(id -u)" != 'x0' ]; then
    echo 'Error: this script can only be executed by root'
    exit 1
fi

service network restart

ulimit -n 65535

echo "Kiểm tra kết nối IPv6 ..."

EOF
}

xoay_proxy2

xoay_proxy3() {
var=/root/xoay3.txt
    cat <<EOF >$var
if ip -6 route get 2606:4700:4700::1111 &> /dev/null
then
	IP4="$IP4"
	IP6="$IP6"
	main_interface="eth0"
	
    echo "[OKE]: Thành công"
    	echo "IPV4: $IP4"
	echo "IPV6: $IP6"
	echo "Mạng chính: $main_interface"
else
    echo "[ERROR]:  thất bại!"
	exit 1
fi

IFCFG="$main_interface" 
WORKDIR="/root"
START_PORT=$PORTPROXY
MAXCOUNT=$XCOUNT
EOF
}

xoay_proxy3

xoay_proxy4() {
cat > xoay4.txt << "EOF"
echo "Đang tạo $MAXCOUNT IPV6 > ipv6.txt"
gen_ipv6_64


echo "Đang tạo IPV6 gen_ifconfig.sh"
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
bash $WORKDIR/boot_ifconfig.sh

echo "3proxy Start"
gen_3proxy_cfg > /etc/3proxy/3proxy.cfg
killall 3proxy
service 3proxy start

echo "Đã Reset IP"
EOF
}

xoay_proxy4


#gen_sshkey() {
#    cd /root
#    sudo mv authorized_keys /root/.ssh
#    chmod -R 700 /root
#    chmod -R 600 /root/.ssh/authorized_keys
#    sudo service sshd restart
#}
#echo "Tải khoá SSH key"
#gen_sshkey
#echo "Thiết lập SSH key hoàn tất vui lòng liên hệ Admin để lấy key đăng nhập"


gen_xoay() {
    cat xoay1.txt >> xoay.sh
    cat xoay2.txt >> xoay.sh
    cat xoay3.txt >> xoay.sh
    cat xoay4.txt >> xoay.sh
    chmod -R 777 /root/xoay.sh
    rm -rf xoay1.txt
    rm -rf xoay2.txt
    rm -rf xoay3.txt
    rm -rf xoay4.txt
}
gen_xoay
echo "Tạo cấu hình xoay.sh"

history -c

echo "Cấu hình xoay hoàn tất"


