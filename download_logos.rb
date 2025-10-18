#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'fileutils'

# All 30 NBA team tricodes
TEAMS = %w[
  ATL BOS BKN CHA CHI CLE DAL DEN DET GSW
  HOU IND LAC LAL MEM MIA MIL MIN NOP NYK
  OKC ORL PHI PHX POR SAC SAS TOR UTA WAS
]

LOGOS_DIR = 'logos'
FileUtils.mkdir_p(LOGOS_DIR)

# ESPN provides high-quality team logos
# Format: https://a.espncdn.com/i/teamlogos/nba/500/[tricode].png
BASE_URL = 'https://a.espncdn.com/i/teamlogos/nba/500'

# ESPN uses different tricodes for some teams
ESPN_TRICODE_MAP = {
  'NOP' => 'no',    # New Orleans Pelicans
  'UTA' => 'utah'   # Utah Jazz
}

def download_logo(team)
  # Use mapped tricode if available, otherwise use team tricode
  espn_tricode = ESPN_TRICODE_MAP[team] || team.downcase
  url = "#{BASE_URL}/#{espn_tricode}.png"
  output_file = File.join(LOGOS_DIR, "#{team}.png")
  
  # Skip if already exists
  if File.exist?(output_file)
    puts "⏭️  #{team} - already exists"
    return true
  end
  
  begin
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0'
      
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        File.binwrite(output_file, response.body)
        puts "✅ #{team} - downloaded (#{response.body.size} bytes)"
        true
      else
        puts "❌ #{team} - failed (HTTP #{response.code})"
        false
      end
    end
  rescue => e
    puts "❌ #{team} - error: #{e.message}"
    false
  end
  
  # Be nice to the server
  sleep 0.2
end

puts "🏀 Downloading NBA team logos..."
puts "📂 Output directory: #{LOGOS_DIR}"
puts "🌐 Source: ESPN CDN"
puts ""

successful = 0
failed = 0

TEAMS.each do |team|
  if download_logo(team)
    successful += 1
  else
    failed += 1
  end
end

puts ""
puts "=" * 50
puts "✅ Successfully downloaded: #{successful}/#{TEAMS.size}"
puts "❌ Failed: #{failed}/#{TEAMS.size}" if failed > 0
puts "📁 Logos saved to: #{File.expand_path(LOGOS_DIR)}"
puts "=" * 50

