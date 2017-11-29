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
client = Slack::Web::Client.new
client.auth_test

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

# fetches google sheet generated from form data
def get_sheet
	sheet = Array.new
	i = 1
	while i < RC_C.num_rows
		sheet[i-1] = RC_C.rows[i]
		i += 1
	end
	return sheet
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

# returns list of teams that did their correction
def if_match(teams, start)
	match = Array.new
	test = FuzzyStringMatch::JaroWinkler.create( :native )
	while start < RC_C.num_rows
		teams.each do |team|
			i = test.getDistance(team, RC_C.rows[start][1])
			if i > 0.65
				match.push(team)
				# puts "match, #{team} matches #{RC_C.rows[start][1]}"
			end
		end
		start += 1
	end
	return match
end

# prints list of every correction from a given week 
def print_from(start)
	while start < RC_C.num_rows
		puts RC_C.rows[start][1]
		start += 1
	end
end

#appends x to missed correction cell
def no_correction(teams)
	teams.each do |team|
		i = 0
		j = RC_AP.num_cols
		while i < RC_AP.num_rows
			if RC_AP.rows[i][5] == team
				tmp = RC_AP[(i + 1), j] + 'x'
				RC_AP[(i + 1), j] = tmp
			end
			i += 1
		end
	end
	RC_AP.save 
end
		# members = # range of each person on RC_A worksheet 2
		# if person team == team
		# 		message on slack

missed_teams = get_teams - if_match(get_teams, week_start)
no_correction(missed_teams)
puts missed_teams
# puts RC_AP.rows[1][5]
# id = client.users_info(user: '@jtrujill')[:user][:id]
#id2 = client.users_info(user: '@rlutt')[:user][:id]
# client.chat_postMessage(channel: id, text: "testing", as_user: true)