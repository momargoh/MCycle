"""A brief library of commercial component designs."""
from ..bases import Config
from ..constants import *
from .. import components as cps
from .. import geometries as gms
from . import materials as mats


def alfaLaval_AC30EQ(
        flowConfig=cps.hxs.HxFlowConfig(
            sense=COUNTERFLOW, passes=1, verticalWf=True, verticalSf=True),
        flowInWf=None,
        flowInSf=None,
        flowOutWf=None,
        flowOutSf=None,
        ambient=None,
        sizeAttr="NPlate",
        sizeBounds=[3, 100],
        sizeUnitsBounds=[1e-5, 10.],
        name="HxPlate instance",
        kwargs={}):
    """Alfa Laval AC30EQ brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/ac/ac30eq--ach30eq.pdf"""
    hx = cps.HxPlate(
        flowConfig=flowConfig,
        NPlate=3,
        RfWf=0,
        RfSf=0,
        plate=mats.stainlessSteel_316(),
        tPlate=0.424e-3,
        geomWf=gms.GeomHxPlateChevron(1.096e-3, 60, 10e-3, 1.117),
        geomSf=gms.GeomHxPlateChevron(1.096e-3, 60, 10e-3, 1.117),
        L=269e-3,
        W=95e-3,
        portWf=gms.Port(d=0.0125),
        portSf=gms.Port(d=0.0125),
        coeffs_LPlate=[0.056, 1],
        coeffs_WPlate=[0, 1],
        coeffs_mass=[
            1. / (0.325 * 0.095 * 0.424e-3), 0.09 / (0.325 * 0.095 * 0.424e-3)
        ],
        efficiencyThermal=1.0,
        flowInWf=flowInWf,
        flowInSf=flowInSf,
        flowOutWf=flowOutWf,
        flowOutSf=flowOutSf,
        ambient=ambient,
        sizeAttr=sizeAttr,
        sizeBounds=sizeBounds,
        sizeUnitsBounds=sizeUnitsBounds,
        name=name,
        notes=
        "Alfa Laval AC30EQ brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/ac/ac30eq--ach30eq.pdf"
    )
    hx.update(kwargs)
    return hx


def alfaLaval_CBXP27(
        flowConfig=cps.hxs.HxFlowConfig(
            sense=COUNTERFLOW, passes=1, verticalWf=True, verticalSf=True),
        flowInWf=None,
        flowInSf=None,
        flowOutWf=None,
        flowOutSf=None,
        ambient=None,
        sizeAttr="NPlate",
        sizeBounds=[3, 100],
        sizeUnitsBounds=[1e-5, 10.],
        name="HxPlate instance",
        kwargs={}):
    """Alfa Laval CBXP27 brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/cb/cbxp27_productleaflet_che00131en.pdf"""
    hx = cps.HxPlate(
        flowConfig=flowConfig,
        NPlate=3,
        RfWf=0,
        RfSf=0,
        plate=mats.stainlessSteel_316(),
        tPlate=0.95e-3,
        geomWf=gms.GeomHxPlateChevron(1.45e-3, 60, 10e-3, 1.117),
        geomSf=gms.GeomHxPlateChevron(1.45e-3, 60, 10e-3, 1.117),
        L=250e-3,
        W=111e-3,
        portWf=gms.Port(d=0.0315),
        portSf=gms.Port(d=0.0315),
        coeffs_LPlate=[0.060, 1],
        coeffs_WPlate=[0, 1],
        coeffs_mass=[
            2. / (0.310 * 0.111 * 0.95e-3), 0.13 / (0.310 * 0.111 * 0.95e-3)
        ],
        efficiencyThermal=1.0,
        flowInWf=flowInWf,
        flowInSf=flowInSf,
        flowOutWf=flowOutWf,
        flowOutSf=flowOutSf,
        ambient=ambient,
        sizeAttr=sizeAttr,
        sizeBounds=sizeBounds,
        sizeUnitsBounds=sizeUnitsBounds,
        name=name,
        notes=
        "Alfa Laval CBXP27 brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/cb/cbxp27_productleaflet_che00131en.pdf"
    )
    hx.update(kwargs)
    return hx
