
# Introduction

Define, create, and run the analyses used in the paper:
"Iron in Adipocyte Browning: A Key Regulator of Adenylyl Cyclase Activation."

This repository contains everything one should need to create a
singularity container which is able to run all of the various R
tasks performed, recreate the raw images used in the figures, create
the various intermediate rda files for sharing with others, etc.  In
addition, one may use the various singularity shell commands to enter
the container and play with the data.

# Cheater installation

I occasionally put a copy of pre-built containers here:

[https://elsayedsingularity.umiacs.io/](https://elsayedsingularity.umiacs.io/)

It probably does not have the newest changes and is slightly limited by our available disk space.

# Installation

Grab a copy of the repository:

```{bash, eval=FALSE}
git pull https://github.com/elsayed-lab/fe_adipocyte_analyses.git
```

The resulting directory should contain a few subdirectories of note:

* local: Contains the configuration information and setup scripts for the
  container and software inside it.
* data: Numerically sorted R markdown files which contain all the fun
  stuff.  Look here first.
* preprocessing: Archives of the count tables produced when using cyoa
  to process the raw sequence data. Once we have accessions for SRA, I
  will finish the companion container which creates these.
* sample_sheets: A series of excel files containing the experimental
  metadata we collected over time.  In some ways, these are the most
  important pieces of this whole thing.

At the root, there should also be a yml and Makefile which contain the
definition of the container and a few shortcuts for
building/running/playing with it.

# Creating the container

With either of the following commands, singularity should read the yml
file and build a Debian stable container with a R environment suitable
for running all of the analyses in Rmd/.

```{bash, eval=FALSE}
make
## Really, this just runs:
sudo -E singularity build fe_adipocyte_analyses.sif fe_adipocyte_analyses.yml
```

## Notes on the Makefile

The default Makefile target has dependencies for all of the .Rmd files
in data/; so if any of them change it should rebuild.

There are a couple options in the Makefile which may help the running
of the container in different environments:

1.  SINGULARITY_BIND: This, along with the environment variable
    'RENV_PATHS_CACHE' in local/etc/bashrc has a profound effect on
    the build time (assuming you are using renv).  It makes it
    possible to use a global renv cache directory in order to find and
    quickly install the various packages used by the container.
    If it is not set, the container will always take ~ 5 hours to
    build.  If it is set, then it takes ~ 2 minutes (assuming all the
    prerequisites are located in the cache already, YMMV).
2.  PARALLEL: Some tasks in the container will run across all
    available cpu cores, thus taking up significantly more memory.
    If this is set to 'FALSE' in the Makefile, then it will use one
    core, take longer, but use less memory.

# Generating the html/rda/excel output files

One of the neat things about singularity is the fact that one may just
'run' the container and it will execute the commands in its
'%runscript' section.  That runscript should use knitr to render a
html copy of all the Rmd/ files and put a copy of the html outputs
along with all of the various excel/rda/image outputs into the current
working directory of the host system.

```{bash, eval=FALSE}
./fe_adipocyte_analyses.sif
```

# Playing around inside the container

If, like me, you would rather poke around in the container and watch
it run stuff, either of the following commands should get you there:

```{bash, eval=FALSE}
make fe_adipocyte_analyses.overlay
## That makefile target just runs:
mkdir -p fe_adipocyte_analyses
sudo singularity shell --overlay  fe_adipocyte_analyses  fe_adipocyte_analyses.sif
```

### The container layout and organization

When the runscript is invoked, it creates a directory in $(pwd) named
YYYYMMDDHHmm_outputs/ and rsync's a copy of my working tree into it.
This working tree resides in /data/ and comprises the following:

* samplesheets/ : xlsx files containing the metadata collected and
  used when examining the data.  It makes me more than a little sad
  that we continue to trust this most important data to excel.
* preprocessing/ : The tree created by cyoa during the processing of
  the raw data downloaded from the various sequencers used during the
  project.  Each directory corresponds to one sample and contains all
  the logs and outputs of every program used to play with the data.
  In the context of the container this is relatively limited due to
  space constraints.
* renv/ and renv.lock : The analyses were all performed using a
  specific R and bioconductor release on my workstation which the
  container attempts to duplicate.  If one wishes to create an R
  environment on one's actual host which duplicates every version of
  every package installed, these files provide that ability.
* The various .Rmd files : These comprise the analyses performed by Theresa.
* /usr/local/bin/* : This comprises the bootstrap scripts used to
  create the container and R environment, the runscript.sh used to run
  R/knitr on the Rmd documents, and some configuration material in
  etc/ which may be used to recapitulate this environment on a
  bare-metal host.

```{bash, eval=FALSE}
## From within the container
cd /data
## Copy out the Rmd files to a directory where you have permissions via $SINGULARITY_BIND
## otherwise you will get hit with a permissions hammer.
## Or invoke the container with an overlay.
emacs -nw 01datasets.Rmd
## Render your own copy of the data:
Rscript -e 'rmarkdown::render("01datasets.Rmd")'
## If you wish to get output files with the YYYYMM date prefix I use:
Rscript -e 'hpgltools::renderme("01datasets.Rmd")'
```

# Experimenting with renv

I have a long-running misapprehension about bioconductor: for unknown
reasons I cannot seem to shake the idea that each release of
bioconductor is static and the set of package versions post-release
will stop changing at some point in time.  This is (AFAICT) not true,
an older release of bioconductor only guarantees the set of package
names which worked at the time of release (I think).  As a result,
when this container builds with a specific bioconductor release, it
will happily download the newest versions of every package, even when
those newer versions explicitly conflict with other packages.

A case in point: there was a relatively recent security problem in the
rda data format which allowed one to craft malicious rda files that
could execute arbitrary code.  In response, some bioconductor packages
made new releases which explicitly conflicted with other packages that
they previously used.  This is quite reasonable, but caused this
singularity container to fail building until I traced the dependency
tree and worked around the conflict.

The obvious solution is renv, which seek to record and use
versions of every package in an extant environment.  I previously used
pakrat for this purpose and found it a little frustrating to keep
updated; in addition when I attempted renv previously for this, it
failed spectacularly for two reasons: it installed everything in
serial and therefore took _forever_, in addition it seemed to lose the
environment variables which I require for things like C/C++
compilation and therefore mis-compiled many packages and resulted in a
basically unusable R installation.

I strongly suspect that I did something wrong in my
installation/configuration/parameters of the renv that I set up; so I
want to try again here.

## renv setup

The following block is being executed using the R installation on my
workstation in order to create the renv lock/json configuration which
I will provide to the singularity container.  I will therefore test
the resulting environment in two ways:

1. copy it to /tmp/ on my workstation and attempt a restore using the
   system-installed R.
2. create a bootstrap_renv.R and use it during the singularity
   bootstrapping process.
