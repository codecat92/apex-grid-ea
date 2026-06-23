#!/usr/bin/env python3
"""
Apex Grid EA — ForexFactory News Fetcher
=========================================
Fetches economic calendar data from ForexFactory and writes a JSON cache file
for the Apex Grid EA to read via MQL4 FileRead.

USAGE:
    python news_fetcher.py [--output PATH] [--currencies USD,EUR,GBP] [--log PATH]

OUTPUT (news_cache.json):
    {
      "fetched_at": "2026-06-23 08:30:00",
      "source": "nfs.faireconomy.media",
      "events": [
        {"datetime": "2026-06-23T14:00:00Z", "currency": "USD",
         "event_name": "FOMC Minutes", "impact": "High"}
      ]
    }

FALLBACK CHAIN:
    1. nfs.faireconomy.media JSON (community proxy)
    2. Forexfactory HTML scrape via cloudscraper + BeautifulSoup
    3. If all fail: write file with empty events array + error flag

SETUP:
    pip install requests beautifulsoup4 cloudscraper

BUILD EXE (for servers without Python):
    pip install pyinstaller
    pyinstaller news_fetcher.spec
"""

import argparse
import json
import os
import sys
import time
from datetime import datetime, timedelta
from typing import Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_OUTPUT = "news_cache.json"
DEFAULT_CURRENCIES = ["USD", "EUR", "GBP", "CHF", "CAD", "AUD", "NZD", "JPY"]
LOG_FILE = "news_fetcher.log"

# Timezone: Forexfactory uses US Eastern (EST/EDT), DST-aware per-event



# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
def log(msg: str, level: str = "INFO") -> None:
    stamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"[{level}] {stamp} | {msg}"
    print(line)
    try:
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except OSError:
        pass


# ---------------------------------------------------------------------------
# Source 1: nfs.faireconomy.media JSON
# ---------------------------------------------------------------------------
def fetch_faireconomy_json() -> Optional[list]:
    """Try the community JSON proxy. Returns list of event dicts or None."""
    try:
        import requests
    except ImportError:
        log("requests not installed; skipping Source 1", "WARN")
        return None

    url = "https://nfs.faireconomy.media/ff_calendar_thisweek.json"
    try:
        log(f"Fetching {url} ...")
        resp = requests.get(url, timeout=30, headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        })
        if resp.status_code != 200:
            log(f"Source 1 returned HTTP {resp.status_code}", "WARN")
            return None

        data = resp.json()
        events = _parse_faireconomy(data)
        if events:
            log(f"Source 1 OK: {len(events)} events", "OK")
            return events
        else:
            log("Source 1 returned empty event list", "WARN")
            return None
    except Exception as e:
        log(f"Source 1 failed: {e}", "WARN")
        return None


def _parse_faireconomy(data: list) -> list:
    """Parse the faireconomy JSON structure into our standard event format."""
    events = []
    now = datetime.utcnow()
    cutoff = now + timedelta(days=2)

    for item in data:
        try:
            name = str(item.get("title", item.get("name", ""))).strip()
            country = str(item.get("country", item.get("currency", ""))).strip()
            impact = str(item.get("impact", "")).strip().lower()
            date_str = str(item.get("date", item.get("datetime", ""))).strip()

            if not name or not country or not date_str:
                continue

            # Parse date (ISO 8601 with timezone, e.g. 2026-06-23T14:00:00-04:00)
            try:
                dt_aware = datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%S%z")
                dt_utc = datetime.utcfromtimestamp(dt_aware.timestamp())
            except ValueError:
                try:
                    dt_utc = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
                except ValueError:
                    try:
                        dt_utc = datetime.strptime(date_str, "%Y-%m-%d")
                    except ValueError:
                        continue

            # Skip past events older than 1 hour and events beyond 2 days
            if dt_utc < now - timedelta(hours=1) or dt_utc > cutoff:
                continue

            # Map country code to currency
            currency = _country_to_currency(country)

            # Normalize impact
            impact = _normalize_impact(impact)

            events.append({
                "datetime": dt_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "currency": currency,
                "event_name": name,
                "impact": impact,
            })
        except Exception:
            continue

    return events


# ---------------------------------------------------------------------------
# Source 2: Forexfactory HTML scrape
# ---------------------------------------------------------------------------
def fetch_forexfactory_html() -> Optional[list]:
    """Scrape forexfactory.com/calendar HTML as fallback. Uses cloudscraper."""
    try:
        import cloudscraper
        from bs4 import BeautifulSoup
    except ImportError:
        log("cloudscraper/bs4 not installed; skipping Source 2", "WARN")
        return None

    url = "https://www.forexfactory.com/calendar"
    try:
        log(f"Fetching {url} via cloudscraper ...")
        scraper = cloudscraper.create_scraper(
            browser={"browser": "chrome", "platform": "windows", "mobile": False}
        )
        resp = scraper.get(url, timeout=45)
        if resp.status_code != 200:
            log(f"Source 2 returned HTTP {resp.status_code}", "WARN")
            return None

        events = _parse_forexfactory_html(resp.text)
        if events:
            log(f"Source 2 OK: {len(events)} events", "OK")
            return events
        else:
            log("Source 2 returned empty event list", "WARN")
            return None
    except Exception as e:
        log(f"Source 2 failed: {e}", "WARN")
        return None


def _parse_forexfactory_html(html: str) -> list:
    """Parse Forexfactory calendar HTML into standard event format."""
    from bs4 import BeautifulSoup
    from datetime import timezone as dt_timezone

    events = []
    now = datetime.utcnow()
    cutoff = now + timedelta(days=2)

    soup = BeautifulSoup(html, "html.parser")

    table = soup.find("table", class_="calendar__table")
    if not table:
        log("Could not find calendar table in HTML", "WARN")
        return events

    rows = table.find_all("tr", class_="calendar__row")
    current_date = None
    last_time = None

    for row in rows:
        classes = row.get("class", [])
        classes_str = " ".join(classes)

        # Skip day-breaker rows (section headers like "Mon Jun 22")
        if "calendar__row--day-breaker" in classes_str:
            date_cell = row.find("td", class_="calendar__date")
            if date_cell:
                date_text = " ".join(date_cell.stripped_strings)
                try:
                    # Format: "Sun Jun 21"
                    current_date = datetime.strptime(date_text, "%a %b %d")
                    current_date = current_date.replace(year=now.year)
                except ValueError:
                    pass
            continue

        tds = row.find_all("td")
        if len(tds) < 4:
            continue

        try:
            is_new_day = "calendar__row--new-day" in classes_str
            off = 1 if is_new_day else 0

            # Update current_date from new-day rows (td[0] = date)
            if is_new_day:
                date_cell = tds[0]
                date_text = " ".join(date_cell.stripped_strings)
                try:
                    current_date = datetime.strptime(date_text, "%a %b %d")
                    current_date = current_date.replace(year=now.year)
                except ValueError:
                    pass

            time_cell     = tds[off]
            currency_cell = tds[off + 1]
            impact_cell   = tds[off + 2]
            event_cell    = tds[off + 3]

            time_text = time_cell.get_text(strip=True)
            currency = currency_cell.get_text(strip=True).upper()
            name = event_cell.get_text(strip=True)

            if not currency or not name:
                continue

            # Carry forward time from previous row if current is empty
            if not time_text:
                time_text = last_time
            else:
                last_time = time_text

            if not time_text:
                continue

            # Parse time: "8:00am", "10:00am", "2:30pm"
            try:
                time_parsed = datetime.strptime(time_text.lower(),
                                                "%I:%M%p").time()
            except ValueError:
                continue

            if current_date is None:
                continue

            # Combine date + time into ET local datetime
            dt_et = datetime.combine(current_date, time_parsed)

            # Convert ET -> UTC. ET offset depends on DST.
            # For the current week, use the offset from the event's own date.
            # If event month is between Mar-Nov, assume EDT (-4); else EST (-5)
            if 3 <= dt_et.month <= 11:
                offset = timedelta(hours=4)  # EDT = UTC-4
            else:
                offset = timedelta(hours=5)  # EST = UTC-5
            dt_utc = dt_et + offset  # ET + 4h or 5h = UTC

            if dt_utc < now - timedelta(hours=1) or dt_utc > cutoff:
                continue

            # Parse impact from icon class
            impact = "Low"
            if impact_cell:
                icon = impact_cell.find("span", class_="icon")
                if icon:
                    icon_cls = " ".join(icon.get("class", []))
                    if "icon--ff-impact-red" in icon_cls:
                        impact = "High"
                    elif "icon--ff-impact-ora" in icon_cls:
                        impact = "Medium"

            events.append({
                "datetime": dt_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "currency": currency,
                "event_name": name,
                "impact": _normalize_impact(impact),
            })
        except Exception:
            continue

    return events


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _country_to_currency(country: str) -> str:
    """Map country code or name to ISO currency code."""
    mapping = {
        "US": "USD", "UNITED STATES": "USD", "USA": "USD",
        "EU": "EUR", "EUROZONE": "EUR", "EUROPEAN UNION": "EUR",
        "GB": "GBP", "UK": "GBP", "UNITED KINGDOM": "GBP",
        "CH": "CHF", "SWITZERLAND": "CHF",
        "CA": "CAD", "CANADA": "CAD",
        "AU": "AUD", "AUSTRALIA": "AUD",
        "NZ": "NZD", "NEW ZEALAND": "NZD",
        "JP": "JPY", "JAPAN": "JPY",
        "CN": "CNY", "CHINA": "CNY",
    }
    return mapping.get(country.upper(), country.upper()[:3])


def _normalize_impact(impact: str) -> str:
    """Normalize impact string to High/Medium/Low."""
    impact = impact.strip().lower()
    if impact in ("high", "3", "red"):
        return "High"
    if impact in ("medium", "2", "orange"):
        return "Medium"
    return "Low"


def filter_events(events: list, currencies: list) -> list:
    """Keep only events whose currency is in the allowed list."""
    if events is None:
        return []
    if not currencies:
        return events
    allowed = [c.upper() for c in currencies]
    return [e for e in events if e["currency"].upper() in allowed]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    global LOG_FILE

    parser = argparse.ArgumentParser(description="Apex Grid News Fetcher")
    parser.add_argument("--output", default=DEFAULT_OUTPUT,
                        help="Output JSON file path")
    parser.add_argument("--currencies", default=",".join(DEFAULT_CURRENCIES),
                        help="Comma-separated list of currency codes to filter")
    parser.add_argument("--log", default=LOG_FILE,
                        help="Log file path")
    args = parser.parse_args()

    LOG_FILE = args.log

    currencies = [c.strip().upper() for c in args.currencies.split(",") if c.strip()]

    log(f"Apex Grid News Fetcher started")
    log(f"  output={args.output}  currencies={currencies}")

    # --- Fallback chain ---
    events: list = []
    source = "none"

    # Source 1
    events = fetch_faireconomy_json()
    if events:
        source = "nfs.faireconomy.media"

    # Source 2
    if not events:
        events = fetch_forexfactory_html()
        if events:
            source = "forexfactory.com (scrape)"

    # --- Filter & Write ---
    events = filter_events(events, currencies)
    events.sort(key=lambda e: e["datetime"])

    result = {
        "fetched_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
        "source": source,
        "events_count": len(events),
        "events": events,
    }

    # Write JSON (human-readable / debug)
    try:
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
    except OSError as e:
        log(f"Failed to write JSON: {e}", "ERR")
        sys.exit(1)

    # Write pipe-delimited text file for MQL4 (simple line-by-line parse)
    txt_path = args.output.replace(".json", ".txt")
    try:
        with open(txt_path, "w", encoding="utf-8") as f:
            f.write(f"# FX:{args.currencies} TS:{result['fetched_at']}\n")
            for e in events:
                f.write(f"{e['datetime']}|{e['currency']}|{e['impact']}\n")
        log(f"Wrote {len(events)} events to {args.output} + {txt_path}")
    except OSError as e:
        log(f"Failed to write TXT: {e}", "ERR")

    if not events:
        log("No events found (either no data or no events matching filter). "
            "EA will trade normally without news filter.", "WARN")
    else:
        log("Done.")


if __name__ == "__main__":
    main()
