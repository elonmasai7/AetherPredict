from pydantic import BaseModel


class BundleResponse(BaseModel):
    id: str
    name: str
    description: str
    theme: str
    markets: list[str]
    target_return: float
    risk_level: str
