
compile_features <- function(which, path, files, means, stds, activities) {
    
    # fetch the activity labels
    if(is.na(index.labels <- match(x=paste(which, "/y_", which, ".txt", sep=""), files))) {
        stop(paste("Unable to find the labels for the ", which, " set.\n", sep=""))
    } else {
        subjects.activities <- read.table(file=paste("./", path,"/", files[index.labels],sep=""), header=FALSE)
        names(subjects.activities) <- c("ActivityID")
        subjects.activities <- merge(x=subjects.activities, y=activities, by="ActivityID", all.x=TRUE)
    }
    
    # fetch the feature data
    if(is.na(index.data_set <- match(x=paste(which, "/X_", which, ".txt", sep=""), files))) {
        stop(paste("Unable to find the data for the ", which, " set.\n", sep=""))
    } else {
        subjects.features <- read.table(file=paste("./", path,"/", files[index.data_set],sep=""), header=FALSE)    
    }
    
    # fetch the subject IDs
    if(is.na(index.subject_ids <- match(x=paste(which, "/subject_", which, ".txt", sep=""), files))) {
        stop(paste("Unable to find the subject IDs for the ", which, " set.\n", sep=""))
    } else {
        subjects.id <- read.table(file=paste("./", path,"/", files[index.subject_ids],sep=""), header=FALSE)
        names(subjects.id) <- c("ID")    
    }
    
    # prepare the labels for the mean features
    subjects.means <- subjects.features[,means[[1]]]
    names(subjects.means) <- means[[2]]
    
    # prepare the labels for the standard deviation features
    subjects.std <- subjects.features[,stds[[1]]]
    names(subjects.std) <- stds[[2]]
    
    # merge everything together into one data frame and return
    return(cbind(subjects.id, subjects.activities, subjects.means, subjects.std))
}

main <- function() {
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
    
    if (!file.exists("./run_analysis.R")) {
        stop("Please select the working directory where this script was executed before proceeding.\n")
    }
    
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
    all_files <- list.files(f, recursive = TRUE)
    raw_sample_files <- grep(pattern="Inertial Signals", list.files(f, recursive=TRUE, pattern=".txt$"), value=TRUE)
    
    if (length(raw_sample_files) < 1) {
        stop("Directory ", f, " does not appear to have the data files we need to proceed.\n\n", sep="")
    }
    
    cat(paste("Processing data on ", date_processed <- date(), "\n\n", sep=""))
    
    #t<-read.table(file=paste("./",f,"/",test_files[1],sep=""), header=FALSE)
    #DT<-data.table(t)
    
    # labels
    cat("Reading feature and activity meta data...\n")
    
    if(is.na(index.features <- match(x="features.txt", all_files))) {
        stop("Unable to find the feature list for the data set.\n")
    } else {
        features <- read.table(file=paste("./", f, "/", all_files[index.features], sep=""), header=FALSE)
        mean_features <- features[grepl("mean\\(\\)",features[,2]),]
        std_features <- features[grepl("std\\(\\)",features[,2]),]   
    }
    
    if(is.na(index.activity_labels <- match(x="activity_labels.txt", all_files))) {
        stop("Unable to find the feature list for the data set.\n")
    } else {
        activities <- read.table(file=paste("./", f, "/", all_files[index.activity_labels], sep=""), header=FALSE) 
        names(activities) <- c("ActivityID", "ActivityLabel")
        activities$ActivityLabel <- gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", gsub("_", tolower(activities$ActivityLabel), replacement=" "), perl=TRUE)
    }
    
    # process test and training data sets
    data.list <- list()
    datasets <- c("test", "train")
    for (i in 1:length(datasets)) {
        dataset <- datasets[i]
        cat("Extracting feature means and standard deviations from ", dataset, " data...\n", sep="")
        data.list[[i]] <- compile_features(which=dataset, path=f, files=all_files, means=mean_features, stds=std_features, activities=activities)
    }

    # merge the data and return it
    numsets <- length(data.list)
    if (numsets < 1) {
        stop("There was a problem processing the data set.\n")
    }
    all_subjects <- data.list[[1]]
    if (numsets > 1) {
        for(n in 2:numsets) {
            all_subjects <- rbind(all_subjects, data.list[[n]])
        }
    }

    return(all_subjects)
}

# Do the processing

results <- main()
my_subjects <- split(results, f=as.factor(results$ID))
my_activities <- split(results, f=as.factor(results$ActivityLabel))

cat("Processed ", nrow(results), " samples for ", length(names(results))-3, " features over a total of ", length(my_subjects), " subjects.\n\n", sep="")
