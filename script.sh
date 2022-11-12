 #!/bin/bash
 
 su -
 
 apt install sed grep gawk curl gnupg dirmngr lsb-release ca-certificates ubuntu-keyring debian-keyring debian-archive-keyring

 key_id='573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62'
 key_gpg="/usr/share/keyrings/nginx-archive-keyring.gpg"
 
 gpg --keyserver keyserver.ubuntu.com --recv-keys $key_id 2>/dev/null 1>/dev/null
 if [ "$?" = "0" ]; then ubuntu=y; else ubuntu=n; fi
 
 gpg --keyserver keyserver.debian.com --recv-keys $key_id 2>/dev/null 1>/dev/null
 if [ "$?" = "0" ]; then debian=y; else debian=n; fi
 
 BASE="$ubuntu $debian"
 
 case $BASE in *y*) gpg --export --armor $key_id | apt-key add - 2>/dev/null 1>/dev/null && \
 apt-key export $key_id 2>/dev/null | gpg --yes --dearmor -o $key_gpg ;; *) echo "ERROR: gpg and/or distro-based identity.." && exit 1 ;; esac
 
 if [ "$ubuntu" = "y" ]; then distro=ubuntu; elif [ "$debian" = "y" ]; then distro=debian; fi
 
 codename=$(lsb_release -cs 2>/dev/null)
 
 codenames_for_ubuntu_based=$(curl -s https://nginx.org/packages/ubuntu/dists/ | grep '<a' | sed -e 's/"/ /g' -e 's,/,,g' | awk '{print $3}');
 codenames_for_debian_based=$(curl -s https://nginx.org/packages/debian/dists/ | grep '<a' | sed -e 's/"/ /g' -e 's,/,,g' | awk '{print $3}');
 
 if [ "$distro" = "ubuntu" ]; then for x in $codenames_for_ubuntu_based; do if [ "$identity" = "" ]; then \
 if [ "$codename" = "$x" ]; then identity="$x"; fi; fi; done; fi
 
 if [ "$distro" = "debian" ]; then for x in $codenames_for_debian_based; do if [ "$identity" = "" ]; then \
 if [ "$codename" = "$x" ]; then identity="$x"; fi; fi; done; fi
 
 if [ "$identity" = "" ]; then echo "ERROR: the code name "$codename" is not available.." && exit 1; fi
 
 echo "deb http://nginx.org/packages/${distro} ${codename} nginx" > /etc/apt/sources.list.d/nginx.list
 
 printf "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx

 apt update -y
