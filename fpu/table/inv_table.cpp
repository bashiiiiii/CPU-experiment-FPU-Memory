#include <iostream>
#include <fstream>

int main() {
    union data{
        float f;
        unsigned int d;
    };

    std::ofstream file;
    file.open("inv_table.txt");
    for(int i = 0; i < 1024; i++){
        double slope = (1024.0/((double)i+1024.0))*(1024.0/((double)i+1025.0));
        double intercept = 768.0/(1024.0+(double)i) - 256.0/(1025.0+(double)i) + 1024.0/(2049.0+(double)(2*i));
        union data bitslope;
        bitslope.f = (float)slope;
        union data bitintercept;
        bitintercept.f = (float)intercept;
        for(int j = 22; j >= 0; j--){
            file << ((bitintercept.d >> j) & 1);
        }
        if(bitslope.f >= 0.5){
            file << 1;
            for(int j = 22; j >= 11; j--){
                file << ((bitslope.d >> j) & 1); 
            }
        }else{
            file << 0 << 1;
            for(int j = 22; j >= 12; j--){
                file << ((bitslope.d >> j) & 1); 
            }
        }
        file << std::endl;
    }
    file.close();
    return 0;
}
