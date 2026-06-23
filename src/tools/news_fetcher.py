#!/usr/bin/env python3
"""
Apex Grid EA — ForexFactory News Fetcher
=========================================
Fetches economic calendar data from nfs.faireconomy.media (Fair Economy, Inc.)
and writes a JSON cache + pipe-delimited text file for the Apex Grid EA.

USAGE:
    python news_fetcher.py [--output PATH] [--currencies USD,EUR,GBP] [--log PATH]

OUTPUT:
    news_cache.json  — JSON (human-readable / debug)
    news_cache.txt   — Pipe-delimited for MQL4 (datetime|currency|impact)

FAIL-OPEN:
    If fetch fails or returns empty, files are still written with 0 events.
    The EA will detect this and trade normally without news filter.

SETUP:
    pip install requests

BUILD EXE (for servers without Python):
    pip install pyinstaller
    pyinstaller news_fetcher.spec
"""

import argparse
import json
import sys
from datetime import datetime, timedelta
from typing import Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DEFAULT_OUTPUT = "news_cache.json"
DEFAULT_CURRENCIES = ["USD", "EUR", "GBP", "CHF", "CAD", "AUD", "NZD", "JPY"]
LOG_FILE = "news_fetcher.log"
API_URL = "https://nfs.faireconomy.media/ff_calendar_thisweek.json"


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
# Data Fetching
# ---------------------------------------------------------------------------
def fetch_calendar() -> list:
    """Fetch and parse the Forexfactory calendar JSON. Returns list of events."""
    import requests

    log(f"Fetching {API_URL} ...")
    resp = requests.get(API_URL, timeout=30, headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    })

    if resp.status_code != 200:
        log(f"HTTP {resp.status_code}", "WARN")
        return []

    data = resp.json()
    events = _parse_events(data)

    if events:
        log(f"OK: {len(events)} events", "OK")
    else:
        log("0 events in range (all past or too far future)", "WARN")

    return events


def _parse_events(data: list) -> list:
    """Parse the faireconomy JSON into our standard event format."""
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
            except (ValueError, OSError):
                try:
                    dt_utc = datetime.strptime(date_str, "%Y-%m-%d %H:%M:%S")
                except ValueError:
                    try:
                        dt_utc = datetime.strptime(date_str, "%Y-%m-%d")
                    except ValueError:
                        continue

            # Skip past events (>1h old) and events beyond 2 days
            if dt_utc < now - timedelta(hours=1) or dt_utc > cutoff:
                continue

            currency = _country_to_currency(country)
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
# Helpers
# ---------------------------------------------------------------------------
def _country_to_currency(country: str) -> str:
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
    impact = impact.strip().lower()
    if impact in ("high", "3", "red"):
        return "High"
    if impact in ("medium", "2", "orange"):
        return "Medium"
    return "Low"


def filter_events(events: list, currencies: list) -> list:
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
    parser.add_argument("--output", default=DEFAULT_OUTPUT)
    parser.add_argument("--currencies", default=",".join(DEFAULT_CURRENCIES))
    parser.add_argument("--log", default=LOG_FILE)
    args = parser.parse_args()

    LOG_FILE = args.log

    currencies = [c.strip().upper() for c in args.currencies.split(",") if c.strip()]

    log("Apex Grid News Fetcher started")
    log(f"  output={args.output}  currencies={currencies}")

    events = fetch_calendar()
    events = filter_events(events, currencies)
    events.sort(key=lambda e: e["datetime"])

    result = {
        "fetched_at": datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S"),
        "source": "nfs.faireconomy.media",
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

    # Write pipe-delimited text file for MQL4
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
        log("No events found. EA will trade normally without news filter.", "WARN")
    else:
        log("Done.")


if __name__ == "__main__":
    main()
