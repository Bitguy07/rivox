# 🧭 Rivox — Offline Campus Navigation

Rivox is a privacy-first, offline indoor navigation app for campus buildings. It uses 3D reconstruction from video (via [LingBot-Map](https://github.com/Robbyant/lingbot-map)), visual localization from photos, and IMU-based dead reckoning to navigate users through mapped buildings — **without GPS, without internet, without cloud services**.

> **Note:** This is an admin/developer tool for creating and testing campus maps. End users will only have the navigation features; the recording and map-building pipeline is for map creators.

---

## 📋 Table of Contents

- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Project Setup (Flutter App)](#project-setup-flutter-app)
- [Building the App](#building-the-app)
- [Backend Setup (Docker)](#backend-setup-docker)
- [Full Workflow: Record → Reconstruct → Navigate](#full-workflow-record--reconstruct--navigate)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)

---

## 🔄 How It Works

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  📱 Record  │────▶│ 🖥️ Backend   │────▶│ 📱 Navigate     │
│  Video on   │     │ (Docker)     │     │ Import map,     │
│  Phone App  │     │ Reconstruct  │     │ take photo to   │
│             │     │ + Merge +    │     │ localize, get   │
│             │     │ Export .zip  │     │ turn-by-turn    │
└─────────────┘     └──────────────┘     └─────────────────┘
```

1. **Record**: Walk through campus corridors recording video with the app
2. **Upload**: Transfer video to your lab computer running the Docker backend
3. **Reconstruct**: Backend creates a 3D point cloud using LingBot-Map
4. **Export**: Backend packages everything into a `.zip` map package
5. **Import**: Transfer the `.zip` to your phone, import it in the app
6. **Navigate**: Take a photo to localize yourself, then get turn-by-turn directions

---

## ✅ Prerequisites

### For the Flutter App (Mobile)

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| **Flutter SDK** | ≥ 3.22.0 | `flutter --version` |
| **Dart SDK** | ≥ 3.4.0 | `dart --version` |
| **Android SDK** | API 24+ (Android 7.0+) | `flutter doctor` |
| **Java JDK** | 17 | `java --version` |
| **Git** | Any | `git --version` |

### For the Backend (Lab Computer)

| Requirement | Version | Check Command |
|-------------|---------|---------------|
| **Docker Desktop** | Latest | `docker --version` |
| **Docker Compose** | v2+ | `docker compose version` |
| **Python** *(optional, for running scripts directly)* | 3.10+ | `python3 --version` |
| **NVIDIA GPU + CUDA** *(optional, for faster reconstruction)* | CUDA 11.8+ | `nvidia-smi` |

### Android Phone

- Android 7.0 (API 24) or higher
- Camera (for localization photos and video recording)
- Accelerometer + Gyroscope + Magnetometer (for IMU tracking)
- USB Debugging enabled (for installing the app)

---

## 📱 Project Setup (Flutter App)

### 1. Clone the repository

```bash
git clone https://github.com/Bitguy07/rivox.git
cd rivox
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Verify everything is set up

```bash
flutter doctor
```

Make sure you see ✅ for Flutter, Android toolchain, and Connected device (or Android Studio).

### 4. Verify the code compiles

```bash
flutter analyze
```

You should see: `No issues found!`

---

## 🔨 Building the App

### Option A: Debug APK (for testing)

Connect your phone via USB with USB debugging enabled, then:

```bash
flutter run
```

Or build the APK without a connected device:

```bash
flutter build apk --debug
```

The APK will be at: `build/app/outputs/flutter-apk/app-debug.apk`

### Option B: Release APK (optimized, smaller)

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

### Install on Phone

Transfer the APK to your phone and install it. Or with USB connected:

```bash
flutter install
```

---

## 🐳 Backend Setup (Docker)

The backend runs on your lab computer (Windows with Docker Desktop, or Linux).

### 1. Navigate to the backend directory

```bash
cd backend
```

### 2. Build and start the containers

**CPU only (works on any machine):**

```bash
docker compose up --build
```

**With NVIDIA GPU (much faster reconstruction):**

```bash
docker compose --profile gpu up --build
```

### 3. Verify the server is running

Open in browser or curl:

```
http://localhost:8000/docs
```

You should see the FastAPI Swagger UI with all available endpoints.

### 4. Stop the backend

```bash
docker compose down
```

---

## 🗺️ Full Workflow: Record → Reconstruct → Navigate

### Step 1: Record Campus Video 🎥

1. Open the Rivox app on your phone
2. Go to **Settings** → Enable **Admin Mode**
3. Go to **Record Video** (from Home screen or Settings)
4. Walk slowly through corridors and rooms
5. **Tips for good recordings:**
   - Walk at a steady, slow pace (~0.5 m/s)
   - Keep the phone at chest height, pointing forward
   - Cover doorways, corners, and distinctive features
   - Record in well-lit conditions
   - Each recording should be 2-5 minutes

### Step 2: Transfer Video to Lab Computer 💻

Transfer the recorded video from your phone to the lab computer:

```bash
# Via USB (with adb)
adb pull /sdcard/Android/data/com.example.rivox/files/videos/ ./videos/

# Or simply copy via USB file transfer / Bluetooth / network share
```

### Step 3: Upload Video to Backend 📤

```bash
# Upload video file
curl -X POST http://localhost:8000/api/upload-video \
  -F "video=@/path/to/campus_video.mp4"
```

### Step 4: Run 3D Reconstruction 🔧

```bash
# Start reconstruction (runs in background)
curl -X POST http://localhost:8000/api/reconstruct \
  -H "Content-Type: application/json" \
  -d '{"video_id": "campus_video"}'

# Check status
curl http://localhost:8000/api/status/{job_id}
```

Wait until status shows `"completed"`. This can take 10-60 minutes depending on video length and hardware.

### Step 5: Merge Multiple Recordings (Optional) 🔗

If you have multiple video recordings of different areas:

```bash
curl -X POST http://localhost:8000/api/merge \
  -H "Content-Type: application/json" \
  -d '{"recording_ids": ["recording_1", "recording_2"]}'
```

### Step 6: Export Map Package 📦

```bash
# Export as .zip
curl -X POST http://localhost:8000/api/export-package \
  -H "Content-Type: application/json" \
  -d '{"name": "ABESIT Campus", "version": "1.0.0"}'

# Download the .zip
curl -O http://localhost:8000/api/packages/{package_id}/download
```

### Step 7: Import Map to Phone App 📲

1. Transfer the `.zip` file to your phone
2. Open Rivox app → **Settings** → **Manage Maps**
3. Tap **Import Map** → Select the `.zip` file
4. Wait for import to complete
5. The map will appear in the map list — tap to set as active

### Step 8: Navigate! 🧭

1. Go to **3D Map** or **2D Map** to explore the building
2. Tap **Localize** → Point camera at a distinctive area → Take photo
3. The app will match your photo against the keyframe database
4. Once localized, your position appears as an orange dot on the map
5. Go to **Navigate** → Search for a room/destination → **Start Navigation**
6. Follow the turn-by-turn directions!

---

## 📁 Project Structure

```
rivox/
├── lib/                          # Flutter app source code
│   ├── app/                      # App shell, router, theme
│   │   ├── app.dart              # Root MaterialApp
│   │   ├── router/app_router.dart # GoRouter with bottom nav
│   │   └── theme/                # Colors + Material 3 dark theme
│   ├── core/                     # Business logic layer
│   │   ├── models/               # Data models (Pose3D, NavGraph, Keyframe, MapPackage)
│   │   ├── providers/            # Riverpod state management
│   │   ├── services/             # Map storage, navigation, IMU, localization
│   │   └── utils/                # PnP solver, filters, descriptors, step detector
│   ├── features/                 # UI screens
│   │   ├── splash/               # Animated splash screen
│   │   ├── home/                 # Dashboard with feature cards
│   │   ├── map_3d/               # GLB 3D model viewer
│   │   ├── map_2d/               # Custom 2D canvas map
│   │   ├── localize/             # Camera-based localization
│   │   ├── navigation/           # Search + turn-by-turn navigation
│   │   ├── video_capture/        # Campus video recording
│   │   └── settings/             # App settings + map manager
│   └── main.dart                 # Entry point
├── backend/                      # Docker-based reconstruction backend
│   ├── api/                      # FastAPI server
│   │   ├── main.py               # API endpoints
│   │   └── job_manager.py        # Background job queue
│   ├── scripts/                  # Processing pipeline
│   │   ├── reconstruct.py        # LingBot-Map wrapper
│   │   ├── merge_pointclouds.py  # Open3D point cloud merging
│   │   ├── export_map_package.py # Full export pipeline
│   │   ├── build_nav_graph.py    # Point cloud → navigation graph
│   │   ├── build_keyframe_db.py  # Keyframe extraction + descriptors
│   │   └── build_floor_plan.py   # Wall/room detection
│   ├── Dockerfile                # CPU container
│   ├── Dockerfile.gpu            # GPU container (CUDA)
│   ├── docker-compose.yml        # Service orchestration
│   └── requirements.txt          # Python dependencies
├── android/                      # Android platform config
├── ios/                          # iOS platform config
├── pubspec.yaml                  # Flutter dependencies
└── README.md                     # This file
```

---

## 🛠️ Tech Stack

### Mobile App
- **Flutter** — Cross-platform UI framework
- **Riverpod** — State management
- **GoRouter** — Declarative routing with bottom navigation
- **model_viewer_plus** — 3D GLB model rendering
- **camera** — Photo capture for visual localization
- **sensors_plus** — Accelerometer, gyroscope, magnetometer for PDR
- **hive** — Local key-value storage
- **archive** — ZIP extraction for map packages

### Backend
- **FastAPI** — Python REST API server
- **Docker** — Containerized deployment
- **LingBot-Map** — Monocular 3D reconstruction from video
- **Open3D** — Point cloud processing and registration
- **Trimesh** — PLY to GLB mesh conversion
- **OpenCV** — Image processing for keyframe extraction
- **NumPy/SciPy** — Scientific computing

### Navigation Algorithms
- **A\* / Dijkstra** — Shortest path on navigation graph
- **Pedestrian Dead Reckoning (PDR)** — Step detection + heading estimation
- **Visual Localization** — Color histogram matching + PnP pose estimation
- **Complementary Filter** — Gyroscope + magnetometer fusion for heading
- **Kalman Filter** — Noise reduction on sensor data

---

## 📄 License

This project is for educational and research purposes.

---

## 🤝 Contributing

This is a personal project. Feel free to fork and adapt for your own campus!
