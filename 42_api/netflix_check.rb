require 'oauth2'
require 'active_support'
require 'active_support/time'

UID = ENV['FT_API_UID']
SECRET = ENV['FT_API_SEC']

client = OAuth2::Client.new(UID, SECRET, site: "https://api.intra.42.fr")

TOKEN = client.client_credentials.get_token

# writes succesful logins to file 'logins.txt'
def write_logins(users)
	puts 'starting write_logins, length is ' + users.length.to_s
	res = Array.new
	users.each do |person|
		puts person
		res.push(person)
	end
	puts 'starting actual write to netflix.txt'
	open('netflix.txt', 'w') do |f|
		res.each do |login|
			f.puts login
		end
	end
end

def events_rsvp
	res = Array.new
	tmp = Array.new
	i = 0
	j = 0
	while (response = TOKEN.get("/v2/events/1640/events_users", params: { page: j, per_page: 100 }).parsed).length > 0
		response.each do |one|
			tmp.push(one)
			j += 1
		end
	end
	tmp.each do |user|
		res[i] = user["user"]["login"]
		i += 1
	end
	puts res.length
	return res
end

if ARGV[0] == 'save'
	write_logins(events_rsvp)
elsif ARGV[0] == 'print'
	puts events_rsvp
else
	puts "Usage: ruby netflix_check.rb 'save' to write to netflix.txt"
	puts "       ruby netflix_check.rb 'print' to print results only on terminal"
end