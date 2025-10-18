# nba_2025_26_schedule_to_csv.rb
# Run inside your Codespace terminal:
#   ruby nba_2025_26_schedule_to_csv.rb
# Produces nba_2025_26_regular_season.csv in the workspace.

require 'json'
require 'csv'
require 'net/http'
require 'uri'
require 'time'

SCHEDULE_URL = 'https://cdn.nba.com/static/json/staticData/scheduleLeagueV2.json'
CHANNELS_URL = 'https://cdn.nba.com/static/json/liveData/channels/v2/channels_00.json'

SEASON_START = Time.new(2025, 10, 1, 0, 0, 0, '+00:00')
SEASON_END   = Time.new(2026, 4, 30, 23, 59, 59, '+00:00')

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
  (arr || []).map { |x| chan_map[x['broadcasterId']] || x['broadcasterDisplay'] }.uniq
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
    else
      puts "Warning: Unexpected channel format: #{c.inspect}"
    end
  end
else
  puts "Warning: No channels data available or unexpected format"
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
    
    # Skip if not in our date range (assuming all games in this data are regular season)
    next unless t_utc && t_utc >= SEASON_START && t_utc <= SEASON_END

    b = g['broadcasters'] || {}

    rows << {
      game_id: g['gameId'],
      season_type: 'Regular Season',
      tip_utc: t_utc.utc.iso8601,
      tip_et:  t_utc.getlocal('-05:00').iso8601,
      away_team: "#{g.dig('awayTeam', 'teamTricode')} (#{g.dig('awayTeam', 'teamName')})",
      home_team: "#{g.dig('homeTeam', 'teamTricode')} (#{g.dig('homeTeam', 'teamName')})",
      venue: g.dig('arena', 'arenaName'),
      city:  g.dig('arena', 'arenaCity'),
      state: g.dig('arena', 'arenaState'),
      national_tv:  map_broadcasters(b['national'], chan_map).join(' | '),
      home_rsns:    map_broadcasters(b['homeTeam'], chan_map).join(' | '),
      away_rsns:    map_broadcasters(b['awayTeam'], chan_map).join(' | '),
      international: map_broadcasters(b['international'], chan_map).join(' | '),
      is_tbd: (!!g['tbaTime']) || (!!g['ifNecessary']) ||
              g.dig('awayTeam','teamName').nil? || g.dig('homeTeam','teamName').nil?
    }
  end
end

# --- Write CSV --------------------------------------------------------------

if date_range.any?
  puts "\nSchedule data contains games from #{date_range.min.strftime('%Y-%m-%d')} to #{date_range.max.strftime('%Y-%m-%d')}"
end
puts "Filtered for: Oct 1 2025 - Apr 30 2026"
puts "Games found: #{rows.size}"

if rows.empty?
  puts "\n❌ No games found matching criteria"
  puts "   Adjust SEASON_START/SEASON_END if needed"
  exit 1
end

outfile = 'nba_2025_26_regular_season.csv'
CSV.open(outfile, 'w') do |csv|
  csv << rows.first.keys
  rows.each { |r| csv << r.values }
end

puts "✅ Wrote #{rows.size} games to #{outfile}"