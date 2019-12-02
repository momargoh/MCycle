#from libc.math cimport NAN

cpdef public double htc(double Nu, double k, double charLength) except -1
cpdef public double dpf(double f, double G, double L, double Dh, double rho, int N) except -1
cpdef public double lmtd(double TIn1, double TOut1, double TIn2, double TOut2, unsigned char flowSense) except -1
