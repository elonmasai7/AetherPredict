from __future__ import annotations


SEEDED_TEAMS = [
    ("ATL", "Atlanta Hawks", "East", "Southeast"),
    ("BOS", "Boston Celtics", "East", "Atlantic"),
    ("BKN", "Brooklyn Nets", "East", "Atlantic"),
    ("CHA", "Charlotte Hornets", "East", "Southeast"),
    ("CHI", "Chicago Bulls", "East", "Central"),
    ("CLE", "Cleveland Cavaliers", "East", "Central"),
    ("DAL", "Dallas Mavericks", "West", "Southwest"),
    ("DEN", "Denver Nuggets", "West", "Northwest"),
    ("DET", "Detroit Pistons", "East", "Central"),
    ("GSW", "Golden State Warriors", "West", "Pacific"),
    ("HOU", "Houston Rockets", "West", "Southwest"),
    ("IND", "Indiana Pacers", "East", "Central"),
    ("LAC", "LA Clippers", "West", "Pacific"),
    ("LAL", "Los Angeles Lakers", "West", "Pacific"),
    ("MEM", "Memphis Grizzlies", "West", "Southwest"),
    ("MIA", "Miami Heat", "East", "Southeast"),
    ("MIL", "Milwaukee Bucks", "East", "Central"),
    ("MIN", "Minnesota Timberwolves", "West", "Northwest"),
    ("NOP", "New Orleans Pelicans", "West", "Southwest"),
    ("NYK", "New York Knicks", "East", "Atlantic"),
    ("OKC", "Oklahoma City Thunder", "West", "Northwest"),
    ("ORL", "Orlando Magic", "East", "Southeast"),
    ("PHI", "Philadelphia 76ers", "East", "Atlantic"),
    ("PHX", "Phoenix Suns", "West", "Pacific"),
    ("POR", "Portland Trail Blazers", "West", "Northwest"),
    ("SAC", "Sacramento Kings", "West", "Pacific"),
    ("SAS", "San Antonio Spurs", "West", "Southwest"),
    ("TOR", "Toronto Raptors", "East", "Atlantic"),
    ("UTA", "Utah Jazz", "West", "Northwest"),
    ("WAS", "Washington Wizards", "East", "Southeast"),
]

SEEDED_STAR_PLAYERS = [
    ("LeBron James", "LAL"),
    ("Stephen Curry", "GSW"),
    ("Kevin Durant", "PHX"),
    ("Nikola Jokic", "DEN"),
    ("Giannis Antetokounmpo", "MIL"),
    ("Luka Doncic", "DAL"),
    ("Joel Embiid", "PHI"),
    ("Jayson Tatum", "BOS"),
    ("Shai Gilgeous-Alexander", "OKC"),
    ("Anthony Edwards", "MIN"),
    ("Ja Morant", "MEM"),
    ("Damian Lillard", "MIL"),
    ("Kawhi Leonard", "LAC"),
    ("Jimmy Butler", "MIA"),
    ("Devin Booker", "PHX"),
    ("Donovan Mitchell", "CLE"),
    ("Zion Williamson", "NOP"),
    ("Trae Young", "ATL"),
    ("Bam Adebayo", "MIA"),
    ("Karl-Anthony Towns", "NYK"),
]

TEAM_COLOR_MAP = {
    "ATL": ("#E03A3E", "#C1D32F"),
    "BOS": ("#007A33", "#BA9653"),
    "BKN": ("#000000", "#FFFFFF"),
    "CHA": ("#1D1160", "#00788C"),
    "CHI": ("#CE1141", "#000000"),
    "CLE": ("#860038", "#FDBB30"),
    "DAL": ("#00538C", "#B8C4CA"),
    "DEN": ("#0E2240", "#FEC524"),
    "DET": ("#C8102E", "#1D42BA"),
    "GSW": ("#1D428A", "#FFC72C"),
    "HOU": ("#CE1141", "#C4CED4"),
    "IND": ("#002D62", "#FDBB30"),
    "LAC": ("#C8102E", "#1D428A"),
    "LAL": ("#552583", "#FDB927"),
    "MEM": ("#5D76A9", "#12173F"),
    "MIA": ("#98002E", "#F9A01B"),
    "MIL": ("#00471B", "#EEE1C6"),
    "MIN": ("#0C2340", "#78BE20"),
    "NOP": ("#0C2340", "#C8102E"),
    "NYK": ("#006BB6", "#F58426"),
    "OKC": ("#007AC1", "#EF3B24"),
    "ORL": ("#0077C0", "#C4CED4"),
    "PHI": ("#006BB6", "#ED174C"),
    "PHX": ("#1D1160", "#E56020"),
    "POR": ("#E03A3E", "#000000"),
    "SAC": ("#5A2D81", "#63727A"),
    "SAS": ("#C4CED4", "#000000"),
    "TOR": ("#CE1141", "#000000"),
    "UTA": ("#002B5C", "#F9A01B"),
    "WAS": ("#002B5C", "#E31837"),
}


def seeded_teams() -> list[dict]:
    rows = []
    for code, name, conference, division in SEEDED_TEAMS:
        short_name = name.replace("Portland Trail ", "").split()[-1] if code == "POR" else name.split()[-1]
        colors = TEAM_COLOR_MAP.get(code, ("#111827", "#374151"))
        rows.append(
            {
                "id": code,
                "name": name,
                "short_name": short_name,
                "conference": conference,
                "division": division,
                "color": colors[0],
                "accent": colors[1],
                "logo_text": code,
                "win_pct": 0.0,
                "last_five": "",
            }
        )
    return rows


def seeded_players() -> list[dict]:
    teams = {team["id"]: team for team in seeded_teams()}
    rows = []
    for name, team_id in SEEDED_STAR_PLAYERS:
        team = teams[team_id]
        rows.append(
            {
                "id": name.lower().replace(" ", "-"),
                "name": name,
                "team_id": team_id,
                "team_name": team["name"],
                "position": "",
                "stats_json": {},
            }
        )
    return rows
