# apt-get install gawk
BEGIN {
	FS="\n";
	RS="[^\n:]*:[^\n]*"	;
	ORS="";
	OFS="";
	val=val":";
	
}
{	
	if( savedRT ~ val)
	{
		split(savedRT,a,":");
		if(a[2] != "" )
			print a[2],$0;
		else
			print $0;
	}
	savedRT=RT
}
	
