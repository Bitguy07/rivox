import argparse
import json
import os
import numpy as np
import open3d as o3d

def build_floor_plan(ply_path: str, output_path: str):
    print(f"Building floor plan from {ply_path}")
    if not os.path.exists(ply_path):
        print("File not found, creating dummy floor_plan.json")
        with open(output_path, "w") as f:
            json.dump({"layers": {}}, f)
        return

    pcd = o3d.io.read_point_cloud(ply_path)
    points = np.asarray(pcd.points)
    
    # Dummy implementation: bounding box walls
    layers = {}
    if len(points) > 0:
        min_b = points.min(axis=0)
        max_b = points.max(axis=0)
        
        layers["0"] = {
            "walls": [
                [min_b[0], min_b[1], max_b[0], min_b[1]],
                [max_b[0], min_b[1], max_b[0], max_b[1]],
                [max_b[0], max_b[1], min_b[0], max_b[1]],
                [min_b[0], max_b[1], min_b[0], min_b[1]]
            ],
            "rooms": [{"label": "Room 1", "points": [[min_b[0], min_b[1]], [max_b[0], min_b[1]], [max_b[0], max_b[1]], [min_b[0], max_b[1]]]}],
            "width": max_b[0] - min_b[0],
            "height": max_b[1] - min_b[1],
            "offset_x": min_b[0],
            "offset_y": min_b[1]
        }
        
    floor_plan = {"layers": layers}
    with open(output_path, "w") as f:
        json.dump(floor_plan, f, indent=2)
    print(f"Saved floor plan to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ply_path", type=str, required=True, help="Input PLY")
    parser.add_argument("--output_path", type=str, required=True, help="Output JSON")
    args = parser.parse_args()
    
    build_floor_plan(args.ply_path, args.output_path)
