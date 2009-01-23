# creates the thread
def getPXECfgThread()
  
  return Thread.new{
    while($exit_flag == false)
     
      $Log.debug "PXE: Waking up..."
      
      # lock the host list for other threads
      $hostListMutex.synchronize {
        $hostList.each do |key,host|
          
          # applies if host is marked for pxe menu change
          if (host[:changePXE] == true)
            
            # determine location of current pxe menu file of host
            pxeBootFile = $TFTP_ROOT_DIR + "/pxelinux.cfg/" + $utility.getHostFile(host[:MAC])
            
            # determine location of pxe menu file which should be linked
            pxeMenuFile = $TFTP_ROOT_DIR + "/pxelinux.cfg/" + host[:PXE][:time] + "/" + $utility.getHostFile(host[:MAC])
          
            $Log.info "PXE: Changing PXE image of #{host[:Name]}"
            
            # delete current pxe menu file if exists
            if File.exists?(pxeBootFile)
              File.delete(pxeBootFile)
            end
            
            # link new pxe menu file against the deleted one
            if File.exists?(pxeMenuFile)
              File.link(pxeMenuFile, pxeBootFile)
            end
            
            # mark host as "ready"
            $state.change(key,$state.ReadyForWakeUp)
            
            # if host is not supposed to be woken up
            # a ping thread is created
            if ($hostList[key][:PXE][:wake] == false)
              $Log.info "PXE: Creating permanent ping thread for \"#{host[:Name]}\""
              $hostList[key][:pingThread] = getPingThread(key,host)
            end
          
          end
        
        end
      }
    
    $Log.debug "PXE: Going to sleep..."
    
    # sleep until second 34 of current minute or second 4 of next minute
    sleep($utility.computeSleepTime(4))
    
  end
  $Log.debug "PXE: Thread is shutting down..."
  }
end
