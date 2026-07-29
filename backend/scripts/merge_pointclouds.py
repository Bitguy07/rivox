import argparse
import open3d as o3d
import numpy as np

def merge_clouds(source_path: str, target_path: str, output_path: str, voxel_size: float = 0.05):
    print(f"Merging {source_path} into {target_path}...")
    source = o3d.io.read_point_cloud(source_path)
    target = o3d.io.read_point_cloud(target_path)
    
    # Downsample
    source_down = source.voxel_down_sample(voxel_size)
    target_down = target.voxel_down_sample(voxel_size)
    
    # Compute normals and FPFH features
    source_down.estimate_normals(o3d.geometry.KDTreeSearchParamHybrid(radius=voxel_size * 2, max_nn=30))
    target_down.estimate_normals(o3d.geometry.KDTreeSearchParamHybrid(radius=voxel_size * 2, max_nn=30))
    
    source_fpfh = o3d.pipelines.registration.compute_fpfh_feature(
        source_down, o3d.geometry.KDTreeSearchParamHybrid(radius=voxel_size * 5, max_nn=100)
    )
    target_fpfh = o3d.pipelines.registration.compute_fpfh_feature(
        target_down, o3d.geometry.KDTreeSearchParamHybrid(radius=voxel_size * 5, max_nn=100)
    )
    
    # RANSAC registration
    result_ransac = o3d.pipelines.registration.registration_ransac_based_on_feature_matching(
        source_down, target_down, source_fpfh, target_fpfh, True,
        voxel_size * 1.5,
        o3d.pipelines.registration.TransformationEstimationPointToPoint(False),
        3, [
            o3d.pipelines.registration.CorrespondenceCheckerBasedOnEdgeLength(0.9),
            o3d.pipelines.registration.CorrespondenceCheckerBasedOnDistance(voxel_size * 1.5)
        ], o3d.pipelines.registration.RANSACConvergenceCriteria(100000, 0.999)
    )
    
    # ICP Refinement
    result_icp = o3d.pipelines.registration.registration_icp(
        source_down, target_down, voxel_size * 0.4, result_ransac.transformation,
        o3d.pipelines.registration.TransformationEstimationPointToPlane()
    )
    
    # Transform and merge
    source.transform(result_icp.transformation)
    merged = source + target
    merged_down = merged.voxel_down_sample(voxel_size)
    
    o3d.io.write_point_cloud(output_path, merged_down)
    print(f"Merged point cloud saved to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=str, required=True, help="Source PLY path")
    parser.add_argument("--target", type=str, required=True, help="Target PLY path")
    parser.add_argument("--output", type=str, required=True, help="Output PLY path")
    args = parser.parse_args()

    merge_clouds(args.source, args.target, args.output)
