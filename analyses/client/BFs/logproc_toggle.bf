ExecuteAFile ("../Shared/HyPhyGlobals.ibf");/*------------------------------------------------------------------------------------*/function MakeStringCanonical (modelString){	charOccurrences = {};	for (s2 = 0; s2 < Abs (modelString); s2 = s2 + 1)	{		c = modelString[s2];		if (charOccurrences[c] == 0)		{			charOccurrences [c] = Abs(charOccurrences)+1;		}	}	modString = "";	for (s2 = 0; s2 < Abs (modelString); s2 = s2 + 1)	{		c = modelString[s2];		c = charOccurrences[c];		modString = modString + (c-1);	}	return modString;}/*------------------------------------------------------------------------------------*/function secondsSinceJan1_2004 (timeString){	parsedTime = timeString || "( |\\:)+";	ps1 = parsedTime[0]+1;	ps2 = parsedTime[2]-1;	mon = timeString[ps1][ps2];	mon = months[mon];	ps1 = parsedTime[4]-1;	day = 0+timeString[ps2+2][ps1];	ps2 = parsedTime[6]-1;	hr  = 0+timeString[ps1+2][ps2];	ps1 = parsedTime[8]-1;	min = 0+timeString[ps2+2][ps1];	ps2 = parsedTime[10]-1;	sec = 0+timeString[ps1+2][ps2];	yar = 0+timeString[ps2+2][Abs(parsedTime)-1];	parsedTime = ((((yar-2004)*365 + (yar-2001)$4 + monthsNum[1][mon] + day)*24 + hr)*60 + min)*60 +sec;	if (yar % 4 == 0 && mon > 1)	{		parsedTime = parsedTime + 24*3600;	}	return parsedTime;}/*------------------------------------------------------------------------------------*/function statOnMatrix (aMatrix, startIndex, doHist){	summaryStats = {};		itemCount 	 = Abs(aMatrix)-startIndex;	numMatrix	 = {itemCount,1};	oneMatrix	 = {1,itemCount};		nonNegs = 0;	for (ii = 0; ii < itemCount; ii = ii+1)	{		numMatrix[ii] = aMatrix[startIndex+ii];		oneMatrix[ii] = 1;		if (numMatrix[ii] >= 0)		{			nonNegs = nonNegs + 1;		}	}		if (nonNegs < itemCount)	{		numMatrix	 = {nonNegs,1};		oneMatrix	 = {1,nonNegs};				ii2 = 0;		for (ii = 0; ii < itemCount; ii = ii+1)		{			if (aMatrix[startIndex+ii] >= 0)			{				numMatrix[ii2] = aMatrix[startIndex+ii];				oneMatrix[ii2] = 1;				ii2 = ii2 + 1;			}		}		itemCount = nonNegs;	}		numMatrix = numMatrix % 0;	summaryStats ["Min"] = numMatrix[0];	summaryStats ["Max"] = numMatrix[itemCount-1];		oneMatrix = oneMatrix * numMatrix;	summaryStats ["Mean"]   = oneMatrix[0]/itemCount;	if (itemCount % 2)	{		summaryStats ["Median"] = numMatrix[itemCount$2];	}	else	{		summaryStats ["Median"] = 0.5*(numMatrix[itemCount$2]+numMatrix[itemCount$2-1]);	}		if (doHist>1)	{		range = summaryStats["Max"]-summaryStats["Min"];		if (range > 1)		{			step 	   = range/doHist;			step	   = step$1;			if (step == 0)			{				step = 1;			}			doHist 		= (range-0.5)$step+1;		}		else		{			step 	   = range/doHist;				}				histMatrix = {doHist,5};		curUpBound = step + summaryStats["Min"];		curStop	   = 0;		curPos	   = 0;		curBin	   = 0;				while (curUpBound < (summaryStats["Max"]+step-0.0001) && curPos < itemCount)		{			while (numMatrix[curPos] <= curUpBound)			{				curPos = curPos+1;				if (curPos == itemCount)				{					break;				}			}			histMatrix [curBin][0] = curUpBound-step;			histMatrix [curBin][1] = curUpBound;			histMatrix [curBin][2] = curPos-curStop;			histMatrix [curBin][3] = histMatrix [curBin][2]/itemCount;			if (curBin)			{				histMatrix [curBin][4] = histMatrix [curBin-1][4] + histMatrix [curBin][3];			}			else			{				histMatrix [curBin][4] = histMatrix [curBin][3];						}			curStop = curPos;			curUpBound = curUpBound + step;			curBin     = curBin+1;		}				summaryStats["Histogram"] = histMatrix;	}		return summaryStats;}/*------------------------------------------------------------------------------------*/function nFormat (n){	if (n$1 == n)	{		return ""+n;	}	return Format (n,8,2);}/*------------------------------------------------------------------------------------*/function addTableLine (startIndex, doHist, timeframe, title){	outputHTML * ("<TR class = 'HeaderClassSM' style = 'font-size:11px'>");	if (Abs(timeframe))	{		outputHTML * ("<TH>Last " + timeframe + " days</TH>");	}	else	{		timeframe = (currentTime - dates[0])$86400+1;		outputHTML * ("<TH>Lifetime ("+timeframe+" days)</TH>");			}	jobs = 0;		if (startIndex >= 0)	{		jobs = Abs(dates)-startIndex;				outputHTML * (class1+jobs+"</TD>" +class1+ Format(jobs/timeframe,6,2)+ "</TD>");		ss = statOnMatrix (seqs,startIndex, doHist);				outputHTML * (class2+					  nFormat(ss["Mean"])+"</TD>"  +class2+					  nFormat(ss["Median"])+"</TD>"+class2+					  nFormat(ss["Min"]) + 					  "-" + nFormat(ss["Max"]) + "</TD>");				ss = statOnMatrix (sites,startIndex, doHist);				outputHTML * (class1+					  nFormat(ss["Mean"])+"</TD>"  +class1+					  nFormat(ss["Median"])+"</TD>"+class1+					  nFormat(ss["Min"]) + "-" 					  + nFormat(ss["Max"]) + "</TD>");		ss = statOnMatrix (times,startIndex, doHist);		outputHTML * (class2+					  nFormat(ss["Mean"])+"</TD>"  +class2+					  nFormat(ss["Median"])+"</TD>"+class2+					  nFormat(ss["Min"]) + "-" 					  + nFormat(ss["Max"]) + "</TD>");		outputHTML * "</TR>\n";	}	else	{		outputHTML * ("<TD>0</TD><TD COLSPAN='10'></TD></TR>\n");		}		return {{jobs__,timeframe__}};}/*------------------------------------------------------------------------------------*/ExecuteAFile ("../Shared/ReadDelimitedFiles.bf");fscanf (stdin, "String", logFilePath);fscanf (stdin, "String", pvalString);fscanf (stdin, "String", method);fscanf (logFilePath,"Raw",logFile);sscanf (logFile,"String",aLine);logEntries = {};dates        = {};seqs         = {};sites        = {};times        = {};ptestsites   = {};ptogsites	 = {};pvals	     = {};months = {};months ["Jan"]=0;months ["Feb"]=1;months ["Mar"]=2;months ["Apr"]=3;months ["May"]=4;months ["Jun"]=5;months ["Jul"]=6;months ["Aug"]=7;months ["Sep"]=8;months ["Oct"]=9;months ["Nov"]=10;months ["Dec"]=11;monthsNum = {{31,28,31,30,31,30,31,31,30,31,30,31};			 {0,0,0,0,0,0,0,0,0,0,0,0}};			 for (idx = 1; idx < 12; idx = idx + 1){	monthsNum[1][idx] = monthsNum[1][idx-1]+monthsNum[0][idx-1];}idx = 0;GetString(currentTimeS,TIME_STAMP,1);class1	   = "<TD class = 'ModelClass1'>";class2	   = "<TD class = 'ModelClass2'>";outputHTML = "";outputHTML * 8192;outputHTML * ("<DIV class = 'RepClassSM'>"+method+" usage summary as of "+currentTimeS+"PST.<p>");outputHTML * "\n<TABLE style = 'font-size: 10px; font-family: times;' cellspacing = '1'><TR class = 'HeaderClassSM'><TH>Timeframe</TH><TH COLSPAN='2' align='center'>Analyses</TH><TH COLSPAN=3 align='center'>Sequences</TH><TH COLSPAN=3 align='center'>Sites</TH><TH COLSPAN=3 align='center'>CPU time</TH></TR>\n";outputHTML * "<TR class = 'HeaderClassSM'><TH></TH><TH>Total</TH><TH>Per 24 hrs</TH><TH>Mean</TH><TH>Median</TH><TH>Range</TH><TH>Mean</TH><TH>Median</TH><TH>Range</TH><TH>Mean</TH><TH>Median</TH><TH>Range</TH></TR>\n";currentTime = secondsSinceJan1_2004 (currentTimeS);lastDay		= currentTime-86400;lastDIdx	= -1;lastWeek	= currentTime-7*86400;lastWIdx	= -1;lastMonth	= currentTime-30*86400;lastMIdx	= -1;pvtogsites 	= {};while (!END_OF_FILE){	sscanf (logFile,"String",aLine);	if (Abs(aLine))	{		lineParts = splitOnRegExp (aLine, ",");		dates [idx] = secondsSinceJan1_2004(lineParts[0]);				if (lastMIdx < 0)		{			if (dates[idx] >= lastMonth)			{				lastMIdx = idx;			}		}		if (lastWIdx < 0)		{			if (dates[idx] >= lastWeek)			{				lastWIdx = idx;			}		}		if (lastDIdx < 0)		{			if (dates[idx] >= lastDay)			{				lastDIdx = idx;			}		}				seqs  [idx] = 0+lineParts[1];		sites  [idx] = 0+lineParts[2];		times  [idx] = 0+lineParts[3];		aModel = MakeStringCanonical(lineParts[4]); /*default toggle model is hky85: no need to report */		ptestsites [idx] = 0+lineParts[5];		ptogsites [ idx ] = (0+lineParts[6])*100/ptestsites [idx];		pval	 = 0+lineParts[7];		pvals [idx] = pval;		pvtogsites [pval] = pvtogsites[pval] + ptogsites[idx];		idx = idx + 1;	}}addTableLine (lastDIdx,0,1,0);addTableLine (lastWIdx,0,7,0);stats1 = addTableLine (lastMIdx,0,30,0);stats2 = addTableLine (0,0,0,0);fscanf 		 (LOG_SUMMARY_FILE, "NMatrix,NMatrix", lstats2, lstats1);stats1[0] 	= stats1[0] + lstats1[0];fprintf		 (LOG_SUMMARY_FILE, CLEAR_FILE, stats2+lstats2, stats1);	outputHTML * "\n</TABLE></DIV>";outputHTML * 0;fprintf (stdout, outputHTML);