ExecuteAFile ("../../Shared/HyPhyGlobals.ibf");ExecuteAFile ("../../Shared/GrabBag.bf");ExecuteAFile ("../../Shared/DBTools.ibf");ExecuteAFile ("../../Shared/ReadDelimitedFiles.bf");fscanf		 (stdin, "String", arg);arg = splitOnRegExp (arg,"-");if (Abs (arg) != 2){	fprintf (stdout, "");	return 0;}slacDBID 		 = _openCacheDB      (arg[0]);codon = 0 + arg[1];propertyMatrix = (_ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM PRIME_SUMMARY WHERE COL_KEY = 'PropertiesMatrix'"))[0];parameterValues = _ExecuteSQL (slacDBID,"SELECT ATTRIBUTE, VALUE FROM PRIME_RESULTS WHERE CODON = " + codon + " AND ATTRIBUTE NOT LIKE '% %'");parameterValues ["apply"][""];resultJSON = {};(Eval(propertyMatrix)) ["compute"][""];fprintf (stdout, resultJSON);_closeCacheDB (slacDBID);function apply (key, value) {    Eval (value["Attribute"] + " = " + value ["Value"]);    return 0;}function compute (key, value) {    resultJSON [key] = Eval (value);    return 0;}