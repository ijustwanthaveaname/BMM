################################################################################
# Stan-related utility functions for BMM
################################################################################

#' Check whether CmdStan is installed
#'
#' Internal helper function to check if CmdStan is available
#' via \pkg{cmdstanr}.
#'
#' @return Logical. TRUE if CmdStan is installed, FALSE otherwise.
#' @keywords internal
check_cmdstan_installed <- function() {
  tryCatch({
    cmdstanr::cmdstan_version()
    TRUE
  }, error = function(e) {
    FALSE
  })
}

#' Check Stan setup for BMM
#'
#' Check whether \pkg{cmdstanr} and CmdStan are properly installed
#' and available for running BMM models.
#'
#' This function does not install anything and is safe to run
#' in non-interactive environments.
#'
#' @return Invisibly returns TRUE if the Stan environment is ready,
#' FALSE otherwise.
#'
#' @export
check_stan_setup <- function() {

  # Check cmdstanr package
  if (!requireNamespace("cmdstanr", quietly = TRUE)) {
    message(
      "cmdstanr is not installed.\n",
      "Install with:\n",
      "  install.packages(\n",
      "    'cmdstanr',\n",
      "    repos = c('https://stan-dev.r-universe.dev', getOption('repos'))\n",
      "  )"
    )
    return(invisible(FALSE))
  }

  # Check CmdStan binary
  if (!check_cmdstan_installed()) {
    message(
      "CmdStan is not installed.\n",
      "After installing cmdstanr, run:\n",
      "  cmdstanr::install_cmdstan()"
    )
    return(invisible(FALSE))
  }

  # Everything looks good
  version <- tryCatch(
    cmdstanr::cmdstan_version(),
    error = function(e) "unknown"
  )

  message(
    "✓ Stan environment ready\n",
    sprintf("  CmdStan version: %s", version)
  )

  invisible(TRUE)
}

#' Check BMM runtime environment
#'
#' Perform a lightweight check of system and Stan-related
#' requirements needed to run BMM.
#'
#' This function does not install any dependencies.
#'
#' @param verbose Logical. Whether to print detailed messages.
#'
#' @return Invisibly returns TRUE if all required components
#' are available, FALSE otherwise.
#'
#' @export
setup_bmm_environment <- function(verbose = TRUE) {

  ok <- TRUE

  # Check TBB environment variable
  if (Sys.getenv("TBB_CXX_TYPE") == "") {
    if (verbose) {
      message("TBB_CXX_TYPE is not set (recommended: 'gcc')")
    }
    ok <- FALSE
  } else if (verbose) {
    message(sprintf("✓ TBB_CXX_TYPE = '%s'", Sys.getenv("TBB_CXX_TYPE")))
  }

  # Check cmdstanr + CmdStan
  if (!requireNamespace("cmdstanr", quietly = TRUE)) {
    if (verbose) {
      message("cmdstanr package is not installed")
    }
    ok <- FALSE
  } else if (!check_cmdstan_installed()) {
    if (verbose) {
      message("CmdStan is not installed")
    }
    ok <- FALSE
  } else if (verbose) {
    version <- tryCatch(
      cmdstanr::cmdstan_version(),
      error = function(e) "unknown"
    )
    message(sprintf("✓ CmdStan available (version %s)", version))
  }

  if (verbose) {
    if (ok) {
      message("✓ BMM environment looks ready")
    } else {
      message(
        "⚠️  Some requirements are missing.\n",
        "Run install_bmm_dependencies() for installation guidance."
      )
    }
  }

  invisible(ok)
}

