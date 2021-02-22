#called from functions-support.sh

echo "host $1  {" >> $4
echo "  hardware ethernet $3;" >> $4
echo "  fixed-address $2;" >> $4
echo "  option host-name \"$1\";" >> $4
echo "}" >> $4
