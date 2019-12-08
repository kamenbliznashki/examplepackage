#' Load csv data
#'
#' A simple wrapper around readr read_csv to read and load raw csv data files.
#'
#' @import readr dplyr
#'
#' @param filename Character string with the filepath.
#' @param datadir Character string of the data directory. Default is NULL, in which case
#'   the package loads the built in datasets.
#' @return Returns a tibble dataframe of the parsed csv file.
#'
#' @examples
#' fars_read('accident_2015.csv.bz2')
#'
#' @export
fars_read <- function(filename, datadir=NULL) {
        if(is.null(datadir))
                datadir = system.file('extdata', package='examplepackage')
        filename = file.path(datadir, filename)
        if(!file.exists(filename))
                stop("file '", filename, "' does not exist")
        data <- suppressMessages({
                readr::read_csv(filename, progress = FALSE)
        })
        dplyr::tbl_df(data)
}

#' Make filename
#'
#' Construct filename for a dataset given the year of data collection
#'
#' @param year Numeric of the year of data to be included in the filename.
#' @return Character string of the filename composed of base name + year
make_filename <- function(year) {
        year <- as.integer(year)
        sprintf("accident_%d.csv.bz2", year)
}

#' Read years
#'
#' Load multiple datasets from a vector of the years of data to be loaded.
#'
#' @import dplyr
#'
#' @inheritParams fars_read
#' @param years Vector of numerics of the years of data to be loaded.
#' @return List of data frames giving month and year, each corresponding to
#'   the dataset for the year specified in the input.
#'
#' @note Data is assumed to be in the same folder as the script.
fars_read_years <- function(years, datadir=NULL) {
        lapply(years, function(year) {
                file <- make_filename(year)
                tryCatch({
                        dat <- fars_read(file, datadir)
                        dplyr::mutate(dat, year = year) %>%
                                dplyr::select(MONTH, year)
                }, error = function(e) {
                        warning("invalid year: ", year)
                        return(NULL)
                })
        })
}

#' Summarize years
#'
#' Load and summarize number of data records by year over several datasets
#'
#' @import dplyr tidyr
#'
#' @inheritParams fars_read
#' @param years Numeric vector of years of data to be loaded
#' @return Data frame summary of the number of records by month, by year.
#'
#' @examples
#' fars_summarize_years(c(2013,2015))
#'
#' @export
fars_summarize_years <- function(years, datadir=NULL) {
        dat_list <- fars_read_years(years, datadir)
        dplyr::bind_rows(dat_list) %>%
                dplyr::group_by(year, MONTH) %>%
                dplyr::summarize(n = n()) %>%
                tidyr::spread(year, n)
}

#' Map data by state
#'
#' Plot a map with locations of accident data for given state and year.
#'
#' @import dplyr
#' @importFrom maps map
#' @importFrom graphics points
#'
#' @inheritParams fars_read
#' @param state.num Numeric of the US state to be plotted (must be between 1 and 50).
#' @param year Numeric of the year of data to be accessed.
#' @return Nothing. Plots map with accident locations for state and year as function side effect.
#'
#' @note State id's available are:
#'   1  2  4  5  6  8  9 10 11 12 13 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34
#'   35 36 37 38 39 40 41 42 44 45 46 47 48 49 50 51 53 54 55 56
#'
#' @examples
#' fars_map_state(1, 2013)
#'
#' @export
fars_map_state <- function(state.num, year, datadir=NULL) {
        filename <- make_filename(year)
        data <- fars_read(filename, datadir)
        state.num <- as.integer(state.num)

        if(!(state.num %in% unique(data$STATE)))
                stop("invalid STATE number: ", state.num)
        data.sub <- dplyr::filter(data, STATE == state.num)
        if(nrow(data.sub) == 0L) {
                message("no accidents to plot")
                return(invisible(NULL))
        }
        is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
        is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
        with(data.sub, {
                maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
                          xlim = range(LONGITUD, na.rm = TRUE))
                graphics::points(LONGITUD, LATITUDE, pch = 46)
        })
}
