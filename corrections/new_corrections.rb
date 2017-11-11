require 'google_drive'
require 'googleauth'
require 'fileutils'

# authenticate a session with your service account
session = GoogleDrive::Session.from_config("client_secret.json")

WS = session.spreadsheet_by_key("1wQA-jDQfux5K8Y7mkcYtn7MKgkf3GUL1bHAJ7F_Frbw").worksheets[0]

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
			random = team.shuffle
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

# writes new corrections to google sheet
def write_res(res, start)
	i = 0
	while i < res.length
		WS[(i + 2), (start + 1)] = res[i]
		i += 1
	end
	WS.save
end
res = teams_matchup(get_teams, get_info)

# print_matchups(get_teams, res)
write_res(res, WS.num_cols)

























