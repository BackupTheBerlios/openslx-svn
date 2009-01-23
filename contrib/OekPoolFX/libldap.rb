# loading "ldap" from ruby standard library
require 'ldap'

# returns a hash table which contains all important information about the host and pools
# which are stored in the ldap directory
def getHosts()
	
	# Opens a connection and binds
	conn = LDAP::Conn.open($LDAP_SERVER, $LDAP_PORT)
	conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
	conn.bind($LDAP_USER, $LDAP_PASSWORD)

	# Aquires information about subnets known by the DHCP
	dhcpinfo = getDHCPInfo(conn)

	# Performs a search and saves the result in an array
	ous = {}
	conn.search("ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de", LDAP::LDAP_SCOPE_SUBTREE, "(&(!(ou=Rechenzentrum))(ou=*))") do |entry|
		
		current_pool = entry.vals("ou")
		ous[current_pool] = []
		
		i = 0
		# search for PXE configurations for the current pool
		conn.search("ou=" + current_pool[0] + ",ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de", LDAP::LDAP_SCOPE_ONELEVEL, "(objectClass=ActivePXEConfig)") do |pxe_menu|
			
			# Apply the found PXE configuration for pool
      if pxe_menu.vals("ForceBoot") == nil
        wakeOnLAN = false
      else
        wakeOnLAN = true
      end
      
			ous[current_pool][i] = {:time => pxe_menu.vals("TimeSlot")[0], :menu => pxe_menu.vals("cn")[0], :wake => wakeOnLAN}
      i += 1
		end
		
		# if no PXE configuration was found for this pool
		# the default config is applied
		if i == 0
			ous[current_pool] = nil
		end
		
	end

	# Looks for Hostnames in the specified ou's and creates a hashmap
	pools = {}
	ous.each do |org_unit,default_pxe|

		# Initialization of hashmaps
		pools[org_unit[0]] = {}
		pools[org_unit[0]][:hosts] = {}
		
		# Search for computers of current pool
		conn.search("ou=" + org_unit[0] + ",ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de", LDAP::LDAP_SCOPE_SUBTREE, "(HostName=*)") do |entry|

			# Process entry if IP and MAC exist
			if entry.vals("HWaddress") != nil and entry.vals("IPAddress") != nil

				# Initialization
				pools[org_unit[0]][:hosts][entry.vals("HostName")[0]] = {}
				pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:pxe] = []
				
				# Store pxe info, MAC and broadcast address
				pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:MAC] = entry.vals("HWaddress")[0]
				ip_address = entry.vals("IPAddress")[0].split("_")[0]
				pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:BC] =  getBroadcastAddress(ip_address,dhcpinfo)
				pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:IP] = ip_address
				pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:HostName] = entry.vals("HostName")[0]
				
				# Search for PXE menus assigned to the current computer
				i = 0
				conn.search("HostName=" + pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:HostName] + ",cn=computers,ou=" + org_unit[0] + ",ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de", LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=ActivePXEConfig)") do |pxe_menu|
					
					# Apply the found PXE configuration for computer
          if pxe_menu.vals("ForceBoot") == nil
            wakeOnLAN = false
          else
            wakeOnLAN = true
          end
      
          pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:pxe][i] = {:time => pxe_menu.vals("TimeSlot")[0], :menu => pxe_menu.vals("cn")[0], :wake => wakeOnLAN}
          i += 1
				end
				# if no PXE configuration was found for this computer
				# the default config for the pool is applied
				if i == 0
					pools[org_unit[0]][:hosts][entry.vals("HostName")[0]][:pxe] = default_pxe
				end
				
			end
		end
	end
  
  # return the resulting hash table
	return pools
end

# Aquires information about subnets known by the DHCP
def getDHCPInfo(conn)
	dhcpinfo = {}

	# Performs a search and creates an hashmap
	conn.search("cn=dhcp,ou=Rechenzentrum,ou=UniFreiburg,ou=RIPM,dc=uni-freiburg,dc=de", LDAP::LDAP_SCOPE_SUBTREE, "(dhcpoptNetmask=*)") do |entry|
		dhcpinfo[entry.vals("cn")[0]] = {}
		dhcpinfo[entry.vals("cn")[0]][:SubnetMask] = entry.vals("dhcpoptNetmask")[0]
		dhcpinfo[entry.vals("cn")[0]][:Broadcast] = entry.vals("dhcpoptBroadcast-address")[0]
	end
	return dhcpinfo
end

# Returns the broadcast address for a given IP address based on the given DHCP Info
def getBroadcastAddress(ip_address, dhcpinfo)
	ip_array = ip_address.split(".")

	dhcpinfo.each do |key,value|
		dhcp_network = key.split(".")
		subnetmask = value[:SubnetMask].split(".")
		network = []
		network[0] = ip_array[0].to_i & subnetmask[0].to_i
		network[1] = ip_array[1].to_i & subnetmask[1].to_i
		network[2] = ip_array[2].to_i & subnetmask[2].to_i
		network[3] = ip_array[3].to_i & subnetmask[3].to_i
		if (network[0] == dhcp_network[0].to_i) and (network[1] == dhcp_network[1].to_i) and (network[2] == dhcp_network[2].to_i) and (network[3] == dhcp_network[3].to_i)
			return value[:Broadcast]	
		end
	end
	return nil
end
