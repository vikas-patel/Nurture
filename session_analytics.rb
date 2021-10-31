# Incase json not already installed
# gem install json
require 'json'

@session_gap_time = 1000 * 60 * 10

def add_session(start_time, end_time, pages)
  { duration: end_time - start_time, pages: pages, startTime: start_time }
end

def generate_session_by_user
  output = {}
  user_session_map = {}
  # Read event data from file
  event_data = read_json_file_data['events']
  # Group events by user and store in a map - key as visitorId
  event_data.each { |event|
    (user_session_map[event['visitorId']] ||= []) << { timestamp: event['timestamp'], url: event['url'] }
  }
  user_session_map.each { |user, events|
    # Sort events of user
    events.sort_by! { |event| event[:timestamp] }
    sessions = pages = []
    start_time = end_time = 0
    events.each { |event|
      # Just initialize for the first iteration
      if start_time.zero?
        start_time = event[:timestamp]
        pages = [event[:url]]
        next
      end

      # If last visit was within 10 minutes, don't create new session just add page
      if event[:timestamp] <= start_time + @session_gap_time
        pages << event[:url]
        end_time = event[:timestamp]
      else
        # User visited after 10 minutes, create new session
        sessions << add_session(start_time, end_time, pages)
        pages = [event[:url]]
        start_time = end_time = event[:timestamp]
      end
    }
    sessions << add_session(start_time, end_time, pages) if pages.any?

    output[user] = sessions
  }
  { sessionsByUser: output }
end

def read_json_file_data()
  # First argument is expected to be file name with full path
  file_path = ARGV[0]
  file = File.read(file_path)
  JSON.parse(file)
end

# Print results
puts generate_session_by_user
