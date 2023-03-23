package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class ConfidenceCategorizer {
	
	public static void main(String[] args) throws IOException {
		
		String inputFilename = args[0];
		String outputName = args[1];
		String outputPrefix = args[2];
		String inputFiltered = args[3];
	
		int lowCount = 0;
		int highCount = 0;
		int m6aCount = 0;
		String strand = "";

		BufferedReader bufferedReader = new BufferedReader(new FileReader(inputFilename));
		BufferedWriter bufferedWriter_ALL = new BufferedWriter(new FileWriter(outputPrefix + ".bed"));
		BufferedWriter bufferedWriter_LOW = new BufferedWriter(new FileWriter(outputPrefix + ".lowConfidence.bed"));
		BufferedWriter bufferedWriter_HIGH = new BufferedWriter(new FileWriter(outputPrefix + ".highConfidence.bed"));
		BufferedWriter bufferedWriter_SUMMARY = new BufferedWriter(new FileWriter(outputPrefix + ".summary.tsv"));
		
		
		bufferedReader.readLine();

		bufferedWriter_SUMMARY.write("Sample Name" + '\t' + "% Input Filtered" + '\t' + "Low Confidence m6A" + '\t' + "High Confidence m6A" + '\t' + "Total m6A" + '\n');

		String line;
		String chr;
		String m6a;
		String metadata;
		String m6a_count;
		
		while ((line = bufferedReader.readLine()) != null) {
			
			String[] fileContents = line.split("\t");
			chr = fileContents[0];
			m6a = fileContents[1];
			String ref = fileContents[2];
			String freq = fileContents[3];
			String mutationCount = fileContents[4];
			String readCount = fileContents[5];
			
			metadata = freq + "|" + mutationCount + "|" + readCount;
			++m6aCount;
			m6a_count = "m6A_" + m6aCount;
			double frequency = Double.parseDouble(freq);
			
			if (ref.equals("C")) {
				
				strand = "+";
			} 
			
			else if (ref.equals("G")) {
				
				strand = "-";
			}

			if (frequency < 0.05) {
				
				bufferedWriter_LOW.write(
						chr + '\t' + m6a + '\t' + m6a + '\t' + m6a_count + '\t' + metadata + '\t' + strand + '\n');
				++lowCount;
			} 
			
			else {
				
				bufferedWriter_HIGH.write(
						chr + '\t' + m6a + '\t' + m6a + '\t' + m6a_count + '\t' + metadata + '\t' + strand + '\n');
				++highCount;
			}

			bufferedWriter_ALL.write(chr + '\t' + m6a + '\t' + m6a + '\t' + m6a_count + '\t' + metadata + '\t' + strand + '\n');
		}

		bufferedWriter_SUMMARY.write(outputName + '\t' + inputFiltered + '\t' + Integer.toString(lowCount) + '\t' + Integer.toString(highCount) + '\t' + Integer.toString(m6aCount));

		bufferedReader.close();
		bufferedWriter_ALL.close();
		bufferedWriter_LOW.close();
		bufferedWriter_HIGH.close();
		bufferedWriter_SUMMARY.close();
	}
}
