#' validate_data Discharge timeseries screening
#' @description Function to check dataframe inputs for appropriate data classes and screen for missing values.
#' @param x A dataframe containing a vector of date values in the first column and vector of numeric flow values in the second column.
#' @param yearType A charcter of either "water" or "calendar" indicating whether to use water years or calendar years, respectively.
#' @return a data.frame with rows sorted by date.
#' @examples
#' x <- sampleData[c("date","discharge")]
#' yearType = "water"
#' validate_data(x=x,yearType=yearType)
#' @export
validate_data <- function(x,yearType) {
        
        #Just grab first two columns incase it has been run through validate_data already
        x <- x[,1:2]
        
        # Class variables
        col1_class = class(x[,1])
        col2_class = class(x[,2])
        
        ###Check dataframe inputs
        if(col1_class != "Date" && col2_class != "numeric")
        {
                warning("First column of x must contain a vector of class date.\nSecond column of x must contain a vector of class numeric.")
                return(FALSE)
        } else if (col1_class != "Date")
        {
                warning("First column of x must contain a vector of class date.") 
                return(FALSE)
        } else if (col2_class != "numeric" & col2_class != "integer")
        {
                warning("Second column of x must contain a vector of class numeric.") 
                return(FALSE)
        }
        if(!(yearType %in% c("water","calendar")))
        {
                warning("yearType must be one of either 'water' or 'calendar'")
                return(FALSE)
        }
        
        if(anyNA(x))
        {
                warning("dataframe x cannot contain NA values")
                return(FALSE)
        }
        
        ###rename dataframe for convenient use inside function
        names(x) <- c("date","discharge")
        
        ###Order by date
        x = dplyr::arrange(x, date)
        ###Get water year value
        if(yearType == "water")
        {
                x$year_val <- get_waterYear(x$date,numeric=T)
                x$day <- get_waterYearDay(x$date)
        } else {
                x$year_val <- lubridate::year(x$date)
                x$day <- lubridate::yday(x$date)
        }
        
        #check for complete years
        x$leapYear <- is.leapyear(as.numeric(as.character(x$year_val)))
        
        fullYearCheck <- dplyr::summarize(dplyr::group_by(x,year_val),
                                          completeYear = 
                                                  if(!any(leapYear)){
                                                          ifelse(length(day) == 365,T,F)
                                                  } else if (any(leapYear))
                                                  {
                                                          ifelse(length(day) == 366,T,F)
                                                  }
        )
        
        x$leapYear <- NULL
        if(any(fullYearCheck$completeYear==F))
        {
                incYears <- paste(fullYearCheck$year_val[fullYearCheck$completeYear == F],collapse = ",")
                warning(paste0("Every year as defined by the yearType argument must be complete, 
                    the following years have missing data: ",
                            incYears))
                return(FALSE)
        }
        
        return(x)
        
}
