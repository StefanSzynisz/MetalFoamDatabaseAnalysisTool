# MetalFoamDatabaseAnalysisTool
 Matlab script for analysis of trends between pairs of properties

 This MATLAB scrip 'Metal_foam_database_analysis_tool.m' automates the collection
 and processing of data from the "metalfoams_sqlite3" database (MetF_StandardTable)
 to produce a table of data and graph of two selected metal foam properties

Before running the code the database data source must be set up
First ensure that the metalfoams_sqlite3.db file is downloaded in the
same folder as this MATLAB file
Then go to https://bitbucket.org/xerial/sqlite-jdbc/downloads/ to download the
latest JDBC driver
Once the JDBC driver is installed enter "configureJDBCDataSource" into
the command line
In the JDBC Data Source Configuration pop up enter the following:

Name: Provide a name for the database (e.g. Metalfoams). Note this name
       as it will be used later (databasename)
Vendor: Other
Driver location: Enter the full path to the JDBC driver file (or Select the
                  location of the JDBC driver using the button to the right)
Driver: org.sqlite.JDBC
URL: jdbc:sqlite:DBPATH (where dbpath is the full path to your SQLite
      database on your computer, including the database file name!)
      Example: jdbc:splite:C:\Database\metalfoams_sqlite3.db

Click test
In the pop up box leave Username and Password blank, click test
If connection is successful a box will pop up saying "Connection
 successful!"
Click save

Database is now connected!
For more information on setting up the database connection please visit
uk.mathworks.com/help/database/ug/sqlite-jdbc-windows.html
