/*
	Converts output from 1942.v to .wav file

  (c) Jose Tejada Gomez, 9th May 2013
  You can use this file following the GNU GENERAL PUBLIC LICENSE version 3
  Read the details of the license in:
  http://www.gnu.org/licenses/gpl.txt
  
  Send comments to: jose.tejada@ieee.org

*/

// Compile with  g++ log2wav.cc -o log2wav

#include <iostream>
#include <fstream>
#include <vector>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

using namespace std;

int main(int argc, char *argv[]) {
	try {
		ifstream fin;
		if( argc == 2) 
			fin.open(argv[1]);
		else
			fin.open("/dev/stdin");
		ofstream fout("out.wav");
		if( fin.bad() ) throw "Cannot open input file";
		if( fout.bad() ) throw "Cannot open output file";		
		assert( sizeof(short int)==2 );
		char buffer[1024];
		int data=0;
		
		// depending on the simulator the following "while"
		// section might no be needed or modified
		// It just skips simulator output until the real data
		// starts to come out
		while( !fin.eof() ) {
			fin.getline( buffer, sizeof(buffer) );
			if( strcmp(buffer,"ncsim> run" )==0) break;
		} 
		
		if( fin.eof() ) throw "Data not found";
		fout.seekp(44);
		while( !fin.eof() ) {
			short int value;
			fin.getline( buffer, sizeof(buffer) );
			if( buffer[0]=='S' ) break; // reached line "Simulation complete"
			value = atoi( buffer );
			fout.write( (char*) &value, sizeof(value) );
			data++;
		}
		cout << data << " samples written\n";
		// Write the header
		const char *RIFF = "RIFF";
		fout.seekp(0);
		fout.write( RIFF, 4 );
		int aux=36+2*data;
		fout.write( (char*)&aux, 4 );
		const char *WAVE = "WAVE";
		fout.write( WAVE, 4 );
		const char *fmt = "fmt ";
		fout.write( fmt, 4 );
		aux=16;
		fout.write( (char*)&aux, 4 );// suubchunk 1 size
		short int aux_short = 1; 
		fout.write( (char*)&aux_short, 2 ); // audio format (1)
		fout.write( (char*)&aux_short, 2 ); // num channels (1)
		aux=44100;
		fout.write( (char*)&aux, 4 );
		aux=44100*1*2;		
		fout.write( (char*)&aux, 4 ); // byte rate
		aux_short=2;		
		fout.write( (char*)&aux_short, 2 ); // block align		
		aux_short=16;		
		fout.write( (char*)&aux_short, 2 ); // bits per sample
		RIFF="data";
		fout.write( RIFF, 4 );
		aux = data*2;
		fout.write( (char*)&aux, 4 ); // data size		
		return 0;
	}
	catch( const char *msg ) {
    cout << msg << "\n";
    return -1;
  }
}
