# NBA 2025-26 Schedule Data Extractor

Ruby script to fetch and export the NBA 2025-26 regular season schedule with TV broadcast information to CSV format.

## Usage

```bash
ruby nba_2025_26_schedule_to_csv.rb
```

This will generate `nba_2025_26_regular_season.csv` containing all regular season games from October 2025 to April 2026.

## Output CSV Columns

- `game_id` - Unique NBA game identifier
- `season_type` - Season type (Regular Season)
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

The script filters games based on:

1. **Date Range:** October 1, 2025 - April 30, 2026
   - Configured via `SEASON_START` and `SEASON_END` constants
   - Uses `gameDateTimeUTC` for accurate filtering

2. **Season Type:** Regular season games only
   - Note: Current API version doesn't include `seasonStage` field
   - All games in date range are assumed to be regular season

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
