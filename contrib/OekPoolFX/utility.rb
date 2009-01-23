class Utility
  def computeSleepTime(offset)
    
    # compute sleep time in seconds
    sleepTime = (60 - Time.now.sec + offset) % 30
    
    # prevents the threads from running several times (in fact hundrets of times)
    # because zero is passed to sleep
    if(sleepTime == 0)
      sleepTime = 30
    end
  
    return sleepTime
  end
  
  # returns the file name of the pxe menu file
  # for a given mac address
  def getHostFile(mac)
    dir = mac.gsub(/[:]/, "-")
    return "01-" + dir
  end
  
end
