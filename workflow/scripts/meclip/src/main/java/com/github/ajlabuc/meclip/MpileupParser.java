package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

import org.biojava.nbio.core.sequence.DNASequence;
import org.biojava.nbio.core.exceptions.CompoundNotFoundException;

/**
 * @author Justin Roberts
 * 
 * For conversion definitions, use uppercase letters
 * 
 * For frequency cutoffs, the low value is inclusive and the high value is exclusive.
 * 
 * For motif offsets, count number of nucleotides to left and right of mutation, i.e. for 'DRACH'
 * where the mutation is the 'C', the left offset would be 3 and the right offset would be 1. 
 *
 */
public class MpileupParser {

	/**
	 * @param args
	 * @throws IOException 
	 * @throws CompoundNotFoundException
	 */
	
	public static void main(String[] args) throws IOException, CompoundNotFoundException {
		
		int mutationCount, m6a;
		int motifStart = 0;
		int motifEnd = 0;
		Double freq;		
		String line, strand;
		
		String inputFilename = args[0];
		String outputPrefix = args[1];
		DNASequence reference = new DNASequence(args[2]);
		DNASequence mutation = new DNASequence(args[3]);
		double freqCutoff_low = Double.parseDouble(args[4]);
		double freqCutoff_high = Double.parseDouble(args[5]);		
		int motifOffset_left = Integer.parseInt(args[6]);
		int motifOffset_right = Integer.parseInt(args[7]);
		
		String reference_rc = reference.getReverseComplement().getSequenceAsString();
		String mutation_rc = mutation.getReverseComplement().getSequenceAsString();
	
		File file = new File(inputFilename);
		String path = file.getParent();
		
		BufferedReader bufferedReader = new BufferedReader(new FileReader(inputFilename));
		BufferedWriter bufferedWriter_mpileupParser_positive = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_MpileupParser_positive.xls"));
		BufferedWriter bufferedWriter_mpileupParser_negative = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_MpileupParser_negative.xls"));
		BufferedWriter bufferedWriter_motifList_positive = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_motifList_positive.bed"));
		BufferedWriter bufferedWriter_motifList_negative = new BufferedWriter(new FileWriter(path + "/" + outputPrefix + "_motifList_negative.bed"));
				
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
			
			if (ref.equals(reference.getSequenceAsString())) {
				
				for (int i = 0; i < readsCharArray.length; i++) {
					
					if (readsCharArray[i] == mutation.getSequenceAsString().charAt(0)) {
						
						mutationCount++;
						m6a = position - 1;
						motifStart = position - (motifOffset_left + 1);
    					motifEnd = position + motifOffset_right;
    					strand = "positive";
					}
				}
			}

			else if (ref.equals(reference_rc)) { 
				
				for (int i = 0; i < readsCharArray.length; i++) {
					
					if (readsCharArray[i] == mutation_rc.toLowerCase().charAt(0)) {
						
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
					bufferedWriter_motifList_positive.write(chr + '\t' + motifStart + '\t' + motifEnd + '\n');
				}
				
				else if (strand.equals("negative")) {
					
					bufferedWriter_mpileupParser_negative.write(chr + '\t' + m6a + '\t' + ref + '\t' + freq + '\t' + mutationCount + '\t' + readCount + '\t' + motifStart + '\t' + motifEnd + '\n');
					bufferedWriter_motifList_negative.write(chr + '\t' + motifStart + '\t' + motifEnd + '\n');
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
