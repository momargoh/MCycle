"""A brief collection of useful, MATLAB-style unit conversions."""


cpdef double atm2Pa(double value):
    "float: pressure: standard atmospheres to Pascal."
    return value * 101325.


cpdef double Pa2atm(double value):
    "float: pressure: Pascal to standard atmospheres."
    return value / 101325.

cpdef double bar2Pa(double value):
    "float: pressure: bar to Pascal."
    return value * 10**5


cpdef double Pa2bar(double value):
    "float: pressure: Pascal to bar."
    return value / 10**5


cpdef double mps2knots(double value):
    "float: float: velocity: metres per second to knots."
    return value * 1.94384


cpdef double knots2mps(double value):
    "float: velocity: knots to metres per second."
    return value / 1.94384


cpdef double kph2mps(double value):
    "float: velocity: kilometers per hour to metres per second."
    return value / 3.6


cpdef double mps2kph(double value):
    "float: velocity: metres per second to kilometers per hour."
    return value * 3.6


cpdef double degC2K(double value):
    "float: temperature: Celcius to Kelvin."
    return value + 273.15


cpdef double K2degC(double value):
    "float: temperature: Kelvin to Celcius."
    return value - 273.15


cpdef double bhp2W(double value):
    "float: power: Brake Horse Power to Watts."
    return value * 745.699872


cpdef double W2bhp(double value):
    "float: power: Watts to Brake Horse Power."
    return value / 745.699872


cpdef double ft2m(double value):
    "float: length: Feet to metres."
    return value * 0.3048


cpdef double m2ft(double value):
    "float: length: Metres to feet."
    return value / 0.3048


cpdef double in2m(double value):
    "float: length: Inches to metres."
    return value * 0.0254


cpdef double m2in(double value):
    "float: length: Metres to inches."
    return value / 0.0254
