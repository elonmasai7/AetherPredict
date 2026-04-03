from fastapi import APIRouter

from app.schemas.bundle import BundleResponse
from app.services.platform_data import sample_bundles

router = APIRouter(prefix="/bundles", tags=["bundles"])


@router.get("", response_model=list[BundleResponse])
def bundles() -> list[BundleResponse]:
    return [BundleResponse(**item) for item in sample_bundles()]
