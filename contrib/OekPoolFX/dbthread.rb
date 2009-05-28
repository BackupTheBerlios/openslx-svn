
def getDbThread(debug_)

	return Thread.new(debug_) { |debug|

		# The main loop
		while($exit_flag == false)
			$Log.debug "DB: Thread is waking up"

			# Storing the current time
			actual_time = Time.now

			# Aquiring hosts and pool information
      # if application runs in debug mode pool_hash
      # needs to be global
			if(debug == true)
        $pool_hash = getHosts()
      else
        pool_hash = getHosts()
      end
      
      # unless debug mode is enabled the application processes the host
      # according to the data in the directory
      unless(debug == true)
      
      
	   		# iterating over all pools...
  			pool_hash.each do |pool_desc, pool_info|
  				$Log.debug "DB: Checking pool \"" + pool_desc + "\"..."
  				
  				# iterate over all hosts of pool...
  				pool_info[:hosts].each do |host_desc,host_info|
  				
  					# if no wake time is set skip client
  					if (host_info[:pxe] == nil)
  						next
  					end
  					
  					# Determine wake times
            wakeTimeInFuture = determineWakeTime(host_info[:pxe], actual_time + $WARN_TIME + $SHUTDOWN_TIME)
            wakeTime = determineWakeTime(host_info[:pxe], actual_time)
            
            # lock the host list for other threads
            $hostListMutex.synchronize {
              # Host in list
              if $hostList.include?(host_info[:MAC])
              
                # PXE image will change
                # applies if there exists a wake time in future which is different from the current wake time
                if(wakeTimeInFuture != nil) 
                  if($hostList[host_info[:MAC]][:PXE][:menu] != wakeTimeInFuture[:menu]) or ($hostList[host_info[:MAC]][:PXE][:time] != wakeTimeInFuture[:time])
                    if($hostList[host_info[:MAC]][:shutDown] == false)
                  
                      $Log.info "DB: Config change for \"#{host_info[:HostName]}\" in approx. #{((wakeTimeInFuture[:start] - $SHUTDOWN_TIME - actual_time).to_i)/60} minutes."
                      $hostList[host_info[:MAC]][:warnTime] = wakeTimeInFuture[:start] - $WARN_TIME - $SHUTDOWN_TIME
                      $hostList[host_info[:MAC]][:shutDownTime] = wakeTimeInFuture[:start] - $SHUTDOWN_TIME
                      $hostList[host_info[:MAC]][:shutDown] = true
                  
                    end
                  
                  end
                
                # no PXE image defined in future
                # applies if there exists no wake time in future
                # if host is already marked as "to be deleted" nothing needs to be done
                else
                
                  if ($hostList[host_info[:MAC]][:toBeDeleted] == false)
                    $Log.info "DB: Removing host #{$hostList[host_info[:MAC]][:Name]} on #{(actual_time + $WARN_TIME).to_s}."
                    $hostList[host_info[:MAC]][:warnTime] = actual_time
                    $hostList[host_info[:MAC]][:shutDownTime] = actual_time + $WARN_TIME
                    $hostList[host_info[:MAC]][:shutDown] = true
                    $hostList[host_info[:MAC]][:toBeDeleted] = true
                  end
                
                end
              
              
                # pxe image change for current time is scheduled
                # applies is there exists a current wake time and the wake time stored
                # in DB is different from the wake time stored in the host object
                if(wakeTime != nil)
                  if($hostList[host_info[:MAC]][:PXE][:menu] != wakeTime[:menu]) or ($hostList[host_info[:MAC]][:PXE][:time] != wakeTime[:time])
                    
                    # processing cannot be done if host is not marked as "down"
                    if($hostList[host_info[:MAC]][:isDown] == true)
                      
                      $Log.info "DB: Changing image for \"#{host_info[:HostName]}\""
                      $hostList[host_info[:MAC]][:PXE] = wakeTime
                      $state.change(host_info[:MAC],$state.changePXE)
                    end
                    
                  end
                  
                end
              
              # Host is not in list
              else
              
                # PXE image is defined for current time
                # applies if there is a current wake time
                if(wakeTime != nil)
                  $Log.info "DB: Adding \"#{host_info[:HostName]}\" to list and setting up config"
                  
                  # inserts host into host list
                  $hostList[host_info[:MAC]] = $Host.new(host_info[:IP], host_info[:MAC],
                  host_info[:BC], host_info[:HostName], 0, wakeTime,
                  nil, nil, true, false,
                  0, false, false, nil, nil, false, false, nil, nil, nil, nil)
                
                end
              end
            }
					 
				  end
				  
	   	  end
        
      end
      
      # lock the host list for other threads
			$hostListMutex.synchronize{
        # iterate over the host list
        $hostList.each do |key,host|
        
          # delete host if it is down and marked to be deleted
          if(host[:isDown] == true) and (host[:toBeDeleted] == true)
             $hostList.delete(key)
          end
          
        end
      }
			$Log.debug "DB: Thread is going to sleep"
      
      # Go to sleep until 30 seconds
      sleep ($utility.computeSleepTime(0))
	 end
    
    $Log.debug "DB: Thread is shutting down..."
	}
end

# determines if the given wake time is active during the given time
# returns the result als boolean
def timeApplicable(timeArray, actual_time)
  timeArray = timeArray.downcase().split("_")
	startTime = timeArray[1].split(":")
	endTime   = timeArray[2].split(":")
	
	# check whether it's the right week day
	if (timeArray[0].to_i != actual_time.wday) and (timeArray[0] != "x")
		return false
  end

  # checks whether the current hour is after or equal to the start hour
  # or it's always the right time ("x")
  if (startTime[0] != "x" ) and (startTime[0].to_i > actual_time.hour)
    return false
  end
  
  # checks whether the curret minutes is after or equal to the start hour
  # or it's alway the right time
  if (startTime[0] != "x") and ((startTime[1].to_i * 10) > actual_time.min)
    if(startTime[0].to_i == actual_time.hour)
      return false
    end
  end
  
  # checks whether the current hour is before or equal to the end hour
  # or it's always the right time ("x")
  if (endTime[0] != "x") and (endTime[0].to_i < actual_time.hour)
    return false
  end
  
  # checks whether the current minute is before or equal to the end minute
  # or it's always the right time ("x")
  if (endTime[0] != "x") and ((endTime[1].to_i * 10) < actual_time.min)
    if(endTime[0].to_i == actual_time.hour)
      return false
    end
  end
  
  return true
  
end

# determines the wake time which is active during a specified time and returns it
# if no wake time is active nil is returned
def determineWakeTime(pxe, actual_time)
  
  pxeConfigPriority = []
  pxeConfigPriority[0] =  []
  pxeConfigPriority[1] =  []
  pxeConfigPriority[2] =  []
  pxeConfigPriority[3] =  []
  
  # iterate over all PXE configurations of host
  # and store the according to their priority
  pxe.each do |pxeConfig|
    
    # separate the time components
    pxeTime = pxeConfig[:time].downcase().split("_")
    
    # assign the time to the right priority
    if(pxeTime[0] != "x")
      if(pxeTime[1] != "x")
        pxeConfigPriority[0] << pxeConfig
        
      else
        pxeConfigPriority[1] << pxeConfig
        
      end
    else
      if(pxeTime[1] != "x")
        pxeConfigPriority[2] << pxeConfig
        
      else
        pxeConfigPriority[3] << pxeConfig
        
      end
    end
    
  end
  
  # iterate over the four priorities
  pxeConfigPriority.each do |priority|
  
    goToNextClient = false
    
    # iterate over all configurations in the current priority
    priority.each do |pxeConfig|
      
      # if a PXE configuration is applicable (it's the right time)
      # start and end time is computed and the result is returned
      if(timeApplicable(pxeConfig[:time], actual_time) == true)
      
        timeArray = pxeConfig[:time].downcase().split("_")
        unless timeArray[1].downcase() == "x"
          startArray = timeArray[1].split(":")
          pxeConfig[:start] = Time.local(actual_time.year, actual_time.month, actual_time.day, startArray[0].to_i, startArray[1].to_i * 10, 0)
        else
          pxeConfig[:start] = Time.local(actual_time.year, actual_time.month, actual_time.day, actual_time.hour, actual_time.min)
        end
        
        unless timeArray[2].downcase() == "x"
          endArray = timeArray[2].split(":")
          pxeConfig[:end] = Time.local(actual_time.year, actual_time.month, actual_time.day, endArray[0].to_i, endArray[1].to_i * 10, 0)
        else
          pxeConfig[:end] = nil
        end
        
        return pxeConfig
      end
    end
  end
  
  # return nil if no suitable time has been found
  return nil
  
end
