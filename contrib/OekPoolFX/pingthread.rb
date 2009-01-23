# include necessary library
require 'ping'

# creates the thread
def getPingThread(key, next_host)
	return Thread.new(key, next_host) { |hostKey,host|
    
    i = 0
    
    # initialize necessary flags
    permanent = false
    shutdown = false
    
    # lock the host list
    $hostListMutex.synchronize {
      
      # set flags according to host status
      shutdown = $hostList[key][:isDown]
      permanent = !$hostList[key][:PXE][:wake]
    
    }
    
    while(permanent == true) or (i <= $NUM_WAKE_ATTEMPTS)
      
      # Give host time to come up
      if(permanent == true)
        sleep($BOOT_TIMEOUT - $PING_TIMEOUT)
      else
        sleep($BOOT_TIMEOUT)
      end
      
      
      $Log.info "PING: Pinging \"#{host[:Name]}\" (#{host[:IP]})"
      
      # Try to ping the host
      # If that fails...
      if(Ping.pingecho(host[:IP], $PING_TIMEOUT) == false)
        
        # ...and ping thread does not run in permanent mode...
        if (permanent == false)
          
          $Log.warn "PING: Waked Host \"#{host[:Name]}\" (#{host[:IP]}) not responding..."
          $Log.warn "Attempt #{i+1}"
          $hostListMutex.synchronize {
          
            # ...host is marked for wake up again...
            $state.change(hostKey,$state.ReadyForWakeUp)
            
            # ...and counter is increased
            $hostList[key][:wakeAttempt] = i + 1
          
          }
        end
        
      # If host responds...
      else
        
        $Log.info "PING: Host \"#{host[:Name]}\" (#{host[:IP]}) answering..."
        $Log.info "Attempt #{i+1}"
        
        $hostListMutex.synchronize {
          
          # ... host is marked as awake...
          $state.change(hostKey,$state.isWake)
          
        }
        Thread.stop()
        
      end
      i += 1
    end
    
    # this code is only reached if maximum number of wake attempts for
    # a host that is supposed to be woken up is reached.
    # in this case host status is set to error
    if(permanent == false)
      $hostListMutex.synchronize {
        $Log.error "PING: Host \"#{host[:Name]}\" (#{host[:IP]}) has not responded for #{i+1} times."
        $state.change(hostKey,$state.pingError)
      }
    end
  $Log.debug "PING: Thread is shutting down..."
	}
end