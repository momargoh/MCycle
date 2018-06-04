"""Compute FlowState properties in standard atmospheres.
"""
from ..bases.flowstate cimport FlowState
from ..DEFAULTS cimport COOLPROP_EOS
from math import nan
from numpy import exp
import CoolProp as CP


cdef tuple isaPropsFromBase(double altitude, double lapseRate, double altitudeBase, double pStagBase, double TStagBase, double g, double R):
    cdef double T=nan
    cdef double p=nan
    if lapseRate != 0:
        T = TStagBase + lapseRate * (altitude - altitudeBase)
        p = pStagBase * (T / TStagBase)**(-g / lapseRate / R)
    else:
        T = TStagBase
        p = pStagBase * exp(-g / R / TStagBase * (altitude - altitudeBase))
    return p, T

cpdef FlowState isa(double altitude,
                    double pStag=101325.,
                    double TStag=288.15,
                    double g=9.80665,
                    double R=287.058,
                    str fluidCP="Air",
                    int phaseCP=-1):
    """FlowState: Returns FlowState at desired altitude in the International Standard Atmosphere.


Parameters
-----------
altitude : float
    Geopotential altitude [m].
pStag : float, optional
    Stagnation (absolute) pressure at sea level [Pa]. Defaults to 101325.
TStag : float, optional
    Stagnation (absolute) temperature at sea level [Pa]. Defaults to 101325.
g : float, optional
    Acceleration due to gravity [m/s^2]. Assumed to be constant. Defaults to 9.80665.
R : float, optional
    Specific gas constant of air [J/Kg/K]. Assumed to be constant, air is assumed to be dry. Defaults to 287.058.
"""
    assert altitude >= -610, "Altitude must be above -610 [m] (given: {})".format(
        altitude)
    assert altitude <= 86000, "Altitude must be below 86,000 [m] (given: {})".format(
        altitude)
    cdef list refLapseRate = [-0.0065, 0, 0.001, 0.0028, 0, -0.0028, -0.002]
    cdef list refAltitude = [0, 11000, 20000, 32000, 47000, 51000, 71000, 86000]
    cdef double _pStag = pStag
    cdef double _TStag = TStag
    cdef int i = 0
    while i < len(refAltitude) - 1:
        if altitude <= refAltitude[i + 1]:
            _pStag, _TStag = isaPropsFromBase(altitude, refLapseRate[i],
                                         refAltitude[i], _pStag, _TStag, g, R)
            break
        else:
            _pStag, _TStag = isaPropsFromBase(refAltitude[i + 1], refLapseRate[i],
                                         refAltitude[i], _pStag, _TStag, g, R)
            i += 1
    try:
        return FlowState(fluidCP, phaseCP, 0, CP.PT_INPUTS, _pStag,
                         _TStag)
    except:
        raise ValueError(
            "Was not able to produce FlowState from computed pStag={}, TStag={}".
            format(_pStag, _TStag))
