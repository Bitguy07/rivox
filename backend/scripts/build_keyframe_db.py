import argparse
import json
import os
import cv2
import numpy as np

def build_keyframe_db(traj_path: str, video_path: str, output_db: str, output_images_dir: str, skip_frames: int = 10):
    os.makedirs(output_images_dir, exist_ok=True)
    
    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"Error opening video {video_path}")
        return

    keyframes = []
    frame_idx = 0
    keyframe_idx = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break
            
        if frame_idx % skip_frames == 0:
            # Extract descriptor (simple color histogram for dummy implementation)
            hist = cv2.calcHist([frame], [0, 1, 2], None, [8, 8, 8], [0, 256, 0, 256, 0, 256])
            hist = cv2.normalize(hist, hist).flatten()
            
            image_name = f"kf_{keyframe_idx:04d}.jpg"
            image_path = os.path.join(output_images_dir, image_name)
            cv2.imwrite(image_path, frame)
            
            kf_data = {
                "id": str(keyframe_idx),
                "pose": {"matrix": np.eye(4).flatten().tolist()},
                "intrinsics": {"fx": 500, "fy": 500, "cx": frame.shape[1]/2, "cy": frame.shape[0]/2, "width": frame.shape[1], "height": frame.shape[0]},
                "global_descriptor": hist.tolist(),
                "keypoints": [],
                "points_3d": [],
                "image_path": image_name
            }
            keyframes.append(kf_data)
            keyframe_idx += 1
            
        frame_idx += 1
        
    cap.release()
    
    db = {"keyframes": keyframes}
    with open(output_db, "w") as f:
        json.dump(db, f, indent=2)
    print(f"Keyframe DB saved to {output_db} with {len(keyframes)} keyframes.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--traj_path", type=str, required=True, help="Trajectory file")
    parser.add_argument("--video_path", type=str, required=True, help="Video file")
    parser.add_argument("--output_db", type=str, required=True, help="Output JSON path")
    parser.add_argument("--output_images_dir", type=str, required=True, help="Output images directory")
    args = parser.parse_args()
    
    build_keyframe_db(args.traj_path, args.video_path, args.output_db, args.output_images_dir)
