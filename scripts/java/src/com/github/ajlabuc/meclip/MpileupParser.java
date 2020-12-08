package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

/**
 * @author Justin Roberts
 * 
 * For motif offsets, count number of nucleotides to left and right of mutation, i.e. for 'DRACH'
 * where the mutation is the 'C', the left offset would be 3 and the right offset would be 1. For
 * the frequency cutoffs, the low value is inclusive and the high value is exclusive.
 *
 */
public class MpileupParser {

	/**
	 * @param args
	 * @throws IOException 
	 */
	
	public static void main(String[] args) throws IOException {
		
		int mutationCount, m6a;
		int motifStart = 0;
		int motifEnd = 0;
		Double freq;		
		String line, strand;
		
		String inputFilename = args[0];
		String outputPrefix = args[1];
		double freqCutoff_low = Double.parseDouble(args[2]);
		double freqCutoff_high = Double.parseDouble(args[3]);		
		int motifOffset_left = Integer.parseInt(args[4]);
		int motifOffset_right = Integer.parseInt(args[5]);
		
		File file = new File(inputFilename);
		String path = file.getParent();
		
		BufferedReader bufferedReader = new BufferedReader(new FileReader(inputFilename));
		BufferedWriter bufferedWriter_mpileupParser_positive = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_mpileupParser_positive.xls"));
		BufferedWriter bufferedWriter_mpileupParser_negative = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_mpileupParser_negative.xls"));
		BufferedWriter bufferedWriter_motifList_positive = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_motifList_positive.txt"));
		BufferedWriter bufferedWriter_motifList_negative = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_motifList_negative.txt"));
				
		while ((line = bufferedReader.readLine()) != null) {
			
			mutationCount = 0;
			m6a = 0;
			freq = 0.0;
			strand = "";
			
			String[] fileContents = line.split("\t");
			String chr = fileContents[0];
			int position = Integer.parseInt(fileContents[1]);
			String ref = fileContents[2];
			Double readCount = Double.parseDouble(fileContents[3]);
			String reads = fileContents[4];
			char[] readsCharArray = reads.toCharArray();
			
			if (ref.equals("C")) {
				
				for (int i = 0; i < readsCharArray.length; i++) {
					
					if (readsCharArray[i] == 'T') {
						
						mutationCount++;
						m6a = position - 1;
						motifStart = position - (motifOffset_left + 1);
    					motifEnd = position + motifOffset_right;
    					strand = "positive";
					}
				}
			}

			else if (ref.equals("G")) { 
				
				for (int i = 0; i < readsCharArray.length; i++) {
					
					if (readsCharArray[i] == 'a') {
						
						mutationCount++;
						m6a = position + 1;
        				motifStart = position - (motifOffset_left - 1);
        				motifEnd = position + (motifOffset_right + 2);
        				strand = "negative";
					}
				}
			}
			
			freq = mutationCount / readCount;
			
			if ((freq >= freqCutoff_low) && (freq <= freqCutoff_high) && (mutationCount >=3)) {
							
				if (strand.equals("positive")) {
					
					bufferedWriter_mpileupParser_positive.write(chr + '\t' + m6a + '\t' + ref + '\t' + freq + '\t' + mutationCount + '\t' + readCount + '\t' + motifStart + '\t' + motifEnd + '\n');
					bufferedWriter_motifList_positive.write(chr + ":" + motifStart + "-" + motifEnd + '\n');
				}
				
				else if (strand.equals("negative")) {
					
					bufferedWriter_mpileupParser_negative.write(chr + '\t' + m6a + '\t' + ref + '\t' + freq + '\t' + mutationCount + '\t' + readCount + '\t' + motifStart + '\t' + motifEnd + '\n');
					bufferedWriter_motifList_negative.write(chr + ":" + motifStart + "-" + motifEnd + '\n');
				}
			}
		}
		
		bufferedReader.close();
		bufferedWriter_mpileupParser_positive.close();
		bufferedWriter_mpileupParser_negative.close();
		bufferedWriter_motifList_positive.close();
		bufferedWriter_motifList_negative.close();
	}
}
