#include <bitset>
#include <cassert>
#include <cstdint>
#include <algorithm>    // std::sort
#include <chrono>
#include <iostream>
#include <unordered_map>
#include <random>
#include <string>
#include <vector>
#include <string.h>

using namespace std ;
using namespace std::chrono;

typedef uint32_t KEY ;

typedef unordered_map<KEY, int> KEYMAP ;

typedef pair<KEY, int> ENTRY ;

bool compare (const ENTRY &x, const ENTRY &y) { return (x.second < y.second); }

void
pp(uint32_t ip) {
  union {
    unsigned char cp[4] ;
    uint32_t n ;
  } xx ;
  xx.n = ip ;
  //  printf("%d.%d.%d.%d\n", xx.cp[3], xx.cp[2], xx.cp[1], xx.cp[0]) ;
}

class IT {
public:

  IT() {
    uniques = new bitset<(1UL<<32)>() ;
  }

  inline void insert(const uint32_t ip) {
    if ((*uniques)[ip]) {
      counts[ip]++ ;
    }
    else {
      (*uniques)[ip] = true ;
    }
  }

  inline void load() {
    char c ;

    uint32_t ip = 0;
    uint32_t octet = 0;
    while(cin.get(c)) {
      if (c == '\n') {
	ip = (ip << 8) | octet ;
	insert(ip) ;
	ip = 0 ;
	octet = 0 ;
      }
      else if ('0' <= c && c <= '9') {
	octet = octet * 10 + (c - '0') ;
      }
      else if (c == '.') {
	ip = (ip << 8) | octet ;
	octet = 0 ;
      }
      else { assert(false) ; }

    }
  }
  bitset<(1UL<<32)> *uniques = NULL ;
  KEYMAP counts ;
} ;

int
main(int ac, char **av) {
  high_resolution_clock::time_point stime, etime ;
  duration<double> elapsed ;
  IT it ;

  stime = high_resolution_clock::now() ;
  it.load() ;

  etime = high_resolution_clock::now() ;
  elapsed = duration_cast<duration<double>>(etime - stime);  
  cerr << "read: "<< elapsed.count() << endl ;

  cerr << it.counts.size() << " entries" << endl ;

  vector< ENTRY > entries(it.counts.size()) ;

  stime = high_resolution_clock::now() ;
  {
    int i = 0 ;
    for(KEYMAP::const_iterator e = it.counts.begin() ; e != it.counts.end() ; ++e) {
      ENTRY& ve = entries.at(i++) ;
      ve.first = e->first ;
      ve.second = e->second ;
    }
  }
  etime = high_resolution_clock::now() ;
  elapsed = duration_cast<duration<double>>(etime - stime);  
  cerr << "unload: " << elapsed.count() << endl ;

  stime = high_resolution_clock::now() ;
  std::sort (entries.begin(), entries.end(), compare); // 12 32 45 71(26 33 53 80)
  etime = high_resolution_clock::now() ;
  elapsed = duration_cast<duration<double>>(etime - stime);  
  cerr << "sort: " << elapsed.count() << endl ;

}
