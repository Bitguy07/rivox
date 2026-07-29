import json
import os
import uuid
import subprocess
from datetime import datetime
from typing import Dict, Any

class JobManager:
    def __init__(self, db_path: str):
        self.db_path = db_path
        if not os.path.exists(self.db_path):
            self._save_jobs({})

    def _load_jobs(self) -> Dict[str, Any]:
        try:
            with open(self.db_path, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return {}

    def _save_jobs(self, jobs: Dict[str, Any]):
        with open(self.db_path, "w") as f:
            json.dump(jobs, f, indent=2)

    def create_job(self, job_type: str, metadata: Dict[str, Any] = None) -> str:
        jobs = self._load_jobs()
        job_id = str(uuid.uuid4())
        jobs[job_id] = {
            "type": job_type,
            "status": "pending",
            "metadata": metadata or {},
            "created_at": datetime.utcnow().isoformat(),
            "updated_at": datetime.utcnow().isoformat()
        }
        self._save_jobs(jobs)
        return job_id

    def update_job_status(self, job_id: str, status: str, error: str = None):
        jobs = self._load_jobs()
        if job_id in jobs:
            jobs[job_id]["status"] = status
            jobs[job_id]["updated_at"] = datetime.utcnow().isoformat()
            if error:
                jobs[job_id]["error"] = error
            self._save_jobs(jobs)

    def get_job_status(self, job_id: str) -> Dict[str, Any]:
        jobs = self._load_jobs()
        return jobs.get(job_id)

    def run_reconstruct_job(self, job_id: str, video_path: str, output_dir: str):
        self.update_job_status(job_id, "running")
        try:
            script_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts", "reconstruct.py")
            subprocess.run(["python", script_path, "--video_path", video_path, "--output_dir", output_dir], check=True)
            self.update_job_status(job_id, "completed")
        except subprocess.CalledProcessError as e:
            self.update_job_status(job_id, "failed", str(e))
        except Exception as e:
            self.update_job_status(job_id, "failed", str(e))

    def run_merge_job(self, job_id: str, source: str, target: str, output: str, output_dir: str):
        self.update_job_status(job_id, "running")
        try:
            script_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts", "merge_pointclouds.py")
            s_path = os.path.join(output_dir, source)
            t_path = os.path.join(output_dir, target)
            o_path = os.path.join(output_dir, output)
            subprocess.run(["python", script_path, "--source", s_path, "--target", t_path, "--output", o_path], check=True)
            self.update_job_status(job_id, "completed")
        except Exception as e:
            self.update_job_status(job_id, "failed", str(e))

    def run_export_job(self, job_id: str, map_name: str, maps_dir: str, outputs_dir: str):
        self.update_job_status(job_id, "running")
        try:
            script_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts", "export_map_package.py")
            map_path = os.path.join(outputs_dir, map_name)
            output_zip = os.path.join(maps_dir, f"{map_name}.zip")
            subprocess.run(["python", script_path, "--input", map_path, "--output", output_zip], check=True)
            self.update_job_status(job_id, "completed")
        except Exception as e:
            self.update_job_status(job_id, "failed", str(e))
