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

#define ENV_BITS        10
#define ENV_LEN         (1<<ENV_BITS)
#define ENV_STEP        (128.0/ENV_LEN)
#define TL_RES_LEN      (256) /* 8 bits addressing (real chip) */
#define SIN_BITS        10
#define SIN_LEN         (1<<SIN_BITS)
#define SIN_MASK        (SIN_LEN-1)
#define TL_TAB_LEN (13*2*TL_RES_LEN)

signed int tl_tab[TL_TAB_LEN];
unsigned int sin_tab[SIN_LEN];

void init_tables(void) // copied from fm.c
{
	signed int i,x;
	signed int n;
	double o,m;

	for (x=0; x<TL_RES_LEN; x++)
	{
		m = (1<<16) / pow(2, (x+1) * (ENV_STEP/4.0) / 8.0);
		m = floor(m);

		/* we never reach (1<<16) here due to the (x+1) */
		/* result fits within 16 bits at maximum */

		n = (int)m;     /* 16 bits here */
		n >>= 4;        /* 12 bits here */
		if (n&1)        /* round to nearest */
			n = (n>>1)+1;
		else
			n = n>>1;
						/* 11 bits here (rounded) */
		n <<= 2;        /* 13 bits here (as in real chip) */
		tl_tab[ x*2 + 0 ] = n;
		tl_tab[ x*2 + 1 ] = -tl_tab[ x*2 + 0 ];

		for (i=1; i<13; i++)
		{
			tl_tab[ x*2+0 + i*2*TL_RES_LEN ] =  tl_tab[ x*2+0 ]>>i;
			tl_tab[ x*2+1 + i*2*TL_RES_LEN ] = -tl_tab[ x*2+0 + i*2*TL_RES_LEN ];
		}
	}

	for (i=0; i<SIN_LEN; i++)
	{
		/* non-standard sinus */
		m = sin( ((i*2)+1) * M_PI / SIN_LEN ); /* checked against the real chip */

		/* we never reach zero here due to ((i*2)+1) */
		if (m>0.0)
			o = 8*log(1.0/m)/log(2.0);  /* convert to 'decibels' */
		else
			o = 8*log(-1.0/m)/log(2.0); /* convert to 'decibels' */

		o = o / (ENV_STEP/4);

		n = (int)(2.0*o);
		if (n&1)                        /* round to nearest */
			n = (n>>1)+1;
		else
			n = n>>1;

		sin_tab[ i ] = n*2 + (m>=0.0? 0: 1 );
		/*logerror("FM.C: sin [%4i]= %4i (tl_tab value=%5i)\n", i, sin_tab[i],tl_tab[sin_tab[i]]);*/
	}
}

void dump_tl_tab() {
	// cout.setf( ios::hex, ios::basefield );
  for( int i=0; i<TL_TAB_LEN; i++ ) {
    cout << i << " => " << tl_tab[i] << "\n";
  }
}

void dump_sin_tab() {
	// cout.setf( ios::hex, ios::basefield );
  for( int i=0; i<SIN_LEN; i++ ) {
    cout /*<< i << " => " */<< sin_tab[i] << "\n";
  }
}

void dump_composite() {
	// cout.setf( ios::hex, ios::basefield );
  for( int i=0; i<SIN_LEN; i++ ) {
    cout << sin_tab[i] << "," << tl_tab[ sin_tab[i] ] << "\n";
  }
}

unsigned conv( double x ) {
  double xmax = 0xFFFFF; // 20 bits, all ones
  return (unsigned)(xmax* 20*log(x+0.5));
}

int main(void) {
  init_tables();  
	dump_composite();
	return 0;
}
