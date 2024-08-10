#settings
set PORT 34560

# Window
wm title . "Server"

label .file -textvariable env(var_file)
label .status -textvariable env(var_status) -foreground "grey"
label .addr -textvariable env(var_addres) -foreground "blue"

button .open -text "Choose" -width 10 -command open_file
button .send -text "Send" -width 10 -command send_file

grid .addr -columnspan 2 -sticky news
grid .file -columnspan 2 -sticky news
grid .status -columnspan 2 -sticky news
grid .open .send -sticky news

set env(var_file) " - "
set env(var_status) "Waiting"
set env(full_name) ""
set env(is_connected) false
set env(var_addres) " - "


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
  if {$env(is_connected) && [gets $env(var_socket) line] > 0} {
    set env(var_status) "Receiving ..."
    set name [lindex $line 0]
    set size [lindex $line 1]
    set env(var_file) $name

    # read data
    set fp [open $name w]
    fconfigure $fp -translation binary
    fcopy $env(var_socket) $fp -size $size
    close $fp  
    set env(var_status) "Received"
  }   
}

# Channel configuration
proc new_connection {channel addr port} {
  global env

  set env(is_connected) true
  set env(var_status) "Ready"
  set env(var_socket) $channel
  set env(var_addres) $addr
  fconfigure $channel -translation binary
  fileevent $channel readable file_receive
}

# Create server
socket -server new_connection $PORT
