# include the necessary 'libwol.rb' library
require 'libwol.rb'

# creates the thread
def getWakeThread()
	return Thread.new {
		
		while($exit_flag == false)
    
      $Log.debug "WAKE: Waking up..."
			
			# Using semaphore to access shared variable "hostList"
			$hostListMutex.synchronize {
			
        # iterate over all hosts in list
				$hostList.each do |key,host|
          
          # host need to be woken up
          # applies if host is marked as "ready" and if it is
          # intended for wake up
          if (host[:ReadyForWakeUp] == true) and (host[:PXE][:wake] == true)
            
            # wake the host
            $Log.info "WAKE: Waking \"#{host[:Name]}\" (#{host[:MAC]}, BC: #{host[:BC]}) "
            wake_host(host[:BC], host[:MAC])
            
            # mark the host as woken up
            $hostList[key][:ReadyForWakeUp] = false
            
            # if host is woken up for first time a ping thread is created
            if ($hostList[key][:wakeAttempt] <= 0)
              $Log.info "WAKE: Creating ping thread for \"#{host[:Name]}\""
              $hostList[key][:pingThread] = getPingThread(key, host)
            end
            
          end
          
        end
				
			}
	    $Log.debug "WAKE: Going to sleep..."
      
      # sleep until second 38 of current minute or second 8 of next minute
      sleep($utility.computeSleepTime(8))
      
		end
    $Log.debug "WAKE: Thread is shutting down..."
	}
end
