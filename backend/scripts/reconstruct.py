import argparse
import os
import subprocess
import sys

try:
    from device_utils import get_best_device
except ImportError:
    from .device_utils import get_best_device

def run_lingbot(video_path: str, output_dir: str):
    """
    Wrapper for LingBot-Map demo.py with adaptive GPU/CPU device selection.
    """
    device = get_best_device()
    device_str = str(device)
    print(f"Running reconstruction on {video_path} into {output_dir} using device: {device_str}")
    
    # Check if demo.py (LingBot-Map) exists in the expected location
    lingbot_demo = os.environ.get("LINGBOT_DEMO_PATH", "demo.py")
    if os.path.exists(lingbot_demo):
        cmd = [
            sys.executable, lingbot_demo,
            "--video_path", video_path,
            "--mode", "windowed",
            "--output_dir", output_dir,
            "--device", device_str
        ]
        subprocess.run(cmd, check=True)
    else:
        print("LingBot-Map not found. Falling back to mock reconstruction.")
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
