require 'net/http'
require 'json'
require 'date'
require 'fileutils'

API_KEY = ENV["GOOGLE_API_KEY"]
CALENDAR_ID = ENV["GOOGLE_CALENDAR_ID"]
url = URI("https://www.googleapis.com/calendar/v3/calendars/#{CALENDAR_ID}/events?singleEvents=true&key=#{API_KEY}")

begin
  response = Net::HTTP.get(url)
  puts "API response: #{response}"
  data = JSON.parse(response)
  events = data['items']
  puts "Events: #{events}"
rescue StandardError => e
  puts "Error: #{e.message}"
  exit 1
end

if events.nil? || events.empty?
  puts "No events found"
  exit 0
end

# Ensure the _calendar_ics directory exists
FileUtils.mkdir_p('calendar_ics')

ics_content = "BEGIN:VCALENDAR\n"
ics_content += "VERSION:2.0\n"
ics_content += "CALSCALE:GREGORIAN\n"

events.each do |event|
  event_start = DateTime.parse(event['start']['dateTime'] || event['start']['date'])
  event_end = DateTime.parse(event['end']['dateTime'] || event['end']['date'])

  ics_content += "BEGIN:VEVENT\n"
  ics_content += "UID:#{event['id']}\n"
  ics_content += "DTSTAMP:#{DateTime.now.strftime('%Y%m%dT%H%M%SZ')}\n"
  ics_content += "DTSTART:#{event_start.strftime('%Y%m%dT%H%M%S')}\n"
  ics_content += "DTEND:#{event_end.strftime('%Y%m%dT%H%M%S')}\n"
  ics_content += "SUMMARY:#{event['summary']}\n"
  ics_content += "DESCRIPTION:#{event['description'] || 'No description available.'}\n"
  ics_content += "LOCATION:#{event['location'] || 'TBD'}\n"
  ics_content += "END:VEVENT\n"
end

ics_content += "END:VCALENDAR\n"

# Write the ICS content to a file in the calendar_ics directory
File.write('calendar_ics/events.ics', ics_content)
puts "ICS file generated: calendar_ics/events.ics"
