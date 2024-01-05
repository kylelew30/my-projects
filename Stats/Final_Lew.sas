/* 
Name: Kyle Lew
Date: December 7, 2021
Assignment: Final Lab
 */

/* ----------------------------------------------------------------------------------------------------------- */
/* create import macro */
%macro import_gapminder (path=, mydataset1=, mylibname=) ;
	/* macro debugging options */
	options mprint mlogic symbolgen;
	proc import datafile="&path&mydataset1"
		out=&mylibname
		dbms=csv
		replace;
	run;
%mend;

/* ----------------------------------------------------------------------------------------------------------- */
/* create reshape macro */
%macro reshape_gapminder(mydataset1=, mylibname=);
	/* Sort the data by country to prep for transpose */
	proc sort data = &mylibname;
		by country;
	run;

	/* transpose the data set from wide to long */
	proc transpose 
		data = &mylibname 
		out = long
		name = year1; 
		by country;
	run;

	/* create a temporary data set to change one of the column names and to change the type of variable for year */
	data temp;
		set long (rename = (col1=variable));
		year = input(year1, 4.);
		drop year1;
	run;
	
	/* Sort the other data set to prep for merge*/
	proc sort data = "&mydataset1";
	by country;
	run;
	/* Merge the two data sets */
	data mygapminder;
		merge temp "&mydataset1";
		by country year;
	run;
	/* Check output */
	proc print data = mygapminder (obs = 10);run;
%mend;

/* ----------------------------------------------------------------------------------------------------------- */
/* Create visualize macro */
%macro visualize_gapminder(mylibname=, mystartyear=, myendyear=, path=, varname=,);
	/* Check if the start year and end year are the same */
	%if &mystartyear = &myendyear %then 
		%do;
		/* title the plot and specify the path and file to export */
		title "&mystartyear";
		ods listing gpath="&path";
		ods graphics / imagename="single" imagefmt=png;
		/* Create the bubble plot of a single year given */
		proc sgplot data=&mylibname(where=(year=&mystartyear)) noautolegend;
			bubble x=life_exp y=variable size=population / group=world_bank_region
		    	transparency=0.4 datalabelattrs=(size=9 weight=bold);
			yaxis grid label="&varname";
			xaxis grid;
		run;
		%end;
		
	%else %do;
	/* else if the start and end year are different */
		/* create a macro that creates a bubble plot with the given year */
		%macro plot (year=);
			title "&year";
			proc sgplot data=&mylibname(where=(year=&year)) noautolegend;
				bubble x=life_exp y=variable size=population / group=world_bank_region
				transparency=0.4 datalabelattrs=(size=9 weight=bold);
				yaxis grid label="&varname";
				xaxis grid;
			run;
		%mend;
		/* create a macro that uses the above macro to create a bubble plot for each year given in the year range */
		%macro animation (startyear=,stopyear=);
			%local year;
			%do year=&startyear %to &stopyear;
			%plot(year=&year);
			%end;
		%mend animation;
		
		/* Use the given bubble plots and create a gif from them */
		options printerpath=gif animation=start animduration=.5 animloop=yes noanimoverlay
		nodate nonumber;
		ods printer file="&path/final.gif";
		
		/* call the above macro */
		%animation(startyear=&mystartyear,stopyear=&myendyear);
		options printerpath=gif animation=stop;
		ods printer close;
	%end;
%mend;

/* call the import macro */
%import_gapminder(path = /home/u59505716/SAS330/Final/, mydataset1 = child_mortality.csv, mylibname = myfile);

/* call the reshape macro */
%reshape_gapminder(mydataset1 = /home/u59505716/SAS330/Final/gapminder_data.sas7bdat, mylibname = myfile);

/* call the visualize macro with (1990,1990) */
%visualize_gapminder(
mylibname = mygapminder,
varname = mortality_rates,
mystartyear=1990,
myendyear=1990,
path=/home/u59505716/SAS330/Final);

/* call the visualize macro with (1970,2000) */
%visualize_gapminder(
mylibname = mygapminder,
varname = mortality_rates,
mystartyear=1970,
myendyear=2000,
path=/home/u59505716/SAS330/Final);
 



