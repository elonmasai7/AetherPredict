from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.db.session import get_db
from app.models.entities import Workspace
from app.schemas.workspace import WorkspaceRequest, WorkspaceResponse
from app.services.auth_service import get_current_user

router = APIRouter(prefix="/workspaces", tags=["workspaces"])


@router.get("", response_model=list[WorkspaceResponse])
def list_workspaces(db: Session = Depends(get_db), user=Depends(get_current_user)) -> list[WorkspaceResponse]:
    rows = db.scalars(select(Workspace).where(Workspace.user_id == user.id).order_by(Workspace.updated_at.desc())).all()
    return [WorkspaceResponse.model_validate(item, from_attributes=True) for item in rows]


@router.post("", response_model=WorkspaceResponse, status_code=201)
def save_workspace(payload: WorkspaceRequest, db: Session = Depends(get_db), user=Depends(get_current_user)) -> WorkspaceResponse:
    workspace = Workspace(
        user_id=user.id,
        name=payload.name,
        layout_json=payload.layout_json,
        notes_json=payload.notes_json,
        chart_preferences=payload.chart_preferences,
    )
    db.add(workspace)
    db.commit()
    db.refresh(workspace)
    return WorkspaceResponse.model_validate(workspace, from_attributes=True)
