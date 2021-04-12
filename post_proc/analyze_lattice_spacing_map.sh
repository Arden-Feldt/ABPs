#!/bin/sh
#SBATCH -p general                          # partition to run on
#SBATCH -n 1                                # number of cores
#SBATCH -t 11-00:00                          # time (D-HH:MM)

# Command to increase memory allocated --mem=100g


hoomd_path=$1
gsd_path=$2
script_path=$3
fname=$4

vars="$(python3.5 ${script_path}/get_parameters.py ${fname})"

pass=()
for i in $vars
do
    # Put in array to unpack
    pass+=($i)
done



# This is activity (monodisperse)
pe=${pass[0]}
# This is A-type activity
pa=${pass[5]}
# This is B-type activity
pb=${pass[1]}
# This is fraction of A particles
xa=${pass[2]}
# This is epsilon
ep=${pass[3]}
# This is system density (phi)
phi=${pass[4]}
# This is if the system is initially a cluster (binary)
clust=${pass[7]}
# This is the timestep size (in Brownian time)
dtau=${pass[6]}

echo 'fname'
echo $fname
echo 'pe'
echo $pe
echo 'pa'
echo $pa
echo 'pb'
echo $pb
echo 'xa'
echo $xa
echo 'ep'
echo $ep
echo 'phi'
echo $phi
echo 'dtau'
echo $dtau

#python3.8 $script_path/
#python $script_path/nearest_neigh_small_array.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/nearest_neigh.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/heatmap.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/post_proc.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/pp_msd_perc_A.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/pp_msdten_perc_A.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/MCS.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/MCSten.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/voronoi.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/meshed_output.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/per_particle_output.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/gtar_pressure.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/phase_types.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/dense_CoM.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/number_densities.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/force_diff_sources.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/histogram_distance.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/histogram_output_txt.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/plotNumberDensities.py $pa $pb $xa
#python $script_path/pairCorrelationRelations.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/mesh_nearest_neighbor.py $pa $pb $xa $hoomd_path $gsd_path
#python3 $script_path/computeRDF.py $pe $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/heatmapType.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/extrinsic_txt.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/extrinsic_all_time.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/phi_extrinsic_all_time.py $pa $pb $xa $hoomd_path $gsd_path $ep $phi
#python $script_path/sim_to_txt_no_cutoff.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/convergence_analysis.py $pa $pb $xa $hoomd_path $gsd_path $ep $num
#python $script_path/extrinsic_all_time_back_compat.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/edge_detection.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/edge_detection_v2.py $pa $pb $xa $hoomd_path $gsd_path
#python $script_path/check_cluster_alg.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/diffHeatmapType.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/orientation_snapshots.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/binnedNetActivity.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/analyze_alpha.py $pa $pb $xa $hoomd_path $gsd_path $ep $al
#python $script_path/alpha_diameter_histogram.py $pa $pb $xa $hoomd_path $gsd_path $ep $al
#python /Users/kolbt/Desktop/compiled/whingdingdilly/art/voronoi_tessellation.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/mesh_nearest_neighbors.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/mesh_nearest_neighbors_periodic.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python3 $script_path/delta_spacial.py $pa $pb $xa $hoomd_path $gsd_path $ep $fname
#python $script_path/soft_nearest_neighbors.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python $script_path/compute_phase_area.py $pa $pb $xa $hoomd_path $gsd_path $ep
#python3 $script_path/computeMCS_threshold.py $fname $pe $pb $xa $ep $phi
#python3 $script_path/edge_distance.py $fname $pe $pb $xa $ep $phi
#python3 $script_path/edges_from_bins.py $fname $pe $pb $xa $ep $phi
#python3 $script_path/indiv_cluster_pressure.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/histogram-densities.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/interparticle_pressure.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/image_final_tstep.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/image_single_particle.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/sim_frames.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/sim_velocity.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/sim_orientation.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/full-video-analysis.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/radial_com_data.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/radial_density.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/alignment_analysis2.py $fname $pa $pb $xa $ep $phi $tau
python3 $script_path/lattice_spacing_map.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/cluster_comp_new.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/2activepartg_cluster.py $fname $pe $pb $xa $ep $phi $tau
#python3 $script_path/getRDF.py $pe $pb $xa $hoomd_path $gsd_path $ep
#python3 $script_path/untitled6.py $fname $pe $pb $xa $ep $phi $tau

##Nicks Video for Particle Motion

pa=${pa%%.*}
pe=${pe%%.*}
pb=${pb%.*}
xa=${xa%.*}
eps=${ep}
echo ${phi}
phi=${phi%%.*}
pNum=${pNum%.*}


ffmpeg -start_number 0 -framerate 20 -i /pine/scr/n/j/njlauers/scm_tmpdir/lat_video/lat_cluster_pe${pe}_phi${phi}_eps${eps}_frame_%04d.png\
 -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
 /pine/scr/n/j/njlauers/scm_tmpdir/complete_videos/lat_pa${pe}_pb${pb}_xa${xa}_phi${phi}_eps${eps}_pNum${pNum}.mp4

ffmpeg -start_number 0 -framerate 20 -i /pine/scr/n/j/njlauers/scm_tmpdir/lat_video/lat2_cluster_pe${pe}_phi${phi}_eps${eps}_frame_%04d.png\
 -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
 /pine/scr/n/j/njlauers/scm_tmpdir/complete_videos/lat2_pa${pe}_pb${pb}_xa${xa}_phi${phi}_eps${eps}_pNum${pNum}.mp4

#ffmpeg -start_number 0 -framerate 10 -i /Users/nicklauersdorf/hoomd-blue/build/outside_slow_pe${pa}_150_r26_39_rAlign_3.0_frame_%04d.png\
# -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
# outside_slow_pe${pa}_150_r26_39_rAlign_3.0.mp4

#ffmpeg -start_number 0 -framerate 10 -i cluster_pe${pa}_phi${phi}_eps${ep}_frame_%04d.png\
# -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
# cluster_pa${pa}_phi${phi}_eps${ep}.mp4
## Videos for seminar
#ffmpeg -start_number 0 -framerate 40 -i test_fm%04d.png\
# -vcodec libx264 -s 640x480 -pix_fmt yuv420p -threads 1\
# sim_orientation.mp4

## Movie for single particle motion
#ffmpeg -start_number 0 -framerate 20 -i test_fm%04d.png\
# -vcodec libx264 -s 3200x2400 -pix_fmt yuv420p -threads 1\
# brownian_particle_motion.mp4

## Movie for defects
#ffmpeg -start_number 0 -framerate 6 -i defects_pa${pa}_pb${pb}_xa${xa}_ep${ep}_frame%04d.png\
# -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
# defects_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4

# Movie for RDF
#ffmpeg -framerate 10 -i RDF_pa${pa}_pb${pb}_xa${xa}_ep${ep}_fm%d.png\
# -vcodec libx264 -s 1000x1000 -pix_fmt yuv420p -threads 1\
# RDF_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4
#rm RDF_pa${pa}_pb${pb}_xa${xa}_ep${ep}_fm*.png

# Movies for net activity and other force relations
#ffmpeg -start_number 450 -framerate 10 -i forces_pa${pa}_pb${pb}_xa${xa}_eps${ep}_fm%d.png\
# -vcodec libx264 -s 2000x2000 -pix_fmt yuv420p -threads 1\
# forces_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4
#rm forces_pa${pa}_pb${pb}_xa${xa}_eps${ep}_fm*.png
#
#ffmpeg -start_number 450 -framerate 10 -i netPe_pa${pa}_pb${pb}_xa${xa}_eps${ep}_fm%d.png\
# -vcodec libx264 -s 2000x2000 -pix_fmt yuv420p -threads 1\
# netPe_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4
#rm netPe_pa${pa}_pb${pb}_xa${xa}_eps${ep}_fm*.png

# Movie for heatmap by type
#ffmpeg -start_number 450 -framerate 10 -i heatType_pa${pa}_pb${pb}_xa${xa}_ep${ep}_fm%d.png\
# -vcodec libx264 -s 2000x2000 -pix_fmt yuv420p -threads 1\
# heatType_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4
#rm heatType_pa${pa}_pb${pb}_xa${xa}_ep${ep}_fm*.png

# Command to make movie for checking cluster algorithm
#ffmpeg -framerate 10 -i pa${pa}_pb${pb}_xa${xa}_ep${ep}_frame%d.png\
# -vcodec libx264 -s 2000x2000 -pix_fmt yuv420p -threads 1\
# clust_alg_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4
#
#rm pa${pa}_pb${pb}_xa${xa}_ep${ep}_frame*.png

# Center of mass movie
#ffmpeg -framerate 10 -i mvy_pa${pa}_pb${pb}_xa${xa}_%d.png\
# -vcodec libx264 -s 1000x1000 -pix_fmt yuv420p -threads 1\
# CoM_pa${pa}_pb${pb}_xa${xa}.mp4

# Orientation specific scripts
#myfile=$(pwd)
#mkdir "pa${pa}_pb${pb}_xa${xa}_images"
#cd "pa${pa}_pb${pb}_xa${xa}_images"

#python $script_path/orientations.py $pa $pb $xa $hoomd_path $gsd_path $myfile $ep
#python $script_path/orientationsCentered.py $pa $pb $xa $hoomd_path $gsd_path $myfile

#ffmpeg -start_number 450 -framerate 10 -i orientation_pa${pa}_pb${pb}_xa${xa}_ep${ep}_fm%d.png\
# -vcodec libx264 -s 2000x2000 -pix_fmt yuv420p -threads 1\
# orientation_pa${pa}_pb${pb}_xa${xa}_ep${ep}.mp4
#rm orientation_pa${pa}_pb${pb}_xa${xa}_ep${ep}_fm*.png

# Move the movie once it's been made
#mv orientation_pa${pa}_pb${pb}_xa${xa}.mp4 ../orientation*

#ffmpeg -framerate 10 -i tot_press_pa${pa}_pb${pb}_xa${xa}_mvout_%d.png\
# -vcodec libx264 -s 1000x1000 -pix_fmt yuv420p -threads 1\
# pressure_pa${pa}_pb${pb}_xa${xa}.mp4

# Movies for binned vector force
#ffmpeg -framerate 10 -i nBins100_pa${pa}_pb${pb}_xa${xa}_step_%d.png\
# -vcodec libx264 -s 1000x1000 -pix_fmt yuv420p -threads 1\
# nBins100_pa${pa}_pb${pb}_xa${xa}.mp4
#
#rm nBins100_pa${pa}_pb${pb}_xa${xa}*.png

exit 0