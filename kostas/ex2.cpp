#include <fcntl.h>
#include <linux/fadvise.h>
#include <unistd.h>
#include <bitset>
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <algorithm>    // std::sort
#include <chrono>
#include <istream>
#include <fstream>
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

  inline void do_just_read(istream& is) {
    char c ;

    while(is.get(c)) {
    }
  }

  inline void just_read(const string& fname) {
    if ("-" == fname) {
      do_just_read(cin) ;
    }
    else {
      ifstream is ;
      is.open (fname, std::ifstream::in);
      do_just_read(is) ;
      
    }
  }

  inline uint32_t parse(char *cp, const char *lim) {
    uint32_t ip = 0;
    uint32_t octet = 0;
    
    while (cp < lim) {
      char c = *cp++ ;
      if ('0' <= c && c <= '9') {
	octet = octet * 10 + (c - '0') ;
      }
      else if (c == '.') {
	ip = (ip << 8) | octet ;
	octet = 0 ;
      }
      else { assert(false) ; }
    }
    ip = (ip << 8) | octet ;
    return ip ;
  }

  inline void print(uint32_t ip) {
    union {
      unsigned char octets[4] ;
      uint32_t word ;
    } b ;
    b.word = ip ;
    printf("%d.%d.%d.%d\n", b.octets[3], b.octets[2], b.octets[1], b.octets[0]) ;
  }

  inline void read_lines_and_parse(const string& fname, bool doprint) {
    if ("-" == fname) {
      do_read_lines_and_parse(cin, doprint) ;
    }
    else {
      ifstream is ;
      is.open (fname, std::ifstream::in);
      do_read_lines_and_parse(is, doprint) ;
      
    }
  }

  inline void do_read_lines_and_parse(istream& is, bool doprint) {
    string line ;

    while(is) {
      getline(is, line) ;
      if (!is) break ;

      const char *cp = line.c_str() ;
      const char *lim = cp + line.size() ;
      uint32_t ip = parse(const_cast<char *>(cp), lim) ;
      if (doprint) print(ip) ;
    }
  }
  inline void do_read_and_parse(istream& is, const bool doinsert, const bool doprint) {
    char c ;

    uint32_t ip = 0;
    uint32_t octet = 0;
    while(is.get(c)) {
      if (c == '\n') {
	ip = (ip << 8) | octet ;
	if (doinsert) insert(ip) ;
	if (doprint) print(ip) ;
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

  inline void read_and_parse(const string& fname, const bool doinsert, const bool doprint) {
    if ("-" == fname) {
      do_read_and_parse(cin, doinsert, doprint) ;
    }
    else {
      ifstream is ;
      is.open (fname, std::ifstream::in);
      do_read_and_parse(is, doinsert, doprint) ;
      
    }
  }

  inline void do_just_read0(int fd) {
    char c ;
    const size_t SIZE = 131072 ;
    char buf[SIZE] ;

    
    posix_fadvise (fd, 0, 0, POSIX_FADV_SEQUENTIAL);
    while(0 < read(fd, buf, SIZE)) {
    }
  }

  inline void just_read0(const string& fname) {
    if ("-" == fname) {
      do_just_read0(0) ;
    }
    else {
      int fd = open(fname.c_str(), O_RDONLY) ;
      if (fd < 0) perror("just_read0: open") ;
      do_just_read0(fd) ;
    }
  }

  inline void do_just_read_stdio(FILE *fp) {
    char c ;

    while(-1 != (c = getc(fp))) {
    }
  }

  inline void just_read_stdio(const string& fname) {
    if ("-" == fname) {
      do_just_read_stdio(stdin) ;
    }
    else {
      FILE *fp = fopen(fname.c_str(), "r") ;
      do_just_read_stdio(fp) ;
    }
  }

  inline void do_read_and_parse_stdio(FILE *fp, const bool doinsert, const bool doprint) {
    char c ;

    uint32_t ip = 0;
    uint32_t octet = 0;
    while(-1 != (c = getc(fp))) {
      if (c == '\n') {
	ip = (ip << 8) | octet ;
	if (doinsert) insert(ip) ;
	if (doprint) print(ip) ;
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

  inline void read_and_parse_stdio(const string& fname, const bool doinsert, const bool doprint) {
    if ("-" == fname) {
      do_read_and_parse_stdio(stdin, doinsert, doprint) ;
    }
    else {
      FILE *fp = fopen(fname.c_str(), "r") ;
      do_read_and_parse_stdio(fp, doinsert, doprint) ;
    }
  }

  inline void do_read0_and_parse(int fd, const bool doinsert, const bool doprint) {
    char c ;

    uint32_t ip = 0;
    uint32_t octet = 0;

    const size_t SIZE = 1024 ;
    char buf[SIZE] ;
    char *lim = buf + SIZE ;
    char *cp = lim ;

    while(true) {
      if (cp == lim) {
	size_t nread = read(fd, buf, SIZE) ;
	if (0 == nread) { break ; }
	lim = buf + nread ;
	cp = buf ;
      }
      c = *cp++ ;

      if (c == '\n') {
	ip = (ip << 8) | octet ;
	if (doinsert) insert(ip) ;
	if (doprint) print(ip) ;
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

  inline void read0_and_parse(const string& fname, const bool doinsert, const bool doprint) {
    if ("-" == fname) {
      do_read0_and_parse(0, doinsert, doprint) ;
    }
    else {
      int fd = open(fname.c_str(), O_RDONLY) ;
      if (fd < 0) perror("read0_and_parse: open") ;
      do_read0_and_parse(fd, doinsert, doprint) ;
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

  assert(ac >= 3) ;

  string op = av[1] ;
  string fname = av[2] ;

  if ("just-read" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.just_read(fname) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "just-read: "<< elapsed.count() << endl ;

  }

  else if ("just-read0" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.just_read0(fname) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "just-read0: "<< elapsed.count() << endl ;

  }

  else if ("just-read-stdio" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.just_read_stdio(fname) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "just-read-stdio: "<< elapsed.count() << endl ;

  }

  else if ("read-lines-and-parse" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_lines_and_parse(fname, false) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read-lines-and-parse: "<< elapsed.count() << endl ;
  }

  else if ("read-lines-and-print" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_lines_and_parse(fname,true) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read-lines-and-print: "<< elapsed.count() << endl ;
  }

  else if ("read-and-parse" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_and_parse(fname, false, false) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read-and-parse: "<< elapsed.count() << endl ;

  }

  else if ("read-and-parse-stdio" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read_and_parse_stdio(fname, false, false) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read-and-parse-stdio: "<< elapsed.count() << endl ;

  }

  else if ("read0-and-parse" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read0_and_parse(fname, false, false) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read0-and-parse: "<< elapsed.count() << endl ;

  }

  else if ("read0-and-print" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read0_and_parse(fname, false, true) ;

    etime = high_resolution_clock::now() ;
    elapsed = duration_cast<duration<double>>(etime - stime);  
    cerr << "read0-and-print: "<< elapsed.count() << endl ;

  }

  else if ("top-k-ips" == op) {
    IT it ;

    stime = high_resolution_clock::now() ;
    it.read0_and_parse(fname, true, false) ;

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
