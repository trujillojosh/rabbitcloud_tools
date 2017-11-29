require 'google_drive'
require 'googleauth'
require 'fileutils'
require 'date'
require 'slack-ruby-client'

# authenticate a session with your service account
session = GoogleDrive::Session.from_config("client_secret.json")

RC_AP = session.spreadsheet_by_key("1wQA-jDQfux5K8Y7mkcYtn7MKgkf3GUL1bHAJ7F_Frbw").worksheets[1]

#authenticates slackbot
Slack.configure do |config|
	config.token = ENV['SLACK_API_TOKEN']
end
Client = Slack::Web::Client.new
Client.auth_test

# fetches google sheet generated from form data
def get_sheet
	sheet = Array.new
	i = 1
	j = 0
	while i < RC_AP.num_rows
		if RC_AP.rows[i][5] != 'Admin' && RC_AP.rows[i][5] != 'other' && RC_AP.rows[i][RC_AP.num_cols - 2] != 'Excused'
			sheet[j] = Array.new
			sheet[j][0] = RC_AP.rows[i][2]
			sheet[j][1] = RC_AP.rows[i][5]
			j += 1
		end
		i += 1
	end
	return sheet
end


# takes in list of usernames to contact and messages them on slack
def contact_devil(teams)
	teams.each do |team|
		id = Client.users_info(user: '@' + team)[:user][:id]
		puts 'login is ' + team + ', id is ' + id
		Client.chat_postMessage(channel: id, text: 'You have been selected to play the Devil\'s Advocate role at Rabbit Cloud\'s weekly meeting. You will be one of 3 people tasked with this role and your job is to ensure each team is challenged with atleast 1 question during their presentation. Please let me know if you cannot make this meeting or perform this role. Thanks', as_user: true)
	end
end

# randomly finds 3 students from unique teams
def find_devil
	people = get_sheet.shuffle
	teams = Array.new
	res = Array.new
	i = 0
	j = 0
	while i < 3
		if teams.include?(people[j][1]) == false
			res.push(people[j][0])
			teams.push(people[j][1])
			i += 1
		end
		j+= 1
	end
	return res
end

if ARGV[0] == 'production'
	contact_devil(find_devil)
elsif ARGV[0] == 'test'
	puts find_devil
else
	puts "Usage: ruby devils_advocate.rb \"production\""
end