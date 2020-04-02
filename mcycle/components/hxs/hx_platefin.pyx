from .hxunit_basic cimport HxUnitBasic
from .hx_plate cimport HxPlate
from .hxunit_plate cimport HxUnitPlate
from .flowconfig cimport HxFlowConfig
from ...bases.config cimport Config
from ...bases.component cimport Component22
from ...bases.geom cimport Geom
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from ..._constants cimport *
from warnings import warn
from math import nan, isnan, pi
import scipy.optimize as opt

cdef tuple _inputs = ('flowConfig', 'NPlate', 'RfWf', 'RfSf', 'plate', 'tPlate', 'geomWf', 'geomSf', 'L', 'W', 'ARatioWf', 'ARatioSf', 'ARatioPlate', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'runBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'A', 'dpWf()', 'dpSf()', 'isEvap()')

cdef class HxPlateFin(HxPlate):
    r"""TODO
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 unsigned int NPlate=3,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial plate=None,
                 double tPlate=nan,
                 Geom geomWf=None,
                 Geom geomSf=None,
                 double L=nan,
                 double W=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioPlate=1,
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[3, 100],
                 list sizeUnitsBounds=[1e-5, 10.],
                 runBounds=[nan, nan],
                 str name="HxPlateFin instance",
                 str notes="No notes/model info.",
                 Config config=None,
                 _unitClass=HxUnitPlate):

        super().__init__(flowConfig, NPlate, RfWf, RfSf, plate, tPlate, geomWf, geomSf, L, W, ARatioWf, ARatioSf, ARatioPlate, efficiencyThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, name, notes, config, _unitClass)
        self._inputs = _inputs
        self._properties = _properties

                
