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
    #print(c(train_files, test_files))
}

date_processed <- date()

#t<-read.table(file=paste("./",f,"/",test_files[1],sep=""), header=FALSE)
#DT<-data.table(t)

# labels
cat("Reading feature and activity meta data...\n")
features <- read.table(file="UCI HAR Dataset/features.txt", header=FALSE)
activities <- read.table(file="UCI HAR Dataset/activity_labels.txt", header=FALSE) 
mean_features <- features[grepl("mean\\(\\)",features[,2]),]
std_features <- features[grepl("std\\(\\)",features[,2]),]

# test data
cat("Extracting feature means and standard deviations from test data...\n")
test_subjects.activities <- read.table(file=paste("./",f,"/",test_files[12],sep=""), header=FALSE)
names(test_subjects.activities) <- c("Activities")
test_subjects.features <- read.table(file=paste("./",f,"/",test_files[11],sep=""), header=FALSE)
test_subjects.id <- read.table(file=paste("./",f,"/",test_files[10],sep=""), header=FALSE)
names(test_subjects.id) <- c("ID")

test_subjects.means <- test_subjects.features[,mean_features[[1]]]
names(test_subjects.means) <- mean_features[[2]]

test_subjects.std <- test_subjects.features[,std_features[[1]]]
names(test_subjects.std) <- std_features[[2]]

test_subjects <- cbind(test_subjects.id, test_subjects.activities, test_subjects.means, test_subjects.std)

# train data
cat("Extracting feature means and standard deviations from training data...\n")
train_subjects.activities <- read.table(file=paste("./",f,"/",train_files[12],sep=""), header=FALSE)
names(train_subjects.activities) <- c("Activities")
train_subjects.features <- read.table(file=paste("./",f,"/",train_files[11],sep=""), header=FALSE)
train_subjects.id <- read.table(file=paste("./",f,"/",train_files[10],sep=""), header=FALSE)
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
#my_subjects <- dlply(all_subjects,.(ID, Activities))

cat("Processed ", nrow(all_subjects), " samples for ", (ncol(all_subjects)-2)/2, " features over a total of ", length(my_subjects), " subjects.\n\n", sep="")
cat("Means:\n\n")
print(as.factor(mean_features[[2]]))
cat("Standard Deviations:\n\n")
print(as.factor(std_features[[2]]))