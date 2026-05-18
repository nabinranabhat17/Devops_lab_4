"""
Task 4b: Backend Flask REST API
Endpoints:
  GET  /api/notes       — list all notes
  POST /api/notes       — create a new note  { "title": "...", "content": "..." }
  GET  /api/health      — health check
"""

import os
import time
import pymysql
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)  # Allow requests from the frontend container

# ── Database configuration (values come from Docker Compose env vars) ──────────
DB_HOST     = os.getenv("DB_HOST",     "db")
DB_PORT     = int(os.getenv("DB_PORT", "3306"))
DB_USER     = os.getenv("DB_USER",     "lab2user")
DB_PASSWORD = os.getenv("DB_PASSWORD", "lab2pass")
DB_NAME     = os.getenv("DB_NAME",     "lab2db")


def get_connection():
    """Return a new database connection."""
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        cursorclass=pymysql.cursors.DictCursor,
    )


def wait_for_db(retries: int = 10, delay: int = 3):
    """Retry connecting to the database until it is ready."""
    for attempt in range(1, retries + 1):
        try:
            conn = get_connection()
            conn.close()
            print(f"[DB] Connected on attempt {attempt}")
            return
        except Exception as exc:
            print(f"[DB] Attempt {attempt}/{retries} failed: {exc}. Retrying in {delay}s…")
            time.sleep(delay)
    raise RuntimeError("Could not connect to the database after multiple retries.")


# ── Routes ─────────────────────────────────────────────────────────────────────

@app.route("/api/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "service": "backend"})


@app.route("/api/notes", methods=["GET"])
def get_notes():
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, title, content, created_at FROM notes ORDER BY created_at DESC")
            notes = cursor.fetchall()
        # Convert datetime objects to strings for JSON serialisation
        for note in notes:
            if note.get("created_at"):
                note["created_at"] = str(note["created_at"])
        return jsonify(notes)
    finally:
        conn.close()


@app.route("/api/notes", methods=["POST"])
def create_note():
    data = request.get_json(force=True)
    title   = (data.get("title")   or "").strip()
    content = (data.get("content") or "").strip()

    if not title or not content:
        return jsonify({"error": "Both 'title' and 'content' are required."}), 400

    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO notes (title, content) VALUES (%s, %s)",
                (title, content),
            )
            conn.commit()
            new_id = cursor.lastrowid
        return jsonify({"id": new_id, "title": title, "content": content}), 201
    finally:
        conn.close()


# ── Entry point ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    wait_for_db()
    app.run(host="0.0.0.0", port=5000, debug=False)
