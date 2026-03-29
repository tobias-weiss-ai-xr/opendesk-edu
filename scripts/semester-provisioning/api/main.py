# SPDX-FileCopyrightText: 2024 Zentrum für Digitale Souveränität der öffentlichen Verwaltung (ZenDiS) GmbH
# SPDX-FileCopyrightText: 2024 Bundesministerium des Innern und für Heimat, PG ZenDiS "Projektgruppe für Aufbau ZenDiS"
# SPDX-License-Identifier: Apache-2.0
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from api.config.settings import get_settings
from api.routes import courses, semesters, enrollments, archival

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield
    pass


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.api_title,
        version=settings.api_version,
        description="REST API for semester-based course provisioning in openDesk Edu",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(courses.router)
    app.include_router(semesters.router)
    app.include_router(enrollments.router)
    app.include_router(archival.router)

    @app.get("/health", tags=["health"])
    async def health_check() -> dict:
        return {"status": "healthy"}

    @app.get("/ready", tags=["health"])
    async def readiness_check() -> dict:
        return {"status": "ready"}

    return app


app = create_app()
