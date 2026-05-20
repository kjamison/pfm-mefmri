#module load apptainer
#module load git

outdef=Singularity_mefmri_debian.def
outsif=mefmri_debian.sif

yamlfile="../environment-mefmri.yml"

LOCAL_REPO_COPY=TEMP_REPO
rm -rf ${LOCAL_REPO_COPY}
mkdir -p ${LOCAL_REPO_COPY}

#(cd ${LOCAL_REPO_COPY} && git clone https://github.com/cjl2007/pfm-mefmri.git)
#(cd ${LOCAL_REPO_COPY}/pfm-mefmri && git submodule update --init --recursive)

mkdir -p ${LOCAL_REPO_COPY}/pfm-mefmri
tar --exclude "*/${LOCAL_REPO_COPY}" --exclude "./.git" -C ../ -cf - . | tar -C ${LOCAL_REPO_COPY}/pfm-mefmri/ -xf -

#modify local copy to point to charm install location inside container
NEW_CHARM_DIR="/opt/SimNIBS-4.5"
sed -i -E 's#^CHARM_BIN=.+$#CHARM_BIN="'${NEW_CHARM_DIR}'/bin/charm"#' ${LOCAL_REPO_COPY}/pfm-mefmri/config/mefmri_wrapper_config.sh

#needed for wb_command: libglib2.0-0 needed for wb_command
#needed for msm: libexpat1 zlib1g libopenblas0 libstdc++6 libgfortran5 libquadmath0
apptainer run docker://repronim/neurodocker:latest generate singularity \
	--pkg-manager apt \
	--base-image debian:bookworm --yes \
	--install gawk sed parallel unzip ca-certificates wget curl bc rsync libglib2.0-0 \
	--install libexpat1 zlib1g libopenblas0 libstdc++6 libgfortran5 libquadmath0 \
	--copy ${yamlfile} / \
	--copy ${LOCAL_REPO_COPY}/pfm-mefmri / \
	--miniconda version=latest env_name=mefmri_env yaml_file=/environment-mefmri.yml \
	--env PATH="\\\$PATH:/opt/workbench/bin_linux64" \
	--env PATH="\\\$PATH:${NEW_CHARM_DIR}/bin" \
	--run 'curl -fsSL -o wbc.zip https://www.humanconnectome.org/storage/app/media/workbench/workbench-linux64-v2.0.0.zip && unzip -o wbc.zip -d /opt && rm wbc.zip' \
	--run 'curl -fsSL -o msm_ubuntu_v3 https://github.com/ecr05/MSM_HOCR/releases/download/v3.0FSL/msm_ubuntu_v3 && mv msm_ubuntu_v3 /usr/local && chmod a+rx /usr/local/msm_ubuntu_v3' \
	--run 'curl -fsSL -o simnibs.tar.gz https://github.com/simnibs/simnibs/releases/download/v4.5.0/simnibs_installer_linux.tar.gz && tar -xzf simnibs.tar.gz && simnibs_installer/install -s -t '${NEW_CHARM_DIR}' && chmod -R a+rX '${NEW_CHARM_DIR}' && rm simnibs.tar.gz' \
	--fsl version=6.0.7.4 \
	--freesurfer version=6.0.0 \
	--ants version=2.6.2 \
	> ${outdef}

apptainer build ${outsif} ${outdef}

rm -rf ${LOCAL_REPO_COPY}
