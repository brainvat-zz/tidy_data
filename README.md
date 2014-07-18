# Tidy Data #

Project Assignment for Coursera [Getting and Cleaning Data](https://class.coursera.org/getdata-005/) by 
Jeff Leek, PhD, Brian Caffo, PhD, and Roger D. Peng, PhD, of John Hopkins Bloomberg
School of Public Health.  This course is part of the [Data Science Specialization Course](https://www.coursera.org/specialization/jhudatascience/1).

This code is the sole work of Allen Hammock ([brainvat](https://github.com/brainvat)).

**ATTENTION STUDENTS**

This repository contains code intended to complete an assignment for an online certification program.
This code should not be reviewed by any current students or any individuals planning to take
the course in the future except as provided in the course instructions.

## Repository contents ##

This repository contains a few files:

1. *README.md*, this readme file
2. *run_analysis.R*, an R script that will extract data from the Internet, process it according to a set of rules 
3. *CodeBook.md*, a markdown file that describes the extractions and transformations performed on the data

To learn more about the data set summarized in this project, please visit the [Human Activity Recognition Using Smartphones Data Set](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones) a part of the [UCI Machine Learning Repository](http://archive.ics.uci.edu/ml/index.html), or the [Course Syllabus](https://class.coursera.org/getdata-005/wiki/syllabus) for this project on Coursera.

## Project requirements ##

The *run_analysis.R* source file is an interactive R program that will download the UCI HAR
Data set from [a public repository](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip) performing the following required tasks on it:

1. Merge the training and the test sets to create one data set.
2. Extract only the measurements on the mean and standard deviation for each measurement.
3. Use descriptive activity names to name the activities in the data set.
4. Appropriately label the data set with descriptive variable names.
5. Creat a second, independent tidy data set with the average of each variable for each activity and each subject.
6. Save the file to the local working directory.

## How to use the code ##

First, make sure you have the required dependencies installed on your machine:

1. Install the plyr package, version 1.8.1 or newer
2. Install the reshape2 package, version 1.4 or newer

The code has been tested in R Studio v0.98.953 for Macintosh with R version 3.1.1 (2014-07-10).

To execute the source file and obtain the output results:

1. Make sure your current working directory is the same directory where you have saved the source file.
2. In your R shell, source the file. It will execute immediately.
3. Follow the interactive prompts to download and extract the data file from the public repository.  You do not need to download this file yourself.
4. The script will log its activities to the console.
5. When the script complets, open the *UCI_HAR_Dataset.tidy.txt* file in your favorite text editor or spreadsheet.  It is saved as a tab-delimited text file.

## Data dictionary ##

The output file consists of a tidy data set summarizing the average means and average
standard deviations of measurements made about activities observed through the gyroscope
and accelerameter of a mobile device.  The raw measurements in the original data set
were summarized the origianl researchers.

A complete desdription of the original measurements can be found [here](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones).

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
