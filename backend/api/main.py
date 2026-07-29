import os
import shutil
from fastapi import FastAPI, UploadFile, File, BackgroundTasks, HTTPException
from fastapi.responses import FileResponse
from typing import List, Dict, Any

from .job_manager import JobManager

app = FastAPI(title="Rivox Backend API")

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VIDEOS_DIR = os.path.join(BASE_DIR, "videos")
MAPS_DIR = os.path.join(BASE_DIR, "maps")
OUTPUTS_DIR = os.path.join(BASE_DIR, "outputs")

os.makedirs(VIDEOS_DIR, exist_ok=True)
os.makedirs(MAPS_DIR, exist_ok=True)
os.makedirs(OUTPUTS_DIR, exist_ok=True)

job_manager = JobManager(os.path.join(BASE_DIR, "jobs.json"))

@app.post("/api/upload-video")
async def upload_video(file: UploadFile = File(...)):
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")
    file_path = os.path.join(VIDEOS_DIR, file.filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    return {"message": "Video uploaded successfully", "filename": file.filename}

@app.post("/api/reconstruct")
async def reconstruct(video_filename: str, background_tasks: BackgroundTasks):
    video_path = os.path.join(VIDEOS_DIR, video_filename)
    if not os.path.exists(video_path):
        raise HTTPException(status_code=404, detail="Video not found")
    
    job_id = job_manager.create_job("reconstruct", {"video_filename": video_filename})
    background_tasks.add_task(job_manager.run_reconstruct_job, job_id, video_path, OUTPUTS_DIR)
    
    return {"message": "Reconstruction started", "job_id": job_id}

@app.post("/api/merge")
async def merge(source_map: str, target_map: str, output_name: str, background_tasks: BackgroundTasks):
    job_id = job_manager.create_job("merge", {"source": source_map, "target": target_map})
    background_tasks.add_task(job_manager.run_merge_job, job_id, source_map, target_map, output_name, OUTPUTS_DIR)
    return {"message": "Merge started", "job_id": job_id}

@app.post("/api/export-package")
async def export_package(map_name: str, background_tasks: BackgroundTasks):
    job_id = job_manager.create_job("export", {"map_name": map_name})
    background_tasks.add_task(job_manager.run_export_job, job_id, map_name, MAPS_DIR, OUTPUTS_DIR)
    return {"message": "Export started", "job_id": job_id}

@app.get("/api/packages")
async def list_packages() -> List[str]:
    return [f for f in os.listdir(MAPS_DIR) if f.endswith(".zip")]

@app.get("/api/packages/{package_id}/download")
async def download_package(package_id: str):
    package_path = os.path.join(MAPS_DIR, f"{package_id}.zip")
    if not os.path.exists(package_path):
        raise HTTPException(status_code=404, detail="Package not found")
    return FileResponse(package_path, media_type="application/zip", filename=f"{package_id}.zip")

@app.get("/api/status/{job_id}")
async def job_status(job_id: str) -> Dict[str, Any]:
    status = job_manager.get_job_status(job_id)
    if not status:
        raise HTTPException(status_code=404, detail="Job not found")
    return status

@app.get("/api/videos")
async def list_videos() -> List[str]:
    return os.listdir(VIDEOS_DIR)

@app.delete("/api/videos/{video_id}")
async def delete_video(video_id: str):
    video_path = os.path.join(VIDEOS_DIR, video_id)
    if not os.path.exists(video_path):
        raise HTTPException(status_code=404, detail="Video not found")
    os.remove(video_path)
    return {"message": "Video deleted"}
