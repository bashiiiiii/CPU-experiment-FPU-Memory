#include <iostream>
#include <fstream>
#include <cmath>
int main() {
    union data{
        float f;
        unsigned int d;
    };

    std::ofstream file;
    file.open("sqrt_table.txt");
    for(int i = 0; i < 512; i++){
        double slope = 32.0/(std::sqrt((double)(2*i+1026)) + std::sqrt((double)(2*i+1024)));
        double intercept = (3.0*std::sqrt((double)(2*i + 1024))-std::sqrt((double)(2*i + 1026)))/128.0 + std::sqrt((double)(2*i+1025))/64.0;
        union data bitslope;
        bitslope.f = (float)slope;
        union data bitintercept;
        bitintercept.f = (float)intercept;
        for(int j = 22; j >= 0; j--){
            file << ((bitintercept.d >> j) & 1);
        }
        file << 1;
        for(int j = 22; j >= 11; j--){
            file << ((bitslope.d >> j) & 1); 
        }
        file << std::endl;
    }
    for(int i = 0; i < 512; i++){
        double slope = 16.0/(std::sqrt((double)(i + 512)) + std::sqrt((double)(i + 513)));
        double intercept = (3.0*std::sqrt((double)(i + 512))-std::sqrt((double)(i + 513)))/64.0 + std::sqrt((double)(4*i)+2050)/64.0;
        union data bitslope;
        bitslope.f = (float)slope;
        union data bitintercept;
        bitintercept.f = (float)intercept;
        for(int j = 22; j >= 0; j--){
            file << ((bitintercept.d >> j) & 1);
        }
        file << 1;
        for(int j = 22; j >= 11; j--){
            file << ((bitslope.d >> j) & 1); 
        }
        file << std::endl;
    }
    file.close();
    return 0;
}
