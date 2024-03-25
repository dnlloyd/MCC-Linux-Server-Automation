# https://www.tecmint.com/restrict-ssh-user-to-directory-using-chrooted-jail/
# https://www.redhat.com/sysadmin/set-linux-chroot-jails
# useradd bastion

# declare -A users

# users["s1"]=abc123
# users+=( ["s2"]=abc123 ["s3"]=abc123 )
# echo ${password} | passwd $username --stdin;

for user in ${users}
# for user in testy
do
  mkdir /home/$user
  mkdir /home/$user/dev/
  cd /home/$user/dev/
  
  mknod -m 666 null c 1 3
  mknod -m 666 tty c 5 0
  mknod -m 666 zero c 1 5
  mknod -m 666 random c 1 8

  chown root:root /home/$user
  chmod 0755 /home/$user

  mkdir -p /home/$user/bin
  cp -v /bin/bash /home/$user/bin/

  mkdir -p /home/$user/lib64
  cp -v /lib64/{libtinfo.so.6,libdl.so.2,libc.so.6,ld-linux-x86-64.so.2} /home/$user/lib64/

  useradd $user -p dontusemypassword
done
