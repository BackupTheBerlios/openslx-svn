# creates the thread
def getErrorThread()
  return Thread.new(){
    
    # doing all the stuff again and again until the program will shutdown
    while($exit_flag == false)
      
      $Log.debug "ERROR: Waking up... (no real error, just debug msg)"
      
      # lock the host list
      $hostListMutex.synchronize{
        
	# iterating over all items in host list
        $hostList.each do |key,host|
        
	  # check whether a ping error occured
          if(host[:pingErr] != nil)
            
	    # Send error message to log and delete host from list
            $Log.error("ERROR: Could not wake up host \"#{host[:Name]}\" (IP: #{host[:IP]}, MAC: #{host[:MAC]})")
            $hostList.delete(key)
            
	  # check whether a ssh error occured
          elsif(host[:sshErr] != nil)

	    # Send error message to log and delete host from list		  
            $Log.error("ERROR: Could not establish ssh connection on host \"#{host[:Name]}\" (IP: #{host[:IP]}, MAC: #{host[:MAC]})")
            $hostList.delete(key)
            
          end
        
        end
      
      }
      
      $Log.debug "ERROR: Going to sleep... (no real error, just debug msg)"
      
      # sleep until second 54 of current minute or second 24 of next minute
      sleep($utility.computeSleepTime(24))
    end
    
  }
end
