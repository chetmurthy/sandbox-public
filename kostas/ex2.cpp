#include <unistd.h>
#include <bitset>
#include <cassert>
#include <cstdint>
#include <cstdio>
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

  inline void just_read() {
    char c ;

    while(cin.get(c)) {
    }
  }

  inline void read_and_parse(const bool doinsert) {
    char c ;

    uint32_t ip = 0;
    uint32_t octet = 0;
    while(cin.get(c)) {
      if (c == '\n') {
	ip = (ip << 8) | octet ;
	if (doinsert) insert(ip) ;
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

  inline void just_read0_stdio() {
    char c ;
    const size_t SIZE = 1024 ;
    char buf[SIZE] ;

    while(0 < read(0, buf, SIZE)) {
    }
  }

  inline void just_read_stdio() {
    char c ;

    while(-1 != (c = getchar())) {
    }
  }

  inline void read_and_parse_stdio(const bool doinsert) {
    char c ;

    uint32_t ip = 0;
    uint32_t octet = 0;
    while(-1 != (c = getchar())) {
      if (c == '\n') {
	ip = (ip << 8) | octet ;
	if (doinsert) insert(ip) ;
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

  vector< ENTRY > entries ;

  inline void unload() {
      entries.resize(counts.size()) ;

    int i = 0 ;
    for(KEYMAP::const_iterator e = counts.begin() ; e != counts.end() ; ++e) {
      ENTRY& ve = entries.at(i++) ;
      ve.first = e->first ;
      ve.second = e->second ;
    }
  }

  inline void sort() {
    std::sort (entries.begin(), entries.end(), compare);
  }

  bitset<(1UL<<32)> *uniques = NULL ;
  KEYMAP counts ;
} ;

int
main(int ac, char **av) {
  high_resolution_clock::time_point stime, etime ;
  duration<double> elapsed ;

  if ("just-read" == string(av[1])) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.just_read() ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "just-read: "<< elapsed.count() << endl ;

  }

  else if ("just-read0-stdio" == string(av[1])) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.just_read0_stdio() ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "just-read0-stdio: "<< elapsed.count() << endl ;

  }

  else if ("just-read-stdio" == string(av[1])) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.just_read_stdio() ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "just-read-stdio: "<< elapsed.count() << endl ;

  }

  else if ("read-and-parse" == string(av[1])) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_and_parse(false) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read-and-parse: "<< elapsed.count() << endl ;

  }

  else if ("read-and-parse-stdio" == string(av[1])) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_and_parse_stdio(false) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read-and-parse-stdio: "<< elapsed.count() << endl ;

  }

  else if ("top-k-ips" == string(av[1])) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_and_parse_stdio(true) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read: "<< elapsed.count() << endl ;

    cerr << it.counts.size() << " entries" << endl ;

    stime = high_resolution_clock::now() ;
    it.unload() ;
    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "unload: " << elapsed.count() << endl ;

    stime = high_resolution_clock::now() ;
    it.sort() ;
    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "sort: " << elapsed.count() << endl ;
  }
  else {
    cerr << "no task selected\n" ;
  }
}
