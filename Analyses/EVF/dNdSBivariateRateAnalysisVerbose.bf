RequireVersion ("0.9920060817");

ChoiceList (runType,"Run Type",1,SKIP_NONE,
			"New run","Start a new run",
			"Continued run","Start with an initial point output by a Gateux derivative approximator."
		    );
		    
if (runType < 0)
{
	return 0;
}

randomizeInitValues  = 0;
ModelMatrixDimension = 0;


VERBOSITY_LEVEL = 500;


/*---------------------------------------------------------------------------------------------------------------------------------------------------*/

function ReportDistributionString (rc)
{
	distroString = "";
	distroString * 1024; 
	distroString * "<TABLE><TR CLASS = 'HeaderClassSM'><TH>Class</TH><TH>&alpha;</TH><TH>&beta;</TH><TH>&omega;</TH><TH>Weight</TH></TR>\n";
	
	reportMx = {rc,4};
	
	for (mi=0; mi<rc; mi=mi+1)
	{
		ExecuteCommands ("reportMx[mi][0]=S_"+mi+"/c_scale;");
		ExecuteCommands ("reportMx[mi][1]=NS_"+mi+"/c_scale;");
		reportMx[mi][2] = reportMx[mi][1]/reportMx[mi][0];
		ExecuteCommands ("reportMx[mi][3]="+freqStrMx[mi]+";");
		distroString * ("<TR CLASS = 'ModelClass"+(1+mi%2)+"'><TD>"+(mi+1)+"</TD><TD>"+Format(reportMx[mi][0],10,3)
									   +"</TD><TD>"+Format(reportMx[mi][1],10,3)
									   +"</TD><TD>"+Format(reportMx[mi][2],10,3)
									   +"</TD><TD>"+Format(reportMx[mi][3],10,3) + "</TR>");
	}						
	
	distroString * "</TABLE>";
	distroString * 0;
	return distroString;
}


	

/*---------------------------------------------------------------------------------------------------------------------------------------------------*/
if (runType == 0)
{
	ChoiceList (branchLengths,"Branch Lengths",1,SKIP_NONE,
				"Codon Model","Jointly optimize rate parameters and branch lengths (slow and thorough)",
				"Nucleotide Model","Estimate branch lengths once, using an appropriate nucleotide model (quick and dirty)."
			    );

	if (branchLengths<0)
	{
		return;
	}

	
	ExecuteAFile ("CF3x4.bf");
	observedFreq = CF3x4 (positionFrequencies, GeneticCodeExclusions);
	
	done = 0;
	while (!done)
	{
		/*fprintf (stdout,"\nPlease enter a 6 character model designation (e.g:010010 defines HKY85):");*/
		fscanf  (stdin,"String", modelDesc);
		if (Abs(modelDesc)==6)
		{	
			done = 1;
		}
	}			

	ModelTitle = "MG94x"+modelDesc[0];
				
	rateBiasTerms = {{"AC","1","AT","CG","CT","GT"}};
	paramCount	  = 0;

	modelConstraintString = "";

	for (customLoopCounter2=1; customLoopCounter2<6; customLoopCounter2=customLoopCounter2+1)
	{
		for (customLoopCounter=0; customLoopCounter<customLoopCounter2; customLoopCounter=customLoopCounter+1)
		{
			if (modelDesc[customLoopCounter2]==modelDesc[customLoopCounter])
			{
				ModelTitle  = ModelTitle+modelDesc[customLoopCounter2];	
				if (rateBiasTerms[customLoopCounter2] == "1")
				{
					modelConstraintString = modelConstraintString + rateBiasTerms[customLoopCounter]+":="+rateBiasTerms[customLoopCounter2]+";";
				}
				else
				{
					modelConstraintString = modelConstraintString + rateBiasTerms[customLoopCounter2]+":="+rateBiasTerms[customLoopCounter]+";";			
				}
				break;
			}
		}
		if (customLoopCounter==customLoopCounter2)
		{
			ModelTitle = ModelTitle+modelDesc[customLoopCounter2];	
		}
	}	

	ExecuteAFile ("MG94xREVxBivariate_Multirate.mdl");

	if (Abs(modelConstraintString))
	{
		ExecuteCommands (modelConstraintString);
	}

	ChoiceList (randomizeInitValues, "Initial Value Options",1,SKIP_NONE,
				"Default",	 "Use default inital values for rate distribution parameters.",
				"Randomized",	 "Select initial values for rate distribution parameters at random.",
				"User Values",	 "Set initial values for rate distribution parameters and fix them for the optimization process");


	if (randomizeInitValues < 0)
	{
		return;
	}

	resp  = 0;

	while (resp<1)
	{
		/*fprintf (stdout,"Number of rate classes:");*/
		fscanf  (stdin, "Number", resp);
	}

	if (randomizeInitValues < 2)
	{
		ChoiceList (stratDNDS, "dN/dS Stratification",1,SKIP_NONE,
					"Unconstrained",	 "Do not place constraints on dN/dS classes.",
					"Split",	 "Assign all dN/dS classes to negative/neutral/positive clases.");
		if (stratDNDS<0)
		{
			return 0;
		}
	}
	else
	{
		stratDNDS = 0;
	}

	if (stratDNDS)
	{
		respM = -1;
		respN = 0;
		respP = 0;

		while (respM<0 || respM > resp)
		{
			/*fprintf (stdout,"Number of negative rate classes [0-",resp,"]:");*/
			fscanf  (stdin, "Number", respM);
		}

		if (respM < resp)
		{
			respN = -1;
			while (respN<0 || respN > resp-respM)
			{
				/*fprintf (stdout,"Number of neutral rate classes [0-",resp-respM,"]:");*/
				fscanf  (stdin, "Number", respN);
			}
		}

		respP = resp-respN-respM;

		/*fprintf (stdout, "\nUsing\n\t", respM, " negatively selected classes\n\t", respN, " neutrally evolving classes\n\t", 
							respP, " positively selected classes\n\n");*/
	}

	categDef1 = "";
	categDef1 * 1024;
	
	lfDef	  = {};
	
	for (fileID = 0; fileID < fileCount; fileID = fileID + 1)
	{
		lfDef[fileID] = "";
		lfDef[fileID] * 1024;
		lfDef[fileID] * "Log(";
	}
	

	global		S_0  = 0.5;
	S_0:>0.0000001;
	global		NS_0 = 0.1;

	for (mi=1; mi<resp; mi=mi+1)
	{
		categDef1 * ("global S_"+mi+"=0.5;S_"+mi+":>0.0000001;\nglobal NS_"+mi+";\n");
		if (randomizeInitValues)
		{
			categDef1*("global P_"+mi+" = Random(0.05,0.95);\nP_"+mi+":<1;\n");	
			categDef1*("global S_"+mi+" = Random(0.05,1);");	
		}
		else
		{
			categDef1*("global P_"+mi+" = 1/"+(resp+1-mi)+";\nP_"+mi+":<1;\n");
		}
	}

	freqStrMx    = {resp,1};
	if (resp>1)
	{
		freqStrMx[0] = "P_1";

		for (mi=1; mi<resp-1; mi=mi+1)
		{
			freqStrMx[mi] = "";
			for (mi2=1;mi2<=mi;mi2=mi2+1)
			{
				freqStrMx[mi] = freqStrMx[mi]+"(1-P_"+mi2+")";		
			}
			freqStrMx[mi] = freqStrMx[mi]+"P_"+(mi+1);	
		}	
		freqStrMx[mi] = "";

		for (mi2=1;mi2<mi;mi2=mi2+1)
		{
			freqStrMx[mi] = freqStrMx[mi]+"(1-P_"+mi2+")";		
		}
		freqStrMx[mi] = freqStrMx[mi]+"(1-P_"+mi+")";	
	}
	else
	{
		freqStrMx[0] = "1";
	}

	categDef1*( "\n\nglobal c_scale:=S_0*" + freqStrMx[0]);

	for (mi=1; mi<resp; mi=mi+1)
	{
		categDef1*( "+S_"+mi+"*" + freqStrMx[mi]);
	}

	for (mi=0; mi<resp; mi=mi+1)
	{
		for (fileID = 0; fileID < fileCount; fileID = fileID + 1)
		{
			if (mi)
			{
				lfDef[fileID] * "+";
			}
			lfDef[fileID]*(freqStrMx[mi]+"*SITE_LIKELIHOOD["+(fileID*resp+mi)+"]");
		}
			
	}

	categDef1 * ";";

	for (mi=0; mi<resp; mi=mi+1)
	{
		categDef1 * ("\nglobal R_"+mi+"=1;NS_"+mi+":=R_"+mi+"*S_"+mi+";\n");
	}
	
	if (randomizeInitValues == 2)
	{
		enteredValues = {resp,3};
		
		/*fprintf (stdout, "AC=");*/
		fscanf	(stdin,"Number",thisAlpha);
		categDef1 * ("AC:="+thisAlpha+";");
		/*fprintf (stdout, "AT=");*/
		fscanf	(stdin,"Number",thisAlpha);
		categDef1 * ("AT:="+thisAlpha+";");
		/*fprintf (stdout, "CG=");*/
		fscanf	(stdin,"Number",thisAlpha);
		categDef1 * ("CG:="+thisAlpha+";");
		/*fprintf (stdout, "CT=");*/
		fscanf	(stdin,"Number",thisAlpha);
		categDef1 * ("CT:="+thisAlpha+";");
		/*fprintf (stdout, "GT=");*/
		fscanf	(stdin,"Number",thisAlpha);
		categDef1 * ("GT:="+thisAlpha+";");
		
		for (mi = 0; mi < resp; mi = mi+1)
		{
			/*fprintf (stdout, "Alpha for rate class ", mi+1, ":");*/
			fscanf	(stdin,"Number",thisAlpha);
			/*fprintf (stdout, "Beta for rate class ", mi+1, ":");*/
			fscanf	(stdin,"Number",thisBeta);
			/*fprintf (stdout, "Weight for rate class ", mi+1, ":");*/
			fscanf	(stdin,"Number",thisP);
			enteredValues [mi][0] = thisAlpha;
			enteredValues [mi][1] = thisBeta;
			enteredValues [mi][2] = thisP;
		}
		currentMult = 1-enteredValues[0][2];
		for (mi = 1; mi < resp-1; mi = mi+1)
		{
			enteredValues[mi][2] = enteredValues[mi][2]/currentMult;
			currentMult = currentMult*(1-enteredValues[mi][2]);
		}
		
		for (mi = 0; mi < resp-1; mi = mi+1)
		{
			categDef1 * ("S_"+mi+":>0;S_" + mi + ":=" + enteredValues[mi][0] + ";NS_" +mi+ ":=" + enteredValues[mi][1] + ";P_" + (mi+1) + ":=" +enteredValues[mi][2]+";");
		}
		categDef1 * ("S_"+mi+":>0;S_"+mi+":="+enteredValues[mi][0]+";NS_"+mi+":="+enteredValues[mi][1]+";");
	}

	if (stratDNDS)
	{
		for (mi=respM; mi<respN+respM; mi=mi+1)
		{
			categDef1 * ("\nR_"+mi+":=1;");
		}

		if (randomizeInitValues)
		{
			for (mi=0; mi<respM; mi=mi+1)
			{
				categDef1 * ("\nR_"+mi+":<1;R_"+mi+"="+Random(0.05,0.95)+";");
			}


			for (mi=respM+respN; mi<resp; mi=mi+1)
			{
				categDef1 * ("\nR_"+mi+":>1;R_"+mi+"="+Random(1.05,10)+";");
			}
		}
		else
		{
			for (mi=0; mi<respM; mi=mi+1)
			{
				categDef1 * ("\nR_"+mi+":<1;R_"+mi+"=1/"+(1+mi)+";");
			}

			for (mi=respM+respN; mi<resp; mi=mi+1)
			{
				categDef1 * ("\nR_"+mi+":>1;R_"+mi+"=2+"+(mi-respM-respN)+";");
			}
		}
	}
	else
	{
		if (randomizeInitValues == 1)
		{
			for (mi=0; mi<resp; mi=mi+1)
			{
				categDef1 * ("\nR_"+mi+"="+Random(0.05,1.75)+";");
			}
		}
		else
		{
			if (randomizeInitValues == 0)
			{
				for (mi=0; mi<resp; mi=mi+1)
				{
					categDef1 * ("\nR_"+mi+"="+(0.1+0.3*mi)+";");
				}	
			}
		}
	}

	categDef1 * 0;
	lfDef1 = "";
	lfDef1 * 128;
	lfDef1 * "\"";
	
	for (fileID = 0; fileID < fileCount; fileID = fileID + 1)
	{
		lfDef[fileID] * ")";
		lfDef[fileID] * 0;
		lfDef1 * lfDef[fileID];
		if (fileID < fileCount - 1)
		{
			lfDef1 * "+";
		}
	}

	lfDef1 	  * "\"";
	lfDef1	  * 0;

	ExecuteCommands (categDef1);

	ModelMatrixDimension = 64;
	for (h = 0 ;h<64; h=h+1)
	{
		if (_Genetic_Code[h]==10)
		{
			ModelMatrixDimension = ModelMatrixDimension-1;
		}
	}
	
	
	if (randomizeInitValues < 2)
	{
		SetDialogPrompt ("Save resulting fit to:");
		fprintf (PROMPT_FOR_FILE, CLEAR_FILE);
		resToPath = LAST_FILE_PATH;	
	}
	
	ExecuteAFile		  ("MGFreqsEstimator.ibf");
	BuildCodonFrequencies (paramFreqs, "vectorOfFrequencies");
	
	ExecuteCommands (nucModelString+"\nModel nucModel = (nucModelMatrix,overallFrequencies);");
	
	/*if (randomizeInitValues == 2)
	{
		fileID = ReportDistributionString(resp);
		fprintf (stdout, "\nUsing the following rate distribution\n", fileID, "\n");
	}*/

	nlfDef = "";
	nlfDef * 128;
	nlfDef * "LikelihoodFunction nuc_lf = (";

	for (fileID = 1; fileID <= fileCount; fileID = fileID + 1)
	{
		ExecuteCommands ("DataSetFilter nucFilter_"+fileID+" = CreateFilter (filteredData_"+fileID+",1);");
		ExecuteCommands ("Tree  nucTree_"+fileID+" = treeString_"+fileID+";");
		if (fileID > 1)
		{
			nlfDef * ",";
		}
		nlfDef * ("nucFilter_"+fileID+",nucTree_"+fileID);
	}
	nlfDef * 0;
	ExecuteCommands (nlfDef + ");");
	Optimize (nuc_res, nuc_lf);

	computeExpSubWeights (0);
	if (branchLengths)
	{
		ExecuteCommands("global codonFactor = 0.33;");
	}

	lfParts	= "";
	lfParts * 128;
	lfParts * "LikelihoodFunction lf = (filteredData_1,tree_1_0";

	for (fileID = 1; fileID <= fileCount; fileID = fileID + 1)
	{
		for (part = 0; part < resp; part = part + 1)
		{
			if (fileID == 1)
			{
				ExecuteCommands ("PopulateModelMatrix(\"rate_matrix_"+part+"\",paramFreqs,\"S_"+part+"/c_scale\",\"NS_"+part+"/c_scale\",aaRateMultipliers);");
				ExecuteCommands ("Model MG94model_"+part+"= (rate_matrix_"+part+",vectorOfFrequencies,0);");
			}
			else
			{
				ExecuteCommands ("UseModel (MG94model_"+part+");");
			}
			
			treeID = "tree_"+fileID+"_"+part;
			ExecuteCommands ("Tree "+treeID+"=treeString_" + fileID +";");
			if (branchLengths)
			{
				ExecuteCommands ("ReplicateConstraint (\"this1.?.synRate:=this2.?.t__/codonFactor\","+treeID+",nucTree_"+fileID+");");
			}
			else
			{
				if (part == 0)
				{	
					ExecuteCommands ("bnames = BranchName(nucTree_" + fileID + ",-1);");
					nlfDef * 128;
					for (lc = 0; lc < Columns (bnames); lc=lc+1)
					{
						nlfDef * (treeID + "." + bnames[lc] + ".synRate = nucTree_" + fileID + "." + bnames[lc] + ".t/codonFactor;");
					}
					nlfDef * 0;
					ExecuteCommands (nlfDef);
				}
				else
				{
					ExecuteCommands ("ReplicateConstraint (\"this1.?.synRate:=this2.?.synRate\","+treeID+",tree_1_0);");
				}
			}
			if (part || fileID > 1)
			{
				lfParts = lfParts + ",filteredData_" + fileID + "," + treeID;
			}
		}
	}
	
	lfParts * 0;
	ExecuteCommands (lfParts + "," + lfDef1 + ");");

	USE_LAST_RESULTS = 1;

}
else
{
	SetDialogPrompt ("Choose a model fit:");
	ExecuteAFile (PROMPT_FOR_FILE);

	GetInformation(vars,"^P_[0-9]+$");
	resp = Columns (vars)+1;
	USE_LAST_RESULTS = 1;
	SKIP_CONJUGATE_GRADIENT = 1;
	
	ChoiceList (runKind, "Optimization type:", 1, SKIP_NONE,
							"Unconstrained", "No constraints on rate classes",
							"Constant dS", "Synonymous rates are constant",
							"No positive selection", "All dS <= dN",
							"HKY85", "Nucleotide substitution rates are forced to conform to HKY85");
					
	GetString (lfInfo, lf, -1);				
	fileCount = Columns (lfInfo["Datafilters"])/resp;	
	
	GetInformation (branchLengths, "^codonFactor$");
	branchLengths = (Columns (branchLengths)>0);
	
	/* do we have codonFactor? */			
							
	for (fileID = 1; fileID <= fileCount; fileID = fileID + 1)
	{
		ExecuteCommands ("totalCodonCount=totalCodonCount+filteredData_"+fileID+".sites;totalCharCount=totalCharCount+filteredData_"+fileID+".sites*filteredData_"+fileID+".species;");
	}


	if (runKind < 0)
	{
		return 0;
	}
	
	
	if (runKind == 0)
	{
		resToPath = LAST_FILE_PATH;
	}
	else
	{
		if (runKind == 1)
		{
			resToPath = LAST_FILE_PATH + ".dN_only";
			
			c_scale := 1;
			for (k = 0; k <resp; k=k+1)
			{
				ExecuteCommands("global R_"+k+"= Max(NS_"+k+",0.00001)/Max(S_"+k+",0.00001);");
				ExecuteCommands("S_"+k+":=1;");
				ExecuteCommands("NS_"+k+"=R_"+k+"*S_"+k+";");
			}
		}
		else
		{
			if (runKind == 2)
			{
				resToPath = LAST_FILE_PATH + ".NN";
				
				for (k = 0; k <resp; k=k+1)
				{
					ExecuteCommands("global R_"+k+";R_"+k+":<1;R_"+k+"=Max(NS_"+k+",0.00001)/Max(S_"+k+",0.00001);");
					ExecuteCommands("NS_"+k+":=R_"+k+"*S_"+k+";");
				}
			}		
			else
			{
				resToPath = LAST_FILE_PATH + ".HKY85";
				
				mi  = (1+CT)/2;
				mi2 = ;
				
				AC = (AC+AT+CG+GT)/(2*(1+CT));
				CT := 1;
				AT := AC;
				CG := AC;
				GT := AC;
			}		
		}
	}
	
	freqStrMx    = {resp,1};
	freqStrMx[0] = "P_1";

	for (mi=1; mi<resp-1; mi=mi+1)
	{
		freqStrMx[mi] = "";
		for (mi2=1;mi2<=mi;mi2=mi2+1)
		{
			freqStrMx[mi] = freqStrMx[mi]+"(1-P_"+mi2+")";		
		}
		freqStrMx[mi] = freqStrMx[mi]+"P_"+(mi+1);	
	}	
	freqStrMx[mi] = "";

	for (mi2=1;mi2<mi;mi2=mi2+1)
	{
		freqStrMx[mi] = freqStrMx[mi]+"(1-P_"+mi2+")";		
	}
	freqStrMx[mi] = freqStrMx[mi]+"(1-P_"+mi+")";
}

Optimize (res,lf);
SKIP_CONJUGATE_GRADIENT= 0;
USE_LAST_RESULTS       = 0;

LIKELIHOOD_FUNCTION_OUTPUT = 2;

LogL = res[1][0];

/* check for branch length approximator */

GetString (paramList, lf, -1);

degF = Columns(paramList["Global Independent"]) /* this will overcount by one; because the mean alpha := 1 */
	+ 8 /* 9 frequency parameters -1 */
	- branchLengths; /* remove one more for codon scaling factor, if nuc branch lengths are used */

for (fileID = 1; fileID <= fileCount; fileID = fileID + 1)
{
	ExecuteCommands ("degF = degF + BranchCount(tree_" + fileID + "_0) + TipCount(tree_" + fileID + "_0);");
}	

AIC	 = 2*(degF-LogL);
AICc = 2*(degF*totalCharCount/(totalCharCount-degF-1) - LogL);

/*
fprintf (progressFilePath, CLEAR_FILE, "<html><head><META http-equiv="Content-Style-Type" content="text/css"><meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1"><title></title><LINK REL=STYLESHEET TYPE="text/css" HREF="http://www.datamonkey.org/2007/styles"></head><body background = "http://www.hyphy.org/images/aquastripe.gif" bgcolor = "#FFFFFF" >");
*/

fprintf (progressFilePath, CLEAR_FILE, "<DIV CLASS = 'RepClassSM'> Finished fitting the GBDD model with ", resp, " rate class classes <p>", 
						 	"<DL><DT class = 'DT1'> Log likelihood:", Format (LogL, 15, 5),
				 			"<DT class = 'DT2'>Parameters:", Format (degF, 15, 0),
				 			"<DT class = 'DT1'>AIC:", Format (AIC,  15, 5),
				 			"<DT class = 'DT2'>c-AIC:", Format (AICc,  15, 5),"</DL><p>Inferred rates<p>",
				 			ReportDistributionString(resp),"</DIV>");

fileID = ReportDistributionString(resp);

bivariateReturnAVL = {};
bivariateReturnAVL ["LogL"] 		= LogL;
bivariateReturnAVL ["Parameters"] 	= degF;
bivariateReturnAVL ["AIC"] 			= AIC;
bivariateReturnAVL ["cAIC"] 		= AICc;
bivariateReturnAVL ["Rates"] 		= resp;
bivariateReturnAVL ["AC"]			= AC;
bivariateReturnAVL ["AT"]			= AT;
bivariateReturnAVL ["CG"]			= CG;
bivariateReturnAVL ["CT"]			= CT;
bivariateReturnAVL ["GT"]			= GT;
bivariateReturnAVL ["Estimates"]	= reportMx;
				 

if (randomizeInitValues != 2)
{
	/*fprintf (stdout,  fileID);*/

	LIKELIHOOD_FUNCTION_OUTPUT = 7;
	if (runType == 1)
	{
		fprintf (resToPath,CLEAR_FILE,lf);
	}
	else
	{
		fprintf (resToPath,lf);
	}

	/*sumPath = resToPath + ".posterior";
	ConstructCategoryMatrix (catMat, lf, COMPLETE);

	posteriorProbs = {totalCodonCount, resp};

	catMatS = "";
	catMatS * 1024;

	for (mi2 = 0; mi2 < resp; mi2=mi2+1)
	{
		if (mi2)
		{
			catMatS * ",";
		}
		catMatS * ("Rate class " + (mi2+1) + " omega = " + reportMx[mi2][2]);
	}

	siteOffset = 0;
	for (fileID = 1; fileID <= fileCount; fileID = fileID + 1)
	{
		ExecuteCommands ("thisFilterSize=filteredData_" + fileID + ".sites;");
		for (mi=0; mi<thisFilterSize; mi=mi+1)
		{
			rs = 0;
			for (mi2 = 0; mi2 < resp; mi2=mi2+1)
			{
				posteriorProbs[mi+siteOffset][mi2] = catMat[mi+siteOffset+mi2*totalCodonCount] * reportMx[mi2][3];
				rs = rs + posteriorProbs[mi+siteOffset][mi2];
			}
			catMatS * "\n";
			for (mi2 = 0; mi2 < resp; mi2=mi2+1)
			{
				posteriorProbs[mi+siteOffset][mi2] = posteriorProbs[mi+siteOffset][mi2]/rs;
				if (mi2)
				{
					catMatS * ",";
				}
				catMatS * (""+posteriorProbs[mi+siteOffset][mi2]);
			}
		} 
		siteOffset = siteOffset + thisFilterSize;
	}
	catMatS * 0;
	fprintf (sumPath, CLEAR_FILE, catMatS);*/
}


return bivariateReturnAVL;
