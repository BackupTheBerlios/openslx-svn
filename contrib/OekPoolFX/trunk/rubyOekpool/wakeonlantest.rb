#!/usr/bin/env ruby

# include necessary libraries for standard library
require 'logger'
require 'thread'

# include libraries which are located in the main directory
require 'libldap.rb'
require 'liststate.rb'
require 'utility.rb'
require 'parseconfig.rb'

# include the threading libraries
require 'dbthread.rb'
require 'debugthread.rb'
require 'pxecfgthread.rb'
require 'wakethread.rb'
require 'sshthread.rb'
require 'pingthread.rb'
require 'shutdownthread.rb'
require 'errorthread.rb'
require 'warnthread.rb'

# Initialize Utility Class
$utility = Utility.new

# create the config variables
$utility.initializeConfiguration()

# if debugging is enabled log is written to stdout with info level
if $DEBUG == true
  $Log = Logger.new(STDOUT)
  $Log.level = Logger::INFO
# else log level is set according to config file
else
  $Log = Logger.new("debug.log")
#  $Log = Logger.new(STDOUT)
  case $LOG_LEVEL
    when "debug" then
      $Log.level = Logger::DEBUG
    when "info" then
      $Log.level = Logger::INFO
    when "warn" then
      $Log.level = Logger::WARN
    when "error" then
      $Log.level = Logger::ERROR
    when "fatal" then
      $Log.level = Logger::FATAL
    else
      $Log.level = Logger::WARN
  end
end

# Define struct used for storing client information
$Host = Struct.new(:IP, :MAC, :BC, :Name, :wakeAttempt , :PXE, :shutDownTime,
:warnTime , :changePXE, :ReadyForWakeUp, :isWake, :wakeSSH,
:shutDown, :pingErr, :sshErr, :isDown, :toBeDeleted, :pingThread, :sshThread,
:warnThread, :shutDownThread)

# Define necessary constants
$hostListMutex = Mutex.new # is called everytime a thread accesses the host list
$hostList = Hash.new # the global list where all host information is stored
$exit_flag = false

# Initialize object which changes host states
$state = ListState.new($hostList)

# start the threads

# if debugging is enabled start debug thread
if $DEBUG == true
  dbThread = getDbThread(true)
  sleep(2)
  debugThread = getDebugThread()
# else start db thread
else
  dbThread = getDbThread(false)
end

# start all other threads
sleep(2)
pxeCfgThread = getPXECfgThread()
sleep(2)
wakeThread = getWakeThread()
sleep(2)
sshThread = getSSHThread()
sleep(2)
warnThread = getWarnThread()
sleep(2)
shutdownThread = getShutdownThread()
sleep(2)
errorThread = getErrorThread()

# Specify behaviour if SIGTERM is received
trap("SIGTERM") do
	puts "Exiting..."
  
	$exit_flag = true
  
  # kill the debug thread if it is running
  if debugThread != nil
    debugThread.kill()
  end
  
  # wake up all sleeping threads
	dbThread.wakeup()
  pxeCfgThread.wakeup()
  wakeThread.wakeup()
  sshThread.wakeup()
  warnThread.wakeup()
  shutdownThread.wakeup()
  errorThread.wakeup()
  
  # lock the host list
  $hostListMutex.synchronize(){
    
    # iterate over all hosts in list and kill
    # running ping or ssh threads
    $hostList.each do |key,host|
      if host[:pingThread] != nil
        host[:pingThread].kill()
      end
      if host[:sshThread] != nil
        host[:sshThread].kill()
      end
    end
  }
end

# wait until all threads terminate
dbThread.join()
pxeCfgThread.join()
wakeThread.join()
sshThread.join()
warnThread.join()
shutdownThread.join()
errorThread.join()
