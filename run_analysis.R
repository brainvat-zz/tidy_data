######################
# Utility functions
######################

# make a repeating string
makeNstr <- function(str, num) {
    paste(rep(str, num), collapse="")
}

# print out row and column counts for a data table
summarize_file <- function(filename, data) {
    cat("From ", filename, " processed ", nrow(data), " rows and ", length(names(data)), " columns.\n")
}

# print out a data frame in fixed width format
# can't use write.fwf because it doesn't handle column header widths properly
# http://stackoverflow.com/questions/13590887/print-a-data-frame-with-columns-aligned-as-displayed-in-r
print.to.file <- function(df, filename) {
    cnames <- colnames(df)
    n      <- as.matrix(nchar(cnames))
    
    d <- apply(df, 2, format)
    n <- apply(cbind(n, nchar(d[1,])), 1, max)
    
    fmts <- paste0("%",n, "s")
    for(i in 1:length(cnames)) {
        cnames[i] <- sprintf(fmts[i], cnames[i])
        d[,i] <- sprintf(fmts[i], trim(d[,i]))
    }
    d <- rbind(cnames, d)
    write.table(d, filename, quote=F, row.names=F, col.names=F)
    return(n)
}

# create a horizontal rule
hr <- function(l=60) {
    return(paste(makeNstr("-", l), "\n", sep=""))
}

# create a header wrapped in horizontal rules
h <- function(..., above=1, below=1, rule=60) {
    cat(paste(makeNstr("\n", above), hr(l=rule), ..., "\n", hr(l=rule), makeNstr("\n", below), sep=""))
}

######################
# processing functions
######################

# merge feature and meta data into a data frame
compile_features <- function(which, path, files, means, stds, activities) {
    
    # fetch the activity labels
    if(is.na(index.labels <- match(x=paste(which, "/y_", which, ".txt", sep=""), files))) {
        stop(paste("Unable to find the labels for the ", which, " set.\n", sep=""))
    } else {
        file.labels <- paste("./", path,"/", files[index.labels], sep="")
        subjects.activities <- read.table(file=file.labels, header=FALSE)
        names(subjects.activities) <- c("ActivityID")
        subjects.activities <- merge(x=subjects.activities, y=activities, by="ActivityID", all.x=TRUE)
        summarize_file(filename=file.labels, data=subjects.activities)
    }
    
    # fetch the feature data
    if(is.na(index.data_set <- match(x=paste(which, "/X_", which, ".txt", sep=""), files))) {
        stop(paste("Unable to find the data for the ", which, " set.\n", sep=""))
    } else {
        file.subjects.features <- paste("./", path,"/", files[index.data_set], sep="")
        subjects.features <- read.table(file=file.subjects.features, header=FALSE)    
        summarize_file(filename=file.subjects.features, data=subjects.features)
    }
    
    # fetch the subject IDs
    if(is.na(index.subject_ids <- match(x=paste(which, "/subject_", which, ".txt", sep=""), files))) {
        stop(paste("Unable to find the subject IDs for the ", which, " set.\n", sep=""))
    } else {
        file.subjects.id <- paste("./", path,"/", files[index.subject_ids], sep="")
        subjects.id <- read.table(file=file.subjects.id, header=FALSE)
        names(subjects.id) <- c("SubjectID")    
        summarize_file(filename=file.subjects.id, data=subjects.id)
    }
    
    # prepare the labels for the mean features
    subjects.means <- subjects.features[,means[[1]]]
    names(subjects.means) <- means[[2]]
    summarize_file(filename="subjects.means (internal data)", data=subjects.means)
    
    # prepare the labels for the standard deviation features
    subjects.std <- subjects.features[,stds[[1]]]
    names(subjects.std) <- stds[[2]]
    summarize_file(filename="subjects.std (internal data)", data=subjects.std)
    
    # merge everything together into one data frame and return
    result <- cbind(subjects.id, subjects.activities, subjects.means, subjects.std)
    summarize_file(filename="compiled_subjects (internal data)", data=result)
    return(result)
}

# prompt user for data and compile internal tidy data set
do_processing <- function() {
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
    
    h("Examining data in ", f)
    all_files <- list.files(f, recursive = TRUE)
    raw_sample_files <- grep(pattern="Inertial Signals", list.files(f, recursive=TRUE, pattern=".txt$"), value=TRUE)
    
    if (length(raw_sample_files) < 1) {
        stop("Directory ", f, " does not appear to have the data files we need to proceed.\n\n", sep="")
    }
    
    date_processed <- date()
    h("Processing data on ", date_processed)
    
    #t<-read.table(file=paste("./",f,"/",test_files[1],sep=""), header=FALSE)
    #DT<-data.table(t)
    
    # labels
    h("Reading feature and activity meta data")
    
    
    if(is.na(index.features <- match(x="features.txt", all_files))) {
        stop("Unable to find the feature list for the data set.\n")
    } else {
        file.features <- paste("./", f, "/", all_files[index.features], sep="")
        features <- read.table(file=file.features, header=FALSE)
        mean_features <- features[grepl("mean\\(\\)",features[,2]),]
        std_features <- features[grepl("std\\(\\)",features[,2]),]
        summarize_file(filename=file.features, data=features)
    }
    
    if(is.na(index.activity_labels <- match(x="activity_labels.txt", all_files))) {
        stop("Unable to find the feature list for the data set.\n")
    } else {
        file.activity_labels <- paste("./", f, "/", all_files[index.activity_labels], sep="")
        activities <- read.table(file=file.activity_labels, header=FALSE) 
        names(activities) <- c("ActivityID", "ActivityLabel")
        activities$ActivityLabel <- gsub("(^|[[:space:]])([[:alpha:]])", "\\1\\U\\2", gsub("_", tolower(activities$ActivityLabel), replacement=" "), perl=TRUE)
        summarize_file(filename=file.activity_labels, data=activities)
    }
    
    # process test and training data sets
    data.list <- list()
    datasets <- c("test", "train")
    for (i in 1:length(datasets)) {
        dataset <- datasets[i]
        h("Extracting feature means and standard deviations from ", dataset, " data")
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

    summarize_file(filename="all_subjects (internal data)", data=all_subjects)
    return(all_subjects)
}

# prepare column names for tidy output
tidy_names <- function(df) {
    names <- names(df)    
}

# make variance from std deviation
make_variance <- function(n) {
    n*n
}

# cast an untidy frame into a tidy one
cast_row <- function(row) {
  this_frame <- data.frame(matrix(vector(), 0, length(new_columns), dimnames=list(c(), new_columns)), stringsAsFactors=F)
  for (i in 3:ncol(not_tidy)) {
    this_vector <- variable_list[[c(names(not_tidy)[i])]]        
    new_row <- data.frame(matrix(vector(), 1, length(new_columns), dimnames=list(c(), new_columns)), stringsAsFactors=F)
    new_row[c("SubjectID")] <- row[c("SubjectID")]  
    new_row[c("ActivityLabel")] <- row[c("ActivityLabel")]
    new_row[c("kind")] <- this_vector[c("kind")]
    new_row[c("feature")] <- this_vector[c("feature")]
    new_row[c("dimension")] <- this_vector[c("dimension")]
    new_row[c("measure")] <- this_vector[c("measure")]
    new_row[c("mean_value")] <- row[i]
    this_frame <- rbind(this_frame, new_row)
  }
  return(this_frame)
}

######################
# Main work script
######################

# Do the processing

library(plyr)

results <- do_processing()
my_subjects <- split(results, f=as.factor(results$SubjectID))
my_activities <- split(results, f=as.factor(results$ActivityLabel))

h("Processed ", nrow(results), " samples for ", length(names(results))-3, " features in ", length(my_activities), " activities over a total of ", length(my_subjects), " subjects.")

# prepare data for taking averages
prepared_data <- results[,!(names(results) %in% c("ActivityID"))]
my_features <- names(prepared_data[!(names(prepared_data) %in% c("SubjectID", "ActivityLabel"))])
my_groups <- names(prepared_data[(names(prepared_data) %in% c("SubjectID", "ActivityLabel"))])
mean_features <- grepl("mean\\(\\)",names(prepared_data))
std_features <- grepl("std\\(\\)",names(prepared_data))
grouping_features <- c("kind", "feature", "dimension")
additional_features <- c(grouping_features, "measure", "mean_value")
tidy_features <- c(my_groups, grouping_features)

# take the averages of the variances, not the original standard deviations
# per http://stats.stackexchange.com/questions/25848/how-to-sum-a-standard-deviation
#
# however, our standard deviations are NORMALIZED to a range of -1,1
# so I don't think we should follow these rules
# and instead just take the mean of the values given
#
# variances <- as.data.frame(apply(prepared_data[,std_features], 2, make_variance))
# prepared_data <- cbind(prepared_data[,!std_features], variances)

# first, calculate the means of the feature measures
not_tidy <- ddply(prepared_data, c("SubjectID", "ActivityLabel"), function(df) apply(df[,c(my_features)], 2, mean))
h("Calculated means of feature measures in untidy data set of ", nrow(not_tidy), " rows with ", length(names(not_tidy)), " columns of output.")

# decompose features into multiple variables with two measures (mean and standard deviation)
variable_list <- sapply(X = my_features, FUN=strsplit, split="-")
variable_list <- lapply(variable_list, FUN = function(v) { as.factor(c(kind=(if (substring(v[1], 1, 1) == "t") "time" else "frequency"), feature=substring(v[1], 2), dimension=(if(length(v) == 3) v[3] else "none"), measure=(if(v[2] == "std()") "standard deviation" else "mean")))})

# create empty almost tidy data frame
new_columns <- c(my_groups,additional_features)
almost_tidy <- data.frame(matrix(vector(), 0, length(new_columns), dimnames=list(c(), new_columns)), stringsAsFactors=F)

# loop over the untidy data set and build up the almost tidy version
for (i in 1:nrow(not_tidy)) {
  new_frame <- cast_row(not_tidy[i,])
  summarize_file(filename=paste("not_tidy row ", i, sep=""), data=new_frame)
  almost_tidy <- rbind(almost_tidy, new_frame)
}

# tidy up by casting the data frame 
tidy <- dcast(almost_tidy, SubjectID + ActivityLabel + kind + feature + dimension ~ measure)
tidy.file <- "UCI_HAR_Dataset.tidy.txt"

# alternatively, print to a fixed width format 
# tidy.formats <- print.to.file(tidy, tidy.file)

write.table(tidy, tidy.file, sep="\t", quote=FALSE, row.names=FALSE)
h("Wrote tidy data set of ", nrow(tidy), " rows with ", length(names(tidy)), " columns of output to file ", tidy.file)
