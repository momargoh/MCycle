from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.geom cimport Geom
from ...bases.solidmaterial cimport SolidMaterial
from ...methods import heat_transfer as ht
from .hxunit_plate cimport HxUnitPlate
from .flowconfig cimport HxFlowConfig
from warnings import warn
from math import nan
import numpy as np
import scipy.optimize as opt

cdef str method
cdef tuple _inputs = ('flowConfig', 'NPlate', 'RfWf', 'RfSf', 'plate', 'tPlate', 'geomPlateWf', 'geomPlateSf', 'L', 'W', 'ARatioWf', 'ARatioSf', 'ARatioPlate', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'sizeAttr', 'sizeBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'U()', 'A()', 'dpWf()', 'dpSf()', 'isEvap()')

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
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="L",
                 list sizeBounds=[1e-5, 10.0],
                 str name="HxUnitPlateCorrugated instance",
                 str notes="No notes/model info.",
                 Config config=None):
        super().__init__(flowConfig, NPlate, RfWf, RfSf,
                         plate, tPlate, geomPlateWf, geomPlateSf, L, W, ARatioWf, ARatioSf, ARatioPlate,
                         efficiencyThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         sizeAttr, sizeBounds, name, notes, config)
        self._inputs = _inputs
        self._properties = _properties
        

