# Rivox Backend

Docker-based backend for the Rivox campus navigation app.
It processes uploaded campus videos, generates 3D maps using LingBot-Map, merges point clouds, and exports packages for the Flutter mobile app.

## Setup

1. **Build CPU Image (Default):**
   ```bash
   docker-compose build api
   ```

2. **Build GPU Image:**
   ```bash
   docker-compose --profile gpu build api-gpu
   ```

3. **Run the server:**
   ```bash
   docker-compose up
   ```

## Workflow & API Endpoints

1. **Upload Video:**
   - `POST /api/upload-video` (multipart/form-data with video file)

2. **Reconstruct:**
   - `POST /api/reconstruct?video_filename=...`
   - Returns a `job_id`.

3. **Check Job Status:**
   - `GET /api/status/{job_id}`

4. **Merge Pointclouds:**
   - `POST /api/merge?source_map=...&target_map=...&output_name=...`
   
5. **Export Package:**
   - `POST /api/export-package?map_name=...`

6. **List & Download Packages:**
   - `GET /api/packages`
   - `GET /api/packages/{package_id}/download`

## File Outputs
- Map packages are exported as `.zip` containing: `metadata.json`, `map.glb`, `nav_graph.json`, `keyframe_db.json`, `floor_plan.json`, and `keyframes/` images.

## Architecture
- `api/main.py`: FastAPI server
- `scripts/`: Processing scripts that run standalone or via API.
