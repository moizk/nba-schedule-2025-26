#!/usr/bin/env ruby
require 'net/http'
require 'uri'
require 'fileutils'

LOGOS_DIR = 'broadcaster-logos'
FileUtils.mkdir_p(LOGOS_DIR)

# Broadcaster logo sources
# Using high-quality sources from various CDNs and official sites
BROADCASTERS = {
  'ESPN' => 'https://a.espncdn.com/wireless/mw5/redesign2011/img/logos/ESPN_40.png',
  'ESPN2' => 'https://a.espncdn.com/wireless/mw5/redesign2011/img/logos/ESPN2_40.png',
  'ABC' => 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/ABC-2021-LOGO.svg/320px-ABC-2021-LOGO.svg.png',
  'TNT' => 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/TNT_Logo_2016.svg/320px-TNT_Logo_2016.svg.png',
  'NBA TV' => 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d2/NBA_TV.svg/320px-NBA_TV.svg.png',
  'Peacock' => 'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/NBCUniversal_Peacock_Logo.svg/320px-NBCUniversal_Peacock_Logo.svg.png',
  'Amazon' => 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Amazon_Prime_Video_logo.svg/320px-Amazon_Prime_Video_logo.svg.png',
  'Prime Video' => 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Amazon_Prime_Video_logo.svg/320px-Amazon_Prime_Video_logo.svg.png',
  'NBATV' => 'https://upload.wikimedia.org/wikipedia/en/thumb/d/d2/NBA_TV.svg/320px-NBA_TV.svg.png',
}

def download_logo(name, url)
  # Create a safe filename
  filename = name.gsub(/[^a-zA-Z0-9]/, '_') + '.png'
  output_file = File.join(LOGOS_DIR, filename)
  
  # Skip if already exists
  if File.exist?(output_file)
    puts "⏭️  #{name} - already exists"
    return true
  end
  
  begin
    uri = URI(url)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'Mozilla/5.0'
      
      response = http.request(request)
      
      if response.is_a?(Net::HTTPSuccess)
        File.binwrite(output_file, response.body)
        puts "✅ #{name.ljust(15)} - downloaded (#{response.body.size} bytes) -> #{filename}"
        true
      else
        puts "❌ #{name.ljust(15)} - failed (HTTP #{response.code})"
        false
      end
    end
  rescue => e
    puts "❌ #{name.ljust(15)} - error: #{e.message}"
    false
  end
  
  # Be nice to the server
  sleep 0.3
end

puts "📺 Downloading NBA broadcaster logos..."
puts "📂 Output directory: #{LOGOS_DIR}"
puts ""

successful = 0
failed = 0

BROADCASTERS.each do |name, url|
  if download_logo(name, url)
    successful += 1
  else
    failed += 1
  end
end

puts ""
puts "=" * 60
puts "✅ Successfully downloaded: #{successful}/#{BROADCASTERS.size}"
puts "❌ Failed: #{failed}/#{BROADCASTERS.size}" if failed > 0
puts "📁 Logos saved to: #{File.expand_path(LOGOS_DIR)}"
puts "=" * 60

