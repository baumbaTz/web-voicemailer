untested as of 2024-12-26 4pm CET :)

# Voicemail Recording and Transcription System

This project provides a complete solution for recording, uploading, and transcribing audio voicemails. It features a user-friendly interface for recording messages and an admin panel for managing and transcribing voicemails on-demand using the lightweight and efficient `whisper.cpp` transcription tool.

---

## Features

### User-Side Features
- **Record Audio**: Users can record audio directly in their browser using the MediaRecorder API.
- **Playback**: Users can listen to their recordings before submitting.
- **Submit Voicemails**: Audio files are uploaded to the server with metadata, including the user's name and recording timestamp.

### Admin-Side Features
- **View Voicemails**: Displays a list of recorded voicemails, including details like name, duration, timestamp, and transcription status.
- **On-Demand Transcription**: Admins can transcribe audio files using `whisper.cpp` models on the server.
- **Transcription Storage**: Transcriptions are stored in a database for later review.

### Backend
- **Flask API**: Handles file uploads, transcription requests, and database interactions.
- **Whisper.cpp Integration**: Lightweight CPU-based transcription for efficient operation.
- **SQLite Database**: Stores metadata and transcription results.

### Flexible Transcription Models
- Supports various Whisper models, such as `base`, `medium`, and `large`. The model can be easily switched by changing a single variable in the backend.

---

## Setup

### Prerequisites
1. **Operating System**: Linux or macOS recommended (bash-compatible shell required).
2. **Dependencies**:
   - Python 3.x
   - SQLite
   - FFmpeg
   - GCC or similar C compiler

### Installation
1. Clone the repository and navigate to the project folder:
   ```bash
   git clone <repository-url>
   cd voicemail_project
   ```

2. Run the setup script to install dependencies, configure the environment, and download required models:
   ```bash
   bash setup.sh
   ```

3. Start the server:
   ```bash
   source venv/bin/activate
   python server.py
   ```

4. Open the user interface in a browser to test recording functionality or access the admin panel for managing voicemails.

---

## API Endpoints

### 1. **Upload Voicemail**
- **Endpoint**: `/upload`
- **Method**: POST
- **Parameters**:
  - `name` (string): Name of the user.
  - `audio` (file): Audio file in `.webm` format.
- **Response**:
  - `200 OK`: Voicemail uploaded successfully.
  - `400 Bad Request`: Missing parameters or invalid audio file.

### 2. **List Voicemails**
- **Endpoint**: `/list-voicemails`
- **Method**: GET
- **Response**:
  - JSON array of voicemails with metadata (name, filename, duration, timestamp, played status, transcription).

### 3. **Transcribe Voicemail**
- **Endpoint**: `/transcribe/<voicemail_id>`
- **Method**: POST
- **Response**:
  - `200 OK`: Transcription completed.
  - `404 Not Found`: Voicemail or audio file not found.
  - `500 Internal Server Error`: Transcription failed.

---

## File Structure

```
voicemail_project/
├── uploads/                # Directory for uploaded audio files
├── whisper.cpp/            # Whisper.cpp repository
│   ├── main                # Executable after build
│   ├── models/             # Whisper models (base, medium, large)
├── server.py               # Flask backend for the project
├── schema.sql              # Database schema for SQLite
├── setup.sh                # Bash script for setting up the project
├── voicemail.html          # User-facing recording interface
└── admin.html              # Admin panel for managing voicemails
```

---

## Configuration

### Changing the Transcription Model
To switch between Whisper models, update the `MODEL_PATH` variable in `server.py`:
```python
MODEL_PATH = "whisper.cpp/models/ggml-medium.en.bin"
```
Supported models:
- `ggml-base.en.bin`
- `ggml-medium.en.bin`
- `ggml-large-v2.bin`

### Adjusting Limits
You can modify the duration limits for audio recordings in `server.py`:
```python
if duration < 10 or duration > 300:  # 10 seconds to 5 minutes
```

---

## Future Enhancements
- **Auto-Transcription**: Optionally enable automatic transcription for new voicemails.
- **Email Notifications**: Notify admins when new voicemails are uploaded.
- **Improved Security**: Add CAPTCHA or rate limiting for uploads.

---

## License
This project is licensed under the MIT License. See `LICENSE` for more details.

---

## Acknowledgments
- [Whisper.cpp](https://github.com/ggerganov/whisper.cpp): C-based implementation of OpenAI's Whisper model.
- [Flask](https://flask.palletsprojects.com/): Python web framework.
- [MediaRecorder API](https://developer.mozilla.org/en-US/docs/Web/API/MediaRecorder): Client-side audio recording.

