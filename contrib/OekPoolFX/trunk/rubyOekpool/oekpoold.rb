require 'rubygems'
require 'daemons'

Daemons.run_proc('wakeonlantest.rb') do
  loop do
    sleep(5)
  end
end
