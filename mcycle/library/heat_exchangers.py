"""A brief library of commercial component designs."""
from ..bases import Config
from .. import components as cps
from .. import geometries as gms
from . import materials as mats


def alfaLaval_AC30EQ(flowSense="counterflow",
                     flowInWf=None,
                     flowInSf=None,
                     flowOutWf=None,
                     flowOutSf=None,
                     flowDeadSf=None,
                     solveAttr="NPlate",
                     solveBracket=[3, 100],
                     solveBracketUnits=[1e-5, 10.],
                     name="HxPlate instance",
                     config=Config(),
                     **kwargs):
    """Alfa Laval AC30EQ brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/ac/ac30eq--ach30eq.pdf"""
    hx = cps.HxPlate(
        flowSense=flowSense,
        NPlate=3,
        RfWf=0,
        RfSf=0,
        plate=mats.stainlessSteel_316,
        tPlate=0.424e-3,
        geomPlateWf=gms.GeomHxPlateCorrChevron(1.096e-3, 60, 10e-3, 1.117),
        geomPlateSf=gms.GeomHxPlateCorrChevron(1.096e-3, 60, 10e-3, 1.117),
        L=269e-3,
        W=95e-3,
        ARatioWf=1,
        ARatioSf=1,
        ARatioPlate=1,
        DPortWf=0.0125,
        DPortSf=0.0125,
        coeffs_LPlate=[0.056, 1],
        coeffs_WPlate=[0, 1],
        coeffs_weight=[
            1. / (0.325 * 0.095 * 0.424e-3), 0.09 / (0.325 * 0.095 * 0.424e-3)
        ],
        effThermal=1.0,
        flowInWf=flowInWf,
        flowInSf=flowInSf,
        flowOutWf=flowOutWf,
        flowOutSf=flowOutSf,
        flowDeadSf=flowDeadSf,
        solveAttr=solveAttr,
        solveBracket=solveBracket,
        solveBracketUnits=solveBracketUnits,
        name=name,
        notes=
        "Alfa Laval AC30EQ brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/ac/ac30eq--ach30eq.pdf",
        config=config)
    hx.update(**kwargs)
    return hx


def alfaLaval_CBXP27(flowSense="counterflow",
                     flowInWf=None,
                     flowInSf=None,
                     flowOutWf=None,
                     flowOutSf=None,
                     flowDeadSf=None,
                     solveAttr="NPlate",
                     solveBracket=[3, 100],
                     solveBracketUnits=[1e-5, 10.],
                     name="HxPlate instance",
                     config=Config(),
                     **kwargs):
    """Alfa Laval CBXP27 brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/cb/cbxp27_productleaflet_che00131en.pdf"""
    hx = cps.HxPlate(
        flowSense=flowSense,
        NPlate=3,
        RfWf=0,
        RfSf=0,
        plate=mats.stainlessSteel_316,
        tPlate=0.95e-3,
        geomPlateWf=gms.GeomHxPlateCorrChevron(1.45e-3, 60, 10e-3, 1.117),
        geomPlateSf=gms.GeomHxPlateCorrChevron(1.45e-3, 60, 10e-3, 1.117),
        L=250e-3,
        W=111e-3,
        ARatioWf=1,
        ARatioSf=1,
        ARatioPlate=1,
        DPortWf=0.0315,
        DPortSf=0.0315,
        coeffs_LPlate=[0.060, 1],
        coeffs_WPlate=[0, 1],
        coeffs_weight=[
            2. / (0.310 * 0.111 * 0.95e-3), 0.13 / (0.310 * 0.111 * 0.95e-3)
        ],
        effThermal=1.0,
        flowInWf=flowInWf,
        flowInSf=flowInSf,
        flowOutWf=flowOutWf,
        flowOutSf=flowOutSf,
        flowDeadSf=flowDeadSf,
        solveAttr=solveAttr,
        solveBracket=solveBracket,
        solveBracketUnits=solveBracketUnits,
        name=name,
        notes=
        "Alfa Laval CBXP27 brazed plate heat exchanger, http://www.alfalaval.dk/globalassets/documents/products/heat-transfer/plate-heat-exchangers/brazed-plate-heat-exchangers/cb/cbxp27_productleaflet_che00131en.pdf",
        config=config)
    hx.update(**kwargs)
    return hx
