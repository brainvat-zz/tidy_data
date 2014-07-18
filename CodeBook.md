# Tidy Data Codebook #

Please refer to the *README.md* file in this archive for a description of the purpose
of this code and the requirements it satisfies.

## Overview ##

*run_analysis.R* is designed to be run interactively from an R shell such as R Studio. The code has been written to fail gracefully when the system is unable to find the libraries it needs. The console window will show a series of messages giving diagnostic information about the code's progress processing the file.

The script will detect whether or not the data it needs to process has already been downloaded on previous runs.  The user will be prompted to decide if they want to use the data already decompressed in the current working directory.

Finally, the code does some basic error checking to make sure the data files it requires have been successfully loaded into the working directory.

## Data dictionary ##

*run_analysis.R* produces a summarized set consisting of 5 variables and 2 measures:

* **SubjectID** - the ID of the original subject from the UCI study, one of 30 individuals
* **ActivityLabel** - a description of the activity observed in the subject, one of 6 actions including:
    - Walking,
    - Walking Upstairs,
    - Walking Downstairs,
    - Sitting,
    - Standing, or 
    - Laying
* **Domain** - the domain of the summary measure, either Time or Frequency series
* **Signal** - the raw or dervied measure observed by the original researchers, one of 13 features including:
    - Body Acceleration,
    - Gravity Acceleration,
    - Body Acceleration Jerk,
    - Body Raw Gyroscope,
    - Body Raw Gyroscope Jerk,
    - Body Acceleration Magnitude,
    - Gravity Acceleration Magnitude,
    - Body Acceleration Jerk Magnitude,
    - Body Raw Gyroscope Magnitude,
    - Body Raw Gyroscope Jerk Magnitude,
    - Body Body Acceleration Jerk Magnitude,
    - Body Body Raw Gyroscope Magnitude, or
    - Body Body Raw Gyroscope Jerk Magnitude
* **Axial** - the axial dimension of the raw measurement, either X, Y or Z for the accelerometer or gyroscope; the value is "na" for measures where there are no axial components
* **AverageMean** - the average of the recorded normalized feature means as observed by the original researchers 
* **AverageStandardDeviation** - the average of the recorded normalized feature standard deviations as observed by the original researchers


## Script structure ##

The script begins executing its task immediately after being sourced into the shell.  The user does not need to provide any script parameters or environment variables.  This ensures that the final output data the user obtains is identical to the output produced for the original programmer and for other students.

The script relies on several convenience functions to output diagnostic information to the console window.  Except for the initial user interaction to specify the source of the data files, no further input or interaction is required by the user.  The logging information is provided only to assure the user that processing is on-going.

## Script algorithm ##

### 1. Download and decompress the original data ###

The script creates its utlitiy functions at the top of the file and begins the interactive parts of the program at line 273:

    load_library("plyr")
    load_library("reshape2")
    
    results <- do_processing()

If the required libraries are not installed on the machine, or the user has not set the current working directory to the same location as the source code, the script will produce and error and exit.

The `do_processing()` function handles all of the key data processing tasks.  The script requires that the decompressed data files be present in the working directory, but it does not require the folder have a set name. The user can download the ZIP file with the compressed data and decompress it manually to their working directory if they wish.

The script also gives the user the option of allowing the script to fetch the file from the Internet and decompress it:

    [0] download the data from the Internet

By entering 0 at the prompt, the script will download and extract the data file and complete all processing tasks without further input.  Alternatively, the user can enter the number that corresponds to the folder they created themselves through a manual download.

### 2. Load data files into memory and merge sets into a single data frame. ###

In line 184, the script starts to load the data files into memory.  First the list of feature labels are processed.  The raw feature names are changed into new values using mixed case and full words to make the labels easily recognizable and readable.

    h("Reading signal and activity meta data")
    
    if(is.na(index.features <- match(x="features.txt", all_files))) {
        stop("Unable to find the feature list for the data set.\n")
    } else {
        file.features <- paste("./", f, "/", all_files[index.features], sep="")
        features <- read.table(file=file.features, header=FALSE)
        features[,2] <- sapply(features[,2], USE.NAMES = FALSE, FUN=function(x) gsub("Mag", " Magnitude", x))
        features[,2] <- sapply(features[,2], USE.NAMES = FALSE, FUN=function(x) gsub("Jerk", " Jerk", x))

This process continues for the activity labels ("Walking", "Laying", etc.) in line 203. The labels are converted from their original **UPCASE** format to a natural mixed case format with spaces as separators.  

Spaces are chosen here because the labels are presented in the tidy data set as values, not as column headings.  Since all of the values are unique, this preserves the original data structure while improving readability for the end user.  The column headings in the final tidy ouptut, by contrast, uses **CamelCase** format to make machine processing of the header values more reliable.

With the variable labels and measure labels loaded into memory, the training and test observations can be loaded starting on line 213:

    # process test and training data sets
    data.list <- list()
    datasets <- c("test", "train")
    for (i in 1:length(datasets)) {
        dataset <- datasets[i]
        h("Extracting signal means and standard deviations from ", dataset, " data")
        data.list[[i]] <- compile_features(which=dataset, path=f, files=all_files, means=mean_features, stds=std_features, activities=activities)
    }

To avoid code duplication between the training and data sets, we use a convenience function `compile_features()` to do the work of loading in the original source data and melting the rows into an intermediate format that will later be made tidy before output.  Moving to line 75, we can see that several merge operations are performed:

        subjects.activities <- merge(x=subjects.activities, y=activities, by="ActivityID", all.x=TRUE)

This merges the activity labels with the observation measures for each subject. We load the signal data and subject IDs in lines 84 and 93 respectively, extracting only the features where the original researchers recorded mean values on line 99:

    subjects.means <- subjects.features[,means[[1]]]

On line 104 we capture the standard deviations as well:

    subjects.std <- subjects.features[,stds[[1]]]

This meets the original project requirements (see **README.md**, line 31) by discarding all other features except those whose labels match `mean()` or `std()`.  

Finally, on line 109, we bind the columns together containing the Subject IDs, Activity Labels, Means, and Standard Deviations:

    result <- cbind(subjects.id, subjects.activities, subjects.means, subjects.std)

We return the result back to the `do_processing()` function for further processing. The test and training sets are bound together on line 230:

            all_subjects <- rbind(all_subjects, data.list[[n]])

The results are returned to the main global scope on line 275.

### 3. Melt the data, calculate the means, and cast the results into a tidy format for output. ###

Finally, in the last steps of the procedure we take the combined test and training sets, which have already been reduced down to the required mean and standard deviation measurements, and boil them down into the tidy format.  This requires transforming the data through two intermediate steps.

First, one line 302, we use the `ddply()` function from the *plyr* library to melt the data and calculate the means.  We do not use the `melt()` function, preferring to prepare the data into a melted format using our own algorithm. 

    not_tidy <- ddply(prepared_data, c("SubjectID", "ActivityLabel"), function(df) apply(df[,c(my_features)], 2, mean))

We effectively achieve this melting in lines 282-318 by iterating over the original data frame produced by `do_processing()` and casting each row into the melted form:

    # create empty almost tidy data frame
    new_columns <- c(my_groups,additional_features)
    almost_tidy <- data.frame(matrix(vector(), 0, length(new_columns), dimnames=list(c(), new_columns)), stringsAsFactors=F)
    
    # loop over the untidy data set and build up the almost tidy version
    for (i in 1:nrow(not_tidy)) {
        new_frame <- cast_row(not_tidy[i,])
        summarize_file(filename=paste("not_tidy row ", i, sep=""), data=new_frame)
        almost_tidy <- rbind(almost_tidy, new_frame)
    }

As the code suggests, we're *almost* tidy here, but not quite. The problem is, `almost_tidy` has only one measure per variable per row, separating out the means and standard deviations on separate rows in the data frame.

    > head(almost_tidy)
      SubjectID ActivityLabel Domain                Signal Axial     measure  mean_value
    1         1       Walking   Time     Body Acceleration     X AverageMean  0.26569692
    2         1       Walking   Time     Body Acceleration     Y AverageMean -0.01829817
    3         1       Walking   Time     Body Acceleration     Z AverageMean -0.10784573
    4         1       Walking   Time  Gravity Acceleration     X AverageMean  0.74486741
    5         1       Walking   Time  Gravity Acceleration     Y AverageMean -0.08255626
    6         1       Walking   Time  Gravity Acceleration     Z AverageMean  0.07233987

But, a careful study of the [Tidy Data](http://vita.had.co.nz/papers/tidy-data.pdf) paper by R Studio's Hadley Wickham, suggests that this is not tidy.  Instead, as Wickham notes in his example (Table 12), there should be "one variable in each column, and each row represents a day's observations". 

Thus, on line 321, we use the `dcast()` function from the **reshape2** library to rotate the measures out of the rows and back into the columns to make the final set tidy:

    tidy <- dcast(almost_tidy, SubjectID + ActivityLabel + Domain + Signal + Axial ~ measure)

`dcast()` transforms the data into the desired form, guessing that the `mean_value` column from the melted data is the desired measure in the tidy output, using `measure` row value as the new column name.

### 4. Save tidy output to disk. ###

To make loading the data back into a new data frame or spreadsheet easy, we export the data as a tab-separated data file with headers and inform the user that the script is complete.

The user can interact with the resulting data frame by exploring the `tidy` data frame in the global environment.

    > head(tidy)
      SubjectID ActivityLabel Domain                Signal Axial AverageMean AverageStandardDeviation
    1         1       Walking   Time     Body Acceleration     X  0.26569692               -0.5457953
    2         1       Walking   Time     Body Acceleration     Y -0.01829817               -0.3677162
    3         1       Walking   Time     Body Acceleration     Z -0.10784573               -0.5026457
    4         1       Walking   Time  Gravity Acceleration     X  0.74486741               -0.9598594
    5         1       Walking   Time  Gravity Acceleration     Y -0.08255626               -0.9511506
    6         1       Walking   Time  Gravity Acceleration     Z  0.07233987               -0.9258176

Alternatively, the user can load the data from disk into their favorite editor:

    system("open UCI_HAR_Dataset.tidy.txt")
    

