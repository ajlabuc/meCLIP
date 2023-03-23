package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class BedAnnotator {
	
	static boolean inBED;

	public static void main(String[] args) throws IOException {
		
		String inputFilename = args[0];
		String outputFilename = args[1];
		BufferedReader bufferedReader = new BufferedReader(new FileReader(inputFilename));
		BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(outputFilename));
		bufferedWriter.write("Chromosome\tm6A\tStrand\tGene\tMutations\tReads\tFrequency\n");

		String line1_bed;
		while ((line1_bed = bufferedReader.readLine()) != null) {
			
			boolean run = true;
			String[] line1_fileContents = line1_bed.split("\t");
			String line1_chr = line1_fileContents[0];
			String line1_start = line1_fileContents[1];
			String[] line1_meCLIP = line1_fileContents[4].split("\\|");
			String line1_freq = line1_meCLIP[0];
			String line1_mutations = line1_meCLIP[1];
			String line1_reads = line1_meCLIP[2];
			String line1_strand = line1_fileContents[5];
			String line1_m6a = line1_chr + "_" + line1_start;
			String line1_gene = line1_fileContents[9];

			while (run) {
				
				String line2_bed;
				
				if ((line2_bed = bufferedReader.readLine()) != null) {
					
					String[] line2_fileContents = line2_bed.split("\t");
					String line2_chr = line2_fileContents[0];
					String line2_start = line2_fileContents[1];
					String line2_m6a = line2_chr + "_" + line2_start;
					
					if (!line1_m6a.equals(line2_m6a)) {
						
						run = false;
					}
				} 
				
				else {
					
					run = false;
				}
			}

			bufferedWriter.write(line1_chr + '\t' + line1_start + '\t' + line1_strand + '\t' + line1_gene + '\t' + 
					line1_mutations + '\t' + line1_reads + '\t' + line1_freq + '\n');
		}

		bufferedReader.close();
		bufferedWriter.close();
	}
}
