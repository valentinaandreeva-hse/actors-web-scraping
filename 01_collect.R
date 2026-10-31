# ============================================================
# Title:  Downloading html pages
# Author: Valentina Andreeva
# Date:   2026-10-24
# ============================================================
#
# Source URL: https://en.wikipedia.org/wiki/List_of_actors_with_Hollywood_Walk_of_Fame_motion_picture_stars
#
# Date of collection: October 24, 2026.
#
# Robots.txt and terms were checked, web scraping is allowed.
# ============================================================

# ---- Packages ----
packages <- c("tidyverse", "rvest", "httr", "here", "stringr")
# missing <- packages[!(packages %in% installed.packages()[, "Package"])]
# if (length(missing) > 0) install.packages(missing)
invisible(lapply(packages, library, character.only = TRUE))

# Code to avoid problems with PC username on cyrillics
# ascii_tmp <- "C:/Rtmp"
# dir.create(ascii_tmp, showWarnings = FALSE, recursive = TRUE)
# Sys.setenv(TMPDIR = ascii_tmp, TMP = ascii_tmp, TEMP = ascii_tmp)

# This file is additional and its purpose is to automatically download the required
# pages for further web scraping. Since there are about 950 of them, downloading
# them automatically will be much more convenient and efficient.

# ---- Constants ----
# First, let's state the parsing settings in accordance with the rules of politeness:
# we will set a user agent with a contact email address and a 2-second interval
# between requests so that we do not overload the site. Moreover, robots.txt allows
# parsing and the terms do not forbid it.

MY_UA   <- "HSE-SPb Advanced Data Analysis course, assignment (contact: there_was_my_email)"
DELAY_S <- 2
OUT_DIR <- "data/raw"
TIMEOUT <- 60
TRIES   <- 3

# Now let's set a timeout for httr and create a folder where we will save the pages.

httr::set_config(httr::timeout(TIMEOUT))
dir.create(OUT_DIR, showWarnings = FALSE)

# ---- Parsing from the main page ----
# Let's specify the file from which we will extract pages, and write a function to do so.
# We need to retrieve links to actors from the second table on the main actors page.

main_file <- "data/raw/main_list.html"

main_page <- read_html(main_file)
all_tables <- main_page %>% html_elements("table")

tbl_node <- all_tables[[2]]

# Now let's extract the links to the actors' pages from the main page.

urls <- tbl_node %>% html_elements("tr") %>% .[-1] %>%
  map_chr(\(row) {
    a <- row %>% html_element("td:nth-child(1) a")
    if (length(a) == 0) NA_character_ else html_attr(a, "href")
  }) %>%
  na.omit() %>%
  url_absolute(base = "https://en.wikipedia.org")

# Let's extract the article titles from the links so we can name the files after the articles.

titles <- urls %>%
  str_remove("^https://en\\.wikipedia\\.org/wiki/") %>%
  URLdecode()

safe_title <- titles %>%
  str_replace_all("[^A-Za-z0-9_\\-]+", "_") %>%
  str_replace_all("_+", "_") %>%
  str_remove("^_|_$") %>%
  str_sub(1, 80)

files <- file.path(OUT_DIR,
                   sprintf("%03d_%s.html", seq_along(urls), safe_title))

# ---- Working with the actors' pages ----
# Now let's create a function to download the pages themselves.
# To make the download process more efficient, we have added a feature
# that prevents already downloaded articles from being downloaded again.

already_ok <- file.exists(files) & file.size(files) > 5000

download_one <- function(url, file) {
  if (file.exists(file) && file.size(file) > 5000) return("already")
  for (i in seq_len(TRIES)) {
    Sys.sleep(DELAY_S)
    resp <- tryCatch(
      httr::GET(url, httr::user_agent(MY_UA), httr::timeout(TIMEOUT)),
      error = function(e) NULL
    )
    if (!is.null(resp) && !httr::http_error(resp)) {
      txt <- httr::content(resp, "text", encoding = "UTF-8")
      if (nchar(txt) > 5000) {
        writeLines(txt, con = file, useBytes = TRUE)
        return("ok")
      }
    }
    if (i < TRIES) Sys.sleep(5 * i)
  }
  "failed"
}

results <- character(length(urls))
t0 <- Sys.time()

# ---- Downloading actors' articles ----
# And finally, let's download our articles.

for (i in seq_along(urls)) {
  if (i %% 10 == 0 || i == 1) {
    done   <- sum(results[seq_len(i - 1)] %in% c("ok", "already"))
    elapsed <- as.numeric(difftime(Sys.time(), t0, units = "mins"))
    eta     <- if (i > 1) elapsed / (i - 1) * (length(urls) - i + 1) else NA
    cat(sprintf("[%4d / %4d] saved=%4d  elapsed=%.1f min  ETA=%.1f min\n",
                i, length(urls), done, elapsed, eta))
  }
  results[i] <- download_one(urls[i], files[i])
}