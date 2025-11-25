module Utility::Hash

import util::Reflective;

int rascalHash(value s) = getHashCode(s);

int BASE = 257;
int MOD  = 1000000007;

int rollingHash(list[str] lines, int s, int t) {
    int h = 0;
    for (k <- [0 .. t]) {
        h = (h * BASE + hash(lines[s + k])) % MOD;
    }
    return h;
}


int hash(value s){
    return rascalHash(s);
}



int hashBlock(list[str] lines, int s, int t) {
    str block = "";
    for (k <- [0 .. t]) {
        block += lines[s + k] + "\n";
    }
    return hash(block);
}