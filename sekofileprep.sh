#!/bin/bash
#pre-fight tools requirement check

echo "Checking prerequisites"
command -v dos2unix >/dev/null 2>&1 || { echo >&2 "Script requires dos2unix but it's not installed. Install Dos2Unix using Homebrew. Aborting."; exit 1; }
command -v iconv >/dev/null 2>&1 || { echo >&2 "Script requires iconv but it's not installed.  Aborting."; exit 1; }
command -v gawk >/dev/null 2>&1 || { echo >&2 "Script requires gawk (not OSX version of awk) but it's not installed. Install gawk using Homebrew.  Aborting."; exit 1; }
command -v q >/dev/null 2>&1 || { echo >&2 "Script requires q (SQL for CSV's) but it's not installed.  Install q using Homebrew. Aborting."; exit 1; }
command -v csvjson >/dev/null 2>&1 || { echo >&2 "Script requires csvjson but it's not installed. Install csvkit using Homebrew. Aborting."; exit 1; }
command -v http >/dev/null 2>&1 || { echo >&2 "Script requires httpie but it's not installed. Install httpie using Homebrew. Aborting."; exit 1; }

# state variables
datestamp=`date +%d-%m-%y` 
inputOrders=$1
inputBarcodes=$2
orders=./orders.csv
barcodes=./barcodes.csv
stateUS=./assets/states.csv
awk1=./assets/1.awk
awk2=./assets/2.awk
awk3=./assets/3.awk
ordTotW=./assets/orderweights.csv
returns=./returns.csv
returnsName=returns_$datestamp
returnsOutput=$returnsName.json


#check if files and assets exist
echo "Checking for presence of files and assets"
[[ -f $inputOrders && -s $inputOrders ]] || { echo >&2 "Script cannot find orders input file. Aborting";exit 1; }
[[ -f $inputBarcodes && -s $inputBarcodes ]] || { echo >&2 "Script cannot find barcodes input file. Aborting";exit 1; }
[[ -f $stateUS && -s $stateUS ]] || { echo >&2 "Script cannot find states.csv file. Aborting";exit 1; }
[[ -f $awk1 && -s $awk1 ]] || { echo >&2 "Script cannot find first awk file. Aborting";exit 1; }
[[ -f $awk2 && -s $awk2 ]] || { echo >&2 "Script cannot find second awk file. Aborting";exit 1; }
[[ -f $awk3 && -s $awk3 ]] || { echo >&2 "Script cannot find third awk file. Aborting";exit 1; }

#convert ap21 windows files from windows to unix format
echo "Converting to UNIX and UTF-8"
	dos2unix -q $inputOrders
	dos2unix -q $inputBarcodes

#Convert both files from ISO to UTF-8 
		iconv -f iso-8859-1 -t UTF-8 $inputOrders > tmporders.csv && mv tmporders.csv orders.csv
		iconv -f iso-8859-1 -t UTF-8 $inputBarcodes > tmpbarcodes.csv && mv tmpbarcodes.csv barcodes.csv

echo "Manipulating file to match required format"

		
#remove commas inside of fields
	gawk -F'"' -v OFS='' '{ for (i=2; i<=NF; i+=2) gsub(",", "", $i) } 1' $orders > p_orders0.csv && mv p_orders0.csv orders.csv
	
#remove all " from both files
	sed  's/\"//g' $orders >p_orders1.csv && mv p_orders1.csv orders.csv
	sed  's/\"//g' $barcodes >tmpbarcodes.csv && mv tmpbarcodes.csv barcodes.csv
	
#remove headers from orders file
	tail -n +2 $orders >p_orders2.csv && mv p_orders2.csv orders.csv

#move columns in order file to the correct order
	gawk -F"," -v OFS="," '{print $1,$3"-"$22"-"$21,$2,$3,$4,$5,$6,$7,$8,"AUD","11","12",$9,$10,"Apparel/"$4"/"$5,"Apparel/"$4"/"$5,$11,$12,$13,$14,$15,$16,$16,$17,"United States", $19;}' $orders > p_orders3.csv && mv p_orders3.csv orders.csv

#lookup item weights from $barcodes and insert them in column 11
	gawk -F "," -f $awk1 $barcodes $orders >p_orders4.csv && mv p_orders4.csv orders.csv
	
# fix State names (column 22 &23), time formatting (column 26), ensure zipcodes are 5 digits only(column 24)
	gawk -F "," -f $awk2 $stateUS $orders >p_orders5.csv 2>/dev/null && mv p_orders5.csv orders.csv 
	
# Create the list of orders and total order weights file
	q -d , "SELECT DISTINCT(c1), sum(c11) FROM $orders GROUP BY c1" > $ordTotW
	
# Insert relevant total order weight against order. 
	gawk -F "," -f $awk3 $ordTotW $orders >p_orders6.csv && mv p_orders6.csv orders.csv
	
# Use SED to add the correct Header row
	sed -e '1i\
				OrderNumber,SKU,Quantity,StyleNumber,Category,SubCategory,EAN,ProductName,ItemValue,Currency,ItemWeight,OrderWeight,CommodityCode,ProductCountryOfOrigin,CommodityName,CommodityShortName,CustomerName,CustomerEmail,Building,Street,Suburb,State,town,DeliveryPostcode,DeliveryCountry,DateDespatched
	' <$orders >p_orders7.csv && mv p_orders7.csv orders.csv

echo "Creating .json file for upload"
	
#convert csv in to json file
	csvjson --blanks -i 4 $orders > $returnsOutput
	
#remove annoying ".0" added to every number by csvjson
	gawk '{sub(/.0,/,",")}1' $returnsOutput >p_returns1.json && mv p_returns1.json $returnsOutput


#display first 66 lines (roughly 2 orders)
	head -66 $returnsOutput
	echo
	echo
#after sight check, ask if upload should continue
	read -p "Upload to OmniParcel? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
#upload orders to omniparcel    
		then
    		echo "Beginning upload"
	  		http --timeout=300 https://www.omnirps.com/app/ftp_return/add_ftp_order_details Token:v4cMnONZ3WQ6Nb62YqXd5UuAQdeIcsxa9LH Content-Type:application/json < $returnsOutput
	fi

#ask do some cleanup
read -p "Have orders uploaded successfully? " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
#clean up files    
		then
    		echo "Cleaning up"
			rm $orders
			rm $barcodes
			rm $inputOrders
			rm $inputBarcodes
			echo "Script complete"
	else
			echo "Error indicated with upload, files retained for debugging"
	fi




