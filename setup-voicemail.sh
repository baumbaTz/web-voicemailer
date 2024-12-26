#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define project directory
PROJECT_DIR="voicemail_project"

# Create project structure
mkdir -p "$PROJECT_DIR/uploads"
cd "$PROJECT_DIR"

# Install system dependencies
echo "Installing system dependencies..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv sqlite3 ffmpeg build-essential git

# Set up Python virtual environment
echo "Setting up Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "Installing Python dependencies..."
pip install flask flask-sqlalchemy

# Clone whisper.cpp
echo "Cloning whisper.cpp repository..."
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
make
cd ..

# Download whisper models
echo "Downloading Whisper models..."
cd whisper.cpp/models
./download-ggml-model.sh base.en
./download-ggml-model.sh medium.en
cd ../..

# Set up SQLite database
echo "Setting up SQLite database..."
cat > schema.sql <<EOF
CREATE TABLE IF NOT EXISTS voicemails (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    filename TEXT NOT NULL,
    duration REAL NOT NULL,
    timestamp TEXT NOT NULL,
    played BOOLEAN DEFAULT 0,
    transcription TEXT DEFAULT NULL
);
EOF
sqlite3 voicemails.db < schema.sql

# Create server.py
echo "Creating Flask backend (server.py)..."
cat > server.py <<'EOF'
import subprocess
from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///voicemails.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db = SQLAlchemy(app)

class Voicemail(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False)
    filename = db.Column(db.String(255), nullable=False)
    duration = db.Column(db.Float, nullable=False)
    timestamp = db.Column(db.String(255), nullable=False)
    played = db.Column(db.Boolean, default=False)
    transcription = db.Column(db.Text, default=None)

db.create_all()

# Global configuration for the model path
MODEL_PATH = "whisper.cpp/models/ggml-base.en.bin"

@app.route("/upload", methods=["POST"])
def upload_voicemail():
    if "audio" not in request.files or not request.form.get("name"):
        return jsonify({"error": "Missing audio file or name"}), 400

    audio_file = request.files["audio"]
    name = request.form["name"].strip()
    timestamp = request.form.get("timestamp", "")
    duration = float(request.form.get("duration", 0))

    if duration < 10 or duration > 300:
        return jsonify({"error": "Audio duration out of range"}), 400

    filename = f"{timestamp}_{name.replace(' ', '_')}.webm"
    save_path = os.path.join("uploads", filename)
    audio_file.save(save_path)

    voicemail = Voicemail(
        name=name,
        filename=filename,
        duration=duration,
        timestamp=timestamp,
        played=False,
    )
    db.session.add(voicemail)
    db.session.commit()

    return jsonify({"message": "Voicemail uploaded successfully"}), 200

@app.route("/transcribe/<int:voicemail_id>", methods=["POST"])
def transcribe_voicemail(voicemail_id):
    voicemail = Voicemail.query.get(voicemail_id)
    if not voicemail:
        return jsonify({"error": "Voicemail not found"}), 404

    audio_path = os.path.join("uploads", voicemail.filename)
    if not os.path.exists(audio_path):
        return jsonify({"error": "Audio file not found"}), 404

    try:
        result = subprocess.check_output(
            f"./whisper.cpp/main -m {MODEL_PATH} -f {audio_path} -otxt",
            shell=True,
        )
        transcription_file = audio_path + ".txt"

        if os.path.exists(transcription_file):
            with open(transcription_file, "r") as f:
                transcription = f.read()
            os.remove(transcription_file)
        else:
            return jsonify({"error": "Transcription failed"}), 500

        voicemail.transcription = transcription
        db.session.commit()

        return jsonify({"message": "Transcription completed", "transcription": transcription}), 200
    except subprocess.CalledProcessError as e:
        return jsonify({"error": f"Transcription failed: {str(e)}"}), 500

@app.route("/list-voicemails", methods=["GET"])
def list_voicemails():
    voicemails = Voicemail.query.all()
    return jsonify([
        {
            "id": vm.id,
            "name": vm.name,
            "filename": vm.filename,
            "duration": vm.duration,
            "timestamp": vm.timestamp,
            "played": vm.played,
            "transcription": vm.transcription,
        }
        for vm in voicemails
    ])

if __name__ == "__main__":
    os.makedirs("uploads", exist_ok=True)
    print(f"Using model: {MODEL_PATH}")
    app.run(host="0.0.0.0", port=5000, debug=True)
EOF

# Final instructions
echo "Setup complete!"
echo "To run the server, use the following commands:"
echo "source venv/bin/activate"
echo "python server.py"
echo "You can now test the API on http://localhost:5000"
