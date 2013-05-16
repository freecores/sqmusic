#include <iostream>
#include <cmath>

using namespace std;

int main(void) {
	const double pi = 3.141592654;
	const double factor = pi / 1024;
	for(double i=0; i<1024; i++ )
		cout << sin( (2*i+1)*factor ) << "\n";
	return 0;
}
