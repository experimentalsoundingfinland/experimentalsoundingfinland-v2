# To run the script locally: 
# export GOOGLE_API_KEY=AIzaSyA8ibG6fO1SGlZilUaFrtQ-oFg0fQF2ksg
# export GOOGLE_CALENDAR_ID=experimentalsoundingfinland@gmail.com
# ruby path/to/update_posts.rb

require 'net/http'
require 'json'
require 'date'
require 'fileutils'

API_KEY = ENV["GOOGLE_API_KEY"]
CALENDAR_ID = ENV["GOOGLE_CALENDAR_ID"]
url = URI("https://www.googleapis.com/calendar/v3/calendars/#{CALENDAR_ID}/events?singleEvents=true&key=#{API_KEY}")

response = Net::HTTP.get(url)
events = JSON.parse(response)['items']

# Ensure the _posts directory exists
FileUtils.mkdir_p('_posts')

events.each do |event|
  date = DateTime.now
  event_start = DateTime.parse(event['start']['dateTime'] || event['start']['date'])
  event_end = DateTime.parse(event['end']['dateTime'] || event['end']['date'])
  title = event['summary'].gsub(/[^0-9A-Za-z.\-]/, '-').downcase
  filename = "_posts/#{date.strftime('%Y-%m-%d')}-#{title}.md"
  
  # Extract venue from the end of the description
  description = event['description'] || 'No description available.'
  venue_marker = 'event_venue123'
  if description.include?(venue_marker)
    venue = description.split(venue_marker).last.strip
    description = description.split(venue_marker).first.strip
  else
    venue = 'TBD'
  end

  # Convert URLs to Markdown links
  description = description.gsub(/(https?:\/\/[^\s]+)|(www\.[^\s]+)|([a-zA-Z0-9]+\.([a-zA-Z]{2,}([^\s]*)?))/) do |match|
    if match.start_with?('http')
      "[#{match}](#{match})"
    else
      "[#{match}](http://#{match})"
    end
  end

  # Replace newline characters with Markdown syntax
  description = description.gsub("\n", "  \n")

  content = <<~CONTENT
    ---
    layout: post
    title: "#{event['summary']}"
    date: #{date.iso8601}
    event_start: #{event_start.iso8601}
    event_end: #{event_end.iso8601}
    venue: "#{venue}"
    address: "#{event['location'] || 'TBD'}"
    ---

    #{description}
  CONTENT

  File.write(filename, content)
end
