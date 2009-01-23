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

# Read the config file
config = ParseConfig.new("oekpool.conf")

# if debugging is enabled log is written to stdout with info level
if config.get_value("DEBUG") == "yes"
  $Log = Logger.new(STDOUT)
  $Log.level = Logger::INFO
# else log level is set according to config file
else
  $Log = Logger.new("debug.log")
#  $Log = Logger.new(STDOUT)
  case config.get_value("LOG_LEVEL").downcase
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

# Read the content of the config file and store it in global variables
$PING_TIMEOUT = config.get_value("PING_TIMEOUT").to_i
$BOOT_TIMEOUT = config.get_value("BOOT_TIMEOUT").to_i
$SSH_TIMEOUT = config.get_value("SSH_TIMEOUT").to_i
$SSH_CHECK_INTERVAL = config.get_value("SSH_CHECK_INTERVAL").to_i
$SHUTDOWN_TIME  = config.get_value("SHUTDOWN_TIME").to_i
$WARN_TIME = config.get_value("WARN_TIME").to_i
$NUM_WAKE_ATTEMPTS = config.get_value("NUM_WAKE_ATTEMPTS").to_i
$TFTP_ROOT_DIR = config.get_value("TFTP_ROOT_DIR")
$LOG_FILE = config.get_value("LOG_FILE")
$SSH_USER = config.get_value("SSH_USER")
$WARN_TEXT_FILE = config.get_value("WARN_TEXT_FILE")
$LDAP_SERVER = config.get_value("LDAP_SERVER")
$LDAP_PORT = config.get_value("LDAP_PORT").to_i
$LDAP_USER = config.get_value("LDAP_USER")
$LDAP_PASSWORD = config.get_value("LDAP_PASSWORD")
$WARN_TEXT = ""

f = File.new($WARN_TEXT_FILE, "r")
tmp_arr = f.readlines()
f.close()

tmp_arr.each do |tmp|
	$WARN_TEXT = $WARN_TEXT + tmp
end


# Define struct used for storing client information
$Host = Struct.new(:IP, :MAC, :BC, :Name, :wakeAttempt , :PXE, :shutDownTime,
:warnTime ,:changePXE, :ReadyForWakeUp, :isWake, :wakeSSH,
:shutDown, :pingErr, :sshErr, :isDown, :toBeDeleted, :pingThread, :sshThread,
:warnThread, :shutDownThread)

# Define necessary constants
$hostListMutex = Mutex.new # is called everytime a thread accesses the host list
$hostList = Hash.new # the global list where all host information is stored
$exit_flag = false

# Initialize object which changes host states
$state = ListState.new($hostList)

# Initialize Utility Class
$utility = Utility.new

# start the threads

# if debugging is enabled start debug thread
if config.get_value("DEBUG") == "yes"
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
