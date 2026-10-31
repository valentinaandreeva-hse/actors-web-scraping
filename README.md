# actors-web-scraping

A reproducible R web-scraping project that collects Wikipedia data on actors with Hollywood Walk of Fame motion picture stars and prepares a clean dataset for analyzing which factors are associated with Oscar wins.

---

## Table of contents

- [Project overview](#project-overview)
- [Research question](#research-question)
- [Data source & collection](#data-source--collection)
- [Repository structure](#repository-structure)
- [Dataset description](#dataset-description)
- [References](#references)

---

## Project overview

This project downloads and parses Wikipedia pages for actors who have a star on the Hollywood Walk of Fame (motion picture category). It combines:

1. **Structured data** from the main Wikipedia list table (name, sex, birth year, death year, age, address, induction year, age at star, Oscar status);
2. **Unstructured data** parsed from each actor's individual Wikipedia infobox (country of birth, number of children).

The result is a clean, analysis-ready dataset (`actors_oscar.csv`) with **944 actors and 10 variables**, intended as the input for a subsequent logistic regression analysis of Oscar wins.

---

## Research question

> **RQ:** What factors are associated with whether a person has won an Oscar?

Predictors for logistic regression model include sex, age, year of birth, location on the Walk of Fame (Vine Street vs. Hollywood Boulevard), age at induction, number of children, and country of birth. The binary target variable is `oscar_won`.

---

## Data source & collection

- **Source:** [List of actors with Hollywood Walk of Fame motion picture stars — Wikipedia](https://en.wikipedia.org/wiki/List_of_actors_with_Hollywood_Walk_of_Fame_motion_picture_stars)
- **Date of collection:** 2026-10-24
- **Method:**
  - The main list page is saved locally as `data/raw/main_list.html`.
  - Links to individual actor pages are extracted from the second table.
  - Each actor page is downloaded separately into `data/raw/` using the script `01_collect.R`.

### Politeness policy

The scraping code follows polite crawling rules:

- Custom **User-Agent** string with a contact email;
- **2-second delay** between requests;
- **Timeout** of 60 seconds and up to **3 retries** per request;
- Downloaded pages are cached locally so that re-running the script does not re-download existing files;
- `robots.txt` and Wikipedia terms were checked beforehand and permit scraping for this kind of use.

Because all interaction with the site is handled in `01_collect.R` and all parsing happens offline, the main analysis (`Actors_web_scraping.Rmd`) is **fully reproducible** even if the live pages change.

---

## Repository structure

.
├── README.md                    # This file
├── 01_collect.R                 # Downloads actor HTML pages from Wikipedia
├── Actors_web_scraping.Rmd      # Main reproducible report (scraping + EDA)
├── Actors_web_scraping.html     # Rendered HTML report
├── Actors_web_scraping.pdf      # Rendered PDF report
├── preamble.tex                 # LaTeX preamble for PDF styling
├── style.css                    # CSS for HTML report styling
└── actors_oscar.csv             # Clean analysis dataset

---

## Dataset description

- **File:** `actors_oscar.csv`
- **Rows:** 944
- **Columns:** 10

| Variable | Type | Role | Description |
|---|---|---|---|
| `actor` | character | Identifier | Full name of the actor |
| `sex` | character | Control | `M` / `F` |
| `age` | integer | Control | Age of the actor (at death or current age) |
| `address` | character | Predictor | Walk of Fame location: `Vine Street` or `Hollywood Boulevard` |
| `birth_country` | factor | Predictor | Country of birth: `United States`, `United Kingdom`, `Canada`, `Australia`, `Other` |
| `n_children` | integer | Predictor | Number of children (values > 50 treated as missing) |
| `oscar_won` | character | **Target** | `1` = won an Oscar, `0` = nominated / not won |
| `birth_year` | integer | Predictor | Year of birth |
| `inducted_year` | integer | Predictor | Year the star was added |
| `age_at_star` | integer | Predictor | Age at induction |

### Target variable details

`oscar_won` is binary and has **no missing values**:

- `1` — the actor won at least one Academy Award;
- `0` — the actor was nominated or did not win.

Nominations are deliberately collapsed into “not won” to keep the target binary for logistic regression.

## References

Wikipedia contributors. (2026, October 24). List of actors with Hollywood Walk of Fame motion picture stars. In *Wikipedia*. Retrieved October 24, 2026, from https://en.wikipedia.org/wiki/List_of_actors_with_Hollywood_Walk_of_Fame_motion_picture_stars
