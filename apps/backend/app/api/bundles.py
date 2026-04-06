from collections import defaultdict

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Market
from app.schemas.bundle import BundleResponse

router = APIRouter(prefix="/bundles", tags=["bundles"])


@router.get("", response_model=list[BundleResponse])
def bundles(db: Session = Depends(get_db)) -> list[BundleResponse]:
    markets = db.scalars(select(Market).order_by(Market.volume.desc())).all()
    grouped: dict[str, list[Market]] = defaultdict(list)
    for market in markets:
        grouped[market.category].append(market)

    results: list[BundleResponse] = []
    for category, items in grouped.items():
        total_confidence = sum(item.ai_confidence for item in items)
        target_return = (total_confidence / max(len(items), 1)) * 20
        results.append(
            BundleResponse(
                id=category.lower().replace(" ", "-"),
                name=f"{category} Bundle",
                description=f"Top live {category.lower()} prediction markets.",
                theme=category,
                markets=[item.slug for item in items[:5]],
                target_return=round(target_return, 2),
                risk_level="HIGH" if target_return > 14 else "MEDIUM" if target_return > 8 else "LOW",
            )
        )
    return results
