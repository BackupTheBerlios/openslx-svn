# creates the thread
def getShutdownThread()
	return Thread.new {
    
    threadList = Hash.new
    
    while($exit_flag == false)
    
      $Log.debug "SHUTDOWN: Waking up..."
      
      currentTime = Time.now
      
      # lock the host list for other threads
      $hostListMutex.synchronize{
      
        # iterate over all hosts in list
        $hostList.each do |key,host|
          
          # check if host actually needs to be shut down
          if(host[:shutDown] == true) and ($hostList[key][:shutDownThread] == nil ) and (host[:shutDownTime] <= currentTime ) and (host[:isDown] == false)
            
            # if ssh connection can be established we can shut down the host via ssh
            if(host[:wakeSSH] == true)
              
              # kill the ssh thread and remove it from host list
              $hostList[key][:sshThread].kill()
              $hostList[key][:sshThread] = nil
              $Log.info "SHUTDOWN: Shutting down host #{host[:Name]}"
              
              # invoke shutdown sequence
              $hostList[key][:shutDownThread] = getHostShutdownThread(key, host)
              
            # if ssh connection cannot be established and host has not been forced
            # to boot, we have to distinguish to cases
            elsif(host[:wakeSSH] == false) and (host[:PXE][:wake] == false)
              
              # 1st case: host has been started
              # then we wait until ssh connection is possible
              if(host[:isWake] == true)
                
                next
                
              # 2nd case: host has not been started
              # then we just tidy up and mark it as down
              else
                
                $Log.info "SHUTDOWN: Shutting down host #{host[:Name]}"
                
                # kill ssh thread if running
                if($hostList[key][:sshThread] != nil)
                  $hostList[key][:sshThread].kill()
                  $hostList[key][:sshThread] = nil
                end
                
                # kill ping thread if running
                if($hostList[key][:pingThread] != nil)
                  $hostList[key][:pingThread].kill()
                  $hostList[key][:pingThread] = nil
                end
                
                # change state to "isDown"
                $state.change(key,$state.isDown)
              
              end
              
            # # if ssh connection cannot be established and host has been forced
            # to boot, something is wrong and we raise an error
            elsif(host[:wakeSSH] == false) and (host[:PXE][:wake] == true)
              $Log.error "SHUTDOWN: Shutdown error for host #{host[:Name]} (SSH connection not possible but supposed to)"
              host[:sshErr] = Time.now
            end
            
            # delete the Boot-Menu after shutdown
            pxeBootFile = $TFTP_ROOT_DIR + "/pxelinux.cfg/" + $utility.getHostFile(host[:MAC])
            if File.exists?(pxeBootFile)
              File.delete(pxeBootFile)
            end
            
          end
          
        end
      
      }
      
      $Log.debug "SHUTDOWN: Going to sleep..."
      
      sleep($utility.computeSleepTime(20))
      
    end
    $Log.debug "SHUTDOWN: Thread is shutting down..."
	}
end

# creates the shutdown thread for the given host
def getHostShutdownThread(key, host)
  
  return Thread.new(key,host){ |hostKey,currentHost|
    
    # try to shut down the host via ssh
    begin
      Net::SSH.start(host[:IP], $SSH_USER) do |session|
    
        session.open_channel do |channel|
        
          channel.exec("shutdown -h now")
        
        end
      
        session.loop
      
      end
    
      # lock the host list
      $hostListMutex.synchronize{
      
        # mark the host as "down"
        $state.change(hostKey,$state.isDown)
        $hostList[key][:shutDownThread] = nil
        $hostList[key][:warnThread] = nil
      
      }
      
    # if something happens during ssh connection
    # an error is written to the log
    rescue
    
    $Log.error "SHUTDOWN: Shutdown error for host #{host[:Name]} (unexpected error during SSH session)"
    
    end
  $Log.debug "SHUTDOWN: Thread is shutting down..."
  }
  
end