---
title: "run_analysis"
author: "André Burati"
date: "23 de agosto de 2014"
output: html_document
---

This is an R Markdown document. Markdown is a simple formatting syntax for authoring HTML, PDF, and MS Word documents. For more details on using R Markdown see <http://rmarkdown.rstudio.com>.

When you click the **Knit** button a document will be generated that includes both content as well as the output of any embedded R code chunks within the document. You can embed an R code chunk like this:

run_analysis
============

About the Project
------------------

> The purpose of this project is to demonstrate your ability to collect, work with, and clean a data set. The goal is to prepare tidy data that can be used for later analysis. You will be graded by your peers on a series of yes/no questions related to the project. You will be required to submit: 1) a tidy data set as described below, 2) a link to a Github repository with your script for performing the analysis, and 3) a code book that describes the variables, the data, and any transformations or work that you performed to clean up the data called CodeBook.md. You should also include a README.md in the repo with your scripts. This repo explains how all of the scripts work and how they are connected.  
> 
> One of the most exciting areas in all of data science right now is wearable computing - see for example this article . Companies like Fitbit, Nike, and Jawbone Up are racing to develop the most advanced algorithms to attract new users. The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 
> 
> http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 
> 
> Here are the data for the project: 
> 
> https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 
> 
> You should create one R script called run_analysis.R that does the following. 
> 
> 1. **DONE** Merges the training and the test sets to create one data set.
> 2. **DONE** Extracts only the measurements on the mean and standard deviation for each measurement.
> 3. **DONE** Uses descriptive activity names to name the activities in the data set.
> 4. **DONE** Appropriately labels the data set with descriptive activity names.
> 5. **DONE** Creates a second, independent tidy data set with the average of each variable for each activity and each subject. 
> 
> Good luck!

Set up the Environment
-------------

Loading the packages


```r
library("data.table")
library("reshape2")
```

Set folder as the working dir to store and find the files of the project


```r
folder <- getwd()
f <- "Dataset.zip"
```


Getting the data from internet into the `UCI HAR Dataset` folder
------------

Downloading the file


```r
download.file("https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip", file.path(folder, f))
datasetfiles <- file.path(folder, "UCI HAR Dataset")
list.files(datasetfiles, recursive=TRUE)
```


Reading all files inside the `UCI HAR Dataset` folder
--------------

Reading the subject and activity files.


```r
subtrain <- fread(file.path(datasetfiles, "train", "subject_train.txt"))
subtest  <- fread(file.path(datasetfiles, "test" , "subject_test.txt" ))
actrain <- fread(file.path(datasetfiles, "train", "Y_train.txt"))
actest  <- fread(file.path(datasetfiles, "test" , "Y_test.txt" ))
```

Reading the data files with `read.table` and converting to a data table.


```r
readingdatafiles <- function (f1) {
  f2 <- read.table(f1)
	data <- data.table(f2)
}
train <- readingdatafiles(file.path(datasetfiles, "train", "X_train.txt"))
test  <- readingdatafiles(file.path(datasetfiles, "test" , "X_test.txt" ))
```

Merging the training and test sets
--------------

Concatenate the data tables.


```r
subject <- rbind(subtrain, subtest)
setnames(subject, "V1", "subject")
activity <- rbind(actrain, actest)
setnames(activity, "V1", "activityNum")
data <- rbind(train, test)
```

Merge columns and sort data table in ascending order


```r
subject <- cbind(subject, activity)
data <- cbind(subject, data)
setkey(data, subject, activityNum)
```


Extracting the mean and std dev
---------------


```r
features <- fread(file.path(datasetfiles, "features.txt"))
setnames(features, names(features), c("featureNum", "featureName"))
features <- features[grepl("mean\\(\\)|std\\(\\)", featureName)]
features$featureCode <- features[, paste0("V", featureNum)]
#head(features)
features$featureCode
```

```
##  [1] "V1"   "V2"   "V3"   "V4"   "V5"   "V6"   "V41"  "V42"  "V43"  "V44" 
## [11] "V45"  "V46"  "V81"  "V82"  "V83"  "V84"  "V85"  "V86"  "V121" "V122"
## [21] "V123" "V124" "V125" "V126" "V161" "V162" "V163" "V164" "V165" "V166"
## [31] "V201" "V202" "V214" "V215" "V227" "V228" "V240" "V241" "V253" "V254"
## [41] "V266" "V267" "V268" "V269" "V270" "V271" "V345" "V346" "V347" "V348"
## [51] "V349" "V350" "V424" "V425" "V426" "V427" "V428" "V429" "V503" "V504"
## [61] "V516" "V517" "V529" "V530" "V542" "V543"
```

```r
s <- c(key(data), features$featureCode)
data <- data[, s, with=FALSE]
```


Use descriptive activity names
------------------------------


```r
activitynames <- fread(file.path(datasetfiles, "activity_labels.txt"))
setnames(activitynames, names(activitynames), c("activityNum", "activityName"))
```


Label with descriptive activity names
-----------------------------------------------------------------

Merge activity labels.


```r
data <- merge(data, activitynames, by="activityNum", all.x=TRUE)
```

Add `activityName` as a key.


```r
setkey(data, subject, activityNum, activityName)
```

Melt the data table to reshape it from a short and wide format to a tall and narrow format.


```r
data <- data.table(melt(data, key(data), variable.name="featureCode"))
```

Merge activity name.


```r
data <- merge(data, dtFeatures[, list(featureNum, featureCode, featureName)], by="featureCode", all.x=TRUE)
```

Create a new variable, `activity` that is equivalent to `activityName` as a factor class.
Create a new variable, `feature` that is equivalent to `featureName` as a factor class.


```r
data$activity <- factor(data$activityName)
data$feature <- factor(data$featureName)
```

Seperate features from `featureName` using the helper function `grepdata`.


```r
grepdata <- function (x) {
  grepl(x, data$feature)
}
## Features with 2 categories
n <- 2
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepdata("^t"), grepdata("^f")), ncol=nrow(y))
data$featDomain <- factor(x %*% y, labels=c("Time", "Freq"))
x <- matrix(c(grepdata("Acc"), grepdata("Gyro")), ncol=nrow(y))
data$featInstrument <- factor(x %*% y, labels=c("Accelerometer", "Gyroscope"))
x <- matrix(c(grepdata("BodyAcc"), grepdata("GravityAcc")), ncol=nrow(y))
data$featAcceleration <- factor(x %*% y, labels=c(NA, "Body", "Gravity"))
x <- matrix(c(grepdata("mean()"), grepdata("std()")), ncol=nrow(y))
data$featVariable <- factor(x %*% y, labels=c("Mean", "SD"))
## Features with 1 category
data$featJerk <- factor(grepdata("Jerk"), labels=c(NA, "Jerk"))
data$featMagnitude <- factor(grepdata("Mag"), labels=c(NA, "Magnitude"))
## Features with 3 categories
n <- 3
y <- matrix(seq(1, n), nrow=n)
x <- matrix(c(grepdata("-X"), grepdata("-Y"), grepdata("-Z")), ncol=nrow(y))
data$featAxis <- factor(x %*% y, labels=c(NA, "X", "Y", "Z"))
```

Create a tidy data set
----------------------

Create a data set with the average of each variable for each activity and each subject.


```r
setkey(data, subject, activity, featDomain, featAcceleration, featInstrument, featJerk, featMagnitude, featVariable, featAxis)
tidydata <- data[, list(count = .N, average = mean(value)), by=key(data)]
```

Generate the codebook


```r
knit("codebook.Rmd", output="codebook.md", quiet=TRUE)
```

```
## [1] "codebook.md"
```

```r
markdownToHTML("codebook.md", "codebook.html")
```
