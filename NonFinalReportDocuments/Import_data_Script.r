#Import data after you change into the directory where the data is stored
setwd("/Users/glori/Documents/GitHub/ORIE4741_Project")

full_data<-read.table("data_excel.csv",header=TRUE,sep=",",stringsAsFactors=FALSE)
#When importing we ran into a few issues such as some lines not having the correct number of elements, so added fill=TRUE for the blanks.

#Libraries Used
library(MASS)
library(class)
library(plyr)


#Data editing
#For ease of use and not using the Fill in feature which seems to be adding NA's everywhere, 
#we are going to edit the data by hand in Excel just so there are no blanks in the csv.
#The fields that are edited are documented in another .txt (Data_Editing.txt) file

#When creating the test and training data sets, we want to separate them out by wave, so that any inter-wave effects are gone
#We also note that we want to subdivide the test and training set by male/female so we can see if there are different variables
#that are strong predictors for men and women.
#Since each wave only has between 50 and 200 data points, median of 280, bootstrapping may be the best option to resample the
#data and have a better idea of the parameters of the model and their sensitivity.  Also we note that there are multiple 
#waves on each day, so it could be beneficial to combine the waves and treat them on a "per-day" basis as we hypothesize 
#that there is no overlap between the two sessions in a day.  In other words, we assume that the sets of people attending
#each session in one day is mutually exclusive.


#Create a temporary vector of the wave to date
date_vector<-1:length(full_data$wave)
for(i in 1:length(date_vector)){
	date_vector[i]<-check_date(full_data$wave[i])
}
#Assign the temporary vector to a new column in the data
full_data$day_num<-date_vector

	
##################General statistics##################
#How many waves
num_waves<-max(full_data[!is.na(full_data$wave),]$wave)

#Frequency of each wave, total and by gender
wave_freq<-table(full_data$wave)
wave_gender_freq<-table(full_data$wave,full_data$gender)

#How many matches 
#Need to divide by 2 to not double count for the "female" view and the "male" view
total_match<-sum(full_data$"match")/2

#Want to find the total number of interactions between people
#Need to do this manually for fail safe
check<-0
for (w in 1:num_waves){
	female_id<-unique(full_data[full_data$wave==w & full_data$gender==0,]$id)
	male_id<-unique(full_data[full_data$wave==w & full_data$gender==1,]$id)
	for (i in 1:length(female_id)){
		for (j in 1:length(male_id)){
			check<-check+1
		}
	}
}
total_interactions<-check

#Consider adding a field denoting whether or not the school that they went to 
#for undergraduate is an Ivy League school or other classification
#First get a unique list of the schools that they went to for undergraduate
undergraduate<-unique(full_data$undergra)

#Proportion of blanks
sum(full_data$undergra=="")/length(full_data$undergra)
#Output = 0.4134638

#Change all blanks to "Other"
full_data[full_data$undergra=="",]$undergra<-"Other"

#Then we get a list of 242 universities although note that some of them are the same but typed in differently
#i.e. "GW" could mean "George Washington University"
#Still have a lot of blanks or "Other" values so we 
#don't think that this is a reliable predictor for compatibility

#Since we are considering using race as a predictor, we also want to know the breakdown
#of the number of people in race overall and by gender
total_race_vector<-rep(0,6)
female_race_vector<-rep(0,6)
male_race_vector<-rep(0,6)

#For each wave, we get the male and female ids
#then for each of those, get the first value in the race vector and then increment
for (w in 1:num_waves){
	#List of female and male ids
	female_id<-unique(full_data[full_data$wave==w & full_data$gender==0,]$id)
	male_id<-unique(full_data[full_data$wave==w & full_data$gender==1,]$id)
	
	#Run through all the female ids first. 
	#Can do the female and male ids in separate loops since we're not comparing their race
	#Also the number of females can be different than the number of males in a wave
	for(i in 1:length(female_id)){
		race<-full_data[full_data$wave==w & full_data$gender==0 & full_data$id==female_id[i],]$race[1]
		total_race_vector[race]<-total_race_vector[race]+1
		female_race_vector[race]<-female_race_vector[race]+1
	}
	
	for (i in 1:length(male_id)){
		race<-full_data[full_data$wave==w & full_data$gender==1 & full_data$id==male_id[i],]$race[1]
		total_race_vector[race]<-total_race_vector[race]+1
		male_race_vector[race]<-male_race_vector[race]+1
	}
}

#Look at outputs
#race=5 corresponds to Native American
#race=3 corresponds to Hispanic--also historically a minority in higher education, unfortunately
#Thankfully if we add the female_race_vector and the male_race_vector we get the total_race_vector
total_race_vector
#Output: [1]  26 304  42 136   0  37

female_race_vector
#Output: [1]  16 142  25  71   0  16

male_race_vector
#Output: [1]  10 162  17  65   0  21