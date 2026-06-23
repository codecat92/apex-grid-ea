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

# Timezone: Forexfactory uses US Eastern (EST/EDT)
# Events are displayed in ET. We convert to UTC for MQL4 consumption.
# ET = UTC-5 (EST) / UTC-4 (EDT). We use a simple offset approach.
US_EASTERN_OFFSET = -5  # EST default; -4 during EDT (Mar-Nov roughly)


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

            # Parse date
            try:
                dt = datetime.strptime(date_str, "%Y-%m-%dT%H:%M:%S%z")
            except ValueError:
                try:
                    dt = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
                except ValueError:
                    try:
                        dt = datetime.strptime(date_str, "%Y-%m-%d")
                    except ValueError:
                        continue

            # Skip past events older than 1 hour and events beyond 2 days
            if dt < now - timedelta(hours=1) or dt > cutoff:
                continue

            # Map country code to currency
            currency = _country_to_currency(country)

            # Normalize impact
            impact = _normalize_impact(impact)

            events.append({
                "datetime": dt.strftime("%Y-%m-%dT%H:%M:%SZ"),
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

    events = []
    now = datetime.utcnow()
    cutoff = now + timedelta(days=2)

    soup = BeautifulSoup(html, "html.parser")

    # FF calendar rows are in a table with class "calendar__table"
    table = soup.find("table", class_="calendar__table")
    if not table:
        log("Could not find calendar table in HTML", "WARN")
        return events

    rows = table.find_all("tr", class_="calendar__row")
    for row in rows:
        try:
            # Get time
            time_cell = row.find("td", class_="calendar__time")
            if not time_cell:
                continue
            time_str = time_cell.get_text(strip=True)

            # Get currency
            currency_cell = row.find("td", class_="calendar__currency")
            if not currency_cell:
                continue
            currency = currency_cell.get_text(strip=True).upper()

            # Get event name
            event_cell = row.find("td", class_="calendar__event")
            if not event_cell:
                continue
            name = event_cell.get_text(strip=True)

            # Get impact
            impact_cell = row.find("td", class_="calendar__impact")
            impact = "Low"
            if impact_cell:
                impact_spans = impact_cell.find_all("span", class_="impact")
                filled = len([s for s in impact_spans
                              if "impact--fill" in s.get("class", [])])
                if filled >= 3:
                    impact = "High"
                elif filled >= 2:
                    impact = "Medium"

            # Build datetime
            # FF times are in ET. We need the date (the row belongs to a day
            # section). Find the parent day section.
            date_str = _find_row_date(row)
            if not date_str:
                continue

            # Combine date + time, convert ET -> UTC
            dt_str = f"{date_str} {time_str}"
            try:
                dt_local = datetime.strptime(dt_str, "%Y-%m-%d %I:%M%p")
            except ValueError:
                try:
                    dt_local = datetime.strptime(dt_str, "%Y-%m-%d %H:%M")
                except ValueError:
                    continue

            dt_utc = dt_local - timedelta(hours=US_EASTERN_OFFSET)

            if dt_utc < now - timedelta(hours=1) or dt_utc > cutoff:
                continue

            events.append({
                "datetime": dt_utc.strftime("%Y-%m-%dT%H:%M:%SZ"),
                "currency": currency,
                "event_name": name,
                "impact": _normalize_impact(impact),
            })
        except Exception:
            continue

    return events


def _find_row_date(row) -> Optional[str]:
    """Walk up the DOM to find the day-header's date."""
    from bs4 import BeautifulSoup

    current = row.parent if hasattr(row, 'parent') else row
    for _ in range(10):
        if current is None:
            return None
        if hasattr(current, 'find_previous'):
            header = current.find_previous("tr", class_="calendar__day-header")
            if header:
                date_span = header.find("span", class_="date")
                if date_span:
                    return date_span.get_text(strip=True)
        current = getattr(current, 'parent', None)
    return None


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
    if not currencies:
        return events
    allowed = [c.upper() for c in currencies]
    return [e for e in events if e["currency"].upper() in allowed]


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="Apex Grid News Fetcher")
    parser.add_argument("--output", default=DEFAULT_OUTPUT,
                        help="Output JSON file path")
    parser.add_argument("--currencies", default=",".join(DEFAULT_CURRENCIES),
                        help="Comma-separated list of currency codes to filter")
    parser.add_argument("--log", default=LOG_FILE,
                        help="Log file path")
    args = parser.parse_args()

    global LOG_FILE
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
