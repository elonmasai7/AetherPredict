from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from email.utils import parsedate_to_datetime
import hashlib
import json
import xml.etree.ElementTree as ET

import httpx

from app.core.config import settings
from app.services.redis_bus import get_cached_json, get_cached_text, set_cached_json, set_cached_text


def _slugify(value: str) -> str:
    return "".join(char.lower() if char.isalnum() else "-" for char in value).strip("-")


@dataclass(slots=True)
class LiveFetchResult:
    data: dict | list | None
    stale: bool = False
    warning: str | None = None


class LiveDataService:
    def __init__(self) -> None:
        self._headers = {
            "User-Agent": "AetherPredict/0.2 (+https://aetherpredict.local)",
            "Accept": "application/json, text/xml, application/rss+xml, application/xml, text/plain",
        }

    def fetch_scoreboard(self) -> LiveFetchResult:
        return self._fetch_json(
            cache_key="live:espn:scoreboard",
            url=settings.espn_scoreboard_url,
            ttl=settings.live_cache_ttl_seconds,
        )

    def fetch_summary(self, game_id: str) -> LiveFetchResult:
        return self._fetch_json(
            cache_key=f"live:espn:summary:{game_id}",
            url="https://site.api.espn.com/apis/site/v2/sports/basketball/nba/summary",
            params={"event": game_id},
            ttl=settings.live_cache_ttl_seconds,
        )

    def fetch_standings(self) -> LiveFetchResult:
        return self._fetch_json(
            cache_key="live:espn:standings",
            url="https://site.api.espn.com/apis/v2/sports/basketball/nba/standings",
            ttl=max(settings.live_cache_ttl_seconds, 300),
        )

    def fetch_news_items(self) -> tuple[list[dict], str | None]:
        urls = [settings.espn_nba_news_rss_url, *settings.sports_rss_urls]
        items: list[dict] = []
        warning: str | None = None
        seen_ids: set[str] = set()

        for index, url in enumerate(urls):
            result = self._fetch_text(
                cache_key=f"live:rss:{index}:{hashlib.sha1(url.encode()).hexdigest()[:12]}",
                url=url,
                ttl=settings.news_cache_ttl_seconds,
            )
            if not result.data:
                warning = result.warning or warning
                continue
            parsed = self._parse_rss_items(str(result.data))
            if not parsed:
                warning = result.warning or warning
                continue
            for item in parsed:
                if item["id"] in seen_ids:
                    continue
                seen_ids.add(item["id"])
                items.append(item)

        items.sort(key=lambda item: item["published_at"], reverse=True)
        return items, warning

    def _fetch_json(
        self,
        *,
        cache_key: str,
        url: str,
        ttl: int,
        params: dict | None = None,
    ) -> LiveFetchResult:
        cached = get_cached_json(cache_key)
        try:
            with httpx.Client(timeout=4, follow_redirects=True, headers=self._headers) as client:
                response = client.get(url, params=params)
                response.raise_for_status()
                payload = response.json()
            set_cached_json(cache_key, payload, ttl)
            return LiveFetchResult(data=payload)
        except Exception as error:
            if cached is not None:
                return LiveFetchResult(
                    data=cached,
                    stale=True,
                    warning=f"Live provider unavailable; using cached data ({error}).",
                )
            return LiveFetchResult(data=None, warning=f"No live data available ({error}).")

    def _fetch_text(
        self,
        *,
        cache_key: str,
        url: str,
        ttl: int,
    ) -> LiveFetchResult:
        cached = get_cached_text(cache_key)
        try:
            with httpx.Client(timeout=4, follow_redirects=True, headers=self._headers) as client:
                response = client.get(url)
                response.raise_for_status()
                payload = response.text
            set_cached_text(cache_key, payload, ttl)
            return LiveFetchResult(data=payload)
        except Exception as error:
            if cached is not None:
                return LiveFetchResult(
                    data=cached,
                    stale=True,
                    warning=f"Live feed unavailable; using cached data ({error}).",
                )
            return LiveFetchResult(data=None, warning=f"No live data available ({error}).")

    def _parse_rss_items(self, xml_text: str) -> list[dict]:
        try:
            root = ET.fromstring(xml_text)
        except ET.ParseError:
            return []

        parsed: list[dict] = []
        for item in root.findall(".//item"):
            title = (item.findtext("title") or "").strip()
            link = (item.findtext("link") or "").strip()
            description = (item.findtext("description") or "").strip()
            pub_date = (item.findtext("pubDate") or "").strip()
            if not title or not link:
                continue
            published_at = self._parse_timestamp(pub_date)
            parsed.append(
                {
                    "id": _slugify(link or title),
                    "title": title,
                    "summary": description or title,
                    "source": self._source_name(link),
                    "url": link,
                    "published_at": published_at,
                }
            )
        return parsed

    def _parse_timestamp(self, value: str) -> datetime:
        if not value:
            return datetime.now(UTC)
        try:
            parsed = parsedate_to_datetime(value)
            return parsed.astimezone(UTC) if parsed.tzinfo else parsed.replace(tzinfo=UTC)
        except Exception:
            return datetime.now(UTC)

    def _source_name(self, url: str) -> str:
        lowered = url.lower()
        if "espn" in lowered:
            return "ESPN"
        if "nba.com" in lowered:
            return "NBA"
        return "Sports Feed"
