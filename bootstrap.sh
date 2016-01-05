#! /bin/sh

d=`date --date="%Y-%m-%dS%H:%M:%S"`
tmp="/tmp/dots_$d"
mkdir $tmp
cd $tmp

curl -O https://opscode-omnibus-packages.s3.amazonaws.com/debian/6/x86_64/chef_12.6.0-1_amd64.deb |sudo dpkg -i 


