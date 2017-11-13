require 'google_drive'
require 'googleauth'
require 'fileutils'
require 'date'
require 'slack-ruby-client'

# authenticate a session with your service account
session = GoogleDrive::Session.from_config("client_secret.json")

WS = session.spreadsheet_by_key("1wQA-jDQfux5K8Y7mkcYtn7MKgkf3GUL1bHAJ7F_Frbw").worksheets[0]

#authenticates slackbot
Slack.configure do |config|
	config.token = ENV['SLACK_API_TOKEN']
end
client = Slack::Web::Client.new
client.auth_test

# formats correct slack message
def slack_format(teams, res)
	i = 0
	message = '<!channel> Here are this week\'s peer reviews:

'
	teams.each do |curr|
		message = message + '>' + '*' + curr.to_s + '*' + ' will correct ' + '*' + res[i].to_s + '*' + '
'
		i += 1
	end
	message = message + '
Remember to fill out the following form during your correction: https://goo.gl/forms/vSxwBihzUOLZ0E903'
	return message
end

# prints weekly matchups for each team, used for debugging only
def print_matchups(team, to_correct)
	i = 0
	team.each do |curr|
		puts curr + " correcting " + to_correct[i]
		i += 1
	end
end

# checks if team has corrected current choice before and returns 0 if unique
def match_check(info, choice)
	i = 3
	while i < WS.num_cols
		if info[i] == choice
			return 1
		else
			i += 1
		end
	end
	return 0
end

# finds unique correctors
def teams_matchup(team, info)
	random = team.shuffle
	corr = Array.new
	i = 0
	while i < team.length
		if ((team[i] != random[0]) && (match_check(info[i], random[0]) == 0))
			corr[i] = random[0]
			random.delete_at(0)
			i += 1
		elsif ((i + 1) == team.length)
			i = 0
			random.clear
			random = team.shuffle
			corr.clear
		else
			random.shuffle!
		end
	end
	return corr
end

# finds list of all teams in Rabbit Cloud
def get_teams
	team = Array.new
	i = 1
	while i < WS.num_rows
		team[i-1] = WS[(i+1), 1]
		i += 1
	end
	return team
end

# returns info about each team
def get_info
	info = Array.new
	i = 1
	while i < WS.num_rows
		info[i-1] = WS.rows[i]
		i += 1
	end
	return info
end

#find start date of next week
def next_monday
	monday = Date.parse("monday")
	delta = monday >= Date.today ? 0 : 7
	week_start =  monday + delta
	return "To Correct (week of " + week_start.month.to_s + "/" + week_start.day.to_s + ")"
end

# writes new corrections to google sheet
def write_res(res, start)
	i = 0
	WS[1, (start + 1)] = next_monday
	while i < res.length
		WS[(i + 2), (start + 1)] = res[i]
		i += 1
	end
	WS.save
end

res = teams_matchup(get_teams, get_info)

if ARGV.empty?
	write_res(res, WS.num_cols)
elsif ARGV[0] == "test"
	print_matchups(get_teams, res)
elsif ARGV[0] == "slacktest"
	client.chat_postMessage(channel: 'dev_test2', text: slack_format(get_teams, res), as_user: true)
	puts slack_format(get_teams, res)
else
	puts "Usage for production: ruby new_corrections.rb "
	puts "Usage for local testing: ruby new_corrections.rb \"test\""
	puts "Usage for slack testing: ruby new_corrections.rb \"slacktest\""
end























