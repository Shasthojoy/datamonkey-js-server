ExecuteAFile ("../../Shared/HyPhyGlobals.ibf");ExecuteAFile ("../../Shared/GrabBag.bf");ExecuteAFile ("../../Shared/OutputsPRIME.bf");ExecuteAFile ("../../Shared/DBTools.ibf");ExecuteAFile ("../../Shared/ReadDelimitedFiles.bf");fscanf		 (stdin, "String", arg);arg = splitOnRegExp (arg,"-");if (Abs (arg) != 1){	fprintf (stdout, "");	return 0;}slacDBID 		 = _openCacheDB      (arg[0]);propertyCount = _ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM PRIME_SUMMARY WHERE COL_KEY = 'PropertyCount'");get_csv_table (slacDBID, 0+propertyCount[0]);  _closeCacheDB (slacDBID);