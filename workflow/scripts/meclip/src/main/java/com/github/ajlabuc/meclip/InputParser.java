package com.github.ajlabuc.meclip;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Iterator;

/**
 * @author Justin Roberts
 *
 */

public class InputParser {

	/**
	 * @param args
	 */
	
	static boolean inINPUT;
	
	public static void main(String[] args) throws IOException {
		
		String inputFilename_IP = args[0];
		String inputFilename_INPUT = args[1];
		String outputFilename = args[2];
		
		BufferedReader bufferedReader_IP = new BufferedReader(new FileReader(inputFilename_IP));
		BufferedReader bufferedReader_INPUT = new BufferedReader(new FileReader(inputFilename_INPUT));
		BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(outputFilename));
		
		String line_INPUT, line_IP, chr, m6a, position;
		String[] fileContents;
		
		ArrayList<String> m6a_inputList = new ArrayList<String>();
		
		String firstLine = bufferedReader_IP.readLine();
		bufferedWriter.write(firstLine + '\n');
		bufferedReader_INPUT.readLine();
		
		while ((line_INPUT = bufferedReader_INPUT.readLine()) != null) {
			
			fileContents = line_INPUT.split("\t");
			chr = fileContents[0];
			m6a = fileContents[1];
			position = chr + "_" + m6a;
			m6a_inputList.add(position);
		}
		
		while ((line_IP = bufferedReader_IP.readLine()) != null) {
			
			inINPUT = false;
			
			fileContents = line_IP.split("\t");
			chr = fileContents[0];
			m6a = fileContents[1];
			position = chr + "_" + m6a;
			
			Iterator<String> iterator = m6a_inputList.iterator();

			for (int i = 0; i < m6a_inputList.size(); i++) {
				
				String listLine = ((String) iterator.next()).toString();
				
				if (position.equals(listLine)) {
					
					inINPUT = true;
					break;
				}
			}

			if (!inINPUT) {
				
				bufferedWriter.write(line_IP + '\n');
			}
		}
		
		bufferedReader_IP.close();
		bufferedReader_INPUT.close();
		bufferedWriter.close();
	}
}
