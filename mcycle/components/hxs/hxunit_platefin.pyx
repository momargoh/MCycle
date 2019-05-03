from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.geom cimport Geom
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from ...methods import heat_transfer as ht
from .hxunit_plate cimport HxUnitPlate
from .flowconfig cimport HxFlowConfig
from warnings import warn
from math import nan
import CoolProp as CP
import numpy as np
import scipy.optimize as opt

cdef str method
cdef dict _inputs = {"flowConfig": MCAttr(HxFlowConfig, "none"), "NPlate": MCAttr(int, "none"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "plate": MCAttr(SolidMaterial, "none"), "tPlate": MCAttr(float, "length"), "geomPlateWf": MCAttr(Geom, "none"), "geomPlateSf": MCAttr(Geom, "none"), "L": MCAttr(float, "length"), "W": MCAttr(float, "length"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioPlate": MCAttr(float, "none"), "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"), 
                        "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "U()": MCAttr(float, "htc"), "A()": MCAttr(float, "area"), "dpWf()": MCAttr(float, "pressure"), "dpSf()": MCAttr(float, "pressure"), "isEvap()": MCAttr(bool, "none")}

cdef class HxUnitPlateFin(HxUnitPlate):
    r"""TODO
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 int NPlate=3,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial plate=None,
                 double tPlate=float("nan"),
                 Geom geomPlateWf=None,
                 Geom geomPlateSf=None,
                 double L=float("nan"),
                 double W=float("nan"),
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioPlate=1,
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="L",
                 list sizeBounds=[1e-5, 10.0],
                 str name="HxUnitPlateCorrugated instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(flowConfig, NPlate, RfWf, RfSf,
                         plate, tPlate, geomPlateWf, geomPlateSf, L, W, ARatioWf, ARatioSf, ARatioPlate,
                         effThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         sizeAttr, sizeBounds, name, notes, config)
        self._inputs = _inputs
        self._properties = _properties
        

