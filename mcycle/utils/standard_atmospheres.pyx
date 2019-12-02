"""Compute FlowState properties in standard atmospheres.
"""
from ..bases.flowstate import FlowState
from .. import constants as c
from ..logger import log
from math import nan, exp

gravity = 9.80665
R = 287.05


def isaPropsFromBase(altitude, lapseRate, altitudeBase, pStagBase, TStagBase):
    T = nan
    p = nan
    if lapseRate != 0:
        T = TStagBase + lapseRate * (altitude - altitudeBase)
        p = pStagBase * (T / TStagBase)**(-gravity / lapseRate / R)
    else:
        T = TStagBase
        p = pStagBase * exp(-gravity / R / TStagBase *
                            (altitude - altitudeBase))
    return p, T


def isa(altitude, pStag=101325., TStag=288.15):
    """FlowState: Returns FlowState at desired altitude in the International Standard Atmosphere.


Parameters
-----------
altitude : float
    Geopotential altitude [m].
pStag : float, optional
    Stagnation (absolute) pressure at sea level [Pa]. Defaults to 101325.
TStag : float, optional
    Stagnation (absolute) temperature at sea level [Pa]. Defaults to 288.15.
"""
    assert altitude >= -610, "Altitude must be above -610 [m] (given: {})".format(
        altitude)
    assert altitude <= 86000, "Altitude must be below 86,000 [m] (given: {})".format(
        altitude)
    refLapseRate = [-0.0065, 0, 0.001, 0.0028, 0, -0.0028, -0.002]
    refAltitude = [0, 11000, 20000, 32000, 47000, 51000, 71000, 86000]
    atm = FlowState('Air')
    _pStag = pStag
    _TStag = TStag
    i = 0
    while i < len(refAltitude) - 1:
        if altitude <= refAltitude[i + 1]:
            _pStag, _TStag = isaPropsFromBase(altitude, refLapseRate[i],
                                              refAltitude[i], _pStag, _TStag)
            break
        else:
            _pStag, _TStag = isaPropsFromBase(refAltitude[i + 1],
                                              refLapseRate[i], refAltitude[i],
                                              _pStag, _TStag)
            i += 1
    try:
        atm.updateState(c.PT_INPUTS, _pStag, _TStag)
        return atm
    except Exception as exc:
        msg = "ISA was not able to produce FlowState from computed pStag={}, TStag={}".format(
            _pStag, _TStag)
        log('error', msg, exc)
        raise ValueError(msg)
