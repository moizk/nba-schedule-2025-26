# NBA 2025-26 Schedule Data Extractor

Ruby script to fetch and export the NBA 2025-26 schedule (preseason and regular season) with TV broadcast information in both CSV and JSON formats.

## Usage

```bash
ruby fetch_schedule.rb
```

This will generate two files:
- `nba_2025_26_schedule.csv` - CSV format with all games
- `nba_2025_26_schedule.json` - JSON format with metadata and all games

The data includes:
- **Preseason games:** October 2-20, 2025
- **Regular season games:** October 21, 2025 - April 2026

## Output Formats

### CSV Columns

- `game_id` - Unique NBA game identifier
- `season_type` - Season type ("Preseason" or "Regular Season")
- `tip_utc` - Game tip-off time in UTC (ISO 8601 format)
- `tip_et` - Game tip-off time in Eastern Time (ISO 8601 format)
- `away_team` - Away team (tricode and name)
- `home_team` - Home team (tricode and name)
- `venue` - Arena name
- `city` - Arena city
- `state` - Arena state/province
- `national_tv` - National TV broadcasters (ESPN, ABC, TNT, NBA TV, etc.)
- `home_rsns` - Home team regional sports networks
- `away_rsns` - Away team regional sports networks
- `international` - International broadcasters
- `is_tbd` - Whether game details are to be determined

### JSON Structure

The JSON file contains metadata and an array of all games:

```json
{
  "season": "2025-26",
  "total_games": 1279,
  "preseason_games": 80,
  "regular_season_games": 1199,
  "regular_season_start_date": "2025-10-21",
  "last_updated": "2025-10-18T15:30:00Z",
  "games": [
    {
      "game_id": "0012500008",
      "season_type": "Preseason",
      "tip_utc": "2025-10-02T16:00:00Z",
      "tip_et": "2025-10-02T11:00:00-05:00",
      "away_team": "PHI (76ers)",
      "home_team": "NYK (Knicks)",
      "venue": "Etihad Arena",
      "city": "Abu Dhabi",
      "state": "",
      "national_tv": "NBA TV",
      "home_rsns": "MSG",
      "away_rsns": "",
      "international": "",
      "is_tbd": false
    }
  ]
}
```

## Data Source

The script fetches data from the official NBA schedule API:

**Schedule Endpoint:**
```
https://cdn.nba.com/static/json/staticData/scheduleLeagueV2.json
```

**Channels Endpoint (currently unavailable):**
```
https://cdn.nba.com/static/json/liveData/channels/v2/channels_00.json
```

## NBA Schedule API Structure

### Top Level Structure

```json
{
  "leagueSchedule": {
    "gameDates": [...]
  }
}
```

### Game Date Block

```json
{
  "gameDate": "2025-10-22",
  "games": [...]
}
```

### Game Object - Complete Structure

Each game object contains the following fields:

#### Basic Game Information
- `gameId` - Unique game identifier (e.g., "0012500008")
- `gameCode` - Game code format: YYYYMMDD/AWAYTEAMHOMETEAM (e.g., "20251002/PHINYK")
- `gameStatus` - Game status code (1=scheduled, 2=in progress, 3=final)
- `gameStatusText` - Game status as text (e.g., "Final", "Scheduled")
- `gameSequence` - Game sequence number
- `gameLabel` - Game category label (e.g., "Preseason", "Regular Season")
- `gameSubLabel` - Game sub-category (e.g., "NBA Abu Dhabi Game")
- `gameSubtype` - Special game type (e.g., "Global Games", "In-Season Tournament")
- `seriesText` - Series information (e.g., "Neutral Site")
- `seriesGameNumber` - Game number in series
- `ifNecessary` - Whether game is "if necessary" ("true"/"false")
- `postponedStatus` - Postponement status ("N" for not postponed)
- `branchLink` - Branch link reference

#### Date/Time Information
- `gameDateEst` - Game date in EST (date only, time is 00:00:00Z)
- `gameTimeEst` - Game time in EST (time only, date is 1900-01-01)
- `gameDateTimeEst` - Complete game datetime in EST (ISO 8601)
- `gameDateUTC` - Game date in UTC (date only, time is 04:00:00Z)
- `gameTimeUTC` - Game time in UTC (time only, date is 1900-01-01)
- `gameDateTimeUTC` - Complete game datetime in UTC (ISO 8601) **← Use this field**
- `awayTeamTime` - Adjusted time for away team's timezone
- `homeTeamTime` - Adjusted time for home team's timezone
- `day` - Day of week abbreviation (e.g., "Thu")
- `monthNum` - Month number (1-12)
- `weekNumber` - Week number in season
- `weekName` - Week name/label

#### Venue Information
- `arenaName` - Arena name (e.g., "Etihad Arena")
- `arenaCity` - Arena city (e.g., "Abu Dhabi")
- `arenaState` - Arena state/province (empty string for international)
- `isNeutral` - Whether venue is neutral site (true/false)

#### Team Information

**Home Team (`homeTeam` object):**
```json
{
  "teamId": 1610612752,
  "teamName": "Knicks",
  "teamCity": "New York",
  "teamTricode": "NYK",
  "teamSlug": "knicks",
  "wins": 0,
  "losses": 0,
  "score": 0,
  "seed": null,
  "inBonus": null,
  "timeoutsRemaining": 0,
  "periods": []
}
```

**Away Team (`awayTeam` object):** Same structure as home team

#### Broadcaster Information

The `broadcasters` object contains arrays of broadcaster information:

```json
{
  "nationalBroadcasters": [
    {
      "broadcasterScope": "natl",
      "broadcasterMedia": "tv",
      "broadcasterId": 7,
      "broadcasterDisplay": "NBA TV",
      "broadcasterAbbreviation": "NBATV",
      "regionId": 0,
      "type": "tv",
      "homeVisitor": "natl",
      "callLetters": ""
    }
  ],
  "homeTvBroadcasters": [...],
  "awayTvBroadcasters": [...],
  "homeRadioBroadcasters": [...],
  "awayRadioBroadcasters": [...],
  "internationalBroadcasters": [...]
}
```

**Broadcaster Object Fields:**
- `broadcasterScope` - Scope of broadcast (e.g., "natl", "home", "away")
- `broadcasterMedia` - Media type (e.g., "tv", "radio")
- `broadcasterId` - Numeric broadcaster ID
- `broadcasterDisplay` - Full broadcaster name (e.g., "ESPN", "ABC")
- `broadcasterAbbreviation` - Abbreviated name
- `regionId` - Region identifier
- `type` - Type of broadcast
- `homeVisitor` - Indicates national/home/away broadcast
- `callLetters` - Station call letters (for radio)

**Broadcaster Types:**
- `nationalBroadcasters` - National TV (ESPN, ABC, TNT, NBA TV, etc.)
- `homeTvBroadcasters` - Home team local TV (RSNs)
- `awayTvBroadcasters` - Away team local TV (RSNs)
- `homeRadioBroadcasters` - Home team radio
- `awayRadioBroadcasters` - Away team radio
- `internationalBroadcasters` - International broadcasts

#### Game Statistics

**Point Leaders (`pointsLeaders` array):**
```json
[
  {
    "personId": 1630178,
    "firstName": "Tyrese",
    "lastName": "Maxey",
    "teamId": 1610612755,
    "teamCity": "Philadelphia",
    "teamName": "76ers",
    "teamTricode": "PHI",
    "points": 0
  }
]
```

**Additional Statistics Fields:**
- `periods` - Array of period-by-period data
- `gameLeaders` - Top performers by category
- `pbOdds` - Betting odds information
- `tickets` - Ticket purchase information

## Known Broadcaster IDs

Based on historical data and fallback mapping:

| ID | Network |
|----|---------|
| 1  | ABC |
| 2  | ESPN |
| 3  | TNT |
| 4  | NBA TV |
| 5  | ESPN2 |
| 7  | NBA TV |
| 10 | TNT |
| 16 | ESPN |
| 20 | ABC |

**Note:** The script uses `broadcasterDisplay` field when available, falling back to ID mapping.

## Filtering

The script processes games based on:

1. **Date Range:** October 1, 2025 - April 30, 2026
   - Configured via `SEASON_START` and `SEASON_END` constants
   - Uses `gameDateTimeUTC` for accurate filtering

2. **Season Type Classification:**
   - Games before October 21, 2025 are labeled as "Preseason"
   - Games on or after October 21, 2025 are labeled as "Regular Season"
   - Configured via `REGULAR_SEASON_START` constant
   - Note: The NBA API may label preseason games as "Regular Season", so this script corrects that based on the actual regular season start date

## Additional Available Data (Not Currently Extracted)

The following data is available in the API but not currently extracted:

### Game Details
- `tbaTime` - Whether game time is TBA
- `gameClock` - Current game clock (for live games)
- `period` - Current period
- `regulationPeriods` - Number of regulation periods
- `seriesConference` - Conference for series games

### Team Details
- `inBonus` - Team in bonus situation
- `timeoutsRemaining` - Timeouts left
- `periods` - Period-by-period scoring

### Betting Information
- `pbOdds` - Point spread and betting odds
- `tickets` - Ticket availability and links

### Officials
- `gameOfficials` - Referee assignments

### Media
- `video` - Video streaming information
- `audio` - Audio streaming information

## License

MIT License - See LICENSE file for details

## Contributing

To add support for additional fields:

1. Update the row hash in the script to include the new field
2. Add the field to the CSV column list
3. Update this README with the new field documentation
