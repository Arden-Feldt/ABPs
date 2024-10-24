#!/bin/bash
#SBATCH -p general                          # partition to run on
#SBATCH -n 1                                # number of cores
#SBATCH -t 11-00:00                          # time (D-HH:MM)
#SBATCH --mem=10g
# Command to increase memory allocated --mem=100g

#This is the path to hoomd
hoomd_path=$1
#This is the path to save the text files
outpath=$2
#This is the path to the analysis file
script_path=$3
#This is the file name to analyze
fname=$4
# This is the bin size (in simulation units)
bin=$5
# This is the step size (in number of time steps)
step=$6
# This is the analysis function to run
method=$7
# This is whether you want to run a measurement (1=yes, 0=no)
analyze=$8
# This is whether you want plots generated (1=yes, 0=no)
plot=$9
# This is whether you want videos generated (1=yes, 0=no)
vid=${10}
# This is the given operating system
os=${11}
# This is the start frame for analysis
start_frame=${12}
# This is the end frame for analysis
end_frame=${13}
# This is the optional analysis parameters
optional=${14}

# Activate environment if on windows, otherwise, activate yourself or later if longleaf
if [ $os == "windows" ]; then
    source ~/.profile
    conda activate rekt
fi

echo hoomd_path
echo $hoomd_path
echo outpath
echo $outpath
echo script_path
echo $script_path
echo fname
echo $fname
echo bin
echo $bin
echo step
echo $step
echo analyze
echo $analyze
echo plot
echo $plot
echo vid
echo $vid
echo start_frame
echo $start_frame
echo end_frame
echo $end_frame


# Check what system you're using for running analysis
first_letter=$(printf %.5s "$hoomd_path")

#Obtain simulation inputs from .gsd file names
if [ $first_letter == '/User' ]; then
    vars="$(python3 ${script_path}/tools/submission_scripts/post_proc/get_parameters.py ${fname})"
fi

if [ $first_letter == '/c/Us' ]; then
    vars="$(python ${script_path}/tools/submission_scripts/post_proc/get_parameters.py ${fname})"
fi

if [ $first_letter == "/nas/" ]; then
    vars="$(python3.8 ${script_path}/tools/submission_scripts/post_proc/get_parameters.py ${fname})"
    source ~/.bashrc
    conda activate rekt
fi

echo vars
echo $vars

pass=()
for i in $vars
do
    # Put in array to unpack
    pass+=($i)
done

echo $vars
# This is activity (monodisperse)
pe=${pass[0]}
# This is A-type activity
pa=${pass[1]}
# This is B-type activity
pb=${pass[2]}
# This is fraction of A particles
xa=${pass[3]}
# This is epsilon
ep=${pass[4]}
# This is system density (phi)
phi=${pass[5]}
# This is if the system is initially a cluster (binary)
clust=${pass[6]}
# This is the timestep size (in Brownian time)
dtau=${pass[7]}
# This is the system size
pNum=${pass[8]}

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
echo 'xa'
echo $xa


# Verify particle fraction is integer
if (( ${xa%.*} == 0 )); then
    result=$(echo "100*$xa" | bc )
    declare -i xa2=0
    xa2=${result%.*}
else
    xa2=${xa%.*}
fi

echo $xa2


#Label slow activity properly to non-zero input
declare -i pa2=0

if [ $os == "windows" ]; then
    if [ ${pe%%.*} > ${pa%%.*} ]; then
        pa2=${pe%%.*}
    else
        pa2=${pa%%.*}
    fi
elif [ $os == "mac" ]; then
    if (( ${pe%%.*} > ${pa%%.*} )); then
        pa2=${pe%%.*}
    else
        pa2=${pa%%.*}
    fi
fi

echo $pa2

# Runs analysis for whatever method you specified
if [ $analyze == "y" ]; then
    if [ $os == "mac" ]; then
        python3 $script_path/src/post_proc/master_file.py $fname $hoomd_path $outpath $pa2 $pb $xa2 $ep $phi $dtau $bin $step $method $plot $start_frame $end_frame $optional
    elif [ $os == "windows" ]; then
        python $script_path/src/post_proc/master_file.py $fname $hoomd_path $outpath $pa2 $pb $xa2 $ep $phi $dtau $bin $step $method $plot $start_frame $end_frame $optional
    fi
fi

# Makes integers of simulation inputs for file naming
pe=${pe%%.*}
pa=${pa%%.*}
pb=${pb%.*}
eps=${ep}
phi=${phi}
pNum=${pNum%.*}

echo $vid
# Creates videos for whatever method you specified
if [ $vid == "y" ]; then
    if [ $method == "activity-blank" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_blank_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_blank_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 10 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_blank_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_blank_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 10 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "activity-blank-video" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_blank_video_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_blank_video_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 10 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_blank_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_blank_mono_fast_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 10 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "activity" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 12 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 12 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "bulk-heterogeneity" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "activity-wide-desorb" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_desorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "activity-wide-adsorb" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_adsorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_adsorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_adsorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_adsorb_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "activity-wide-desorb-orient" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_desorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_desorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 24 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_desorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_desorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 24 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "activity-wide-adsorb-orient" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/part_activity_adsorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_activity_adsorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 24 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/part_activity_adsorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_activity_adsorb_orient_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 24 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "vorticity" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/vorticity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/vorticity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/vorticity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/vorticity_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "radial-heterogeneity_com_interface" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_fa_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_fa_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_align_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_align_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_align_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_align_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_align_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_align_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_num_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_num_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_num_dens_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_num_dens_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_num_dens_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_num_dens_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_circle_radial_heterogeneity_fa_avg_real_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_circle_radial_heterogeneity_fa_avg_real_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_fa_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_fa_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_align_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_align_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_align_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_align_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_align_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_align_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_num_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_num_dens_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_num_dens_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_num_dens_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_num_dens_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_num_dens_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/dif_noncircle_radial_heterogeneity_fa_avg_real_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/dif_noncircle_radial_heterogeneity_fa_avg_real_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 16 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

        fi
    elif [ $method == "phases" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/phases_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/phases_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/phases_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/phases_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "density" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/density_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/density_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/density_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/density_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/density_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/density_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/density_dif_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/density_dif_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/part_frac_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/part_frac_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/density_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/density_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/density_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/density_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/density_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/density_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/density_dif_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/density_dif_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/part_frac_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/part_frac_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi

    elif [ $method == "com-align" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/com_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/com_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/com_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/com_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/com_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/com_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/com_normal_fa_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/com_normal_fa_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/com_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/com_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/com_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/com_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/com_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/com_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/com_normal_fa_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/com_normal_fa_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "surface-align" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/surface_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/surface_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/surface_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/surface_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/surface_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/surface_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/surface_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/surface_alignment_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/surface_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/surface_alignment_A_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/surface_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/surface_alignment_B_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "fluctuations" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/clust_fluctuations_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/clust_fluctuations_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 12 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/clust_fluctuations_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/clust_fluctuations_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 12 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "int-press" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/int_press_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/int_press_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/int_press_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/int_press_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "centrosymmetry" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/csp_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/csp_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/csp_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/csp_all_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "lattice-spacing" ]; then
        if [ $os == "mac" ]; then
            pic_path="${outpath}_pic_files/lat_histo_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/lat_histo_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path="${outpath}_pic_files/lat_map_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            vid_path="${outpath}_vid_files/lat_map_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        elif [ $os == "windows" ]; then
            pic_path=$(echo "${outpath}_pic_files/lat_histo_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/lat_histo_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

            pic_path=$(echo "${outpath}_pic_files/lat_map_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            vid_path=$(echo "${outpath}_vid_files/lat_map_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}" | tr -d '\r')
            ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
        fi
    elif [ $method == "neighbors" ]; then
        pic_path="${outpath}_pic_files/all_all_neigh_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/all_all_neigh_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

        pic_path="${outpath}_pic_files/all-all_local_ori_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/all-all_local_ori_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 1 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    elif [ $method == "orientation" ]; then
        pic_path="${outpath}_pic_files/ang_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/ang_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    elif [ $method == "penetration" ]; then
        pic_path="${outpath}_pic_files/force_lines_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/force_lines_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number 1 -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    elif [ $method == "phases" ]; then
        pic_path="${outpath}_pic_files/plot_phases_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/plot_phases_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 8 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    elif [ $method == "csp" ]; then
        pic_path="${outpath}_pic_files/all_all_csp_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/all_all_csp_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 4 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    elif [ $method == "hexatic_order" ]; then

        pic_path="${outpath}_pic_files/hexatic_order_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/hexatic_order_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 4 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4

        pic_path="${outpath}_pic_files/relative_angle_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/relative_angle_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 4 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    elif [ $method == "local_density" ]; then

        pic_path="${outpath}_pic_files/local_density2_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        vid_path="${outpath}_vid_files/local_density2_pa${pa2}_pb${pb}_xa${xa2}_eps${eps}_phi${phi}_pNum${pNum}_bin${bin}_time${step}"
        ffmpeg -start_number $start_frame -framerate 1 -i "$pic_path"_frame_%05d.png\
            -vcodec libx264 -s 1600x1200 -pix_fmt yuv420p -threads 1\
            "$vid_path".mp4
    fi
fi



exit 0
