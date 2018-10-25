from ...DEFAULTS cimport TOLABS, MAXITER_COMPONENT, MAX_WALLS
from .hxunit_basic cimport HxUnitBasic
from .hx_basicplanar cimport HxBasicPlanar
from .hxunit_plate cimport HxUnitPlate
from ...bases.config cimport Config
from ...bases.component cimport Component22
from ...bases.geom cimport Geom
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from warnings import warn
from math import nan, isnan, pi
import scipy.optimize as opt
import CoolProp as CP

cdef dict _inputs = {"flowSense": MCAttr(str, "none"), "NPlate": MCAttr(int, "none"), "RfWf": MCAttr(float, "fouling"), "RfSf": MCAttr(float, "fouling"), "plate": MCAttr(SolidMaterial, "none"), "tPlate": MCAttr(float, "length"), "geomPlateWf": MCAttr(Geom, "none"), "geomPlateSf": MCAttr(Geom, "none"), "L": MCAttr(float, "length"), "W": MCAttr(float, "length"), "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioPlate": MCAttr(float, "none"), "DPortWf": MCAttr(float, "none"), "DPortSf": MCAttr(float, "none"), "LVertPortWf": MCAttr(float, "none"), "LVertPortSf": MCAttr(float, "none"), "coeffs_LPlate": MCAttr(list, "none"), "coeffs_WPlate": MCAttr(list, "none"),"coeffs_weight": MCAttr(list, "none"), "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"), "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"),  "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "sizeUnitsBounds": MCAttr(list, "none"), 'runBounds': MCAttr(list, 'none'), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "A": MCAttr( "area"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}

cdef class HxPlate(HxBasicPlanar):
    r"""Characterises a basic plate heat exchanger consisting of alternating working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counter" or "parallel". Defaults to "counter".
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
plate : SolidMaterial, optional
    Plate material. Defaults to None.
tPlate : float, optional
    Thickness of the plate [m]. Defaults to nan.
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
NPlate : int, optional
    Number of parallel plates [-]. The number of thermally activate plates is equal to NPlate - 2, due to the 2 end plates. Must be >= 3. Defaults to 3.
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
coeffs_weight : list of float, optional
    Coefficients to calculate the total weight of the plates from the number of plates and the plate volume.::
        weight = sum(coeffs_weight[i] * NPlates**i)*(LPlate*WPlate*tPlate).

    If None, the weight is approximated from the plate geometry. Defaults to None.
effThermal : float, optional
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
                 str flowSense="counter",
                 int NPlate=3,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial plate=None,
                 double tPlate=nan,
                 Geom geomPlateWf=None,
                 Geom geomPlateSf=None,
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
                 list coeffs_weight=[],
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[3, 100],
                 list sizeUnitsBounds=[1e-5, 10.],
                 runBounds=[nan, nan],
                 str name="HxBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config(),
                 _unitClass=HxUnitPlate):
        assert flowSense != "counter" or flowSense != "parallel", "{} is not a valid value for flowSense; must be 'counter' or 'parallel'.".format(flowSense)
        self.geomPlateWf = geomPlateWf
        self.geomPlateSf = geomPlateSf
        self.DPortWf = DPortWf
        self.DPortSf = DPortSf
        self.LVertPortWf = LVertPortWf
        self.LVertPortSf = LVertPortSf
        self.coeffs_LPlate = coeffs_LPlate
        self.coeffs_WPlate = coeffs_WPlate
        self.coeffs_weight = coeffs_weight
        super().__init__(flowSense, -1, -1, NPlate, nan, nan, nan, nan,
                         RfWf, RfSf, plate, tPlate, L, W, ARatioWf, ARatioSf,
                         ARatioPlate, effThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, name, notes, config, _unitClass)
        self._unitClass = HxUnitPlate
        self._inputs = _inputs
        self._properties = _properties

    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowSense, self.NPlate, self.RfWf, self.RfSf, self.plate,
                self.tPlate, self.geomPlateWf, self.geomPlateSf, self.L,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioPlate,
                self.effThermal)

    cdef public tuple _unitArgsTp(self):
        """Arguments passed to HxUnits in the two-phase region."""
        return self._unitArgsLiq()

    cdef public tuple _unitArgsVap(self):
        """Arguments passed to HxUnits in the vapour region."""
        return self._unitArgsLiq()
    
    cpdef public void update(self, dict kwargs):
        """Update (multiple) variables using keyword arguments."""
        for key, value in kwargs.items():
            if key not in ["DPortWf", "DPortSf", "LVertPortWf", "LVertPortSf", "coeffs_LPlate","coeffs_WPlate", "coeffs_weight"]:
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

    cpdef public int _NWf(self):
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

    cpdef public int _NSf(self):
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
        """float: Frcitional pressure drop of the secondary fluid [Pa]."""
        cdef double dp = 0
        cdef HxUnitPlate unit
        cdef size_t i
        for i in range(len(self._units)):#unit in self._units:
            unit = self._units[i]
            dp += unit._dpFSf()
        return dp

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

    cpdef public double dpAccWf(self):
        """float: Acceleration pressure drop of the working fluid [Pa]."""
        cdef double G = self._mWf() / self._NWf() / (self.geomPlateWf.b * self.W)
        return G**2 * (1 / self.flowsOut[0].rho() - 1 / self.flowsIn[0].rho())

    cpdef public double dpAccSf(self):
        """float: Acceleration pressure drop of the secondary fluid [Pa]."""
        cdef double G = self._mSf() / self._NSf() / (self.geomPlateSf.b * self.W)
        return G**2 * (1 / self.flowsOut[1].rho() - 1 / self.flowsIn[0].rho())

    cpdef public double dpHeadWf(self):
        """float: Static head pressure drop of the working fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.isEvap():
            return self.flowsOut[0].rho() * self.config.g * self._LVertPortWf()
        else:
            return -self.flowsOut[0].rho() * self.config.g * self._LVertPortWf()

    cpdef public double dpHeadSf(self):
        """float: Static head pressure drop of the secondary fluid [Pa]. Assumes the hot flow flows downwards and the cold flow flows upwards."""
        if self.isEvap():
            return -self.flowsOut[1].rho() * self.config.g * self._LVertPortSf()
        else:
            return self.flowsOut[1].rho() * self.config.g * self._LVertPortSf()

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

    cpdef public double weight(self):
        """float: Approximate total weight of the heat exchanger plates [Kg], calculated as either

    - sum(coeffs_weight[i] * NPlate**i)*(LPlate*WPlate*tPlate) if coeffs_weight is defined,
    - or (LPlate*WPlate - 2(0.25*pi*DPortWf**2 + 0.25*pi*DPortSf**2))*tPlate*plate.rho*NPlate.
        """
        cdef double weightPerVol
        cdef int i
        if self.coeffs_weight == []:
            if self.coeffs_LPlate == [0, 1]:
                return (self.L * self.WPlate()) * self.tWall * self.wall.rho * self.NWall
            else:
                return (
                self.LPlate() * self.WPlate() - 2 *
                (0.25 * pi * self.DPortWf**2 + 0.25 * pi * self.DPortSf**
                 2)) * self.tWall * self.wall.rho * self.NWall
        else:
            weightPerVol = 0.
            for i in range(len(self.coeffs_weight)):
                weightPerVol += self.coeffs_weight[i] * self.NWall**i
            return weightPerVol * self.LPlate() * self.WPlate() * self.tWall

    cpdef public int size_NPlate(self) except *:
        """int: size for NPlate that requires L to be closest to self.L"""
        cdef double diff
        cdef int NPlate = self.sizeBounds[0]
        cdef double L = self.L
        cdef list diff_vals = [nan, nan]
        while NPlate < self.sizeBounds[1]:
            self.update({'NWall':NPlate})
            diff = self.size_L(self.sizeUnitsBounds) - L
            diff_vals = [diff_vals[1], diff]
            if diff > 0:
                NPlate += 1
            else:
                break
        if abs(diff_vals[0]) < abs(diff_vals[1]):
            self.update({'NWall':NPlate-1})
            self.size_L(self.sizeUnitsBounds)
            return NPlate - 1
        else:
            return NPlate

    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.

unitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. If None, self.sizeUnitsBounds is used. Defaults to None.
        """
        if attr == "":
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        try:
            if attr in ["N", "NPlate"]:
                self.update({'sizeBounds': bounds, 'sizeUnitsBounds': unitsBounds})
                self.unitise()
                self.NWall = self.size_NPlate()
            else:
                super(HxPlate, self)._size(attr, bounds, unitsBounds)
        except AssertionError as err:
            raise err
        except:
            raise StopIteration("{}.size({},{},{}) failed to converge.".format(
                self.__class__.__name__, attr, bounds, unitsBounds))

    @property
    def NWf(self):
        return self._NWf()

    @property
    def NSf(self):
        return self._NSf()

    @property
    def geomPlate(self):
        if self.geomPlateSf is self.geomPlateWf:
            return self.geomPlateWf
        else:
            warn(
                "geomPlate is not valid: geomPlateWf and geomPlateSf are different objects"
            )
            pass

    @geomPlate.setter
    def geomPlate(self, obj):
        self.geomPlateWf = obj
        self.geomPlateSf = obj
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

    @property
    def ARatioPlate(self):
        """float: Alias of self.ARatioWall"""
        return self.ARatioWall

    @ARatioPlate.setter
    def ARatioPlate(self, value):
        self.ARatioWall = value

    @property
    def NPlate(self):
        """int: Alias of self.NWall"""
        return self.NWall

    @NPlate.setter
    def NPlate(self, value):
        self.NWall = value
