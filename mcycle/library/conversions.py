"""A brief collection of useful, MATLAB-style unit conversions."""


def bar2pa(value):
    "float: pressure: bar to Pascal."
    return value * 10**5


def pa2bar(value):
    "float: pressure: Pascal to bar."
    return value * 10**-5


def mps2knots(value):
    "float: float: velocity: metres per second to knots."
    return value * 1.94384


def knots2mps(value):
    "float: velocity: knots to metres per second."
    return value / 1.94384


def kph2mps(value):
    "float: velocity: kilometers per hour to metres per second."
    return value / 3.6


def mps2kph(value):
    "float: velocity: metres per second to kilometers per hour."
    return value * 3.6


def degC2K(value):
    "float: temperature: Celcius to Kelvin."
    return value + 273.15


def K2degC(value):
    "float: temperature: Kelvin to Celcius."
    return value - 273.15


def bhp2w(value):
    "float: power: Brake Horse Power to Watts."
    return value * 745.699872


def w2bhp(value):
    "float: power: Watts to Brake Horse Power."
    return value / 745.699872


def ft2m(value):
    "float: length: Feet to metres."
    return value * 0.3048


def m2ft(value):
    "float: length: Metres to feet."
    return value / 0.3048
