#!/usr/bin/expect
set user [lindex $argv 0]
set pwd [lindex $argv 1]
send_user "!!!Set user:$user, password:$pwd...\n"
spawn passwd $user
expect "password:"
send "$pwd\r"
expect "password:"
send "$pwd\r"
expect eof