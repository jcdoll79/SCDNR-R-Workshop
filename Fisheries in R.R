#R code built around Introductory Fisheries Analysis with R
#Ogle, D.H. 2016. Introductory Fisheries Analyses with R. Chapman & Hall/CRC, Boca Raton, FL.

################################################
########Day 2: Fisheries Analysis in R##########
################################################


####Topics################################
#   Age-length keys
#   Size structure
#   Weight-length relationships
#   Condition factors
#   Mortality
#   Individual growth
#   Stock-Recruitment
#   Population Estimates
#########################################

#Load packages for today
library(FSA)
library(FSAdata)
library(nlstools)  #needed for calculating 95% confidence intervals
library(ggplot2)
library(dplyr)


#Age-length keys#######
#1. Add length intervals
#2. Separate data into and "age" and "length" data frame
#3. Create a frequency table
#4. Create a proportions table
#5. Apply age-length key to fish without an age
#6. Summarize length at age.

#Load a bass data set from Florida, name includes an upper case "O" not zero
RockBassLO2 <- FSAdata::RockBassLO2

#Add length intervals
#Requires column with lengths, the data frame name, a numeric value 
#identifying the starting length measurement and the width of the length 
#measurement category
RockBassLO2 <- lencat(~tl,data=RockBassLO2,
                      startcat=110,w=10)
head(RockBassLO2)
#Data contains missing age values, NA. We want to assign ages based on the ALK. 

#First create an "age" data frame with all complete records
rb.age <- RockBassLO2 %>%
          dplyr::filter( !is.na(age) )

head(rb.age)

#then create a "length" data frame with records with missing ages.
#Note the only difference from above is the !
rb.len <- RockBassLO2 %>%
          dplyr::filter( is.na(age) )

head(rb.len)

#Construct the age-length key

#Use the xtabs() function to construct a contingency table of the number of 
#fish in each length and age category. The row variable is the first argument 
#and the column variable is the second argument
rb.raw <- xtabs(~LCat+age,data=rb.age)
rb.raw

#convert counts to proportions using the prop.table() function. Requires the 
#table created above and margin=1.
#margin=1 tells R to calculate proportions by row
#margin=2 tells R to calculate proportions by column
rb.key <- prop.table(rb.raw,margin=1)
rb.key


######################################
#Can construct age-length key in a single block of code
rb.key <- xtabs(~LCat+age,data=rb.age) %>%
          prop.table(margin=1)
######################################


#Visualizing Age-Length key
alkPlot(rb.key, type = "area", showLegend = TRUE,
        leg.cex = 0.7, xlab = "Total Length (mm)")

#Bubble size is proportional to the number of fish 
#in each length interval
alkPlot(rb.key, type = "bubble", 
        xlab = "Total Length (mm)")


#now we are ready to assign ages to individuals without ages. This example 
#uses a semi-random method of assigning ages to individuals
#Suppose there are 20 fish in a length category that need assigned an age and
#the age-length key says that 75% in the length category are age-6 and 25% are age-7. 
#The age assignment for age-6 is (0.75 * 20) = 15
#The age assignment for age-7 is (0.25 * 20) = 5

#What about the fractional assignments for 22 fish?
#(0.75 * 22) = 16.5
#(0.25 * 22) = 5.5
#FSA rounds down so that 16 fish are assigned age-6 and 5 fish are assigned age-7.

#The remaining fish is assigned to age-6 with a 
#probability of 0.75 or age-7 with a probability of 0.25

rb.len1 <- alkIndivAge(rb.key, age ~ tl, 
                       data = rb.len, 
                       type = c("SR"))
head(rb.len)
head(rb.len1)

#Combine aged and unaged (but with new ages) samples
rb.combined <- rbind(rb.age, rb.len1)
dim(rb.combined)
dim(rb.age)
dim(rb.len1)

# Calculate mean length-at-age assuming fully 
#random selection
Summarize(tl~age,data=rb.combined,digits=2)

# age frequency distribution
af <- xtabs(~age,data=rb.combined)
# proportional age distribution
ap <- prop.table(af)
ap


#Calculate mean length-at-age following Bettoli and Miranda 2001. 
#Used when fish are aged with a stratified design to get number of 
#fish in each length interval in the entire sample.

#Generate number per length class
len.n <- xtabs(~LCat,data=RockBassLO2)

#Calculate mean length at age and SD
alkMeanVar(rb.key, tl ~ LCat + age, 
           data = rb.age, 
           len.n = len.n)




#Size structure#######
#1. Length Frequency
#2. PSD

#Load Largemouth Bass data from the FSAdata package
LMBassBL <- FSAdata::LMBassBL 

#Add a length category column
LMBassBL$lcat10 <- lencat(LMBassBL$tl , w=10)

#Check data to confirm
headtail(LMBassBL)

#Create a length frequency table
#Using the xtabs function, requires the column name 
#with length category and the dataset
LMBFreq10 <- xtabs(~lcat10, data = LMBassBL)
#print frequency table
LMBFreq10

#Percentage of fish in each interval using the 
#prop.table() function
LMBPer10 <- round( prop.table(LMBFreq10) * 100 , 1)
#print proportion table
LMBPer10


#A histogram can be useful to visualize 
#length frequencies
ggplot(LMBassBL, aes(x = tl)) + 
  geom_histogram(breaks = seq(from = 70 , to = 390, by = 10),
                 fill = "orange", color = "black")


###Histogram practice#############
#Add "Total Length (mm)" to the x-axis label
#Add "Frequency" to the y-axis label

###Answer################
ggplot(LMBassBL, aes(x = tl)) + 
  geom_histogram(breaks = seq(from = 70 , to = 390, 
                              by = 10),
                 fill = "orange", color = "black") +
  xlab("Total Length (mm)") +
  ylab("Frequency")+
  theme( text = element_text(family="serif"))
###End Answer###########


###PSD####
#FSA contains a list of Gabelhouse (1984) 
#length categories
psdVal("Largemouth Bass")

#Use psdVal() to return list of available species
psdVal()


#The units returned are in mm but you can request 
#cm, mm, or in
psdVal("Largemouth Bass", units = "cm")
psdVal("Largemouth Bass", units = "mm")
psdVal("Largemouth Bass", units = "in")

#Assign length category to each fish to the Largemouth Bass data frame

#Load the LMBassBL data set
LMBassBL  <- FSAdata::LMBassBL 
help(LMBassBL)

#First we need to pull out the Largemouth Bass 
#length categories
lmb.cuts <- psdVal("Largemouth Bass", units = "mm")

#Filter based on tl greater then stock length and add the length category column
LMB_SS <- LMBassBL  %>%
  dplyr::filter( tl >= lmb.cuts["stock"]) %>%
  dplyr::mutate( gcat = lencat(tl, breaks = lmb.cuts,
                        use.names = TRUE))

headtail(LMB_SS)

#Calculate a frequency table across size groups
xtabs(~gcat, data = LMB_SS)

#Calculate all PSD-X values and 95% Confidence Intervals. Requires length column, data set, 
#species, and what type. Types available are incremental (e.g., Stock to Quality) or
#traditional (e.g., Quality, Preferred, Memorable)
psdCalc(~tl, data=LMB_SS, 
        species = "Largemouth Bass", 
        what = "traditional")


#Break?

#Weight-length relationships#######
#Load Chinook data from the FSA package
ChinookArg <- FSA::ChinookArg

#Plot TL vs TW on the natural log scale
ggplot(ChinookArg, aes(x = log(tl), y = log(w))) +
  geom_point() +
  xlab("ln(total Length) (mm)") + 
  ylab("ln(total Weight) (g)")


#Estimate parameters of the weight-length model 
#using lm()
lm1 <- lm(log(w) ~ log(tl), data=ChinookArg)

#Extract summary information and send to a new object
sumlw <- summary(lm1)
sumlw

#Extract coefficients and send to a new object
coeflw <- coef(lm1)
coeflw

#Extract confidence intervals for coefficients
confinlw <- confint(lm1)
confinlw


#Exercise 3

#Lunch?


#Condition factors#######
#1. Fulton's Condition Factor
#2. Weight-length residuals
#3. Relative weight

#Load Bluegill data from the FSA package
BLG <- FSAdata::BluegillLM  
help(BluegillLM)
#Select the data and calculate log10 of 
#length and weight

BLGSub <- BLG %>%
  mutate(logW = log10(wght), logL = log10(tl)) %>%  #take log10
  select( -c(sl, fl, sernum))  #remove excess columns

headtail(BLGSub)

#Fulton's Condition Factor
#Describes condition of individual fish
#Metric: K = W / L^3 * 100,000
#English: K = W / L^3 * 10,000

BLGSub <- BLGSub %>% 
  mutate(K = wght / (tl^3) * 100000)

headtail(BLGSub)


#Weight-Length Residuals
#Estimate coefficients of weight-length model
lm1 <- lm(logW ~ logL, data = BLGSub)
coef(lm1)
residuals(lm1)
#Calculate weight residuals
#Weight residuals are the difference between the observed log10 weight and predicted log10 weight
#Residuals can tell you if the fish is plumper or skinnier than average.

BLGSub <- BLGSub %>%
  mutate(lwresid = residuals(lm1))

headtail(BLGSub)

#Plot residuals
ggplot(BLGSub, aes(x = seq(from=1,to=nrow(BLGSub)), y = lwresid)) +
  geom_point() +
  geom_hline(yintercept=0)


#Relative Weight
#Wr = W / Ws * 100 (where Ws is the standard weight given length)
#Ws = 10 ^ (alpha + beta * log10(TL))

#FSA contains a list of standard weights from a variety of sources
#Return list of available species
wsVal()

#View the table of coefficients with references
View(WSlit)

#Return standard weight coefficients for one species
wsVal("Bluegill", units = "metric")

#Return a simplified object for calculation
wsBlg <- wsVal("Bluegill", units="metric", 
               simplify = TRUE)

#How to reference the intercept and slope
wsBlg
wsBlg$int
wsBlg$slope

#Add Ws and Wr column
BLGSub <- BLGSub %>%
  mutate(Ws = 10 ^ (wsBlg$int + wsBlg$slope * logL ),
         Wr = wght/Ws * 100)

headtail(BLGSub)



#Mortality#######
#This example will calculate instantaneous total mortality (Z)

#Create a data frame for say, Brook Trout
bkt <- data.frame(age=1:7,
                  ct=c(49,155,112,45,58,12,8))
bkt

#Create a quick scatterplot with log(ct) to 
#identify the descending limb of the catch curve
ggplot(bkt, aes(x = age, y = log(ct))) +
  geom_point() +
  xlab("Age (years)") + 
  ylab("ln(count)")

#The catchCurve() function requires
#1. Formula in the form of catch ~ age
#2. A data argument, does not have to contain only the descending limb.
#3. A required age2use argument that specifies the ages to use

bktcc <- catchCurve(ct ~ age, data = bkt, ages2use=2:7)

#The summary function will return
#the instantaneous mortality (Z)
#and annual mortality (A)
summary(bktcc)

#the plot() function will create a plot of the 
#catch curve
plot(bktcc)



###Mortality Practice#############
#Create a catch curve of the data below.
#Calculate Z and A from the following data frame
lmbcatch <- data.frame(age=1:8,
          ct=c(102, 325, 230, 150, 99, 45, 12, 6))

###Answer########
ggplot(lmbcatch, aes(x = age, y = log(ct))) +
  geom_point() +
  xlab("Age (years)") + 
  ylab("ln(count)")
lmbcc <- catchCurve(ct ~ age, data = lmbcatch, 
                    ages2use=2:8)
summary(lmbcc)
plot(lmbcc)

###End Answer###########



#LVB growth model#######
#1. Select data
#2. Specify the growth model
#3. Specify starting values and estimate parameters
#4. Summarize results

#Code for fitting a von Bertalanffy Growth Model

#Load Croaker2 data from the FSAdata package
Croaker2 <- FSAdata::Croaker2

help("Croaker2")

#Subset to only Males
crm <- subset(Croaker2, sex=="M")


#plot the data to visualize trends
ggplot(crm, aes(x = age, y = tl)) +
  geom_point() +
  xlab("Age (years)") + 
  ylab("Total Length (mm)")

#Select the von Bertalanffy Growth model to use
#"typical" will use the traditional LVB model
# Linf * (1 - exp(-K * (t - t0)))
vbT <- vbFuns("typical")


#Use the non-linear least squares algorithm to 
#estimate parameters. vbT() arguments must be in 
#the order: age, Linf, K, t0 if using "typical"
fitCroaker <- nls(tl ~ vbT(age, Linf ,K, t0),
                  data=crm,
                  start=vbStarts(tl ~ age, 
                                 data = crm, 
                                 type="typical"))

#Extract summary information and send to a new object
sumCroaker <- summary(fitCroaker, correlation = TRUE)
sumCroaker

#Extract coefficients and send to a new object
coefCroaker <- coef(fitCroaker)
coefCroaker

#Calculate 95% confidence intervals for coefficients
confinCroaker <- confint2(fitCroaker)
confinCroaker

#Common error during parameter estimation, number of iterations exceeded maximum of 50

#Occurs if algorithm has trouble finding coefficients for the model
#Try increasing the algorithms maximum number of iterations
fitCroaker <- nls(tl ~ vbT(age, Linf ,K, t0),
                  data=crm,
                  start=vbStarts(tl ~ age, 
                                 data = crm, 
                                 type="typical"),
                  control=list(maxiter=1000))

summary(fitCroaker, correlation = TRUE)


#Break?


#Stock-Recruitment#######
#1. Select data
#2. Specify the growth model
#3. Specify starting values and estimate parameters
#4. Summarize results

#Stock and recruitment data for Klamath River
#Chinook salmon, 1979-2000
ChinookSR <- FSAdata::ChinookKR
#Remove incomplete records
ChinookSR <- na.omit(ChinookSR)

headtail(ChinookSR)

#Plot spawners (stock) vs recruits
ggplot(ChinookSR, aes(x = spawners, y = recruits)) +
  geom_point() 


#Ricker function
#E[R|S] = alpha * S * exp(-beta * S)

#We will use the nls function to fit this non-linear model
#Requires starting values
svR <- srStarts(recruits ~ spawners, 
                data = ChinookSR, 
                type = "Ricker")
svR

#Obtain Ricker function from FSA
rckr <- srFuns("Ricker")

#Fit Ricker function to stock and recruitment data
srR <- nls(recruits ~ rckr(spawners,a,b), 
           data = ChinookSR, 
           start = svR)

summary(srR)

#Coefficients with 95% Confidence Intervals
cbind(estimates = coef(srR), confint(srR))

#Visualize the model fit
#Range of spawning stock
x <- seq(from = min(ChinookSR$spawners), 
         to = max(ChinookSR$spawners), 
         by= 10000)

#Predict recruitment from model fit above
pR<- rckr(x, a=coef(srR))
#combine in a data frame
CombSR <- data.frame(x = x, pR = pR)

#Plot predictions with raw data
ggplot() +
  geom_point(aes(x = CombSR$x, y = CombSR$pR), 
             color = "orange", size = 3) +
  geom_point(aes(x = ChinookSR$spawners, 
                 y = ChinookSR$recruits)) +
  xlab("Stock size") + 
  ylab("Predicted recruitment")



#Population Estimates from Depletion Data#######
#1. Leslie Method
#2. k-pass removal


#Leslie Method
#C_i/f_i = qN0 - q(K_i-1)

#C_i=catch for sample i
#f_i=fishing effort for sample i
#q=catchability coefficient
#N0=initial abundance
#k_i-1=cumulative catch prior to sample i

#Essentially a linear regression problem

#Build a data frame with capture data
depdat <- data.frame(catch = c(7,7,4,1,2,1),
                     effort = c(10,10,10,10,6,10)) %>%
          mutate(cpe = catch/effort, K = pcumsum(catch))

#Plot catch data
ggplot(depdat, aes(x = seq(1,nrow(depdat)), y = catch)) +
  geom_point()

lm2 <- lm(cpe ~ K, data=depdat)
summary(lm2)
#extract coefficients
(cf1 <- coef(lm2))

#Calculate N0
#C_i/f_i = qN0 - q(K_i-1)

#recall intercept = qN0
#q is also the slope
#N0 = qNO/-q or intercept/-slope
(q_hat <- -cf1[["K"]])
(N0_hat <- cf1[["(Intercept)"]] / q_hat)


#k-pass removal estimates require equal catchability and equal effort:
#removal(catch, method)
#Carle Strub (default) weighted k-pass estimator
#Burnham is a likelihood based estimator used in Microfish software (Van Deventer 1989)
catch <- c(187, 77, 35, 5)
pr1 <- removal(catch, method = "CarleStrub")

#Extract estimates with 95% confidence intervals
cbind(summary(pr1), confint(pr1))

#The previous example can be applied to a single site.
#Multiple sites can be estimated by using the streamlined code below

#Data from three sites
catch2 <- data.frame(sta = c("SC10","SC11","SC12"),
                     p1 = c(19,75,20),    #Pass 1
                     p2 = c(14,19,11),    #Pass 2
                     p3 = c(9,5,3) )      #Pass 3
catch2

#Use the apply function to generate population estimate at all sites
#apply(array or matrix, Margin, function, 
#      and just.est)
#MARGIN = 1 indicates function is applied over rows
#MARGIN = 2 indicates function is applied over columns
#The data frame has one site for each row
res <- apply(catch2[,-1], 
             MARGIN = 1, 
             FUN = removal, 
             just.est=TRUE)

(res <- data.frame(sta=catch2$sta, t(res) ) )

#Exercise 4

