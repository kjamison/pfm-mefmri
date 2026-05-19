#module load apptainer
#module load git

outdef=Singularity_mefmri_debian.def
outsif=mefmri_debian.sif

yamlfile="./environment-mefmri.yml"

git clone https://github.com/cjl2007/pfm-mefmri.git
(cd pfm-mefmri && git submodule update --init --recursive)

#modify local copy to point to charm install location inside container
sed -i -E 's#^CHARM_BIN=.+$#CHARM_BIN="/opt/SimNIBS-4.5/bin/charm"#' pfm-mefmri/config/mefmri_wrapper_config.sh

#needed for wb_command: libglib2.0-0 needed for wb_command
#needed for msm: libexpat1 zlib1g libopenblas0 libstdc++6 libgfortran5 libquadmath0
apptainer run docker://repronim/neurodocker:latest generate singularity \
	--pkg-manager apt \
	--base-image debian:bookworm --yes \
	--install gawk sed parallel unzip ca-certificates wget curl bc rsync libglib2.0-0 \
	--install libexpat1 zlib1g libopenblas0 libstdc++6 libgfortran5 libquadmath0 \
	--copy ${yamlfile} / \
	--copy pfm-mefmri / \
	--miniconda version=latest env_name=mefmri_env yaml_file=/environment-mefmri.yml \
	--env PATH="\\\$PATH:/opt/workbench/bin_linux64" \
	--env PATH="\\\$PATH:/opt/SimNIBS-4.5/bin" \
	--run 'curl -fsSL -o wbc.zip https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v2.0.0.zip && unzip -o wbc.zip -d /opt && rm wbc.zip' \
	--run 'curl -fsSL -o msm_ubuntu_v3 https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_ubuntu_v3 && mv msm_ubuntu_v3 /usr/local && chmod a+rx /usr/local/msm_ubuntu_v3' \
	--run 'curl -fsSL -o simnibs.tar.gz https://github.com/simnibs/simnibs/releases/download/v4.5.0/simnibs_installer_linux.tar.gz && tar -xzf simnibs.tar.gz && simnibs_installer/install -s -t /opt/SimNIBS-4.5 && chmod -R a+rX /opt/SimNIBS-4.5 && rm simnibs.tar.gz' \
	--fsl version=6.0.7.4 \
	--freesurfer version=6.0.0 \
	--ants version=2.6.2 \
	> ${outdef}

apptainer build ${outsif} ${outdef}
