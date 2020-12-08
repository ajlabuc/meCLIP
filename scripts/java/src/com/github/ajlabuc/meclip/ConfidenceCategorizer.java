package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

public class ConfidenceCategorizer {
	
	public static void main(String[] args) throws IOException {
		
		String inputFilename = args[0];
		String outputFilename = args[1];
		int m6aCount = 0;
		String strand = "";
		BufferedReader bufferedReader = new BufferedReader(new FileReader(inputFilename));
		BufferedWriter bufferedWriter_ALL = new BufferedWriter(new FileWriter(outputFilename + ".bed"));
		BufferedWriter bufferedWriter_LOW = new BufferedWriter(new FileWriter(outputFilename + "_lowConfidence.bed"));
		BufferedWriter bufferedWriter_HIGH = new BufferedWriter(new FileWriter(outputFilename + "_highConfidence.bed"));
		bufferedReader.readLine();

		String line;
		String chr;
		String m6a;
		String metadata;
		String m6a_count;
		
		for (; (line = bufferedReader.readLine()) != null; bufferedWriter_ALL
				.write(chr + '\t' + m6a + '\t' + m6a + '\t' + m6a_count + '\t' + metadata + '\t' + strand + '\n')) {
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
			} 
			
			else {
				
				bufferedWriter_HIGH.write(
						chr + '\t' + m6a + '\t' + m6a + '\t' + m6a_count + '\t' + metadata + '\t' + strand + '\n');
			}
		}

		bufferedReader.close();
		bufferedWriter_ALL.close();
		bufferedWriter_LOW.close();
		bufferedWriter_HIGH.close();
	}
}
