#!/usr/bin/env bash
source /usr/local/etc/bashrc

## This file is intended to document my first container installation
## of every R prerequisite via renv.  Once complete I will use renv's
## snapshot function to create its json file which will then be included
## with the container recipe and invoked from within the container installation
## via renv's restore.  The starting point for this script is a reasonably minimal
## singularity instance with a blank R, build-essential, and some known prerequisites.

cd /data || exit

start=$(pwd)
log=/setup_hpgltools.stdout
err=/setup_hpgltools.stderr
prefix="/sw/local/conda/${CONTAINER_VERSION}"

## The primary motivation for this document is the fact that all my containers exploded
## on 20240501.  Suddenly, none of my containers were able to successfully build because
## bioconductor changed versions of many of the prerequisites to versions which simply
## do not install.  As a result, I decided to re-evaluate how I install these prerequisites
## and remove the assumption that installing/using a specific bioconductor version would
## result in a set/usable set of packages.
##
## As a result, I decided to once again try renv.  I previously tried this for a project
## and found it a bit unsatisfactory, just because at the time I thought having extra
## copies of everything across packages too onerous.  However, if I am going to go to the
## trouble of installing a full toolchain for the container, then I will -by-definition-
## have all the packages installed in it, so that complaint is a bit stupid.

## With the above in mind, I am going to write in the following R script with each
## installation command used to get renv set up followed by whatever tasks are required
## to get me all the prerequisite packages for this container.

## If any of the resulting packages require the installation of stuff via apt/conda, then
## I will put them here, before the R script.

echo "Setting up a Debian stable instance."
source /versions.txt
apt-get update 1>/dev/null
apt-get -y upgrade 1>/dev/null
apt-get -y install $(/bin/cat /usr/local/etc/deb_packages.txt) 1>/dev/null 2>/data/apt.stderr
apt-get clean

echo "Creating the conda/mamba tree and hpgltools environment."
mkdir -p "/sw/local/conda/${CONTAINER_VERSION}" /sw/modules/conda
cp /sw/modules/template "/sw/modules/conda/${CONTAINER_VERSION}"
curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -C / -axvj bin/micromamba 2>/data/mamba.stderr 1>/dev/null
eval "$(/bin/micromamba shell hook --shell bash)"
/bin/micromamba --root-prefix="${prefix}" --yes create -n hpgltools \
           $(/bin/cat /usr/local/etc/conda_packages.txt) r-base=${R_VERSION} \
           -c conda-forge 2>>/data/mamba.stderr 1>/dev/null
export PATH="/sw/local/conda/${CONTAINER_VERSION}/envs/hpgltools/bin:/sw/local/conda/${CONTAINER_VERSION}/condabin:${PATH}"

## Setup renv and initialize my package versions.
#if [[ -e "${HOME}/hpgldata" ]]; then
#    mkdir -p /data/hpgldata && rsync -av "${HOME}/hpgldata/" /data/hpgldata/
#else
#    git clone https://github.com/abelew/hpgldata.git
#fi
if [[ -e "${HOME}/hpgltools" ]]; then
    mkdir -p /data/hpgltools && rsync -av "${HOME}/hpgltools/" /data/hpgltools/
else
    git clone https://github.com/abelew/hpgltools.git
fi
#export HPGL_VERSION=$(cd hpgltools && git log -1 --date=iso | grep ^Date | awk '{print $2}' | sed 's/\-//g')
#echo "export HPGL_VERSION=${HPGL_VERSION}" >> /versions.txt
#
#echo "The last commit included:" | tee -a ${log}
#last=$(cd hpgltools && git log -1)
#echo "${last}" | tee -a ${log}
#
#if [[ -n "${HPGLTOOLS_COMMIT}" ]]; then
#    echo "Explicitly setting to the commit: ${HPGLTOOLS_COMMIT}."
#    reset=$(cd hpgltools && git reset "${HPGLTOOLS_COMMIT}" --hard)
#else
#    echo "Using the current HEAD of the hpgltools repository: ${HPGL_VERSION}."
#fi

## The bootstrap will therefore use the renv directory to install everything
## Since renv causes the container to fail, I will not _actually_ use it, but instead
## invoke activate(), snapshot(), deactivate() at the end of the process, thus
## creating the renv.lock and json files which may then be provided if one wishes
## to use this renv in other environments (but not this singularity instance,
## or it will die horribly).
echo "Running the bootstrap R installation script."
{ /usr/local/bin/bootstrap.R || echo "Failed to finish bootstrap.R"; }
/bin/ls -ld /data/R
