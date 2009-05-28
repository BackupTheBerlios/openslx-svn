#!/bin/bash

#echo "<printer name=\"info\" path=\"//printserver/info\"> some pseudo printer </printer>"

for(( i=0; $i<10; i=$i+1)); do
  echo -e "printserver$i\tprinter$i\tPrinter Description $i"
done

echo -e "printserver.ruf.uni-freiburg.de\treal-printer-name\tSome really long printer Description"

