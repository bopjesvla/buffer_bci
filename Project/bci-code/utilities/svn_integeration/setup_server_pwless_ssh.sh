#!/bin/sh
#script to setup ssh keys for server matlab

cd ~
if [ ! -d .ssh ]; then
	mkdir .ssh
	echo "Making .ssh"
fi
cd .ssh
if [ ! -r id_rsa ]; then
	echo "Leave Password EMPTY When Prompted"
	ssh-keygen -t rsa
	echo "Enter your password when prompted"
fi
uname=$1;
if [ -z "$uname" ]; then
  uname=$USER
fi
scp ~/.ssh/id_rsa.pub $uname@mmmxserver.nici.ru.nl:~/authorized_key_new
echo "Once again, Enter your for password when prompted"
ssh $uname@mmmxserver.nici.ru.nl 'mkdir ~/.ssh; cat authorized_key_new >> ~/.ssh/authorized_keys ; rm authorized_key_new;'

