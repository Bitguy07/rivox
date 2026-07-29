"""
Adaptive Device Selector for PyTorch / LingBot-Map.

Automatically detects the best available compute hardware in priority order:
1. NVIDIA CUDA / AMD ROCm (torch.cuda)
2. Apple Silicon Metal (torch.backends.mps)
3. Intel Arc / Xe (torch.xpu via Intel Extension for PyTorch)
4. DirectX 12 Generic GPUs via DirectML (torch_directml)
5. Fallback to CPU
"""

import sys

def get_best_device():
    """
    Returns the optimal PyTorch device object/string based on available hardware.
    """
    try:
        import torch
    except ImportError:
        print("[Device Selector] PyTorch not installed. Using CPU.")
        return "cpu"

    # 1. NVIDIA CUDA or AMD ROCm
    if torch.cuda.is_available():
        device_name = torch.cuda.get_device_name(0)
        print(f"[Device Selector] Found CUDA/ROCm GPU: {device_name}")
        return torch.device("cuda")

    # 2. Apple Silicon (M1/M2/M3/M4) Metal Acceleration
    if hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
        print("[Device Selector] Found Apple Silicon Metal (MPS) Acceleration")
        return torch.device("mps")

    # 3. Intel Arc / Xe GPUs via Intel Extension for PyTorch (IPEX)
    try:
        if hasattr(torch, "xpu") and torch.xpu.is_available():
            print(f"[Device Selector] Found Intel GPU (XPU): {torch.xpu.get_device_name(0)}")
            return torch.device("xpu")
    except Exception:
        pass

    # 4. Generic DirectX 12 GPUs via Microsoft DirectML (AMD, Intel, NVIDIA on Windows)
    try:
        import torch_directml
        dml_device = torch_directml.device()
        print(f"[Device Selector] Found DirectML GPU: {torch_directml.device_name(0)}")
        return dml_device
    except ImportError:
        pass

    # 5. Fallback to CPU
    print("[Device Selector] No dedicated GPU detected. Falling back to CPU.")
    return torch.device("cpu")


if __name__ == "__main__":
    device = get_best_device()
    print(f"Selected compute device: {device}")
