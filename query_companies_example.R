

#  install Selenium. (Drivers web browsers for tasks that might otherwise need tedios manual pointing and clicking)

#How to drive a web browser: 
#1 https://www.computerworld.com/article/2971265/how-to-drive-a-web-browser-with-r-and-rselenium.html
#2 https://www.computerworld.com/article/2971265/how-to-drive-a-web-browser-with-r-and-rselenium.html#RSeleniumChart
#3 https://docs.ropensci.org/RSelenium/articles/saucelabs.html

#installing packages need to run Selenium

install.packages('RSelenium', type="win.binary")
install.packages('curl') #first remove 00curl file from C:\Users\Documents\R\3.4.1 https://stackoverflow.com/questions/61545327/r-install-packages-returns-error-failed-to-lock-directory

# load packages and functions needed 

library("RSelenium")
library("curl")
isFALSE <- function(x) is.logical(x) && length(x) == 1L && !is.na(x) && !x #explicitly define isFALSE bc rsDriver depends on isFALSE and the latter does not seem to be found 

# installing Java to support Selenium
# installing Java on windows https://cimentadaj.github.io/blog/2018-05-25-installing-rjava-on-windows-10/installing-rjava-on-windows-10/


sessionInfo() #check if R is 32- or 64-bit
Sys.setenv(JAVA_HOME="C:/Program Files/Java/jdk-17.0.1/") 
#library("rJava")


#check versions of Chrome https://github.com/ropensci/RSelenium/issues/189

library(binman)
list_versions("chromedriver")


#################################### WRITING LOOPS####################################################
###################################################################################################### 
###############  OBJECTIVE: write nested for loop to run automated search in bins as opposed to in bulk
##To do: add code to persist in loading page for slow loads



## run driver for Chrome version closest to versions listed above

rd<-rsDriver(browser = 'chrome', port = 4444L, chromever = "94.0.4606.61", iedrver = NULL, phantomver = NULL) #https://stackoverflow.com/questions/61950706/r-selenium-server-signals-port-4567-is-already-in-use; https://stackoverflow.com/questions/42316527/running-rselenium-with-rsdriver
remDr <- rd[["client"]] # or remDr <- rd$client

#other useful commands

#remDr$getCurrentUrl()
#remDr$open()

#read in company names to query
setwd("C:/Users/Sadhna/Desktop")
company_data<-data.frame(read.csv("C:\\Users\\Sadhna\\Desktop\\rstudio-temp\\companies_input.csv")) #data subset with ~50 query values to avoid IP flagging for suspicious activity

len<-dim(company_data)


# find and input into 'search' field on Google https://cran.r-project.org/web/packages/RSelenium/vignettes/basics.html

# initialize variables for loop and set google to homepage

remDr$navigate("https://www.google.com/") # opens google!!
remDr$setTimeout(type = "page load", milliseconds = 60000)  #https://cran.r-project.org/web/packages/RSelenium/RSelenium.pdf


all_CEO<-list()
output<-c()
bin_size<-10 # declared var
no_bins<-ceiling(len[1]/bin_size)
# bins<-data.frame(1: bin_size, bin_size+1:bin_size*2)
b<-1
i<-1
j<-bin_size
time_int<-runif(no_bins, 9, 10)

##### for loop and if statements to run function #####
##### reads until row 24, maybe need to break up data and run nested for loops?

for (b in 1:no_bins) {
  
  
  temp<-c()
  CEO_tempID<-1
  
  
  for (a in i:j){  #finds CEO names for bin_size then loops to external for loop
    
    output <- 
      tryCatch(
        expr = {
          remDr$navigate("https://www.google.com/")  
          query<- paste(company_data$companies[a], "CEO")
          address_element <- remDr$findElement( using = "css", "[class = 'gLFyf gsfi']")
          address_element$sendKeysToElement(list(query, "\uE007"))                  # "\uE007" for "Enter", see ??selkeys for other key press options
          #temp<-remDr$findElement( using = "css", "[class^= 'wDYxhc']")
          remDr$findElement( using = "css", "[class^= 'wDYxhc']")
          
        }, 
        
        error = function(e){ 
          message("Caught an error")
          # temp<-(remDr$findElement( using = "css", "[class^= 'VwiC3b']"))
          print(e)
          return(remDr$findElement( using = "css", "[class^= 'VwiC3b']"))
          
        },
        warning = function(w){
          message("Caught a warning")
          message(w)
          return(NULL)
        },
        finally={
          # NOTE:
          # Here goes everything that should be executed at the end,
          # regardless of success or error.
          message("read line ", a, "sucessfully")
          Sys.sleep(5)
          
        }
      )
    
    
    if (is.null(output)== TRUE){
      temp[CEO_tempID]<- NA
    } else {
      temp[CEO_tempID]<-output$getElementText()
    }
    CEO_tempID<-CEO_tempID+1  
    
  }  #closes inner loop to find CEOs for each bin
  
  
  all_CEO[[b]]<-temp
  i<-i+bin_size
  j<-j+bin_size
  Sys.sleep(time_int[b])
  
}  #closes outer loop



#
#worked for amgen and abbvie 'Z0LcW XcVN5d'
#<h2 class="Uo8X3b OhScic zsYMMe">Featured snippet from the web</h2>
#<div class="yp1CPe wDYxhc NFQFxe viOShc LKPcQc" data-md="471" lang="en-US"><div><div class="V3FYCf">
#yp1CPe wDYxhc NFQFxe viOShc LKPcQc #stopped at #6 
#partial match to wDYxhc stopped at row 9 bc invalid selector for #9
#<div class="VwiC3b yXK7lf MUxGbd yDYNvb lyLwlc lEBKkf" style="-webkit-line-clamp:2"><span>The <em>CEO</em> of <em>Branan Medical Corporation</em> is Cindy Horton. 
# end loop here

############

# close port used by driver 

remDr$close() 
rd$server$stop() #closes the server in use - this does not work yet
system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)           # kills Java process occupying port called in line 23


###########
# Exporting the data into CSV
###############


write.csv(data.frame(unlist(all_CEO)), file = "output_CEO3.csv")                 #https://stackoverflow.com/questions/36492452/extract-data-from-list-of-lists-r
