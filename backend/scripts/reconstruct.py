import argparse
import os
import subprocess
import sys

def run_lingbot(video_path: str, output_dir: str):
    """
    Wrapper for LingBot-Map demo.py.
    """
    print(f"Running reconstruction on {video_path} into {output_dir}")
    
    # Check if demo.py (LingBot-Map) exists in the expected location
    lingbot_demo = os.environ.get("LINGBOT_DEMO_PATH", "demo.py")
    if os.path.exists(lingbot_demo):
        cmd = [sys.executable, lingbot_demo, "--video_path", video_path, "--mode", "windowed", "--output_dir", output_dir]
        subprocess.run(cmd, check=True)
    else:
        print("LingBot-Map not found. Falling back to COLMAP (mock fallback).")
        # In a real environment, you'd run COLMAP commands here.
        # Creating dummy files for pipeline testing.
        os.makedirs(output_dir, exist_ok=True)
        with open(os.path.join(output_dir, "points.ply"), "w") as f:
            f.write("ply\nformat ascii 1.0\nelement vertex 0\nend_header\n")
        with open(os.path.join(output_dir, "traj.txt"), "w") as f:
            f.write("")
        print("Mock fallback complete. Created dummy points.ply and traj.txt")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--video_path", type=str, required=True, help="Path to input video")
    parser.add_argument("--output_dir", type=str, required=True, help="Directory to save outputs")
    parser.add_argument("--model_path", type=str, help="Optional path to model weights")
    args = parser.parse_args()

    run_lingbot(args.video_path, args.output_dir)
