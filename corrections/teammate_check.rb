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

# returns index of when previous week's corrections 
def week_start
	i = 1
	while i < RC_C.num_rows
		tmp = RC_C.rows[i][0].split(" ")[0].split("/")
		date = Date.parse(tmp[2] + '-' + tmp[0] + '-' + tmp[1])
				puts 'tmp is ' + tmp.to_s + ', date is ' + date.to_s
		if (Date.parse("monday") - 7) <= date
			puts Date.parse('monday') - 7
			puts 'success at i = ' + i.to_s
			return i + 1
		end
		i += 1
	end
	return i
end

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

# appends strikes on google sheet of teammates that are missing
def mark_misssing_members(login)

end

def get_members(team)
	res = Array.new
	i = 0
	while i < RC_AP.num_rows
		
# finds members who were not present during a correction
def roll_call(team, index)
	members = get_members(team)
end

def find_matchup(teams, start)
	match = Array.new
	test = FuzzyStringMatch::JaroWinkler.create( :native )
	teams.each do |team|
		j = start
		while j < RC_C.num_rows
			if test.getDistance(team, RC_C.rows[j][1]) > 0.65
				roll_call(team, j)
				break
			end
			j += 1
		end
	end
end


find_matchup(get_teams, week_start)

