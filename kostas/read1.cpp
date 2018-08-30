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

#ifdef UNBOXED
struct KEY {
  uint64_t first, second;
  KEY(const string& line) {
    memcpy((void *)&(first), line.c_str(), line.length()) ;
  }
  KEY() : first(0), second(0) {  }
} ;

struct KeyHash {
 std::size_t operator()(const KEY& k) const
 {
     return std::hash<uint64_t>()(k.first) ^
            (std::hash<uint64_t>()(k.second) << 1);
 }
};

struct KeyEqual {
 bool operator()(const KEY& lhs, const KEY& rhs) const
 {
    return lhs.first == rhs.first && lhs.second == rhs.second;
 }
};

typedef unordered_map<KEY, int, KeyHash, KeyEqual> KEYMAP ;

#else
typedef string KEY ;

typedef unordered_map<KEY, int> KEYMAP ;

#endif
 
typedef pair<KEY, int> ENTRY ;

bool compare (const ENTRY &x, const ENTRY &y) { return (x.second < y.second); }

int
main(int ac, char **av) {
  high_resolution_clock::time_point stime, etime ;
  duration<double> elapsed ;

  KEYMAP counts ;

  stime = high_resolution_clock::now() ;
  {
    string line ;
    while(cin) {
      getline(cin, line) ;
      if (!cin) break ;

      KEY k(line) ;
    }
  }
  etime = high_resolution_clock::now() ;
  elapsed = duration_cast<duration<double>>(etime - stime);  
  cerr << "read: " << elapsed.count() << endl ;
}
