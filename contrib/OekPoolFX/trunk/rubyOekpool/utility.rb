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
  
  # read all the configuartion values out of the  configuration file
  # and puts them into global variables
  def initializeConfiguration()
    
    # Read the config file
    config = ParseConfig.new("oekpool.conf")
    
    # Initialization of all the configuration values
    $LOG_LEVEL = config.get_value("LOG_LEVEL").downcase
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
    $SMTP_SERVER = config.get_value("SMTP_SERVER")
    $SMTP_PORT = config.get_value("SMTP_PORT").to_i
    $SMTP_USER = config.get_value("SMTP_USER")
    $SMTP_PASS = config.get_value("SMTP_PASS")
    $DISPLAYED_EMAIL_ADDRESS = config.get_value("DISPLAYED_EMAIL_ADDRESS")
    $SEND_TO_EMAIL_ADDRESS = config.get_value("SEND_TO_EMAIL_ADDRESS")

    # Check wether email notification is demanded
    if config.get_value("NOTIFY_EMAIL") == "yes"
      $NOTIFY_EMAIL = true
    else
      $NOTIFY_EMAIL = false
    end
    
    # Check wether to start in debug mode
    if config.get_value("DEBUG") == "yes"
      $DEBUG = true
    else
      $DEBUG = false
    end

    # Read the content of the text file which contains the user warning
    $WARN_TEXT = ""
    f = File.new($WARN_TEXT_FILE, "r")
    tmp_arr = f.readlines()
    f.close()
    
    # Assemble the user warning text
    tmp_arr.each do |tmp|
      $WARN_TEXT = $WARN_TEXT + tmp
    end
    
    # Replace the marker with the appropriate value
    $WARN_TEXT = $WARN_TEXT.gsub("___time___", $WARN_TIME.to_s)
    
  end
  
end
