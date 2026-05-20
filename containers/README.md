# ME-fMRI Apptainer/Singularity Container

This directory contains the scripts needed to build an Apptainer/Singularity container for the ME-fMRI pipeline.

## Build the container

Make sure Apptainer is available in your environment. On a cluster, this may require loading a module, for example:

```bash
module load apptainer
```

Then build the container from the `containers` directory:

```bash
cd ./containers
bash neurodocker_singularity_build.sh
```

This will create the container image:

```bash
mefmri_debian.sif
```

## Run the pipeline using the container

First, set the path to your local FreeSurfer license file:

```bash
FS_LICENSE=/path/to/freesurfer_license.txt
```

Then run the container:

```bash
apptainer exec --no-home --cleanenv --writable-tmpfs \
    -B /path/to/mystudy/mysubject \
    -B ${FS_LICENSE}:/opt/freesurfer-6.0.0/license.txt \
    mefmri_debian.sif \
    /bin/bash -c "bash /pfm-mefmri/bin/mefmri_pipeline.sh /path/to/mystudy/mysubject /pfm-mefmri/config/mefmri_wrapper_config.sh"
```

## Run with a custom version of the pipeline

To patch in a local/custom version of the pipeline, bind-mount your local repository over `/pfm-mefmri` inside the container:

```bash
apptainer exec --no-home --cleanenv --writable-tmpfs \
    -B /path/to/mystudy/mysubject \
    -B ${FS_LICENSE}:/opt/freesurfer-6.0.0/license.txt \
    -B /path/to/pfm-mefmri:/pfm-mefmri \
    mefmri_debian.sif \
    /bin/bash -c "bash /pfm-mefmri/bin/mefmri_pipeline.sh /path/to/mystudy/mysubject /pfm-mefmri/config/mefmri_wrapper_config.sh"
```

In the custom pipeline example, replace `/path/to/pfm-mefmri` with the path to your local copy of the pipeline repository.

If using a custom pipeline, note that the container places the CHARM binary in `/opt/SimNIBS-4.5/bin/charm`, so be sure your `pfm-mefmri/config/mefmri_wrapper_config.sh` file has:

```bash
CHARM_BIN=/opt/SimNIBS-4.5/bin/charm
```
