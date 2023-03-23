package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map.Entry;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.biojava.nbio.core.sequence.DNASequence;
import org.biojava.nbio.core.sequence.io.FastaReaderHelper;

/**
 * @author Justin Roberts
 *
 */

public class MotifFrequencyCalculator {
	
	/**
	 * @param args
	 * @throws CompoundNotFoundException 
	 * @throws IOException 
	 * @throws IllegalSymbolException 
	 */
	
	public static void main(String[] args) throws IOException {
		
		String inputFilename_fa = args[0];
		String inputFilename_xls = args[1];
		String inputMotif = args[2];
		File file2 = new File(inputFilename_xls);
		String name = file2.getName();
		String[] filename = name.split("\\.");
		String outputFilename = filename[0];
		String path = file2.getParent();
		
		String line, match;
		
		Pattern p = Pattern.compile(inputMotif);
		
		BufferedReader bufferedReader = new BufferedReader(new FileReader(inputFilename_xls));
		BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(path + "/" + outputFilename + "_motifFrequency.xls"));
        LinkedHashMap<String, DNASequence> a = FastaReaderHelper.readFastaDNASequence(new File(inputFilename_fa));
   
        while ((line = bufferedReader.readLine()) != null) {
 
        	for (Entry<String, DNASequence> entry : a.entrySet() ) {
        	
        		String sequence = entry.getValue().getSequenceAsString();       	
        		Matcher matcher = p.matcher(sequence);
        	
        		if (matcher.matches() == true) {

        			match = "Yes";
        		}
        		
        		else {
    			
        			match = "No";
        		}

        		bufferedWriter.write(line + '\t' + match + '\n');
        		line = bufferedReader.readLine();
        	}
        }
         			
        bufferedReader.close();
		bufferedWriter.close();
	}
}
