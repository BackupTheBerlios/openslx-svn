# loading "socket" from ruby standard library
require 'socket'

# Sends a Magic Packet (tm) to IP Address "bc_ip" for waking the client with MAC Address "mac_address"
def wake_host(bc_ip, mac_address)
	
	# Generating sequence of 12 F's
	ffffff = 255.chr + 255.chr + 255.chr + 255.chr + 255.chr + 255.chr
	magic_packet_tm = ffffff
	
	# Converting MAC address into sequence of bytes
	
	mac_address = mac_address.gsub(/[^a-f0-9A-F]/,"")
	
	hw_address = ""
	6.times do |i|
		hw_address += mac_address[2*i,2].hex.chr
	end
	
	# assembling Magic Packet (tm)
	16.times do
		magic_packet_tm += hw_address
	end
	
	# Opening socket and sending broadcast
	begin
		
		sock = UDPSocket.open
		sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, true)
		sock.send(magic_packet_tm, 0, bc_ip, 99)
		sock.close
		
	rescue
		puts "Socket Fehler: Konnte kein Broadcast an die angegebene IP-Adresse senden."
	end
end

# Wakes all clients which are stored in "hosts_hash"
def wake_all(hosts_hash)

	hosts_hash.each do |key,value|
		puts "Waking " + key + " with MAC \"" + value[:MAC] + "\" and BC \"" + value[:BC] + "\"..."
		wake_host(value[:BC],value[:MAC])
	end
end
