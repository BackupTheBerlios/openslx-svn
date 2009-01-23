# include the necessary libraries
require 'socket'
require 'net/ssh'

# creates the thread
def getSSHThread()
  
  return Thread.new {
  
  threadList = Hash.new
  
  while($exit_flag == false)
  
    $Log.debug "SSH: Waking up..."
  
    # lock the host list for other threads
    $hostListMutex.synchronize {
    
      # iterate over all hosts
      $hostList.each do |hostKey,host|
      
        # applies if host responds to ping, is not already observed by a ssh thread and is not marked for shutdown
        if(host[:isWake] == true) and ($hostList[hostKey][:sshThread] == nil) and (host[:shutDown] == false)
          
          $Log.info "SSH: Creating ssh thread for \"#{host[:Name]}\""
          
          # kill the ping thread
          $hostList[hostKey][:pingThread].kill()
          $hostList[hostKey][:pingThread] = nil
          
          # create a ssh thread to observe current host
          $hostList[hostKey][:sshThread] =  getSshCheckThread(hostKey, host)
        
        end
      
      end
    }
    $Log.debug "SSH: Going to sleep..."
    
    # sleep until second 42 of current minute or second 12 of next minute
    sleep($utility.computeSleepTime(12))
  end
  $Log.debug "SSH: Thread is shutting down..."
  }
  
end

#creates the ssh thread to observe hosts
def getSshCheckThread(key, host)
  return Thread.new(key, host) { |hostKey, actual_host|
  
    shutDown = false
    
    # sleep for the time specified for SSH_TIMEOUT
    sleep($SSH_TIMEOUT)
  
    while($exit_flag == false)
      
      sshConnectionAttempt = 0
      checkSuccessfull = false
    
      # Try to establish a ssh connection
      # On success reset error counter
      begin
        ssh = Net::SSH.start(host[:IP], $SSH_USER, {:auth_methods => "publickey"})
        ssh.close
        
        $Log.info "SSH: Host #{host[:Name]} alive..."
        
        # if host has been successfully checked earlier
        # we don't need to set the "wakeSSH" flag
        # that prevents us from unnecessary locking of the host list
        if(checkSuccessfull != true)
          checkSuccessfull = true
          $hostListMutex.synchronize{
            $state.change(hostKey,$state.wakeSSH)
          }
        end
        
        sshConnectionAttempt = 0
        
      
      # If connection is refused error counter is incremented
      rescue(Errno::ECONNREFUSED)
        $Log.warn "SSH: Host #{host[:Name]} refused ssh connection..."
        $Log.warn "SSH: Attempt #{host[:wakeAttempt]}"
        
        sshConnectionAttempt += 1
        
        checkSuccessfull = false
        
        $hostListMutex.synchronize{
          $state.change(hostKey,$state.isWake)
        }
        
      # On authetication error something seriously is wrong
      # so the error counter is set to maximum
      rescue(Net::SSH::AuthenticationFailed)
        $Log.error "SSH: Authentication failed on host #{host[:Name]}"
        
        sshConnectionAttempt = $NUM_WAKE_ATTEMPTS
        
        checkSuccessfull = false
        
        $hostListMutex.synchronize{
          $state.change(hostKey,$state.isWake)
        }
      
      # On socket error something seriously is wrong
      # so the error counter is set to maximum
      rescue
        $Log.error "SSH: Socket error on host #{host[:Name]}"
        
        sshConnectionAttempt = $NUM_WAKE_ATTEMPTS
        
        checkSuccessfull = false
        
        $hostListMutex.synchronize{
          $state.change(hostKey,$state.isWake)
        }
      end
      
      # If error counter is at maximum the time when that happens is recorded
      # and the thread is terminated
      if(sshConnectionAttempt >= $NUM_WAKE_ATTEMPTS )
      
        $hostListMutex.synchronize{
        
          # if the host is intended to run always
          # the something seriously is wrong and therefore
          # error status is set
          if($hostList[hostKey][:PXE][:wake] == true)
            $Log.error "SSH: Fatal Error (#{actual_host[:Name]})"
            $state.change(hostKey,$state.sshError)
            
          # else a ping thread is created because it is assumed
          # that someone shut down the host
          else
            $state.change(hostKey,$state.ReadyForWakeUp)
            $hostList[hostKey][:pingThread] = getPingThread(key, host)
            $hostList[hostKey][:sshThread] = nil
          end
        }
        break
      end
      
      # sleep for the time specified for SSH_CHECK_INTERVAL
      sleep($SSH_CHECK_INTERVAL)
      
    end
    $Log.info "SSH: ssh thread for \"#{host[:Name]}\" terminated"
  }
end