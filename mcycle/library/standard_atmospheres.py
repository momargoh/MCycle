"""Compute FlowState properties in standard atmospheres.
"""
from ..bases import FlowState
import CoolProp as CP
from numpy import exp


def isa(altitude,
        pStag=101325.,
        TStag=288.15,
        g=9.80665,
        R=287.058,
        fluidCP="Air",
        libCP="HEOS",
        phaseCP=None):
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
    refLapseRate = (-0.0065, 0, 0.001, 0.0028, 0, -0.0028, -0.002)
    refAltitude = (0, 11000, 20000, 32000, 47000, 51000, 71000, 86000)
    pStag = pStag
    TStag = TStag

    def propsFromBase(altitude, lapseRate, altitudeBase, pStagBase, TStagBase):
        if lapseRate != 0:
            T = TStagBase + lapseRate * (altitude - altitudeBase)
            p = pStagBase * (T / TStagBase)**(-g / lapseRate / R)
        else:
            T = TStagBase
            p = pStagBase * exp(-g / R / TStagBase * (altitude - altitudeBase))
        return p, T

    i = 0
    while i < len(refAltitude) - 1:
        if altitude <= refAltitude[i + 1]:
            pStag, TStag = propsFromBase(altitude, refLapseRate[i],
                                         refAltitude[i], pStag, TStag)
            break
        else:
            pStag, TStag = propsFromBase(refAltitude[i + 1], refLapseRate[i],
                                         refAltitude[i], pStag, TStag)
            i += 1
    try:
        return FlowState(fluidCP, libCP, phaseCP, None, CP.PT_INPUTS, pStag,
                         TStag)
    except:
        raise ValueError(
            "Was not able to produce FlowState from computed pStag={}, TStag={}".
            format(pStag, TStag))
