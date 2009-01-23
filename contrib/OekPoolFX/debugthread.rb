def getDebugThread()
  return Thread.new {
  
    puts("Ready for input:")
    while($exit_flag == false)
    
    # wait for user input
    command = gets
    
    # evaluate user input
    evalCommand(command[0,command.length - 1])
    
    end
  }
end

# evaluates the given string and perfoms the command the user typed in
def evalCommand(command)
    
  # splitting command into single arguments
  command_arr = command.split(" ")
  
  # on shutdown command issuing shutdown sequence
  if command_arr[0] == "exit" or command_arr[0] == "quit"
    puts("Leaving...")
    $exit_flag = true
    $hostListMutex.synchronize(){
      $hostList.each do |key,host|
        if host[:pingThread] != nil
          host[:pingThread].kill()
        end
        if host[:sshThread] != nil
          host[:sshThread].kill()
        end
      end
    }
  
  # evaluate the print command
  elsif command_arr[0] == "print"
    
    # return if subcommand is missing
    if command_arr.length < 2
      puts "Missing arguments."
      return
    end
    
    # evaluating subcommand
    case command_arr[1].downcase
    
    # user wishes information about the hosts in the given pool
    when "hosts" then
      unless command_arr.length < 3
        printHosts(command_arr[2])
      else
        puts("Missing arguments.")
      end
      
    # user wishes information about the available pools
    when "pools" then
      printPools()
      
    # user wishes information about pxe-menus assigned to the given host
    when "pxe" then
      unless command_arr.length < 4
        printPXE(command_arr[2], command_arr[3])
      else
        puts("Missing arguments.")
      end

    # user wishes to print out the host list
    when "list" then
      printHostlist()
      
    # on every other subcommand an error message is printed on the screen
    else
      puts("Only \"hosts\", \"pools\" and \"pxe\" are allowed as arguments")
    end
    
  # evaluate the "insert" command
  elsif command_arr[0] == "insert"
    if command_arr.length < 4
      puts("Missing arguments.")
    elsif command_arr.length < 5
      changePXE(command_arr[1], command_arr[2], command_arr[3], nil)
    else
      changePXE(command_arr[1], command_arr[2], command_arr[3], command_arr[4])
    end
    
  # evaluate the "delete" command
  elsif command_arr[0] == "delete"
    if command_arr.length < 3
      puts("Missing arguments.")
    else
      deleteHost(command_arr[1],command_arr[2])
    end
    
  elsif command_arr[0] == "set"
    puts("Not yet implemented.")
    
  else
    puts("No such command: #{command_arr[0]}")
  end
  
end

# print all available pools according to the database
def printHosts(pool)
  
  # Checks if the pools exists
  if $pool_hash.include?(pool) == false
    puts "No such pool"
    return
  end
  
  # print all hosts for the pool
  $pool_hash[pool][:hosts].each do |host_name,host_obj|
    puts host_name
  end
end

# print all available hosts for a pool according to the database
def printPools()
  $pool_hash.each do |pool_name,pool_obj|
    puts pool_name
  end
end

# print all available pxe menus for a host in a pool according to the database
def printPXE(pool, host)
  
  # checks if the pool exists
  if $pool_hash.include?(pool) == false
    puts "No such pool"
    return
  end
  
  # checks if the host exists
  if $pool_hash[pool][:hosts].include?(host) == false
    puts "No such host"
    return
  end
  
  # checks if the hosts has any pxe menus
  if $pool_hash[pool][:hosts][host][:pxe] == nil
    puts "Host does not contain any PXE information"
  else
    i = 1
    
    # prints all pxe menus the host has
    $pool_hash[pool][:hosts][host][:pxe].each do |info|
      puts i.to_s + ". " + info[:menu]
      i += 1
    end
  end
end

# inserts the give host with the given pxe menu into the hostlist
# one can choose whether to wake up the host or not
# if wake parameter is omitted the default wake behaviour for the menu is chosen
def changePXE(pool, host, pxe, wake)
  
  # checks if the pool exists
  if $pool_hash.include?(pool) == false
    puts "No such pool"
    return
  end
  
  # checks if the host exists
  if $pool_hash[pool][:hosts].include?(host) == false
    puts "No such host"
    return
  end
  
  # checks if the host has pxe menus
  if $pool_hash[pool][:hosts][host][:pxe] == nil
    puts "Host does not contain any PXE information"
  end
  
  # checks if the given pxe menu exists
  if $pool_hash[pool][:hosts][host][:pxe][pxe.to_i - 1] == nil
    puts "No such PXE menu"
    return
  end
  
  host_info = $pool_hash[pool][:hosts][host]
  
  # checks whether to wake or not to wake the client
  # (if argument is omitted default behaviour is applied)
  if wake == "wake"
    $pool_hash[pool][:hosts][host][:pxe][pxe.to_i - 1][:wake] = true
  elsif wake == "nowake"
    $pool_hash[pool][:hosts][host][:pxe][pxe.to_i - 1][:wake] = false
  end
  
  # insert the host into the hostlist
  $hostListMutex.synchronize{
    if $hostList.include?(host_info[:MAC]) == true
      puts("Host already in host list. Please delete host first.")
    else
      puts("Inserting host into host list.")
      $hostList[host_info[:MAC]] = $Host.new(host_info[:IP], host_info[:MAC],
                  host_info[:BC], host_info[:HostName], 0, $pool_hash[pool][:hosts][host][:pxe][pxe.to_i - 1],
                  nil, nil, true, false,
                  0, false, false, nil, nil, false, false, nil, nil, nil, nil)
    end
    
  }
end

# changes the state of the given host to shutdown
# so that it will be deleted for the host list
def deleteHost(pool, host)
  # checks if the pool exists
  if $pool_hash.include?(pool) == false
    puts "No such pool"
    return
  end
  
  # checks if the host exists
  if $pool_hash[pool][:hosts].include?(host) == false
    puts "No such host"
    return
  end
  
  host_info = $pool_hash[pool][:hosts][host]
  
  # deletes the host from the hostlist
  $hostListMutex.synchronize{
    if $hostList.include?(host_info[:MAC]) == false
      puts("Host is not in list.")
    else
      puts("Preparing host for removal.")
      $hostList[host_info[:MAC]][:warnTime] = Time.now
      $hostList[host_info[:MAC]][:shutDownTime] = Time.now + $WARN_TIME
      $hostList[host_info[:MAC]][:shutDown] = true
      $hostList[host_info[:MAC]][:toBeDeleted] = true
    end
    
  }
  
end

# shows information about the host which are currently in
# the host list
def printHostlist()

  # lock the list
  $hostListMutex.synchronize{

    # iterating over all items in host list
    $hostList.each do |key, value|
            
      # assign a string value to the current host's status
      if(value[:changePXE] == true) and (value[:shutDown] == false)
        status = "Waiting for PXE change"
      elsif(value[:ReadyForWakeUp] == true) and (value[:shutDown] == false)
        status = "PXE changed"
      elsif(value[:isWake] == true) and (value[:shutDown] == false)
        status = "Turned on"
      elsif(value[:wakeSSH] == true) and (value[:shutDown] == false)
        status = "SSH daemon started"
      elsif(value[:shutDown] == true)
        status = "Scheduled for shutdown"
      elsif(value[:isDown] == true)
        status = "Shut down"
      end
      
      # print the host information
      puts("host: #{value[:Name]}, IP: #{value[:IP]}, Status: #{status}")
      
    end
  }
end
