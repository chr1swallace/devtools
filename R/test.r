#' Execute all \pkg{test_that} tests in a package.
#'
#' Tests are assumed to be located in a \code{inst/tests/} directory.
#' See \code{\link[testthat]{test_dir}} for the naming convention of test
#' scripts within that directory.
#'
#' If no testing infrastructure is present, you'll be asked if you want
#' devtools to create it for you (in interactive sessions only). See
#' \code{\link{add_test_infrastructure}} for more details.
#'
#' @param pkg package description, can be path or package name. See
#'   \code{\link{as.package}} for more information
#' @inheritParams testthat::test_dir
#' @inheritParams run_examples
#' @export
test <- function(pkg = ".", filter = NULL, fresh = FALSE) {
  check_testthat()
  pkg <- as.package(pkg)

  if (!uses_testthat(pkg) && interactive()) {
    message("No testing infrastructure found. Create it?")
    if (menu(c("Yes", "No")) == 1) {
      add_test_infrastructure(pkg)
    }
    return(invisible())
  }

  test_path <- find_test_dir(pkg$path)
  test_files <- dir(test_path, "^test.*\\.[rR]$")
  if (length(test_files) == 0) {
    message("No tests found: no files matching pattern '^test.*\\.[rR]$'",
      "found in ", test_path)
    return(invisible())
  }

  message("Testing ", pkg$package)
  if (fresh) {
    to_run <- bquote({
      require("devtools", quiet = TRUE)
      require("testthat", quiet = TRUE)

      load_all(.(pkg$path), quiet = TRUE)
      test_dir(.(test_path), filter = .(filter))
    })
    eval_clean(to_run)
  } else {
    # Run tests in a child of the namespace environment, like
    # testthat::test_package
    load_all(pkg)
    env <- new.env(parent = ns_env(pkg))
    with_envvar(r_env_vars(), test_dir(test_path, filter = filter, env = env))
  }
}

find_test_dir <- function(path) {
  testthat <- file.path(path, "tests", "testthat")
  if (dir.exists(testthat)) return(testthat)

  inst <- file.path(path, "inst", "tests")
  if (dir.exists(inst)) return(inst)

  stop("No testthat directories found in ", path, call. = FALSE)
}

#' Return the path to one of the packages in the devtools test dir
#'
#' Devtools comes with some simple packages for testing. This function
#' returns the path to them.
#'
#' @param package Name of the test package.
#' @keywords internal
#' @examples
#' if (has_tests()) {
#' devtest("testData")
#' }
#' @export
devtest <- function(package) {
  stopifnot(has_tests())

  path <- system.file(package = "devtools", "tests", "testthat", package)
  if (path == "") stop(package, " not found", call. = FALSE)

  path
}

uses_testthat <- function(pkg = ".") {
  pkg <- as.package(pkg)

  paths <- c(
    file.path(pkg$path, "inst", "tests"),
    file.path(pkg$path, "tests", "testthat")
  )

  any(dir.exists(paths))
}


check_testthat <- function() {
  if (!require("testthat")) {
    stop("Please install testthat", call. = FALSE)
  }
}
