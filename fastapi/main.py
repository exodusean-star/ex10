from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from fastapi.routing import APIRouter
import pymysql
import os

app = FastAPI()
templates = Jinja2Templates(directory="templates")

board_router = APIRouter(prefix="/board")
guestbook_router = APIRouter(prefix="/guestbook")


def get_db():
    return pymysql.connect(
        host=os.environ.get("DB_HOST"),
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        database=os.environ.get("DB_NAME"),
        charset="utf8mb4",
        cursorclass=pymysql.cursors.DictCursor
    )


# ── Board ──────────────────────────────────────────────

@board_router.get("/", response_class=HTMLResponse)
async def board_list(request: Request):
    db = get_db()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT * FROM board ORDER BY created_at DESC")
            posts = cursor.fetchall()
    finally:
        db.close()
    return templates.TemplateResponse(request=request, name="board.html", context={"posts": posts})


@board_router.get("/write", response_class=HTMLResponse)
async def board_write(request: Request):
    return templates.TemplateResponse(request=request, name="board_write.html", context={})


@board_router.post("/write")
async def board_write_post(
    title: str = Form(...),
    content: str = Form(...),
    author: str = Form(...)
):
    db = get_db()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                "INSERT INTO board (title, content, author) VALUES (%s, %s, %s)",
                (title, content, author)
            )
        db.commit()
    finally:
        db.close()
    return RedirectResponse(url="/board/", status_code=303)


@board_router.get("/{post_id}", response_class=HTMLResponse)
async def board_detail(request: Request, post_id: int):
    db = get_db()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT * FROM board WHERE id=%s", (post_id,))
            post = cursor.fetchone()
    finally:
        db.close()
    return templates.TemplateResponse(request=request, name="board_detail.html", context={"post": post})


# ── Guestbook ──────────────────────────────────────────

@guestbook_router.get("/", response_class=HTMLResponse)
async def guestbook_list(request: Request):
    db = get_db()
    try:
        with db.cursor() as cursor:
            cursor.execute("SELECT * FROM guestbook ORDER BY created_at DESC")
            entries = cursor.fetchall()
    finally:
        db.close()
    return templates.TemplateResponse(request=request, name="guestbook.html", context={"entries": entries})


@guestbook_router.get("/write", response_class=HTMLResponse)
async def guestbook_write(request: Request):
    return templates.TemplateResponse(request=request, name="guestbook_write.html", context={})


@guestbook_router.post("/write")
async def guestbook_write_post(
    author: str = Form(...),
    message: str = Form(...)
):
    db = get_db()
    try:
        with db.cursor() as cursor:
            cursor.execute(
                "INSERT INTO guestbook (author, message) VALUES (%s, %s)",
                (author, message)
            )
        db.commit()
    finally:
        db.close()
    return RedirectResponse(url="/guestbook/", status_code=303)


# ── Health ─────────────────────────────────────────────

@app.get("/health")
async def health():
    return {"status": "ok"}


app.include_router(board_router)
app.include_router(guestbook_router)
