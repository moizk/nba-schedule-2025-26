# fetch_schedule.rb
# Fetches NBA 2025-26 schedule and outputs both CSV and JSON formats
# Run: ruby fetch_schedule.rb
# Produces: nba_2025_26_schedule.csv and nba_2025_26_schedule.json

require 'json'
require 'csv'
require 'net/http'
require 'uri'
require 'time'

SCHEDULE_URL = 'https://cdn.nba.com/static/json/staticData/scheduleLeagueV2.json'
CHANNELS_URL = 'https://cdn.nba.com/static/json/liveData/channels/v2/channels_00.json'

SEASON_START = Time.new(2025, 10, 1, 0, 0, 0, '+00:00')
SEASON_END   = Time.new(2026, 4, 30, 23, 59, 59, '+00:00')
REGULAR_SEASON_START = Time.new(2025, 10, 21, 0, 0, 0, '+00:00')

def get_json(url)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = 'Mozilla/5.0'
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    res = http.request(req)
    raise "#{url} -> #{res.code}" unless res.is_a?(Net::HTTPSuccess)
    JSON.parse(res.body)
  end
end

def map_broadcasters(arr, chan_map)
  return [] if arr.nil? || arr.empty?
  arr.map do |x| 
    # Try to get channel name from map, or use broadcasterDisplay, or use broadcasterId as fallback
    chan_map[x['broadcasterId']] || x['broadcasterDisplay'] || "ID:#{x['broadcasterId']}"
  end.compact.uniq
end

# --- Fetch data -------------------------------------------------------------

puts "Fetching schedule and channel data..."
schedule = get_json(SCHEDULE_URL)
channels = (get_json(CHANNELS_URL) rescue [])

# Handle either { "channels": [...] } or an array
chan_list =
  if channels.is_a?(Hash)
    channels['channels'] || []
  else
    channels
  end

# Build channel map with error handling
chan_map = {}
if chan_list.is_a?(Array) && !chan_list.empty?
  chan_list.each do |c|
    if c.is_a?(Hash)
      chan_map[c['id']] = c['name'] || c['shortName'] || c['id']
    end
  end
end

# Fallback: Common NBA broadcaster IDs (based on historical data)
if chan_map.empty?
  chan_map = {
    1 => 'ABC',
    2 => 'ESPN',
    3 => 'TNT',
    4 => 'NBA TV',
    5 => 'ESPN2',
    6 => 'NBATV',
    7 => 'NBA TV',
    10 => 'TNT',
    16 => 'ESPN',
    20 => 'ABC',
    # Add more as we discover them
  }
  puts "Note: Using fallback broadcaster map (channels API unavailable)"
end

# --- Build rows -------------------------------------------------------------

rows = []

game_dates = schedule.fetch('leagueSchedule', {}).fetch('gameDates', [])

# Collect some stats for reporting
date_range = []

schedule.fetch('leagueSchedule', {}).fetch('gameDates', []).each do |date_block|
  date_block.fetch('games', []).each do |g|
    t_utc = Time.parse(g['gameDateTimeUTC']) rescue nil
    date_range << t_utc if t_utc
    
    # Skip if not in our date range
    next unless t_utc && t_utc >= SEASON_START && t_utc <= SEASON_END

    # Determine if this is preseason or regular season
    season_type = t_utc < REGULAR_SEASON_START ? 'Preseason' : 'Regular Season'

    b = g['broadcasters'] || {}

    rows << {
      game_id: g['gameId'],
      season_type: season_type,
      tip_utc: t_utc.utc.iso8601,
      tip_et:  t_utc.getlocal('-05:00').iso8601,
      away_team: "#{g.dig('awayTeam', 'teamTricode')} (#{g.dig('awayTeam', 'teamName')})",
      home_team: "#{g.dig('homeTeam', 'teamTricode')} (#{g.dig('homeTeam', 'teamName')})",
      venue: g['arenaName'],
      city:  g['arenaCity'],
      state: g['arenaState'],
      national_tv:  map_broadcasters(b['nationalBroadcasters'], chan_map).join(' | '),
      home_rsns:    map_broadcasters(b['homeTvBroadcasters'], chan_map).join(' | '),
      away_rsns:    map_broadcasters(b['awayTvBroadcasters'], chan_map).join(' | '),
      international: map_broadcasters(b['internationalBroadcasters'], chan_map).join(' | '),
      is_tbd: (!!g['tbaTime']) || (g['ifNecessary'] == 'true') ||
              g.dig('awayTeam','teamName').nil? || g.dig('homeTeam','teamName').nil?
    }
  end
end

# --- Write CSV --------------------------------------------------------------

if date_range.any?
  puts "Schedule data contains games from #{date_range.min.strftime('%Y-%m-%d')} to #{date_range.max.strftime('%Y-%m-%d')}"
end
puts "Filtered for: Oct 1 2025 - Apr 30 2026"
puts "Games found: #{rows.size}"

if rows.empty?
  puts "\n❌ No games found matching criteria"
  puts "   Adjust SEASON_START/SEASON_END if needed"
  exit 1
end

preseason_count = rows.count { |r| r[:season_type] == 'Preseason' }
regular_count = rows.count { |r| r[:season_type] == 'Regular Season' }

# --- Write CSV --------------------------------------------------------------

csv_file = 'nba_2025_26_schedule.csv'
CSV.open(csv_file, 'w') do |csv|
  csv << rows.first.keys
  rows.each { |r| csv << r.values }
end

puts "✅ Wrote CSV: #{csv_file}"
puts "   - Total: #{rows.size} games"
puts "   - Preseason: #{preseason_count} games"
puts "   - Regular Season: #{regular_count} games"

# --- Write JSON -------------------------------------------------------------

json_file = 'nba_2025_26_schedule.json'

# Convert rows to JSON-friendly format
games = rows.map do |row|
  {
    game_id: row[:game_id],
    season_type: row[:season_type],
    tip_utc: row[:tip_utc],
    tip_et: row[:tip_et],
    away_team: row[:away_team],
    home_team: row[:home_team],
    venue: row[:venue],
    city: row[:city],
    state: row[:state],
    national_tv: row[:national_tv],
    home_rsns: row[:home_rsns],
    away_rsns: row[:away_rsns],
    international: row[:international],
    is_tbd: row[:is_tbd]
  }
end

schedule_data = {
  season: '2025-26',
  total_games: games.length,
  preseason_games: preseason_count,
  regular_season_games: regular_count,
  regular_season_start_date: '2025-10-21',
  last_updated: Time.now.utc.iso8601,
  games: games
}

File.write(json_file, JSON.pretty_generate(schedule_data))

puts "✅ Wrote JSON: #{json_file}"