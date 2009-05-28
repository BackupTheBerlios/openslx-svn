def getQueueThread()

  return Thread.new {
    
    while($exit_flag == false)
      puts "Queue: Waking up..."
      
      currentTime = Time.now
      
      $hostListMutex.synchronize {
      
        $hostList.each do |key, host|
          
          if(host[:changePXE] == true)
            
            $hostList[key][:changePXE] = false
            $pxeCfgQueue.push(key)
            puts "Queue: \"#{host[:Name]}\" enqueued for PXE change"
            
          end
          
          if(host[:PXEChanged] == true) and (host[:wakeUp] == true)
          
            $hostList[key][:PXEChanged] = false
            $wakeQueue.push(key)
            puts "Queue: \"#{host[:Name]}\" enqueued for wake up"
            
          end
          
          if(host[:shutDownWarn] == true) and (current_time < host[:warnTime]) and ($hostList[key][:shutDown] == false)
            
            $hostList[key][:shutDown] = true
            $warnQueue.push(key)
            puts "Queue: \"#{host[:Name]}\" enqueued for shutdown warn"
            
          end
          
          if(host[:shutDown] == true) and (current_time < host[:shutDown])
            
            $hostList[key][:shutDown] = nil
            $shutdownQueue.push(key)
            puts "Queue: \"#{host[:Name]}\" enqueued for shutdown"
            
          end
        
        end
      
      }
      
      puts "Queue: Going to sleep"
      
      sleep(2)
      
    end
    
  }
  
end
