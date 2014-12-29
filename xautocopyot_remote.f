#!/usr/bin/expect -f
#download
#usage: xautocopyot_remote.f 243 /home/gwac/software ip term_dir
set copy_file [lindex $argv 0]
set ip [lindex $argv 1]
set term_dir [lindex $argv 2]
set password 123456
set username gwac
spawn scp -r  $copy_file  $username@$ip:$term_dir
set timeout 300
expect {
"*yes/no*" {send "yes\r";exp_continue}
"*@$ip's password:" {send "$password\r";exp_continue}
}

