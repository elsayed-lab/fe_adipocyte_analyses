
# Introduction

Define, create, and run the analyses used in the paper:
""

This repository contains everything one should need to create a
singularity container which is able to run all of the various R
tasks performed, recreate the raw images used in the figures, create
the various intermediate rda files for sharing with others, etc.  In
addition, one may use the various singularity shell commands to enter
the container and play with the data.

# Cheater installation

Periodically I put a copy of the pre-built container here:

[https://elsayedsingularity.umiacs.io/](https://elsayedsingularity.umiacs.io/)

It probably does not have the newest changes.

# Installation

Grab a copy of the repository:

```{bash, eval=FALSE}
git pull https://github.com/elsayed-lab/template.git
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
sudo -E singularity build tmrc3_analyses.sif tmrc3_analyses.yml
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
    build.  If it is set, then it takes ~ 4 minutes (assuming all the
    prerequisites are located in the cache already, YMMV).
2.  PARALLEL: Some tasks in the container will run across all
    available cpu cores, thus taking up significantly more memory.
    Notably, the differential expression analyses can take up to ~
    180G of ram when PARALLEL is on (at least on my computer).  If
    this is set to 'FALSE' in the Makefile, then it will take a bit
    longer, but the maximum memory usage falls to ~ 30-40G.  If your
    machine has less than that, then I think some things are doomed to
    fail.
3.  methods: Not in the Makefile.  By default, my pairwise
    differential expression method attempts to perform ~ 6 different
    ways of doing the analyses.  This is the primary reason it is so
    memory hungry. An easy way to dramatically decrease the memory
    usage and time is to edit the top of the 01datastructures.Rmd
    document and set some more elements of the 'methods' variable to
    FALSE.  Just note that our tables primarily rely on the DESeq2
    results, so if you turn that off, you will by definition get
    different results.  Also, it is fun to poke at the different
    methods and see how their various assumptions affect the results.

# Generating the html/rda/excel output files

One of the neat things about singularity is the fact that one may just
'run' the container and it will execute the commands in its
'%runscript' section.  That runscript should use knitr to render a
html copy of all the Rmd/ files and put a copy of the html outputs
along with all of the various excel/rda/image outputs into the current
working directory of the host system.

```{bash, eval=FALSE}
./template.sif
```

# Playing around inside the container

If, like me, you would rather poke around in the container and watch
it run stuff, either of the following commands should get you there:

```{bash, eval=FALSE}
make template.overlay
## That makefile target just runs:
mkdir -p template
sudo singularity shell --overlay template_overlay template.sif
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
* The various .Rmd files : These are numerically named analysis files.
  The 00preprocessing does not do anything, primarily because I do not
  think anyone wants a 6-10Tb container (depending on when/what is
  cleaned during processing)!  All files ending in _commentary are
  where I have been putting notes and muttering to myself about what
  is happening in the analyses.  01datasets is the parent of all the
  other files and is responsible for creating the data structures
  which are used in every file which follows.  The rest of the files
  are basically what they say on the tin: 02visualization has lots of
  pictures, 03differential_expression* comprises DE analyses of
  various data subsets, 04lrt_gsva combines a series of likelihood
  ratio tests and GSVA analyses which were used (at least by me) to
  generate hypotheses and look for other papers which have similar gene
  signatures (note that the GSVA analysis in the container does not
  include the full mSigDB metadata and so is unlikely to include all
  the paper references, I did include the code blocks which use the
  full 7.2 data, so it should be trivial to recapitulate that if one
  signs up a Broad and downloads the relevant data).  05wgcna is a
  copy of Alejandro's WGCNA work with some minor modifications.
  06classifier* is a series of documents I wrote to learn how to play
  with ML classifiers and was explicitly intended to not be published,
  but just a fun exercise.  07varcor_regression is a copy of Theresa's
  work to examine correlations between various metadata factors,
  surrogate variables, and her own explorations in ML; again with some
  minor changes which I think I noted.
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

Note: I executed the following _after_ running through all of the R
files in the working tree, so everything it needs should be attached
in the extant R session.  I am not sure if that is required, I think
renv might scan the cwd for dependencies or some other odd shenanigans.

## Performed in the working tree of the container

```{r, eval=FALSE}
library(renv)
setwd("/sw/singularity/cure_fail_host_analyses/data")
renv::init()
```

The above created the appropriate renv.lock and renv directory with
the new (empty) library and json configuration.  I suspect I will need
to manually edit one or more of these for a couple of git-derived
packages.  With that caveat in mind, let us create a fresh tree in tmp
and see what happens when I try to recreate the environment and use
it...

## Performed in /tmp/ using the bare-bones /usr/bin/R

```{bash, eval=FALSE}
mkdir -p /tmp/reproducible_test/renv
cd  /tmp/reproducible_test/renv
rsync -av /sw/singularity/cure_fail_host_analyses/data/renv* .
/usr/bin/R
## My 'normal' R is from an environment-module and has a pretty complete bioconductor
## installation for each of the last few bioconductor revisions. (I am a bit of a code hoarder)
## I am doing this in emacs via the interactive shell, YMMV
options(renv.config.install.transactional = FALSE)
source("renv/activate.R")
renv::restore()
renv::install("abelew/hpgltools")
```

yeah, this is pretty much like I remember, I love that it has all the
versions faithfully reproduced, but it is doing everything in serial
and will therefore take a seriously long time.  But, if it works I can
suck that up as the price of not being frustrated.  Watching it, I am
intrigued by the number of packages which give an error when
downloading, but are then successfully downloaded a second time.

<pre>
- Downloading bslib from CRAN ...                   ERROR [error code 22]
- Downloading bslib from CRAN ...               OK [5.8 Mb in 0.17s]
- Downloading sass from CRAN ...                    ERROR [error code 22]
- Downloading sass from CRAN ...                OK [2.9 Mb in 0.15s]
</pre>

Oh, it turns out having multiple repositories configured leads to the
above...  well, that is annoying.  Perhaps for this process I should
remove any repos options?

I am going to check where it is downloading everything to and see if I can
cache the downloads to make rebuilds of the container faster.  The
documentation makes explicit that it has a shared cache across all
packages, but I am not seeing any evidence in my testing that it is
being used on my base-metal host.  Assuming I get it working, I can
tell singularity to bind-mount that tree (wherever it is) and
that should be pretty awesome.  The docs tell me to look in
~/.cache/R/renv/cache ...  At least while the above is running that is
not getting populated (it looks like the downloads are going to
~/.cache/R/renv/source, so good enough for me?) .  I will check again
when(if) it finishes.  But I think therefore I will very much want to
have ~/.cache bind mounted when setting up the container image.

Oh, they nicely provide an environment variable for a global renv
cache: RENV_PATHS_CACHE

So, I should be able to put this in my /sw (I'm thinking
/sw/local/R/renv_cache done!) tree and then access it from the user which is
creating the docker/singularity container.  Oh man I hope that works,
I always feel like such an arsehole when I see the singularity install
log downloading everything.

In addition, a few things which compiled just fine using my
environment-modules R fail to compile in this environment.  I am not
sure why this would be, I have the same shell environment for all the
dependencies/gcc/etc as in my guix/environment-module R, hmph.

Example: S4Vectors causes restore() to stop() due to:

Rle_class.c:1136:17: error: format not a string literal and no format arguments [-Werror=format-security]
 1136 |                 error(errmsg);

Now, at a glance I can see that gcc _would_ be completely fine
compiling this except the S4Vectors compilation has -Wformat on. So that
is annoying but easily fixed.  ok wth I just manually installed
S4Vectors without a problem, no -Wall or -Wformat was set or anything;
is renv messing with CFLAGS (if so I cannot find where)?  This is
infuriating.  Nothing in my shell environment is setting Wall/Wformat,
wtf?  Ooohh perhaps the debian installed R is setting Wall in
/etc/R/Makeconf or whatever that file is...  Bingo, ok, turned off
Wformat in it.  Let us see if that helps the restore() (which, btw
still stop()s on error!

# Final notes
