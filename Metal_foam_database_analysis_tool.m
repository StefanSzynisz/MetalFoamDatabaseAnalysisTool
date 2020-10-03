%% Metal foam database processor
% This code automates the collection and processing of data from the 
% "metalfoams_sqlite3" database (MetF_StandardTable) to produce a table 
% of data and graph of two metal foam properties

% Before running the code the database data source must be set up
% First ensure that the metalfoams_sqlite3.db file is downloaded in the
% same folder as this Matlab file
% Then go to https://bitbucket.org/xerial/sqlite-jdbc/downloads/ to download the
% latest JDBC driver
% Once the JDBC driver is installed enter "configureJDBCDataSource" into
% the command line
% In the JDBC Data Source Configuration pop up enter the following:

% Name: Provide a name for the database (e.g. Metalfoams). Note this name
%       as it will be used later (databasename)
% Vendor: Other
% Driver location: Enter the full path to the JDBC driver file (or Select the 
%                  location of the JDBC driver using the button to the right)
% Driver: org.sqlite.JDBC
% URL: jdbc:sqlite:DBPATH (where dbpath is the full path to your SQLite 
%      database on your computer, including the database file name!)
%      Example: jdbc:splite:C:\Database\metalfoams_sqlite3.db

% Click test
% In the pop up box leave Username and Passord blank, click test
% If connection is sucessfull a box will pop up saying "Connection
% sucessful!"
% Click save

% Database is now connected!
% For more information on setting up the database connection please visit
% uk.mathworks.com/help/database/ug/sqlite-jdbc-windows.html

%% Choose variables you wish to compare and their units
% Below is a list of available properties keywords and their available units:
% Variable names (variable1, variable2,filtervariable) and unit names 
% (unit1, unit2,unit_filter) must match corresponding item from the list 
% exactly (case sensitive)
% Easiest way to ensure no errors is to copy and paste items from list
% If empty tables are produced then there is no available data
% -------------------------------------------------------------------------
% 'average pore size'                   unit: 'um','mm','cm','m'
% 'bulk density'                        unit: 'g_cm3','kg_m3'
% 'densification strain'                unit: 'decimal','percent'
% 'elastic Poisson ratio'               unit: 'decimal','percent'
% 'Forchheimer factor'                  unit: 'one_m','one_ft'
% 'heat transport'                      unit: 'W','kW'
% 'porosity'                            unit: 'percent','decimal'
% 'permeability'                        unit: 'm2'
% 'plastic Poisson ratio'               unit: 'decimal','percent'
% 'plateau stress'                      unit: 'Pa','MPa','GPa'
% 'pores per unit length'               unit: 'pores_cm','pores_inch'
% 'shear failure strain'                unit: 'decimal','percent'
% 'tensile failure strain'              unit: 'decimal','percent'
% 'thermal conductivity'                unit: 'W_mK'
% 'yield stress'                        unit: 'Pa','MPa','GPa'
% 'Young modulus'                       unit: 'Pa','MPa','GPa'
% =========================================================================

% Below is a list of available base metals:
% Metal names (metals) must match corresponding item from the list exactly 
% (case sensitive)
% Easiest way to ensure no errors is to copy and paste items from list
% -------------------------------------------------------------------------
% 'all'                                 All base metals are included
% 'Aluminium'
% 'Ferrous'
% 'Magnesium'
% 'Stainless Steel'
% 'Steel Alloy'
% 'Titanium'
% 'Zinc'
% =========================================================================
close all;
clear all functions;

 databasename = 'Metalfoams';            % Enter whatever you named the database while setting up the connection

% X-axis
 variable1 = 'porosity';
 unit1 = 'percent';
 log1 = 0;                              % scale: 0 for normal, 1 for log
 setlimit1 = 0;                         % 0 for no limits, 1 for limits
 minmax1 = [0 100];                     % Specify limits
 
% Y-axis
 variable2 = 'Young modulus';
 unit2 = 'MPa';
 log2 = 0;                              % Y-axis scale: 0 for normal, 1 for log
 setlimit2 = 0;                         % 0 for no limits, 1 for limits
 minmax2 = [0 50];                       % Specify limits
                                        
 setcelltype = 2;                       % Specify which cell type to compare
                                        % 0 for all cell types, 1 for open cell, 2 for closed cell
                                        
 metals = {'Aluminium'};                  % Specify which metals to include use 'all' to include all metals
                                        % Metals must be separated by semicolons
                                        
 setnumericalfilter = 0;                % Adds a third variable to filter the results by: 0 for off, 1 for on
 filtervariable = 'yield stress';       % Specify variable
 filterunit = 'MPa';                    % Specify unit
 filterrange = [0 5];                   % Specifiy numerical range to incude in results
 
 groupingvariable = 1;                  % Specify which variable to group data by in scatter graph
                                        % 0 for base metal (base_material), 1 for the study that the data came from (label)
                                        % For example 'Ra2009' (= Rabiei A, 2009)
                                 
 exporttable = 1;                       % 0 for no, 1 for yes
                                        % Previous tables of the same file name
                                        % must be deleted
 
 %% Runs functions
 
 [table1,table2,index,foamtype,method,description,references,filtertable] = fetchdata(variable1,variable2,filtervariable,databasename);
 [join1,join2,join3,join4,join5,join6,nrow] = jointables(table1,table2,index,foamtype,method,description,references);
 [unit_table] = makeunittable;
 [join2,nrow] = convertunit(join2,variable1,variable2,unit1,unit2,unit_table,nrow);
 if strcmpi('all',metals) == 0
    [join2,nrow] = removemetals(join2,nrow,metals);
 end
 if setcelltype == 1 || setcelltype == 2
     [join2,nrow] = removecells(join2,nrow,setcelltype);
 end
 if setnumericalfilter == 1
     [join2,filtertable,nrow] = numericalfilter(join2,unit_table,filterrange,filtertable,filtervariable,filterunit);
 end
 [join2,printunit1,printunit2] = prettyunit(join2,unit1,unit2,nrow);
 [graph1,join2] = drawgraph(join2,variable1,variable2,printunit1,printunit2,log1,log2,exporttable,setlimit1,setlimit2,minmax1,minmax2,groupingvariable);
 
 %% Makes connection to database and querys relevant data
 
function [table1,table2,index,foamtype,method,description,references,filtertable] = fetchdata(variable1,variable2,filtervariable,databasename)
    
    % Make connection to database
    conn = database(databasename,'','');

    % Defines SQL querys
    query1 = ['SELECT mf_id, ' ...
    '	mean_value, ' ...
    '	unit ' ...
    'FROM MetF_StandardTable ' ...
    'WHERE keyword = ''',variable1,''' ' ...
    '	AND mean_value != ''NaN'''];
    
    query2 = ['SELECT mf_id, ' ...
    '	mean_value, ' ...
    '	unit ' ...
    'FROM MetF_StandardTable ' ...
    'WHERE keyword = ''',variable2,''' ' ...
    '	AND mean_value != ''NaN'''];

    query3 = ['SELECT mf_id, ' ...
    '	base_material ' ...
    'FROM MetF_Index'];

    query4 = ['SELECT mf_id, ' ...
    '	entry ' ...
    'FROM MetF_General ' ...
    'WHERE keyword = ''foam type'''];

    query5 = ['SELECT mf_id, ' ...
    '	entry ' ...
    'FROM MetF_General ' ...
    'WHERE keyword = ''method'''];

    query6 = ['SELECT mf_id, ' ...
    '	entry ' ...
    'FROM MetF_General ' ...
    'WHERE keyword = ''description'''];

    query7 = ['SELECT mf_id, ' ...
    '	label, ' ...
    '	link ' ...
    'FROM MetF_References'];

    query8 = ['SELECT mf_id, ' ...
    '	mean_value, ' ...
    '	unit ' ...
    'FROM MetF_StandardTable ' ...
    'WHERE keyword = ''',filtervariable,''' ' ...
    '	AND mean_value != ''Nan'''];

    % Fetches querys
    table1 = fetch(conn,query1);

    table2 = fetch(conn,query2);

    index = fetch(conn,query3);
    
    foamtype = fetch(conn,query4);
    
    method = fetch(conn,query5);
    
    description = fetch(conn,query6);
    
    references = fetch(conn,query7);
    
    filtertable = fetch(conn,query8);
    
    % Changes coumn names in table to allow for "innerjoin"
    table1.Properties.VariableNames{2} = 'variable1';       
    table1.Properties.VariableNames{3} = 'unit_variable1';

    table2.Properties.VariableNames{2} = 'variable2';
    table2.Properties.VariableNames{3} = 'unit_variable2';
    
    filtertable.Properties.VariableNames{2} = 'filter_variable';
    filtertable.Properties.VariableNames{3} = 'unit_filter';
    
    foamtype.Properties.VariableNames{2} = 'foam_type';
    
    method.Properties.VariableNames{2} = 'method';
    
    description.Properties.VariableNames{2} = 'description';
    
    % Closes connection
    close(conn)
 
    clear conn query
end 

%% Creates full table of data Creates unit table for conversion of units

function [join1,join2,join3,join4,join5,join6,nrow] = jointables(table1,table2,index,foamtype,method,description,references)
    
    %Joins idividual tables to create full data table (join2)
    join1 = innerjoin(table1,table2);
    join3 = innerjoin(index,foamtype);
    join4 = innerjoin(join3,method);
    join5 = innerjoin(join4,description);
    join6 = innerjoin(join5,references);
    join2 = innerjoin(join1,join6)  %prints initial table in command window
    
    nrow = size(join2,1); % Depth of table 
end

%% Creates unit conversion table for conversion of units 

function [unit_table] = makeunittable
%matlab does not allow use of special characters in an array name therefore
%alternatives have been chosen
%original vales are shown commented

rownames = ["Pa";"MPa";"GPa";"percent";"decimal";"um";"mm";"cm";"m";"g_cm3";"kg_m3";"W";"kW";"m2";"pores_cm";"pores_inch";"W_mK";"one_m";"one_ft"];

n = 19;     %number of units in the unit table

% Makes arrays for table
Pa = zeros(n,1);
MPa = zeros(n,1);
GPa = zeros(n,1);
percent = zeros(n,1);      %'%'
decimal = zeros(n,1);      %'' (empty)
um = zeros(n,1);           
mm = zeros(n,1);
cm = zeros(n,1);
m = zeros(n,1);
g_cm3 = zeros(n,1);        %g/cm^3
kg_m3 = zeros(n,1);        %kg/m^3
W = zeros(n,1);
kW = zeros(n,1);
m2 = zeros(n,1);           %m^2
pores_cm = zeros(n,1);     %pores/cm
pores_inch = zeros(n,1);   %pores/inch
W_mK = zeros(n,1);         %W/mK
one_m = zeros(n,1);        %1/m
one_ft = zeros(n,1);       %1/ft

%Joins arrays into table of zeros
unit_table = table(Pa,MPa,GPa,percent,decimal,um,mm,cm,m,g_cm3,kg_m3,W,kW,m2,pores_cm,pores_inch,W_mK,one_m,one_ft);
unit_table.Properties.RowNames = rownames;

%Assigns conversion values at the intersection of units
%The unit on the row name is the recorded unit and column name is the
%desired unit
unit_table.Pa(1) = 1;
unit_table.Pa(2) = 1000;
unit_table.Pa(3) = 1e06;
unit_table.MPa(1) = 0.001;
unit_table.MPa(2) = 1;
unit_table.MPa(3) = 1000;
unit_table.GPa(1) = 0.000001;
unit_table.GPa(2) = 0.001;
unit_table.GPa(3) = 1;
unit_table.percent(4) = 1;      
unit_table.percent(5) = 100;    
unit_table.decimal(4) = 0.01;   
unit_table.decimal(5) = 1;      
unit_table.um(6) = 1;
unit_table.um(7) = 1000;
unit_table.um(8) = 10000;
unit_table.um(9) = 1e06;
unit_table.mm(6) = 0.001;
unit_table.mm(7) = 1;
unit_table.mm(8) = 10;
unit_table.mm(9) = 1000;
unit_table.cm(6) = 1e-04;
unit_table.cm(7) = 0.1;
unit_table.cm(8) = 1;
unit_table.cm(9) = 100;
unit_table.m(6) = 1e-6;
unit_table.m(7) = 0.001;
unit_table.m(8) = 0.01;
unit_table.m(9) = 1;
unit_table.g_cm3(10) = 1;
unit_table.g_cm3(11) = 0.001;
unit_table.kg_m3(10) = 1000;
unit_table.kg_m3(11) = 1;
unit_table.W(12) = 1;
unit_table.W(13) = 1000;
unit_table.kW(12) = 0.001;
unit_table.kW(13) = 1;
unit_table.m2(14) = 1;
unit_table.pores_cm(15) = 1;
unit_table.pores_cm(16) = 0.393701;
unit_table.pores_inch(15) = 2.54;
unit_table.pores_inch(16) = 1;
unit_table.W_mK(17) = 1;
unit_table.one_m(18) = 1;
unit_table.one_m(19) = 3.28084;
unit_table.one_ft(18) = 0.30480;
unit_table.one_ft(19) = 1;

end

%% Converts units from reported unit to desired unit

function [join2,nrow] = convertunit(join2,variable1,variable2,unit1,unit2,unit_table,nrow)

    %Changes recorded unit to match unittable
    if strcmpi('densification strain',variable1) || strcmpi('porosity',variable1) || strcmpi('elastic Poisson ratio',variable1) || strcmpi('plastic Poisson ratio',variable1)
        for i = 1:nrow
            if strcmpi('%',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'percent';
            else
                join2.unit_variable1{i} = 'decimal';
            end
        end
    end
    if strcmpi('densification strain',variable2) || strcmpi('porosity',variable2) || strcmpi('elastic Poisson ratio',variable2) || strcmpi('plastic Poisson ratio',variable2)
        for i = 1:nrow
            if strcmpi('%',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'percent';
            else
                join2.unit_variable2{i} = 'decimal';
            end
        end
    end
    
    %Fixes error in recording unit from CSV file to SQL database
    if strcmpi('bulk density',variable1)
        for i = 1:nrow
            if strcmpi('g/cm<sup>3</sup>',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'g_cm3';
            elseif strcmpi('kg/m<sup>3</sup>',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'kg_m3';
            end
        end
    end
    if strcmpi('bulk density',variable2)
        for i = 1:nrow
            if strcmpi('g/cm<sup>3</sup>',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'g_cm3';
            elseif strcmpi('kg/m<sup>3</sup>',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'kg_m3';
            end
        end
    end
    
    %Fixes error in recording unit from google sheets to SQL database
    if strcmpi('permeability',variable1)
        for i = 1:nrow
            if strcmpi('m<sup>2</sup>',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'm2';
            end
        end
    end
    if strcmpi('permeability',variable2)
        for i = 1:nrow
            if strcmpi('m<sup>2</sup>',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'm2';
            end
        end
    end
    
    %Changes recorded unit to match unittable
    if strcmpi('thermal conductivity',variable1)
        for i = 1:nrow
            if strcmpi('W/mK',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'W_mK';
            end
        end
    end
    if strcmpi('thermal conductivity',variable2)
        for i = 1:nrow
            if strcmpi('W/mK',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'W_mK';
            end
        end
    end
    
    %Changes recorded unit to match unittable
    if strcmpi('Forchheimer factor',variable1)
        for i = 1:nrow
            if strcmpi('1/m',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'one_m';
            elseif strcmpi('1/ft',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'one_ft';
            end
        end
    end
    if strcmpi('Forchheimer factor',variable2)
        for i = 1:nrow
            if strcmpi('1/m',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'one_m';
            elseif strcmpi('1/ft',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'one_ft';
            end
        end
    end
    
    %Changes recorded unit to match unittable
    if strcmpi('pores per unit length',variable1)
        for i = 1:nrow
            if strcmpi('pores/cm',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'pores_cm';
            elseif strcmpi('pores/inch',join2.unit_variable1{i})
                join2.unit_variable1{i} = 'pores_inch';
            end
        end
    end
    if strcmpi('pores per unit length',variable2)
        for i = 1:nrow
            if strcmpi('pores/cm',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'pores_cm';
            elseif strcmpi('pores/inch',join2.unit_variable2{i})
                join2.unit_variable2{i} = 'pores_inch';
            end
        end
    end
    
    %Deletes any rows with no units (due to error in reporting)
    unit_list = [];
    for i = 1:nrow                      % iterate for every row of table
        k = strcmpi('',join2.unit_variable1{i});  % check if unit_variable1 is empty (== '')
        l = strcmpi('',join2.unit_variable2{i});  % check if unit_variable2 is empty (== '')
        if k == 1 || l == 1               % If either is empyt note row number in delete list
            unit_list = [unit_list,i];    
        end
    end
    join2([unit_list],:) = [];          % Delete all rows on deletelist
    nrow = size(join2,1);               % Find new table depth
    
    %Converts from recorded unit to desired units (unit1,unit2) using
    %unittable
    for i = 1:nrow
        %Variable1
        recorded_unit1 = join2.unit_variable1{i};   %Reads reported unit
        scalar1 = unit_table{recorded_unit1,unit1}; %Finds unit conversion rate
        join2.variable1(i) = join2.variable1(i)*scalar1;    %Multiplies mean value by unit conversion rate
        join2.unit_variable1{i} = unit1;    %Updates unit column
        
        %Variable2
        recorded_unit2 = join2.unit_variable2{i};
        scalar2 = unit_table{recorded_unit2,unit2};
        join2.variable2(i) = join2.variable2(i)*scalar2;
        join2.unit_variable2{i} = unit2; 
    end
    
    %Removes last two characters from label column so that values are the
    %same for the same study
    for i = 1:nrow
        join2.label{i}=join2.label{i}(1:6);
    end 
end

%% Removes unwanted metals from the table

function [join2,nrow] = removemetals(join2,nrow,metals)

    %Finds number of metals to filter by
    metalsize = size(metals,1);

    metal_list = [];
    for i = 1:nrow                      % iterate for every row of table
        trigger = 0;
        for t = 1:metalsize             % iterate for each metal
            k = strcmpi(metals{t},join2.base_material{i});  % check if base material matches item(t) on list
            if k == 1                   % If it does set trigger to 1
                trigger = 1;      
            end                         % Else trigger remains the same
        end
        if trigger == 0                 % If metal matched nothing of list note row number in deletelist
            metal_list = [metal_list,i];    
        end
    end

    join2([metal_list],:) = [];          % Delete all rows on deletelist

    nrow = size(join2,1);                % Find new table depth
        
end

%% Removes unwanted cell types from the table

function [join2,nrow] = removecells(join2,nrow,setcelltype)

    %Assigns desired cell type based off "setcelltype"
    if setcelltype == 1
        celltype = 'Open cell';
    elseif setcelltype == 2
        celltype = 'Closed cell';
    end

    cell_list = [];
    for i = 1:nrow                      % iterate for every row of table
        k = strcmpi(celltype,join2.foam_type{i});  % check if metal matches item(t) on list
        if k == 0                 % If metal matched nothing of list note row number in deletelist
            cell_list = [cell_list,i];    
        end
    end

    join2([cell_list],:) = [];          % Delete all rows on deletelist

    nrow = size(join2,1);               % Find new table depth

end

%% Runs each function for the filter variable

function [join2,filtertable,nrow] = numericalfilter(join2,unit_table,filterrange,filtertable,filtervariable,filterunit)
    %Performs operation from jointables, convertunit, and pretty unit but
    %for the filter variable
    %For more in depth comments refer to earlier functions 
    
    frow = size(filtertable,1); % Depth of filtertable 

    %Changes recorded unit to match unittable
    if strcmpi('densification strain',filtervariable) || strcmpi('porosity',filtervariable) || strcmpi('elastic Poisson ratio',filtervariable) || strcmpi('plastic Poisson ratio',filtervariable)
        for i = 1:frow
            if strcmpi('%',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'percent';
            else
                filtertable.unit_filter{i} = 'decimal';
            end
        end
    end
    
    %Fixes error in recording unit from CSV file to SQL database
    if strcmpi('bulk density',filtervariable)
        for i = 1:frow
            if strcmpi('g/cm<sup>3</sup>',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'g_cm3';
            elseif strcmpi('kg/m<sup>3</sup>',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'kg_m3';
            end
        end
    end
    
    %Fixes error in recording unit from google sheets to SQL database
    if strcmpi('permeability',filtervariable)
        for i = 1:frow
            if strcmpi('m<sup>2</sup>',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'm2';
            end
        end
    end
    
    %Changes recorded unit to match unittable
    if strcmpi('thermal conductivity',filtervariable)
        for i = 1:frow
            if strcmpi('W/mK',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'W_mK';
            end
        end
    end
    
    %Changes recorded unit to match unittable
    if strcmpi('Forchheimer factor',filtervariable)
        for i = 1:frow
            if strcmpi('1/m',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'one_m';
            elseif strcmpi('1/ft',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'one_ft';
            end
        end
    end
    
    %Changes recorded unit to match unittable
    if strcmpi('pores per unit length',filtervariable)
        for i = 1:frow
            if strcmpi('pores/cm',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'pores_cm';
            elseif strcmpi('pores/inch',filtertable.unit_filter{i})
                filtertable.unit_filter{i} = 'pores_inch';
            end
        end
    end
    
    %Deletes any rows with no units (due to error in reporting)
    unit_list = [];
    for i = 1:frow                      % iterate for every row of table
        k = strcmpi('',filtertable.unit_filter{i});  % check if filter_unit is empty (== '')
        if k == 1               % If empty note row number in delete list
            unit_list = [unit_list,i];    
        end
    end
    filtertable([unit_list],:) = [];      % Delete all rows on deletelist
    frow = size(filtertable,1);           % Find new table depth
    
    %Converts from recorded unit to desired units using unittable
    for i = 1:frow
        %filtervariable
        recorded_unit3 = filtertable.unit_filter{i};    
        scalar3 = unit_table{recorded_unit3,filterunit};
        filtertable.filter_variable(i) = filtertable.filter_variable(i)*scalar3;
        filtertable.unit_filter{i} = filterunit;
    end
    
    %Adds filtertable to join2
    join2 = innerjoin(join2,filtertable);
    
    nrow = size(join2,1);               % Find new table depth
    
    %Remove rows outside of filter range
    num_list = [];
    for i = 1:nrow                      % iterate for every row of table
        if join2.filter_variable(i) <= filterrange(1) || join2.filter_variable(i) >= filterrange(2)
            num_list = [num_list,i];
        end
    end
    join2([num_list],:) = [];          % Delete all rows on deletelist

    nrow = size(join2,1);               % Find new table depth
    
    %Fixes units of filtervariable to look nice
    if strcmpi('percent',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = '%';
        end
    elseif strcmpi('g_cm3',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = 'g/cm^3';
        end
    elseif strcmpi('kg_m3',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = 'kg/m^3';
        end
    elseif strcmpi('m2',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = 'm^2';
        end
    elseif strcmpi('pores_cm',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = 'pores/cm';
        end
    elseif strcmpi('pores_inch',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = 'pores/in';
        end
    elseif strcmpi('W_mK',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = 'W/mK';
        end
   elseif strcmpi('one_m',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = '1/m';
        end
    elseif strcmpi('one_ft',filtervariable)
        for i = 1:nrow
            join2.unit_filter{i} = '1/ft';
        end
    end
    
    filtername = regexprep(filtervariable, ' ', '_');
    filterunit = ['unit_',filtername];
    
    join2.Properties.VariableNames{12} = filtername;
    join2.Properties.VariableNames{13} = filterunit;
    
end

%% Changes units back to display nicely in table

function [join2,printunit1,printunit2] = prettyunit(join2,unit1,unit2,nrow)

    %Fixes unit1
    if strcmpi('percent',unit1)
        printunit1 = '%';
        for i = 1:nrow
            join2.unit_variable1{i} = '%';
        end
    elseif strcmpi('g_cm3',unit1)
        printunit1 = 'g/cm^3';
        for i = 1:nrow
            join2.unit_variable1{i} = 'g/cm^3';
        end
    elseif strcmpi('kg_m3',unit1)
        printunit1 = 'kg/m^3';
        for i = 1:nrow
            join2.unit_variable1{i} = 'kg/m^3';
        end
    elseif strcmpi('m2',unit1)
        printunit1 = 'm^2';
        for i = 1:nrow
            join2.unit_variable1{i} = 'm^2';
        end
    elseif strcmpi('pores_cm',unit1)
        printunit1 = 'pores/cm';
        for i = 1:nrow
            join2.unit_variable1{i} = 'pores/cm';
        end
    elseif strcmpi('pores_inch',unit1)
        printunit1 = 'pores/in';
        for i = 1:nrow
            join2.unit_variable1{i} = 'pores/in';
        end
    elseif strcmpi('W_mK',unit1)
        printunit1 = 'W/mK';
        for i = 1:nrow
            join2.unit_variable1{i} = 'W/mK';
        end
   elseif strcmpi('one_m',unit1)
        printunit1 = '1/m';
        for i = 1:nrow
            join2.unit_variable1{i} = '1/m';
        end
    elseif strcmpi('one_ft',unit1)
        printunit1 = '1/ft';
        for i = 1:nrow
            join2.unit_variable1{i} = '1/ft';
        end
    else
        printunit1 = unit1;
    end
    
    %fixes unit2
    if strcmpi('percent',unit2)
        printunit2 = '%';
        for i = 1:nrow
            join2.unit_variable2{i} = '%';
        end
    elseif strcmpi('g_cm3',unit2)
        printunit2 = 'g/cm^3';
        for i = 1:nrow
            join2.unit_variable2{i} = 'g/cm^3';
        end
    elseif strcmpi('kg_m3',unit2)
        printunit2 = 'kg\m^3';
        for i = 1:nrow
            join2.unit_variable2{i} = 'kg/m^3';
        end
    elseif strcmpi('m2',unit2)
        printunit2 = 'm^2';
        for i = 1:nrow
            join2.unit_variable2{i} = 'm^2';
        end
    elseif strcmpi('pores_cm',unit2)
        printunit2 = 'pores/cm';
        for i = 1:nrow
            join2.unit_variable2{i} = 'pores/cm';
        end
    elseif strcmpi('pores_inch',unit2)
        printunit2 = 'pores/in';
        for i = 1:nrow
            join2.unit_variable2{i} = 'pores/in';
        end
    elseif strcmpi('W_mK',unit2)
        printunit2 = 'W/mK';
        for i = 1:nrow
            join2.unit_variable2{i} = 'W/mK';
        end
    elseif strcmpi('one_m',unit2)
        printunit2 = '1/m';
        for i = 1:nrow
            join2.unit_variable2{i} = '1/m';
        end
    elseif strcmpi('one_ft',unit2)
        printunit2 = '1/ft';
        for i = 1:nrow
            join2.unit_variable2{i} = '1/ft';
        end
    else
        printunit2 = unit2;
    end
    
end

%% Draws graph of variable1 against varaible2

function [graph1,join2] = drawgraph(join2,variable1,variable2,printunit1,printunit2,log1,log2,exporttable,setlimit1,setlimit2,minmax1,minmax2,groupingvariable)

    %Assigns grouping item based of groupingvariable
    if groupingvariable == 0
        groupingitem = join2.base_material;     
    elseif groupingvariable == 1
        groupingitem = join2.label;
    end
   
    graph1 = gscatter(join2.variable1,join2.variable2,groupingitem);
    labelx = [variable1,' (',printunit1,')'];   %Define x and y labels
    labely = [variable2,' (',printunit2,')'];
    xlabel(labelx);
    ylabel(labely);
    if setlimit1 == 1                   %sets X axis limit based off setlimit1
        xlim(minmax1);                
    end
    if setlimit2 == 1                   %sets X axis limit based off setlimit2
        ylim(minmax2);                
    end
    if log1 == 1                        %Sets X axis to log based on log1
        set(gca, 'XScale', 'log');
    end
    if log2 == 1                        %Sets Y axis to log based on log2
        set(gca, 'YScale', 'log');      
    end
    
    % Changes column names from variable1, variable2 etc to the names of
    % the properties (porosity, Young modulus etc)
    variable1name = regexprep(variable1, ' ', '_');
    variable1unit = ['unit_',variable1name];
    
    join2.Properties.VariableNames{2} = variable1name;
    join2.Properties.VariableNames{3} = variable1unit;
    
    variable2name = regexprep(variable2, ' ', '_');
    variable2unit = ['unit_',variable2name];
    
    join2.Properties.VariableNames{4} = variable2name;
    join2.Properties.VariableNames{5} = variable2unit;
    join2                                    % Prints final table in command window
    
    if exporttable == 1
        filename = [variable1,'_',variable2,'.xlsx'];
        filename = filename(~isspace(filename));  %removes spaces in filename
        writetable(join2,filename);
    end
    
end
