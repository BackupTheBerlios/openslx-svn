# IMPORTANT:
# This file contains code with improper functionality.
# I added this file because the application is already
# in need of it. The code is not to be considered as
# working.

def getWarnThread()
  return Thread.new(){
  
  threadList = {}
  
  while($exit_flag == false)
  
    $Log.debug "WARN: Waking up..."
    
    currentTime = Time.now
    
    $hostListMutex.synchronize{
    
      $hostList.each do |key,host|
        
        if(host[:isDown] == false) and (host[:shutDown] == true) and ($hostList[key][:warnThread] == nil) and (host[:warnTime] <= currentTime )
          
          if(host[:wakeSSH] == true)
            $Log.info "WARN: Warning host #{host[:Name]}"
            $hostList[key][:warnThread] = getMsgThread(key, host)
          end
          
        end
        
      end
    
    }
    
    $Log.debug "WARN: Going to sleep..."
    
    sleep($utility.computeSleepTime(16))
    
    end
  $Log.debug "WARN: Thread is shutting down..."
  }
  
end


def getMsgThread(key, host)
  return Thread.new(key,host){
  
    Net::SSH.start(host[:IP], $SSH_USER) do |session|
    
      session.open_channel do |channel|
        
        channel.exec("xmessage -timeout 60 -display :0 -center \"#{$WARN_TEXT}\"")
        
      end
      
      session.loop
      
    end
    
  }
end
