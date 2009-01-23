class ListState
  # set read-only status for the given variables
  attr_reader :changePXE, :ReadyForWakeUp, :isWake, :wakeSSH, :shutDown, :isDown, :pingError, :sshError
  
  # on object creation the constants are are
  # initialized
  def initialize(hostList)
    @changePXE = 1
    @ReadyForWakeUp = 2
    @isWake = 3
    @wakeSSH = 4
    @shutDown = 5
    @isDown = 6
    @pingError = 7
    @sshError = 8
    @list = hostList
  end
  
  # change the state of the given host according
  # to the given status
  def change(key,state)  
    case state
      when 1
        @list[key][:changePXE] = true
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = false
        @list[key][:shutDown] = false
        @list[key][:isDown] = false
      when 2
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = true
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = false
        #@list[key][:shutDown] = false
        @list[key][:isDown] = false
      when 3
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = true
        @list[key][:wakeSSH] = false
        #@list[key][:shutDown] = false
        @list[key][:isDown] = false
      when 4
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = true
        #@list[key][:shutDown] = false
        @list[key][:isDown] = false
      when 5
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = false
        @list[key][:shutDown] = true
        @list[key][:isDown] = false
      when 6
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = false
        #@list[key][:shutDown] = false
        @list[key][:isDown] = true
        @list[key][:wakeAttempt] = 0
      when 7
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = false
        #@list[key][:shutDown] = false
        @list[key][:isDown] = false
        @list[key][:pingErr] = Time.now
      when 8
        @list[key][:changePXE] = false
        @list[key][:ReadyForWakeUp] = false
        @list[key][:isWake] = false
        @list[key][:wakeSSH] = false
        #@list[key][:shutDown] = false
        @list[key][:isDown] = false
        @list[key][:sshErr] = Time.now
      else
        return false        
    end
    return true
    
  end
end