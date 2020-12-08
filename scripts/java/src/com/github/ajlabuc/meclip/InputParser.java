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
	
	static boolean inInput;
	
	public static void main(String[] args) throws IOException {
		
		String inputFilenameIP = args[0];
		String inputFilenameINPUT = args[1];
		String outputFilename = args[2];
		
		BufferedReader bufferedReaderIP = new BufferedReader(new FileReader(inputFilenameIP));
		BufferedReader bufferedReaderINPUT = new BufferedReader(new FileReader(inputFilenameINPUT));
		BufferedWriter bufferedWriter = new BufferedWriter(new FileWriter(outputFilename));
		
		String lineInput, lineIP, chr, m6a, position;
		String[] fileContents;
		
		ArrayList<String> m6aInputList = new ArrayList<String>();
		
		String firstLine = bufferedReaderIP.readLine();
		bufferedWriter.write(firstLine + '\n');
		bufferedReaderINPUT.readLine();
		
		while ((lineInput = bufferedReaderINPUT.readLine()) != null) {
			
			fileContents = lineInput.split("\t");
			chr = fileContents[0];
			m6a = fileContents[1];
			position = chr + "_" + m6a;
			m6aInputList.add(position);
		}
		
		while ((lineIP = bufferedReaderIP.readLine()) != null) {
			
			inInput = false;
			
			fileContents = lineIP.split("\t");
			chr = fileContents[0];
			m6a = fileContents[1];
			position = chr + "_" + m6a;
			
			Iterator<String> iterator = m6aInputList.iterator();

			for (int i = 0; i < m6aInputList.size(); i++) {
				
				String listLine = ((String) iterator.next()).toString();
				
				if (position.equals(listLine)) {
					
					inInput = true;
					break;
				}
			}

			if (!inInput) {
				
				bufferedWriter.write(lineIP + '\n');
			}
		}
		
		bufferedReaderIP.close();
		bufferedReaderINPUT.close();
		bufferedWriter.close();
	}
}
