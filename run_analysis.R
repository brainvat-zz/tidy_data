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

while (!file.exists("./run_analysis.R")) {
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
train_files <- list.files(f, recursive = TRUE, pattern="train.txt$")
test_files <- list.files(f, recursive = TRUE, pattern="test.txt$")
all_files <- list.files(f, recursive = TRUE)

if ((length(train_files) < 1) || (length(test_files) < 1)) {
    stop("Directory ", f, " does not appear to have the data files we need to proceed.\n\n", sep="")
} else {
    #print(c(train_files, test_files))
}

date_processed <- date()

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

# test data
cat("Extracting feature means and standard deviations from test data...\n")

if(is.na(index.test.labels <- match(x="test/y_test.txt", test_files))) {
    stop("Unable to find the labels for the test set.\n")
} else {
    test_subjects.activities <- read.table(file=paste("./",f,"/",test_files[index.test.labels],sep=""), header=FALSE)
    names(test_subjects.activities) <- c("ActivityID")
    test_subjects.activities <- merge(x=test_subjects.activities, y=activities, by="ActivityID", all.x=TRUE)
}

if(is.na(index.test.data_set <- match(x="test/X_test.txt", test_files))) {
    stop("Unable to find the data for the test set.\n")
} else {
    test_subjects.features <- read.table(file=paste("./",f,"/",test_files[index.test.data_set],sep=""), header=FALSE)    
}

if(is.na(index.test.subject_ids <- match(x="test/subject_test.txt", test_files))) {
    stop("Unable to find the subject IDs for the test set.\n")
} else {
    test_subjects.id <- read.table(file=paste("./",f,"/",test_files[index.test.subject_ids],sep=""), header=FALSE)
    names(test_subjects.id) <- c("ID")    
}

test_subjects.means <- test_subjects.features[,mean_features[[1]]]
names(test_subjects.means) <- mean_features[[2]]

test_subjects.std <- test_subjects.features[,std_features[[1]]]
names(test_subjects.std) <- std_features[[2]]

test_subjects <- cbind(test_subjects.id, test_subjects.activities, test_subjects.means, test_subjects.std)

# train data
cat("Extracting feature means and standard deviations from training data...\n")

if(is.na(index.train.labels <- match(x="train/y_train.txt", train_files))) {
    stop("Unable to find the labels for the train set.\n")
}

if(is.na(index.train.data_set <- match(x="train/X_train.txt", train_files))) {
    stop("Unable to find the data for the train set.\n")
}

if(is.na(index.train.subject_ids <- match(x="train/subject_train.txt", train_files))) {
    stop("Unable to find the subject IDs for the test set.\n")
}

train_subjects.activities <- read.table(file=paste("./",f,"/",train_files[index.train.labels],sep=""), header=FALSE)
names(train_subjects.activities) <- c("ActivityID")
train_subjects.activities <- merge(x=train_subjects.activities, y=activities, by="ActivityID", all.x=TRUE)
train_subjects.features <- read.table(file=paste("./",f,"/",train_files[index.train.data_set],sep=""), header=FALSE)
train_subjects.id <- read.table(file=paste("./",f,"/",train_files[index.train.subject_ids],sep=""), header=FALSE)
names(train_subjects.id) <- c("ID")
train_subjects.means <- train_subjects.features[,mean_features[[1]]]
names(train_subjects.means) <- mean_features[[2]]

train_subjects.std <- train_subjects.features[,std_features[[1]]]
names(train_subjects.std) <- std_features[[2]]

train_subjects <- cbind(train_subjects.id, train_subjects.activities, train_subjects.means, train_subjects.std)

# merge test and train sets

#require(plyr)
cat("Merging test and training data...\n")
all_subjects <- rbind(test_subjects, train_subjects)
my_subjects <- split(all_subjects, f=as.factor(all_subjects$ID))
my_activities <- split(all_subjects, f=as.factor(all_subjects$ActivityLabel))

#my_subjects <- dlply(all_subjects,.(ID, Activities))

cat("Means:\n\n")
print(as.factor(mean_features[[2]]))
cat("Standard Deviations:\n\n")
print(as.factor(std_features[[2]]))

cat("Processed ", nrow(all_subjects), " samples for ", length(names(all_subjects))-3, " features over a total of ", length(my_subjects), " subjects.\n\n", sep="")
