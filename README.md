Air Pollution at LUC Lake Shore
===============================

## Description of Files:
The documents la.html, la2.html and lala.html are html documents pulled from [the EPA](http://yosemite.epa.gov/r5/in_permt.nsf/33cf5ec06b4d2f1d8625763f0052ba7c!OpenView&Start=1&Count=99999999999999999999&ExpandView). The hpple directory contains a library used in the actual parsing of these html pages. The parser is written in `epapuller.m` and can be compiled with the `make` command (the makefile in the directory will be used). The pdfs2 directory is used to download each of the permit pdfs (I do not upload these to the git repository as, together, they take up quite some space). After running `make` you can run `./epapuller` in order to run the static analyzer. Note that in order to get new results you will need to go to the EPA website and save the tables of all the companies to the `lala.html` file. The `epapuller` then parses through (comments are left in code describing how it works) the html page pulling out all the information. It then dumps it in the file `databank.js`. I have moved this databank file into the website directory. This directory is home to the actual website's code. It uses a mix of javascript, css and html (again comments in code help describe how the code actually works).

## How to compile the analyzer

Run `make` in this directory

## How to run the analyzer

Run `./epapuller` after you have compiled the analyzer

## How to open the website

After running `./epapuller` copy the `database.js` file over to the `website/` directory. Next, open `website/index.html` in your favorite web browser and you should be good to go (note that this needs internet connection in order to get the maps and the such).

## Contact

If you need any help or have any comments then contact me at this [address](mailto:daniel.zimmerman@me.com).

Have a great day, whoever is reading this! :D
