require 'google_drive'
require 'googleauth'
require 'fileutils'
require 'date'
require 'slack-ruby-client'
require 'timeout'

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
	message = String.new
	message = '<!channel> Here are this week\'s peer reviews:

'
	teams.each do |curr|
		message = message + '>' + '*' + curr.to_s + '*' + ' will correct ' + '*' + res[i].to_s + '*' + '
'
		i += 1
	end
	message = message + '
Please conduct these corrections between Wednesday and Sunday, it is up to you to work out a time with the other team. Remember to fill out the following form during your correction: https://goo.gl/forms/vSxwBihzUOLZ0E903'
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
	i = 13 # start of current batch corrections
	if choice.length == 1 || info[0] == choice
		return 1
	end
	while i < WS.num_cols
		if info[i] == choice
			puts '	MATCH. info is ' + info[i] + ' , choice is ' + choice
			return 1
		else
			puts '	No Match. info is ' + info[i] + ' , choice is ' + choice
			i += 1
		end
	end
	puts '	return 0'
	return 0
end

# if no possible match left, return 1
def possible_match(info, choice)
	i = 0
	while i < choice.length
		# puts 'from posssible, team is ' + team[0]
		if match_check(info, choice[i]) == 0
			return 0
		elsif (choice.length == 1) && (info[i] == choice[0])
			return 1
		else
			i += 1
		end
	end
	return 1
end

# randomly assigns matchup without checking history
def rematch_ok(team)
	i = 0
	corr = Array.new
	matchups = team.shuffle
	if team.length == 1
		return team
	end
	while i < team.length
		if team[i] != matchups[0]
			corr[i] = matchups[0]
			matchups.delete_at(0)
			i += 1
		else
			matchups.shuffle!
			if matchups.length == 1
				i = 0
				corr.clear
			end
		end
	end
	return corr
end

# finds unique correctors
# teams is array of teams, info is 2d array of matchup history
def teams_matchup(team, info)
	i = 0
	corr = Array.new
	random = team.shuffle
	while i < team.length
		if ((team[i] != random[0]) && (match_check(info[i], random[0]) == 0))
			corr[i] = random[0]
			random.delete_at(0)
			i += 1
		elsif possible_match(info[i], random) == 1
			puts 'no match'
			i = 0
			random.clear
			random = team.shuffle
			corr.clear
		else
			puts 'shuffle'
			random.shuffle!
		end
	end
	return corr
end
# def teams_matchup(team, info)
# 	retry_attempts = 0
# 	timeouts = 0
# 	random = team.shuffle
# 	corr = Array.new
# 	i = 0
# 	puts '\n\n\n\n\n'
# 	puts info[0]
# 	while i < team.length
# 		puts 'from teams_matchup, team is ' + info[i][0]
# 		if ((team[i] != random[0]) && (match_check(info[i], random[0]) == 0))
# 			corr[i] = random[0]
# 			puts '		' + info[i][0] + ' corrected by ' + corr[i] + '/' + random[0] + "\n\n"
# 			random.delete_at(0)
# 			i += 1
# 		elsif possible_match(info[i], random) == 1
# 			i = 0
# 			puts '		NO POSSIBLE MATCH'
# 			random.clear
# 			random = team.shuffle
# 			corr.clear
# 		else
# 			retry_attempts += 1
# 			if retry_attempts > (team.length * 2)
# 				puts '		retry ok'
# 				return rematch_ok(team)
# 			else
# 				random.shuffle!
# 				retry_attempts += 1
# 			end
# 		end
# 	end
# 	puts "\n\n\nEND RESULT\n\n\n"
# 	return corr
# end

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
	# delta = monday >= Date.today ? 0 : 7
	# uncomment above line and add delta to monday on line below if running before week start
	week_start =  monday
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

if ARGV[0] == 'production'
	client.chat_postMessage(channel: 'general', text: slack_format(get_teams, res), as_user: true)
	write_res(res, WS.num_cols)
	puts "success"
elsif ARGV[0] == "localtest"
	puts next_monday
	print_matchups(get_teams, res)
elsif ARGV[0] == "slacktest"
	client.chat_postMessage(channel: 'rc_dev', text: slack_format(get_teams, res), as_user: true)
	puts next_monday
	puts slack_format(get_teams, res)
else
	puts "Usage for production: ruby new_corrections.rb \"production\""
	puts "Usage for local testing: ruby new_corrections.rb \"localtest\""
	puts "Usage for slack testing: ruby new_corrections.rb \"slacktest\""
end























