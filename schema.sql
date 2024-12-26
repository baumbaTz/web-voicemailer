CREATE TABLE IF NOT EXISTS voicemails (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    filename TEXT NOT NULL,
    duration REAL NOT NULL,
    timestamp TEXT NOT NULL,
    played BOOLEAN DEFAULT 0,
    transcription TEXT DEFAULT NULL
);
