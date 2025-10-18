# Usage inside Codespaces terminal:
#   ruby nba_2025_26_schedule_to_csv.rb
require 'json'; require 'csv'; require 'net/http'; require 'uri'; require 'time'

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

schedule = get_json(SCHEDULE_URL)
channels = (get_json(CHANNELS_URL) rescue {'channels'=>[]})
chan_map = channels.fetch('channels', []).map { |c| [c['id'], c['name'] || c['shortName'] || c['id']] }.to_h

rows = []
schedule.fetch('leagueSchedule', {}).fetch('gameDates', []).each do |date_block|
  date_block.fetch('games', []).each do |g|
    # Regular Season only (seasonStage 2), in Oct 2025–Apr 2026 window
    next unless g['seasonStage'] == 2
    t_utc = Time.parse(g['gameTimeUTC']) rescue nil
    next unless t_utc && t_utc >= SEASON_START && t_utc <= SEASON_END

    b = g['broadcasters'] || {}
    rows << {
      game_id: g['gameId'],
      season_type: 'Regular Season',
      tip_utc: t_utc.utc.iso8601,
      tip_et:  t_utc.getlocal('-05:00').iso8601, # ET for convenience
      away_team: "#{g.dig('awayTeam','teamTricode')} (#{g.dig('awayTeam','teamName')})",
      home_team: "#{g.dig('homeTeam','teamTricode')} (#{g.dig('homeTeam','teamName')})",
      venue: g.dig('arena','arenaName'),
      city:  g.dig('arena','arenaCity'),
      state: g.dig('arena','arenaState'),
      national_tv:  map_broadcasters(b['national'], chan_map).join(' | '),
      home_rsns:    map_broadcasters(b['homeTeam'], chan_map).join(' | '),
      away_rsns:    map_broadcasters(b['awayTeam'], chan_map).join(' | '),
      international: map_broadcasters(b['international'], chan_map).join(' | '),
      is_tbd: (!!g['tbaTime']) || (!!g['ifNecessary']) ||
              g.dig('awayTeam','teamName').nil? || g.dig('homeTeam','teamName').nil?
    }
  end
end

CSV.open('nba_2025_26_regular_season.csv', 'w') do |csv|
  csv << rows.first.keys
  rows.each { |r| csv << r.values }
end

puts "Wrote #{rows.size} games to nba_2025_26_regular_season.csv"