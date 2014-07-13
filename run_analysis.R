# Prompt the user to specify the directory of the source data, or
# download the data if has not already been retrieved
# 
# https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 
#

data_url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
destfile <- "UCI HAR Dataset"
zipfile <- "UCI_HAR_Dataset.zip"

cat("Searching files in working path ")
cat(getwd(), "\n\n", sep="")
data_files <- list.dirs(path = ".", recursive = FALSE, full.names = FALSE)

cat("Enter the number corresponding to the directory where the data resides:\n\n")
if (length(data_files) > 0) {
    for (i in 1:length(data_files)) {
        cat("[", i, "] ", data_files[i], "\n", sep="")
    }
    cat ("\nor,\n\n")
}

cat ("[0] download the data from the Internet\n\n")
n <- scan(what=integer(0), n=1, quiet=TRUE)

if((n >= 0) && (n <= length(data_files))) {
    if (n == 0) {
        if (file.exists(destfile)) {
            stop("There is already a directory called ", destfile, ". Please delete this directory and try again.", sep="")
        }
        cat("Downloading data file from Internet...\n\n")
        res <- download.file(url=data_url, destfile=zipfile, method="curl", mode="w")
        if (!file.exists(zipfile)) {
            stop("Unable to download the data from the Internet.\n\n")
        } else {
            res <- unzip(zipfile=zipfile,overwrite=FALSE)
            if (!file.exists(destfile)) {
                stop("Problem decompressing zip file from Internet\n\n")
            }
            f <- destfile
        }
    } else {
        f <- data_files[n]
    }
} else {
    stop("You must select a file from the list given.\n")
}

# Check to make sure the data file has what we're interested in

cat("Examining data in ", f, "...\n\n", sep="")
train_files <- list.files(f, recursive = TRUE, pattern="train.txt$")
test_files <- list.files(f, recursive = TRUE, pattern="test.txt$")
if ((length(train_files) < 1) || (length(test_files) < 1)) {
    stop("Directory ", f, " does not appear to have the data files we need to proceed.\n\n", sep="")
} else {
    cat("Found test and train data!\n\n")
    print(c(train_files, test_files))
}

date_processed <- date()

