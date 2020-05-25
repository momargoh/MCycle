from .hxunit_basic cimport HxUnitBasic
from .hx_basicplanar cimport HxBasicPlanar
from .hxunit_plate cimport HxUnitPlate
from .flowconfig cimport HxFlowConfig
from ...bases.config cimport Config
from ...bases.component cimport Component22
from ...bases.geom cimport Geom
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from ...bases.utils cimport *
from ..._constants cimport *
from ...logger import log
from warnings import warn
from math import nan, isnan, pi
import scipy.optimize as opt

cdef tuple _inputs = ('flowConfig', 'NPlate', 'RfWf', 'RfSf', 'plate', 'tPlate', 'geomWf', 'geomSf', 'L', 'W', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'runBounds', 'runUnitsBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'A', 'dpWf()', 'dpSf()', 'isEvap()')
cdef str msg

cdef class HxPlate(HxBasicPlanar):
    r"""Characterises a basic plate heat exchanger consisting of alternating working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowConfig : HxFlowConfig, optional
    Flow configuration/arrangement information. See :meth:`mcycle.bases.component.HxFlowConfig`.
NPlate : int, optional
    Number of parallel plates [-]. The number of thermally activate plates is equal to NPlate - 2, due to the 2 end plates. Must be >= 3. Defaults to 3.
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
plate : SolidMaterial, optional
    Plate material. Defaults to None.
tPlate : float, optional
    Thickness of the plate [m]. Defaults to nan.
geomWf : Geom, optional
    Geom object describing the geometry of the working fluid channels.
geomSf : Geom, optional
    Geom object describing the geometry of the secondary fluid channels.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
W : float, optional
    Width of the heat transfer surface area (dimension perpendicular to flow direction) [m]. Defaults to nan.
efficiencyThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowInWf : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
flowInSf : FlowState, optional
    Incoming FlowState of the secondary fluid. Defaults to None.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
ambient : FlowState, optional
    Ambient environment flow state. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "NPlate".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [3, 100].
sizeUnitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. Typically this bounds is used to size for the length of the HxUnit. Defaults to [1e-5, 1.].
name : string, optional
    Description of object. Defaults to "HxPlate instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
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
                 runUnitsBounds=[nan, nan],
                 str name="HxPlate instance",
                 str notes="No notes/model info.",
                 Config config=None,
                 _unitClass=HxUnitPlate):
        super().__init__(flowConfig, 0, 0, NPlate, nan, nan, nan, nan,
                         RfWf, RfSf, plate, tPlate, L, W, 1, 1,
                         1, efficiencyThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, runUnitsBounds, name, notes, config, _unitClass)
        self.geomWf = geomWf
        self.geomSf = geomSf
        self._unitClass = HxUnitPlate
        self._inputs = _inputs
        self._properties = _properties

    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowConfig, self.NPlate, self.RfWf, self.RfSf, self.plate,
                self.tPlate, self.geomWf, self.geomSf, self.L,
                self.W, self.efficiencyThermal)

    cdef public tuple _unitArgsTp(self):
        """Arguments passed to HxUnits in the two-phase region."""
        return self._unitArgsLiq()

    cdef public tuple _unitArgsVap(self):
        """Arguments passed to HxUnits in the vapour region."""
        return self._unitArgsLiq()

    cdef public void _unitiseExtra(self):
        cdef:
            unsigned int i, NUnits=len(self._units)
            unsigned char unitPhaseWf, unitPhaseSf
            str clsName = self.__class__.__name__
            str geomWf = self.geomWf.__class__.__name__
            str geomSf = self.geomSf.__class__.__name__
        for i in range(NUnits):
            unitPhaseWf = get_unitPhase(self._units[i].flowsIn[0], self._units[i].flowsOut[0])
            unitPhaseSf = get_unitPhase(self._units[i].flowsIn[1], self._units[i].flowsOut[1])
            self._units[i]._unitPhaseWf = unitPhaseWf
            self._units[i]._unitPhaseSf = unitPhaseSf
            self._units[i]._methodHeatWf = self.config.lookupMethod(clsName, (geomWf, TRANSFER_HEAT, unitPhaseWf, WORKING_FLUID))
            self._units[i]._methodHeatSf = self.config.lookupMethod(clsName, (geomSf, TRANSFER_HEAT, unitPhaseSf, SECONDARY_FLUID))
            self._units[i]._methodFrictionWf = self.config.lookupMethod(clsName, (geomWf, TRANSFER_FRICTION, unitPhaseWf, WORKING_FLUID))
            self._units[i]._methodFrictionSf = self.config.lookupMethod(clsName, (geomSf, TRANSFER_FRICTION, unitPhaseSf, SECONDARY_FLUID))
        
            #print(unitPhaseWf, unitPhaseSf,self._units[i]._methodHeatWf, self._units[i]._methodHeatSf, self._units[i]._methodFrictionWf, self._units[i]._methodFrictionSf)
                
    cpdef public unsigned int _NWf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NPlate & 1:  # NPlate is odd
            return (self.NPlate - 1) / 2
        else:
            if self.config.evenPlatesWf:
                return self.NPlate / 2
            else:
                return self.NPlate / 2 - 1

    cpdef public unsigned int _NSf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NPlate & 1:  # NPlate is odd
            return (self.NPlate - 1) / 2
        else:
            if self.config.evenPlatesWf:
                return self.NPlate / 2 - 1
            else:
                return self.NPlate / 2

    cpdef public double dpFWf(self):
        """float: Frictional pressure drop of the working fluid [Pa]."""
        cdef double dp = 0
        cdef HxUnitPlate unit
        cdef size_t i
        for i in range(len(self._units)):#unit in self._units:
            unit = self._units[i]
            dp += unit._dpFWf()
        return dp

    cpdef public double dpFSf(self):
        """float: Frictional pressure drop of the secondary fluid [Pa]."""
        cdef double dp = 0
        cdef HxUnitPlate unit
        cdef size_t i
        for i in range(len(self._units)):#unit in self._units:
            unit = self._units[i]
            #dp += unit._dpFSf()
            add = unit._dpFSf()
            dp += add
            #print("adding: ", add)
        #print("dpSf = ", dp)
        return dp

    cpdef public double dpAccWf(self):
        """float: Acceleration pressure drop of the working fluid [Pa]."""
        cdef double G = self._mWf() / self._NWf() / (self.geomWf.b * self.W)
        return G**2 * (1 / self.flowsOut[0].rho() - 1 / self.flowsIn[0].rho())

    cpdef public double dpAccSf(self):
        """float: Acceleration pressure drop of the secondary fluid [Pa]."""
        cdef double G = self._mSf() / self._NSf() / (self.geomSf.b * self.W)
        return G**2 * (1 / self.flowsOut[1].rho() - 1 / self.flowsIn[0].rho())

    cpdef public double dpHeadWf(self):
        """float: Static head pressure drop of the working fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.flowConfig.verticalWf:
            if self.isEvap():
                return self.flowsOut[0].rho() * self.config.gravity * self.L
            else:
                return -self.flowsOut[0].rho() * self.config.gravity * self.L

    cpdef public double dpHeadSf(self):
        """float: Static head pressure drop of the secondary fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.flowConfig.verticalSf:
            if self.isEvap():
                return -self.flowsOut[1].rho() * self.config.gravity * self.L
            else:
                return self.flowsOut[1].rho() * self.config.gravity * self.L

    cpdef public double dpWf(self):
        """float: Total pressure drop of the working fluid [Pa]."""
        cdef double dp = 0
        if self.config.dpFWf:
            dp += self.dpFWf()
        if self.config.dpAccWf:
            dp += self.dpAccWf()
        if self.config.dpHeadWf:
            dp += self.dpHeadWf()
        return dp

    cpdef public double dpSf(self):
        """float: Total pressure drop of the secondary fluid [Pa]."""
        cdef double dp = 0
        if self.config.dpFSf:
            dp += self.dpFSf()
        if self.config.dpAccSf:
            dp += self.dpAccSf()
        if self.config.dpHeadSf:
            dp += self.dpHeadSf()
        return dp

    cpdef public double mass(self):
        """float: Approximate total mass of the heat exchanger plates and fins [kg].
        """
        return self.wall.rho*self.W*self.L * (self.NWall*self.tPlate + self._NWf()*self.geomWf.areaPerWidth() + self._NSf()*self.geomSf.areaPerWidth())

    cpdef public double depth(self):
        return self.NPlate*self.tPlate+self._NWf()*self.geomWf.b+self._NSf()*self.geomSf.b

    cpdef public unsigned int size_NPlate(self) except 0:
        """int: size for NPlate that requires L to be closest to self.L"""
        cdef double diff
        cdef int NPlate = int(self.sizeBounds[0])
        cdef unsigned int NPlateMax = int(self.sizeBounds[1])
        cdef double L = self.L
        cdef list diff_vals = [nan, nan]
        while NPlate < NPlateMax:
            self.update({'NWall':NPlate})
            diff = self.size_L() - L
            diff_vals = [diff_vals[1], diff]
            if diff > 0:
                NPlate += 1
            else:
                break
        if abs(diff_vals[0]) < abs(diff_vals[1]):
            self.update({'NWall':NPlate-1})
            self.size_L()
            return NPlate - 1
        else:
            return NPlate
        
    cpdef public void size(self) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.
unitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. If None, self.sizeUnitsBounds is used. Defaults to None.
        """
        cdef str attr = self.sizeAttr
        try:
            if attr in ["N", "NPlate"]:
                self.unitise()
                self.NWall = self.size_NPlate()
            else:
                super(HxPlate, self).size()
        except Exception as exc:
            msg = 'HxPlate.size(): failed to converge.'
            log('error', msg, exc)
            raise exc

    @property
    def NWf(self):
        return self._NWf()

    @property
    def NSf(self):
        return self._NSf()

    @property
    def NPlate(self):
        """int: Alias of self.NWall"""
        return self.NWall

    @NPlate.setter
    def NPlate(self, value):
        self.NWall = value
    
    @property
    def plate(self):
        """SolidMaterial: Alias of self.wall"""
        return self.wall

    @plate.setter
    def plate(self, value):
        self.wall = value

    @property
    def tPlate(self):
        """float: Alias of self.tWall"""
        return self.tWall

    @tPlate.setter
    def tPlate(self, value):
        self.tWall = value
