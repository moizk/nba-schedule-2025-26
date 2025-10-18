#!/bin/bash

echo "📺 Downloading NBA broadcaster logos..."
echo "📂 Output directory: broadcaster-logos"
echo ""

cd broadcaster-logos

# ESPN
curl -L -s -o ESPN.png "https://a.espncdn.com/combiner/i?img=/redesign/assets/img/icons/ESPN-icon-football.png&w=80&h=80&scale=crop&cquality=40&location=origin" && echo "✅ ESPN downloaded"

# ESPN2  
curl -L -s -o ESPN2.png "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/ESPN2_logo.svg/320px-ESPN2_logo.svg.png" && echo "✅ ESPN2 downloaded"

# ABC
curl -s -o ABC.png "https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/ABC-2021-LOGO.svg/320px-ABC-2021-LOGO.svg.png" && echo "✅ ABC downloaded"

# TNT
curl -s -o TNT.png "https://upload.wikimedia.org/wikipedia/commons/thumb/2/24/TNT_Logo_2016.svg/320px-TNT_Logo_2016.svg.png" && echo "✅ TNT downloaded"

# NBA TV (also copy to NBATV for alternate naming)
curl -s -o "NBA_TV.png" "https://upload.wikimedia.org/wikipedia/en/thumb/d/d2/NBA_TV.svg/320px-NBA_TV.svg.png" && echo "✅ NBA TV downloaded"
cp "NBA_TV.png" "NBATV.png"

# NBC
curl -s -o NBC.png "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3f/NBC_logo.svg/320px-NBC_logo.svg.png" && echo "✅ NBC downloaded"

# Peacock
curl -s -o Peacock.png "https://upload.wikimedia.org/wikipedia/commons/thumb/d/d3/NBCUniversal_Peacock_Logo.svg/320px-NBCUniversal_Peacock_Logo.svg.png" && echo "✅ Peacock downloaded"

# Amazon Prime Video
curl -s -o "Prime_Video.png" "https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Amazon_Prime_Video_logo.svg/320px-Amazon_Prime_Video_logo.svg.png" && echo "✅ Prime Video downloaded"
cp "Prime_Video.png" "Amazon.png"

cd ..

echo ""
echo "=================================================="
echo "✅ Broadcaster logos downloaded to broadcaster-logos/"
echo "=================================================="

