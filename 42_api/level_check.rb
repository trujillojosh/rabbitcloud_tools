require 'oauth2'
require 'active_support'
require 'active_support/time'

UID = "9a277b2dd2230520e716e21fb2f44bf162b52d5523930000091768e33510ec60"
SECRET = "7871e0d145526e0fea6a209ab2a2e7d8ee2c758e5a5dbb5d6f2385a3a555c526"

client = OAuth2::Client.new(UID, SECRET, site: "https://api.intra.42.fr")

TOKEN = client.client_credentials.get_token

# returns array of all fremont user ids
def fremont_users
	tmp = Array.new
	res = Array.new
	i = 0
	while (tmp = TOKEN.get('/v2/campus/7/users', params: { page: i, per_page: 100 }).parsed).length > 0
		puts 'user request page is ' + i.to_s
		tmp.each do |page|
			res.push(page)
		end
		i += 1
	end
	return res
end

# returns users that meet given level, rounded down
def user_test(users, level)
	res = Array.new
	length = users.length
	puts 'starting user_test, length is ' + length.to_s
	test_i = 0
	users.each do |person|
		left = length - test_i
		puts left.to_s + ' left'
		tmp = person['id'].to_s
		response = TOKEN.get('/v2/users/' + tmp).parsed
		if ((response['cursus_users'].length > 0) && (response['cursus_users'][0]['level'] >= level))
			res.push(person)
		end
		test_i += 1
	end
	return res
end

# returns users that have logged in within last month
def recent_login(users)
	puts 'starting recent_login, length is ' + users.length.to_s
	res = Array.new
	last_month_unform = (Time.current - 30.days).to_s.split(" ")
	today_unform = Time.current.to_s.split(" ")
	last_month = last_month_unform[0] + 'T' + last_month_unform[1]
	today = today_unform[0] + 'T' + today_unform[1]
	users.each do |person|
		tmp = person['id'].to_s
		response = TOKEN.get("/v2/users/" + tmp + "/locations?range[begin_at]=#{last_month},#{today}").parsed
		if response.length > 0
			res.push(person)
		end
	end
	return res
end

# writes succesful logins to file 'logins.txt'
def write_logins(users)
	puts 'starting write_logins, length is ' + users.length.to_s
	res = Array.new
	users.each do |person|
		res.push(person['login'])
	end
	puts 'starting actual write'
	open('logins.txt', 'w') do |f|
		res.each do |login|
			f.puts login
		end
	end
end


write_logins(recent_login(user_test(fremont_users, 6)))