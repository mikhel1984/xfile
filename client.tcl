#!/usr/bin/wish
#
# File exchange with server application.
#
# 2024, Stanislav Mikhel

# settings
set IP "127.0.0.1"  ;# server
set PORT 34560

# Window
wm title . "Client"

label .file -textvariable env(var_file)
label .status -textvariable env(var_status) -foreground "grey"

ttk::entry .ip -textvariable env(new_addres) -foreground "blue" -justify center

button .open -text "Choose" -width 10 -command open_file
button .send -text "Send" -width 10 -command send_file
button .upd -text "Update" -width 10 -command update_addr

grid .ip .upd -sticky news
grid .file -columnspan 2 -sticky news
grid .status -columnspan 2 -sticky news
grid .open .send -sticky news

set env(var_file) " - "
set env(var_status) "Waiting"
set env(full_name) ""
set env(is_connected) false
set env(ip_addres) $IP
set env(new_addres) $IP


# Choose file
proc open_file {} {
  global env
  set filename [tk_getOpenFile]
  if {$filename ne ""} {
    set env(full_name) $filename
    set env(var_file) [lindex [file split $filename] end]
  } else {
    set env(full_name) ""
  }
}

# Send the chosen file
proc send_file {} {
  global env

  if { $env(is_connected) } {
    # file info
    set size [file size $env(full_name)]
    set fp [open $env(full_name)]
    fconfigure $fp -translation binary
    set env(var_status) "Sending ..."
    # send info
    puts $env(var_socket) [list $env(var_file) $size]

    # send data
    fcopy $fp $env(var_socket) -size $size
    set env(var_status) "Sent"
    close $fp
  }
}

# Call on input stream
proc file_receive {} {
  global env

  # read info
  if {[gets $env(var_socket) line] > 0} {
    set env(var_status) "Receiving ..."
    set name [lindex $line 0]
    set size [lindex $line 1]
    set env(var_file) $name

    # read data
    set fp [open $name w]
    fconfigure $fp -translation binary
    fcopy $env(var_socket) $fp -size $size
    close $fp  
    set env(var_status) "Receive"
  }   
}

# Use new address
proc update_addr {} {
  global env

  if { [llength [split $env(new_addres) .]] == 4 } {
    set env(ip_addres) $env(new_addres)
  }
}

# Check if the client can be connected
proc try_connection {port} {
  global env

  # connect
  if { [catch {set channel [socket $env(ip_addres) $port]}] } {
    after 1000 [list try_connection $port]
  } else {
    set env(is_connected) true
    set env(var_status) "Ready"
    set env(var_socket) $channel
    fconfigure $channel -translation binary
    fileevent $channel readable file_receive
  }
}

# Create client
try_connection $PORT
