from .hxunit_basic cimport HxUnitBasic
from .hx_basicplanar cimport HxBasicPlanar
from .hxunit_plate cimport HxUnitPlate
from .flowconfig cimport HxFlowConfig
from ...bases.config cimport Config
from ...bases.component cimport Component22
from ...bases.geom cimport Geom
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from ..._constants cimport *
from ...logger import log
from warnings import warn
from math import nan, isnan, pi
import scipy.optimize as opt

cdef tuple _inputs = ('flowConfig', 'NPlate', 'RfWf', 'RfSf', 'plate', 'tPlate', 'geomWf', 'geomSf', 'L', 'W', 'ARatioWf', 'ARatioSf', 'ARatioPlate', 'DPortWf', 'DPortSf', 'LVertPortWf', 'LVertPortSf', 'coeffs_LPlate', 'coeffs_WPlate', 'coeffs_mass', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'runBounds', 'runUnitsBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'A', 'dpWf()', 'dpSf()', 'isEvap()')
cdef str msg

cdef class HxPlateCorrugated(HxPlate):
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
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioPlate : float, optional
    Multiplier for the heat transfer surface area of the plate [-]. Defaults to 1.
DPortWf : float, optional
    Diameter of the working fluid flow ports [m]. Defaults to nan.
DPortSf : float, optional
    Diameter of the secondary fluid flow ports [m]. Defaults to nan.
LVertPortWf : float, optional
    Vertical distance between incoming and outgoing working fluid flow ports [m]. If None, L is used. Defaults to None.
LVertPortSf : float, optional
    Vertical distance between incoming and outgoing secondary fluid flow ports [m]. If None, L is used. Defaults to None.
coeffs_LPlate : list of float, optional
    Coefficients to calculate the total plate length from the length of the heat transfer area. LPlate = sum(coeffs_LPlate[i] * L**i). Defaults to [0, 1].
coeffs_WPlate : list of float, optional
    Coefficients to calculate the total plate width from the width of the heat transfer area. wPlate = sum(coeffs_WPlate[i] * W**i). Defaults to [0, 1].
coeffs_mass : list of float, optional
    Coefficients to calculate the total mass of the plates from the number of plates and the plate volume.::
        mass = sum(coeffs_mass[i] * NPlates**i)*(LPlate*WPlate*tPlate).

    If None, the mass is approximated from the plate geometry. Defaults to None.
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

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
sizeUnitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. Typically this bounds is used to size for the length of the HxUnit. Defaults to [1e-5, 1.].
name : string, optional
    Description of object. Defaults to "HxPlate instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 int NPlate=3,
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
                 double DPortWf=nan,
                 double DPortSf=nan,
                 double LVertPortWf=nan,
                 double LVertPortSf=nan,
                 list coeffs_LPlate=[0, 1],
                 list coeffs_WPlate=[0, 1],
                 list coeffs_mass=[],
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
        super().__init__(flowConfig, NPlate, RfWf, RfSf, plate, tPlate, geomWf, geomSf, L, W, ARatioWf, ARatioSf,
                         ARatioPlate, efficiencyThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, runUnitsBounds, name, notes, config, _unitClass)
        self.DPortWf = DPortWf
        self.DPortSf = DPortSf
        self.LVertPortWf = LVertPortWf
        self.LVertPortSf = LVertPortSf
        self.coeffs_LPlate = coeffs_LPlate
        self.coeffs_WPlate = coeffs_WPlate
        self.coeffs_mass = coeffs_mass
        #
        self._inputs = _inputs
        self._properties = _properties
    
    cpdef public void update(self, dict kwargs):
        """Update (multiple) variables using keyword arguments."""
        for key, value in kwargs.items():
            if key not in ["DPortWf", "DPortSf", "LVertPortWf", "LVertPortSf", "coeffs_LPlate","coeffs_WPlate", "coeffs_mass"]:
                super(HxBasicPlanar, self).update({key: value})
            else:
                super(Component22, self).update({key: value})
                
    cpdef public double LPlate(self):
        """float: Total length of the plate; sum(coeffs_LPlate[i] * L**i)."""
        cdef double ans = 0
        cdef int i
        for i in range(len(self.coeffs_LPlate)):
            ans += self.coeffs_LPlate[i] * self.L**i
        return ans

    cpdef public double WPlate(self):
        """float: Total width of the plate; sum(coeffs_WPlate[i] * W**i)."""
        cdef double ans = 0
        cdef int i
        for i in range(len(self.coeffs_WPlate)):
            ans += self.coeffs_WPlate[i] * self.W**i
        return ans

    cdef double _LVertPortWf(self):
        if isnan(self.LVertPortWf):
            return self.L
        else:
            return self.LVertPortWf

    cdef double _LVertPortSf(self):
        if isnan(self.LVertPortSf):
            return self.L
        else:
            return self.LVertPortSf

    cpdef public double dpPortWf(self):
        """float: Port pressure loss of the working fluid [Pa]."""
        cdef double GPort = self._mWf() / (0.25 * pi * self.DPortWf**2)
        cdef double dpIn = self.config.dpPortInFactor * GPort**2 / 2 / self.flowsIn[0].rho()
        cdef double dpOut = self.config.dpPortOutFactor * GPort**2 / 2 / self.flowsOut[0].rho()
        return dpIn + dpOut

    cpdef public double dpPortSf(self):
        """float: Port pressure loss of the secondary fluid [Pa]."""
        cdef double GPort = self._mSf() / (0.25 * pi * self.DPortSf**2)
        cdef double dpIn = self.config.dpPortInFactor * GPort**2 / 2 / self.flowsIn[1].rho()
        cdef double dpOut = self.config.dpPortOutFactor * GPort**2 / 2 / self.flowsOut[1].rho()
        return dpIn + dpOut

    cpdef public double dpHeadWf(self):
        """float: Static head pressure drop of the working fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.flowConfig.verticalWf:
            if self.isEvap():
                return self.flowsOut[0].rho() * self.config.gravity * self._LVertPortWf()
            else:
                return -self.flowsOut[0].rho() * self.config.gravity * self._LVertPortWf()

    cpdef public double dpHeadSf(self):
        """float: Static head pressure drop of the secondary fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.flowConfig.verticalSf:
            if self.isEvap():
                return -self.flowsOut[1].rho() * self.config.gravity * self._LVertPortSf()
            else:
                return self.flowsOut[1].rho() * self.config.gravity * self._LVertPortSf()

    cpdef public double dpWf(self):
        """float: Total pressure drop of the working fluid [Pa]."""
        cdef double dp = 0
        if self.config.dpFWf:
            dp += self.dpFWf()
        if self.config.dpAccWf:
            dp += self.dpAccWf()
        if self.config.dpHeadWf:
            dp += self.dpHeadWf()
        if self.config.dpPortWf:
            dp += self.dpPortWf()
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
        if self.config.dpPortSf:
            dp += self.dpPortSf()
        return dp

    cpdef public double mass(self):
        """float: Approximate total mass of the heat exchanger plates [Kg], calculated as either

    - sum(coeffs_mass[i] * NPlate**i)*(LPlate*WPlate*tPlate) if coeffs_mass is defined,
    - or (LPlate*WPlate - 2(0.25*pi*DPortWf**2 + 0.25*pi*DPortSf**2))*tPlate*plate.rho*NPlate.
        """
        cdef double massPerVol
        cdef int i
        if self.coeffs_mass == []:
            if self.coeffs_LPlate == [0, 1]:
                return (self.L * self.WPlate()) * self.tWall * self.wall.rho * self.NWall
            else:
                return (
                self.LPlate() * self.WPlate() - 2 *
                (0.25 * pi * self.DPortWf**2 + 0.25 * pi * self.DPortSf**
                 2)) * self.tWall * self.wall.rho * self.NWall
        else:
            massPerVol = 0.
            for i in range(len(self.coeffs_mass)):
                massPerVol += self.coeffs_mass[i] * self.NWall**i
            return massPerVol * self.LPlate() * self.WPlate() * self.tWall

