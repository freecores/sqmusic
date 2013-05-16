/*
	sintable: sine wave table generator
	Based on MAME's fm.c file.

  (c) Jose Tejada Gomez, May 2013
  You can use this file following the GNU GENERAL PUBLIC LICENSE version 3
  Read the details of the license in:
  http://www.gnu.org/licenses/gpl.txt
  
  Send comments to: jose.tejada at ieee.org

*/

#include <iostream>
#include <cmath>

using namespace std;

unsigned conv( double x ) {
  double xmax = 0xFFFFF; // 20 bits, all ones
  return (unsigned)(xmax* 20*log(x+0.5));
}

int main(void) {
	const double pi = 3.141592654;
	const double factor = pi / 1024;
	cout.setf( ios::hex, ios::basefield );
	for(double i=0; i<1024; i++ ) {
	  double sin_val = sin( (2*i+1)*factor );
	  double log_val = 8*log( 1/abs(sin_val) )/log(2);
	  int rounded_val = log_val*2;
	  rounded_val = rounded_val&1 ? (rounded_val>>1)+1 : rounded_val>>1;
	  unsigned int sin_tab = (rounded_val<<1) + (sin_val>=0.0? 0: 1);	  
		cout << sin_val << " -> " << log_val << " dB2 " << " -> " 
		  << rounded_val << " -> " << sin_tab << "\n";
	}
	return 0;
}
