
require 'net/smtp'
require 'rmail'


# implements an smtp mailer through net/smtp and rmail 
class Mailer
	
	# initializes the mailer
	# arguments: server, port, user, password, from_address
	def initialize(
			server='smtp.example.com', port=25, 
			user='mm', 
			pass='123abcd', 
			from_address='example@example.com'
	)
		@from_address = from_address
		
		if(@@mail_conn == nil)
			begin
				@@mail_conn = Net::SMTP.start(server, port, user, pass)
			rescue (Net::SMTPAuthenticationError ex)
				$Log.error("Failed to authenticate SMTP server: #{ex.to_s}")
			rescue (Net::SMTPServerBusy ex)
				$Log.error("SMTP server is busy: #{ex.to_s}")
			rescue (Exception ex)
				$Log.error("Some error connecting: #{ex.to_s}")
			end 
		end
	end
	
	
	# sends mail with given subject, body and receiving address 
	def sendmail(subject, body, to_address, close = true)
		message = RMail::Message.new
		message.subject = subject
		message.body = body
		message.header.from = @from_address
		message.header.to = to_address
		
		msgstr = RMail::Serialize.write('',message)
		@@mail_conn.send(
			msgstr,
			@from_address,
		    to_address
		)
		
		if(close) 
			close()
		end
	end
	
	
	def close()
		unless(@@mail_conn == nil)
			@@mail_conn.close()
		end
	end
	
end