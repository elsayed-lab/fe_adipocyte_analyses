#!/usr/bin/env Rscript
setwd("/data")
## This script will perform the installation of the various tools I want
## into a renv tree and save the results to a renv.lock file.
## Then it will deactivate so that the actual R session will work.

## Start with the bioconductor release from /versions.txt

## 'MHOM' is sufficiently distinct that it will get the L.panamensis MHOM/COL strain from tritrypdb.
github_pkgs <- c(
  "js229/Vennerable", "YuLab-SMU/ggtree", "davidsjoberg/ggsankey")
  ##  "reesyxan/iDA", "abelew/hpgldata", "abelew/hpgltools", "abelew/EuPathDB", "dviraran/xCell")
local_pkgs <- c("hpgltools")
random_helpers <- c(
  "BSgenome", "CMplot", "devtools", "flashClust", "forestplot", "ggbio", "glmnet", "irr",
  "lares", "patchwork", "ranger", "renv", "rpart", "rpart.plot", "tidyverse", "xgboost")

start_options <- options(configure.args.preprocessCore = "--disable-threading",
                         renv.config.install.transactional = FALSE,
                         renv.config.cache.symlinks = FALSE)
source("/data/renv/activate.R")
renv_attempted <- try(renv::restore(prompt = FALSE))
if ("try-error" %in% class(renv_attempted)) {
  warning("renv failed, this will attempt to recover, but shenanigans may happen.")
}
symlinked <- R.utils::createLink(link = "/data/R", target = renv::paths$library())

## Hopefully at this point we have an environment which matches my workstation
## But I have found that cannot be truly guaranteed, so let us double-check
renv_installed <- as.data.frame(installed.packages())[["Package"]]

for (i in local_pkgs) {
  dep_pkgs <- remotes::dev_package_deps(i, dependencies = "Depends")[["package"]]
  missing_idx <- ! dep_pkgs %in% renv_installed
  if (sum(missing_idx) > 0) {
    missing_dep <- dep_pkgs[missing_idx]
    message("Installing still-missing Depends for ", i, ": ", toString(missing_dep))
    for (j in missing_dep) {
      installedp <- try(renv::install(j, prompt = FALSE))
    }
  } else {
    message("Yay, all entries in the Depends are installed!")
  }

  import_pkgs <- remotes::dev_package_deps(i, dependencies = "Imports")[["package"]]
  missing_idx <- ! import_pkgs %in% renv_installed
  if (sum(missing_idx) > 0) {
    missing_import <- import_pkgs[missing_idx]
    message("Installing still-missing Imports for ", i, ": ", toString(missing_import))
    for (j in missing_import) {
      installedp <- try(renv::install(j, prompt = FALSE))
    }
  } else {
    message("Yay, all the imports are installed!")
  }

  suggest_pkgs <- remotes::dev_package_deps(i, dependencies = "Suggests")[["package"]]
  missing_idx <- ! suggest_pkgs %in% renv_installed
  if (sum(missing_idx) > 0) {
    missing_suggests <- suggest_pkgs[missing_idx]
    message("Installing still-missing Suggests for ", i, ": ", toString(missing_suggests))
    for (j in missing_suggests) {
      installedp <- try(renv::install(j, prompt = FALSE))
    }
  } else {
    message("Yay, all the suggests are installed!")
  }
  local_installedp <- try(renv::install(glue::glue("/data/{i}"), prompt = FALSE))
}

missing_helper_idx <- ! random_helpers %in% renv_installed
if (sum(missing_helper_idx) > 0) {
  missing_helpers <- random_helpers[missing_helper_idx]
  message("Install a few helper packages of interest that are not explicitly in my DESCRIPTION.")
  for (j in missing_helpers) {
    installedp <- try(renv::install(j, prompt = FALSE))
  }
}

missing_github_idx <- ! github_pkgs %in% renv_installed
missing_github <- github_pkgs[missing_github_idx]
if (sum(missing_github_idx) > 0) {
  for (pkg in missing_github) {
    github_installed <- try(renv::install(pkg, prompt = FALSE))
    Sys.sleep(5)
  }
}

message("Rebuilding preprocessCore with disable-threading just in case restore() didn't")
installedp <- try(renv::install("preprocessCore", rebuild = TRUE, prompt = FALSE))

renv_options <- options(start_options)
renv::deactivate()
