require 'google_drive'
require 'googleauth'
require 'fileutils'
require 'date'
require 'fuzzystringmatch'
require 'slack-ruby-client'

# authenticates a sessions with your service account
session = GoogleDrive::Session.from_config("client_secret.json")

RC_C = session.spreadsheet_by_key("1dxPaBz2RvAIhUKnQmXDyRsA26z5bvOCGrJvqJrapKb4").worksheets[0]
RC_A = session.spreadsheet_by_key("1wQA-jDQfux5K8Y7mkcYtn7MKgkf3GUL1bHAJ7F_Frbw").worksheets[0]
RC_AP = session.spreadsheet_by_key("1wQA-jDQfux5K8Y7mkcYtn7MKgkf3GUL1bHAJ7F_Frbw").worksheets[1]

# authenticates slack token
Slack.configure do |config|
	config.token = ENV['SLACK_API_TOKEN']
end
Client = Slack::Web::Client.new
Client.auth_test

# finds list of all teams in Rabbit Cloud
def get_teams
	team = Array.new
	i = 1
	while i < RC_A.num_rows
		team[i-1] = RC_A[(i+1), 1]
		i += 1
	end
	return team
end

# returns index of row where week start
def week_start
	i = 1
	while i < RC_C.num_rows
		tmp = RC_C.rows[i][0].split(" ")[0].split("/")
		date = Date.parse(tmp[2] + '-' + tmp[0] + '-' + tmp[1])
		if (Date.parse("monday") - 7) <= date
			return i
		end
		i += 1
	end
	return i
end

#returns array of usernames within a team
def return_users(team)
	i = 1
	res = Array.new
	while i < RC_AP.num_rows
		if RC_AP.rows[i][4] == team
			res.push(RC_AP.rows[i][2])
		end
		i += 1
	end
	return res
end

# returns 2d array of weekly correction info
def corr_info(teams, start)
	match = Array.new
	test = FuzzyStringMatch::JaroWinkler.create( :native )
	j = 0
	while start < RC_C.num_rows
		teams.each do |team|
			i = test.getDistance(team, RC_C.rows[start][2])
			if i > 0.65
				match[j] = Array.new
				match[j][0] = team
				match[j][1] = return_users(team)
				match[j][2] = RC_C.rows[start][1]
				match[j][3] = RC_C.rows[start][4]
				match[j][4] = RC_C.rows[start][5]
				match[j][5] = RC_C.rows[start][6]
				match[j][6] = RC_C.rows[start][7]
				match[j][7] = RC_C.rows[start][8]
				j += 1
			end
		end
		start += 1
	end
	return match
end

def send_message(user)
	blah
end

def send_corr(team_corr)
	q0 = '*Team Corrected by: *'
	q1 = '*Have the team give a 30 second elevator pitch. Were you able to understand their product/service from their pitch? How can they improve?*'
	q2 = '*Take atleast a few minutes to use the website or app that they have created. What can be improved and what do you like best?*'
	q3 = '*Talk with the team about what they planned on accomplishing this week. What progress have they made so far?*'
	q4 = '*Are they currently having any roadblocks or problems with their product? It can be technical or business related.*'
	q5 = '*Any other feedback you would like to give?*'
	team_corr.each do |team|
		team[1].each do |user|
			begin
				message = 'Correction Form Feedback' + '
' + q0 + '
' + '>' + team[2] + '
' + q1 + '
' + '>' + team[3] + '
' + q2 + '
' + '>' + team[4] + '
' + q3 + '
' + '>' + team[5] + '
' + q4 + '
' + '>' + team[6] + '
' + q5 + '
' + '>' + team[7] + '
'
				puts 'user is ' + user
				if user != 'olkovale'
					id = Client.users_search(user: user)[:members][0][:id]
				else
					id = Client.users_search(user: 'oleg')[:members][1][:id]
				end
				puts id
				think = rand(1..7)
			rescue
				think = rand(3..10) * 3
				puts '	retry, ' + think.to_s + ' seconds'
				sleep think
				retry
			end
			begin
				puts '	send message'
				Client.chat_postMessage(channel: id, text: message, as_user: true)
			rescue
				think = rand(3..10) * 2
				puts '	retry chat post ' + think.to_s + ' seconds'
				retry
			end
		end
	end
end

if ARGV[0] == 'production'
	if ARGV[1].length > 0
		adj = ARGV[1].to_i
		puts week_start + adj
		send_corr(corr_info(get_teams, (week_start + adj)))
	end
elsif ARGV[0] == 'week_start'
	puts week_start
else
	puts "Usage: ruby send_corr_results.rb \"production\""
end