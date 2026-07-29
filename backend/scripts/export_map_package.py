import argparse
import os
import json
import zipfile
import trimesh
from datetime import datetime
import shutil

def export_package(input_dir: str, output_zip: str):
    print(f"Exporting package from {input_dir} to {output_zip}")
    # This is a master script that would call build_nav_graph, build_floor_plan, etc.
    # For now, it orchestrates the process by calling functions or scripts.
    
    temp_dir = os.path.join(input_dir, "export_temp")
    os.makedirs(temp_dir, exist_ok=True)
    
    try:
        # Convert PLY to GLB
        ply_path = os.path.join(input_dir, "points.ply")
        glb_path = os.path.join(temp_dir, "map.glb")
        if os.path.exists(ply_path):
            mesh = trimesh.load(ply_path)
            mesh.export(glb_path, file_type='glb')
        else:
            with open(glb_path, "w") as f: f.write("") # Dummy
        
        # Create Dummy nav_graph, keyframe_db, floor_plan
        nav_graph = {"nodes": [], "edges": []}
        keyframe_db = {"keyframes": []}
        floor_plan = {"layers": {}}
        
        with open(os.path.join(temp_dir, "nav_graph.json"), "w") as f: json.dump(nav_graph, f)
        with open(os.path.join(temp_dir, "keyframe_db.json"), "w") as f: json.dump(keyframe_db, f)
        with open(os.path.join(temp_dir, "floor_plan.json"), "w") as f: json.dump(floor_plan, f)
        
        os.makedirs(os.path.join(temp_dir, "keyframes"), exist_ok=True)
        
        metadata = {
            "id": os.path.basename(input_dir),
            "name": "Exported Map",
            "version": "1.0",
            "created_at": datetime.utcnow().isoformat(),
            "recording_count": 1,
            "floors": [],
            "bounds": {"min_x": 0, "max_z": 0},
            "glb_path": "map.glb",
            "nav_graph_path": "nav_graph.json",
            "keyframe_db_path": "keyframe_db.json",
            "floor_plan_path": "floor_plan.json"
        }
        with open(os.path.join(temp_dir, "metadata.json"), "w") as f: json.dump(metadata, f)
        
        # Zip
        with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    file_path = os.path.join(root, file)
                    arcname = os.path.relpath(file_path, temp_dir)
                    zipf.write(file_path, arcname)
                    
    finally:
        shutil.rmtree(temp_dir)
    print(f"Export complete: {output_zip}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=str, required=True, help="Input directory (e.g. in outputs/)")
    parser.add_argument("--output", type=str, required=True, help="Output zip file path")
    args = parser.parse_args()

    export_package(args.input, args.output)
