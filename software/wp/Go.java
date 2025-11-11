// A simple program which interfaces to the W-Prolog engine.
// Author: Michael Winikoff (winikoff@cs.mu.oz.au)
// Date: 6/3/97
//
// Usage: java Go append.pl "append([1,2],X,[1,2,3,4])"
// 
// 

import java.io.*;
import java.util.*;
import ParseString;
import Term;
import Engine;

public class Go {
	static public void main(String args[]) {
		FileInputStream fis;
		String program; String query = args[1];

		try {
			fis = new FileInputStream(new File(args[0]));
			try {
				byte b[] = new byte[fis.available()];
				fis.read(b);
				fis.close();
				program = new String(b,0);
				// Have loaded program ... run query ...
				run(program,query);
			} catch (java.io.IOException x) {
				System.out.println("Can't read: " +args[0]);
			}
		} catch (FileNotFoundException x) {
			System.out.println("Can't open: " +args[0]);
		}
	}

	static private void run(String prog, String query) {
                Term t; Engine eng;

                try {
			// second arg null ... nowhere for error to be indicated
                        t = new Term(new ParseString(query,null));
			try {
			    eng = new Engine(t, 
			    ParseString.consult(prog, new Hashtable(),null));
				// don't indicate error
			    System.out.println(eng.run(true));
                	} catch (Exception f) { 
				System.out.println("Can't parse program!");
			}
                } catch (Exception f) {
                        System.out.println("Can't parse query!\n");
                        t = null; // dummy
                }
	}
}

