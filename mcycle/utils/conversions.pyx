"""A brief collection of useful, MATLAB-style unit conversions. Largely from `<https://www.unitconverters.net/>`_."""

# -----------------------------------------------------------------
# Time
# -----------------------------------------------------------------

cpdef double s2min(double value):
    "float: length: Seconds to minutes."
    return value / 60

cpdef double s2hour(double value):
    "float: length: Seconds to hours."
    return value / 3600

cpdef double s2day(double value):
    "float: length: Seconds to days."
    return value / 86400

cpdef double min2s(double value):
    "float: length: Minutes to seconds."
    return value * 60

cpdef double min2hour(double value):
    "float: length: Minutes to hours."
    return value / 60

cpdef double min2day(double value):
    "float: length: Minutes to days."
    return value / 1440

cpdef double hour2s(double value):
    "float: length: Hours to seconds."
    return value * 3600

cpdef double hour2min(double value):
    "float: length: Hours to minutes."
    return value * 60

cpdef double hour2day(double value):
    "float: length: Hours to days."
    return value / 24

cpdef double day2s(double value):
    "float: length: Days to seconds."
    return value * 86400

cpdef double day2min(double value):
    "float: length: Days to minutes."
    return value * 1440

cpdef double day2hour(double value):
    "float: length: Days to hours."
    return value * 24

# -----------------------------------------------------------------
# Length
# -----------------------------------------------------------------

cpdef double m2ft(double value):
    "float: length: Metres to feet."
    return value / 0.3048

cpdef double m2in(double value):
    "float: length: Metres to inches."
    return value / 0.0254

cpdef double m2mi(double value):
    "float: length: Metres to miles."
    return value / 1609.344

cpdef double m2nmi(double value):
    "float: length: Metres to nautical miles."
    return value / 1852

cpdef double ft2m(double value):
    "float: length: Feet to metres."
    return value * 0.3048

cpdef double ft2in(double value):
    "float: length: Feet to inches."
    return value * 12

cpdef double ft2mi(double value):
    "float: length: Feet to miles."
    return value / 5280

cpdef double ft2nmi(double value):
    "float: length: Feet to nautical miles."
    return value * 0.00016457883369330455

cpdef double in2m(double value):
    "float: length: Inches to metres."
    return value * 0.0254

cpdef double in2ft(double value):
    "float: length: Inches to feet."
    return value / 12

cpdef double in2mi(double value):
    "float: length: Inches to miles."
    return value / 63360

cpdef double in2nmi(double value):
    "float: length: Inches to nautical miles."
    return value * 1.3714902807775378e-05

cpdef double mi2m(double value):
    "float: length: Miles to metres."
    return value * 1609.344

cpdef double mi2ft(double value):
    "float: length: Miles to feet."
    return value * 5280

cpdef double mi2in(double value):
    "float: length: Miles to inches."
    return value * 63360

cpdef double mi2nmi(double value):
    "float: length: Miles to nautical miles."
    return value * 0.8689762419006479

cpdef double nmi2m(double value):
    "float: length: Nautical miles to metres."
    return value * 1852

cpdef double nmi2in(double value):
    "float: length: Nautical miles to inches."
    return value * 72913.38582677166

cpdef double nmi2ft(double value):
    "float: length: Nautical miles to feet."
    return value * 6076.115485564304

cpdef double nmi2mi(double value):
    "float: length: Nautical miles to miles."
    return value * 1.1507794480235425

# -----------------------------------------------------------------
# Volume
# -----------------------------------------------------------------


cpdef public double m32L(double value):
    "float: volume: m^3 to litres."
    return value * 1000

cpdef public double m32galUS(double value):
    "float: volume: m^3 to gallons (US)."
    return value * 264.17217686

cpdef public double m32galImp(double value):
    "float: volume: m^3 to gallons (imperial)."
    return value * 219.9692483

cpdef public double L2m3(double value):
    "float: volume: litres to m^3."
    return value / 1000

cpdef public double L2galUS(double value):
    "float: volume: litres to gallons (US)."
    return value * 0.2641721769

cpdef public double L2galImp(double value):
    "float: volume: litres to gallons (imperial)."
    return value * 0.2199692483

cpdef public double galUS2m3(double value):
    "float: volume: Gallons (US) to m^3."
    return value * 0.00378541

cpdef public double galUS2L(double value):
    "float: volume: Gallons (US) to litres."
    return value * 3.78541

cpdef public double galUS2galImp(double value):
    "float: volume: Gallons (US) to gallons (imperial)."
    return value * 0.8326737922

cpdef public double galImp2m3(double value):
    "float: volume: Gallons (imperial) to m^3."
    return value * 0.00454609

cpdef public double galImp2L(double value):
    "float: volume: Gallons (imperial) to litres."
    return value * 4.54609

cpdef public double galImp2galUS(double value):
    "float: volume: Gallons (imperial) to gallons (US)."
    return value * 1.2009504915

# -----------------------------------------------------------------
# Speed
# -----------------------------------------------------------------

cpdef double mps2kph(double value):
    "float: velocity: metres per second to kilometers per hour."
    return value * 3.6

cpdef double mps2mph(double value):
    "float: velocity: metres per second to miles per hour."
    return value * 2.2369362921

cpdef double mps2knot(double value):
    "float: velocity: metres per second to knot."
    return value * 1.9438444924

cpdef double kph2mps(double value):
    "float: velocity: kilometers per hour to metres per second."
    return value / 3.6

cpdef double kph2mph(double value):
    "float: velocity: kilometers per hour to miles per hour."
    return value * 0.6213711922

cpdef double kph2knot(double value):
    "float: velocity: kilometers per hour to knot."
    return value / 1.852

cpdef double knot2mps(double value):
    "float: velocity: knots to metres per second."
    return value * 0.514444444444444444444

cpdef double knot2kph(double value):
    "float: velocity: metres per second to kilometers per hour."
    return value * 1.852

cpdef double knot2mph(double value):
    "float: velocity: metres per second to miles per hour."
    return value * 1.150779448

# -----------------------------------------------------------------
# Mass
# -----------------------------------------------------------------

cpdef double lb2kg(double value):
    "float: mass: Pounds to kilograms."
    return value * 0.453592

cpdef double kg2lb(double value):
    "float: mass: Kilograms to pounds."
    return value * 2.20462

# -----------------------------------------------------------------
# Pressure
# -----------------------------------------------------------------

cpdef double Pa2bar(double value):
    "float: pressure: Pascal to bar."
    return value * 10**-5

cpdef double Pa2atm(double value):
    "float: pressure: Pascal to standard atmospheres."
    return value / 101325.

cpdef double Pa2at(double value):
    "float: pressure: Pascal to technical atmospheres."
    return value / 98066.5

cpdef double Pa2Torr(double value):
    "float: pressure: Pascal to Torr."
    return value * 0.007500616827041697

cpdef double Pa2psi(double value):
    "float: pressure: Pascal to psi (pound-force per square inch)."
    return value / 6894.757293168 

cpdef double bar2Pa(double value):
    "float: pressure: bar to Pascal."
    return value * 10**5

cpdef double bar2atm(double value):
    "float: pressure: bar to standard atmospheres."
    return value / 1.01325

cpdef double bar2at(double value):
    "float: pressure: bar to technical atmospheres."
    return value * 1.019716213

cpdef double bar2Torr(double value):
    "float: pressure: bar to Torr."
    return value / (1.01325/760)

cpdef double bar2psi(double value):
    "float: pressure: bar to psi (pound-force per square inch)."
    return value * 14.503773773022

cpdef double atm2Pa(double value):
    "float: pressure: standard atmospheres to Pascal."
    return value * 101325.

cpdef double atm2bar(double value):
    "float: pressure: standard atmospheres to bar."
    return value * 1.01325

cpdef double atm2at(double value):
    "float: pressure: standard atmospheres to technical atmospheres."
    return value * 1.0332274528

cpdef double atm2Torr(double value):
    "float: pressure: standard atmospheres to Torr."
    return value * 760

cpdef double atm2psi(double value):
    "float: pressure: standard atmospheres to psi (pound-force per square inch)."
    return value * 14.695948775

cpdef double at2Pa(double value):
    "float: pressure: technical atmospheres to Pascal."
    return value * 98066.5

cpdef double at2bar(double value):
    "float: pressure: technical atmospheres to bar."
    return value * 0.980665

cpdef double at2atm(double value):
    "float: pressure: technical atmospheres to standard atmospheres."
    return value * 0.9678411054

cpdef double at2Torr(double value):
    "float: pressure: technical atmospheres to Torr."
    return value * 735.55924007

cpdef double at2psi(double value):
    "float: pressure: technical atmospheres to psi (pound-force per square inch)."
    return value * 14.223343307

cpdef double Torr2Pa(double value):
    "float: pressure: Torr to Pascal."
    return value * 133.32236842105263

cpdef double Torr2bar(double value):
    "float: pressure: Torr to bar."
    return value * 0.0013332236842105263

cpdef double Torr2atm(double value):
    "float: pressure: Torr to standard atmospheres."
    return value / 760

cpdef double Torr2at(double value):
    "float: pressure: Torr to technical atmospheres."
    return value * 0.0013595098

cpdef double Torr2psi(double value):
    "float: pressure: Torr to psi (pound-force per square inch)."
    return value * 0.0193367747

cpdef double psi2Pa(double value):
    "float: pressure: psi (pound-force per square inch) to Pascal."
    return value * 6894.7572932

cpdef double psi2bar(double value):
    "float: pressure: psi (pound-force per square inch) to bar."
    return value * 0.068947572932

cpdef double psi2atm(double value):
    "float: pressure: psi (pound-force per square inch) to standard atmospheres."
    return value * 0.0680459639

cpdef double psi2at(double value):
    "float: pressure: psi (pound-force per square inch) to technical atmospheres."
    return value * 0.070306958

cpdef double psi2Torr(double value):
    "float: pressure: psi (pound-force per square inch) to Torr."
    return value * 51.714932572

# -----------------------------------------------------------------
# Temperature
# -----------------------------------------------------------------

cpdef double degC2K(double value):
    "float: temperature: Celcius to Kelvin."
    return value + 273.15

cpdef double degC2degF(double value):
    "float: temperature: Celcius to Fahrenheit."
    return value * 9./5 + 32

cpdef double degC2degR(double value):
    "float: temperature: Celcius to Rankine."
    return (value+273.15) * 9./5

cpdef double K2degC(double value):
    "float: temperature: Kelvin to Celcius."
    return value - 273.15

cpdef double K2degF(double value):
    "float: temperature: Kelvin to Fahrenheit."
    return value * 9./5 - 459.67

cpdef double K2degR(double value):
    "float: temperature: Kelvin to Fahrenheit."
    return value * 9./5

cpdef double degF2degC(double value):
    "float: temperature: Fahrenheit to Celcius."
    return (value - 32) * 5./9

cpdef double degF2K(double value):
    "float: temperature: Fahrenheit to Kelvin."
    return (value + 459.67) * 5./9

cpdef double degF2degR(double value):
    "float: temperature: Fahrenheit to Rankine."
    return value + 459.67

cpdef double degR2K(double value):
    "float: temperature: Rankine to Kelvin."
    return value * 5./9

cpdef double degR2degF(double value):
    "float: temperature: Rankine to Fahrenheit."
    return value - 459.67

# -----------------------------------------------------------------
# Power
# -----------------------------------------------------------------

cpdef double W2bhp(double value):
    "float: power: Watt to Brake Horse Power."
    return value / 745.699872

cpdef double bhp2W(double value):
    "float: power: Brake Horse Power to Watt."
    return value * 745.699872
