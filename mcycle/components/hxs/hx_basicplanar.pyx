from ...DEFAULTS cimport TOLABS
from .hx_basic cimport HxBasic
from .hxunit_basicplanar cimport HxUnitBasicPlanar
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
import CoolProp as CP
from math import nan
import scipy.optimize as opt
#from scipy.optimize._zeros._brent cimport _brentq


cdef class HxBasicPlanar(HxBasic):
    r"""Characterises a basic planar heat exchanger consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowSense : str, optional
    Relative direction of the working and secondary flows. May be either "counter" or "parallel". Defaults to "counter".
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
hWf_liq : float, optional
    Heat transfer coefficient of the working fluid in the single-phase liquid region (subcooled). Defaults to nan.
hWf_tp : float, optional
    Heat transfer coefficient of the working fluid in the two-phase liquid/vapour region. Defaults to nan.
hWf_vap : float, optional
    Heat transfer coefficient of the working fluid in the single-phase vapour region (superheated). Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid in a single-phase region. Defaults to nan.
RfWf : float, optional
    Thermal resistance due to fouling on the working fluid side. Defaults to 0.
RfSf : float, optional
    Thermal resistance due to fouling on the secondary fluid side. Defaults to 0.
wall : SolidMaterial, optional
    Wall material. Defaults to None.
tWall : float, optional
    Thickness of the wall [m]. Defaults to nan.
L : float, optional
    Length of the heat transfer surface area (dimension parallel to flow direction) [m]. Defaults to nan.
W : float, optional
    Width of the heat transfer surface area (dimension perpendicular to flow direction) [m]. Defaults to nan.
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioWall : float, optional
    Multiplier for the heat transfer surface area of the wall [-]. Defaults to 1.
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
    Default attribute used by size(). Defaults to "N".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1, 100].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
sizeUnitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. Typically this bounds is used to size for the length of the HxUnit. Defaults to [1e-5, 1.].
name : string, optional
    Description of object. Defaults to "HxBasicPlanar instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    def __init__(self,
                 str flowSense="counter",
                 int NWf=1,
                 int NSf=1,
                 int NWall=1,
                 hWf_liq=nan,
                 hWf_tp=nan,
                 hWf_vap=nan,
                 double hSf=nan,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=nan,
                 double L=nan,
                 double W=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[1, 100],
                 list sizeUnitsBounds=[1e-5, 1.],
                 runBounds = [nan, nan],
                 str name="HxBasic instance",
                 str notes="No notes/model info.",
                 Config config=Config(),
                 _unitClass=HxUnitBasicPlanar):
        assert flowSense != "counter" or flowSense != "parallel", "{} is not a valid value for flowSense; must be 'counter' or 'parallel'.".format(flowSense)
        self.L = L
        self.W = W
        super().__init__(flowSense, NWf, NSf, NWall, hWf_liq, hWf_tp, hWf_vap,
                         hSf, RfWf, RfSf, wall, tWall, L * W, ARatioWf,
                         ARatioSf, ARatioWall, effThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, name, notes, config, _unitClass)
        self._units = []
        self._unitClass = HxUnitBasicPlanar
        if self.hasInAndOut(0) and self.hasInAndOut(1):
            pass  # self._unitise()
        self._inputs = {"flowSense": MCAttr(str, "none"), "NWf": MCAttr(int, "none"), "NSf": MCAttr(int, "none"),
                        "NWall": MCAttr(int, "none"), "hWf_liq": MCAttr(float, "htc"), "hWf_tp": MCAttr(float, "htc"),
                        "hWf_vap": MCAttr(float, "htc"), "hSf": MCAttr(float, "htc"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "wall": MCAttr(SolidMaterial, "none"), "tWall": MCAttr(float, "length"), "L": MCAttr(float, "length"), "W": MCAttr(float, "length"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioWall": MCAttr(float, "none"),
                        "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"),  "ambient": MCAttr(FlowState, "none"),
                        "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"),
                        "sizeUnitsBounds": MCAttr(list, "none"), 'runBounds': MCAttr(list, 'none'), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
        self._properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "A": MCAttr( "area"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}

    cpdef public double _A(self):
        return self.L * self.W

    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_liq,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal)

    cdef public tuple _unitArgsTp(self):
        """Arguments passed to HxUnits in the two-phase region."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_tp,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal)

    cdef public tuple _unitArgsVap(self):
        """Arguments passed to HxUnits in the vapour region."""
        return (self.flowSense, self.NWf, self.NSf, self.NWall, self.hWf_vap,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, None,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioWall,
                self.effThermal)

    cpdef public double size_L(self, list unitsBounds):
        """float: Solve for the required length of the Hx to satisfy the heat transfer equations [m]."""
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        cdef double L = 0.
        cdef HxUnitBasicPlanar unit
        for unit in self._units:
            if abs(unit.Q()) > TOLABS:
                unit.sizeUnits('L', unitsBounds)
                L += unit.L
        self.L = L
        return L


    cpdef double _f_sizeHxBasicPlanar(self, double value, double L, str attr, list unitsBounds):
        self.update({attr: value})
        return self.size_L(unitsBounds) - L
                        
    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=[a]: scipy.optimize.newton is used.

unitsBounds : float or list of float, optional
    Bracket passed on to any HxUnits containing solution of size() for the unit. If None, self.sizeUnitsBounds is used. Defaults to None.
        """
        cdef double L, tol
        cdef HxUnitBasicPlanar unit
        if attr == '':
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        if unitsBounds == []:
            unitsBounds = self.sizeUnitsBounds
        try:
            if attr == "L":
                self.size_L(unitsBounds)
            elif attr == "flowOutSf":
                super(HxBasicPlanar, self)._size(attr, bounds, unitsBounds)
            else:
                # self.unitise()
                L = self.L

                tol = self.config.tolAbs + self.config.tolRel * abs(self.Q())
                if len(bounds) == 2:
                    sizedValue = opt.brentq(
                        self._f_sizeHxBasicPlanar,
                        bounds[0],
                        bounds[1],
                        args=(L, attr, unitsBounds),
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                elif len(bounds) == 1:
                    sizedValue = opt.newton(self._f_sizeHxBasicPlanar, bounds[0], args=(L, attr, unitsBounds), tol=tol)
                else:
                    raise ValueError("bounds is not valid (given: {})".format(bounds))
                self.update({attr: sizedValue})
                #return sizedValue
        except AssertionError as err:
            raise err
        except AttributeError as err:
            raise err
        except:
            raise StopIteration(
                "Warning: {}.size({},{},{}) failed to converge.".format(
                    self.__class__.__name__, attr, bounds, unitsBounds))

    cpdef double _f_runHxBasicPlanar(self, double value, double saveL):
        self.flowsOut[0] = self.flowsIn[0].copyState(CP.HmassP_INPUTS, value, self.flowsIn[0].p())
        cdef double hOut = self.flowsIn[1].h() - self._mWf() * self._effFactorWf() * (self.flowsOut[0].h() - self.flowsIn[0].h()) / self._mSf() / self._effFactorSf()
        self.flowsOut[1] = self.flowsIn[1].copyState(CP.HmassP_INPUTS, hOut, self.flowsIn[1].p())
        self.unitise()
        o = saveL - self.size_L(self.sizeUnitsBounds)
        #print("----------- _f_runHxBasicPlanar, saveL - self.size_L = ", o)
        return o
        
    cpdef public void run(self):
        cdef double tol, sizedValue, a, b, saveL = self.L
        """
        cdef FlowState critWf = self.flowsIn[0].copyState(CP.PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[0]._state.T_critical())
        cdef FlowState minWf = self.flowsIn[0].copyState(CP.PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[0]._state.Tmin())
        cdef double deltah"""
        try:
            """
            if self.isEvap():
                deltah = critWf.h() - self.flowsIn[0].h()
                a = self.flowsIn[0].h() + deltah*self.runBounds[0]
                if self.flowsIn[1].T() > critWf.T():
                    b = self.flowsIn[0].h() + deltah*self.runBounds[1]
                else:
                    deltah = self.flowsIn[0].copyState(CP.PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[1].T()).h() - self.flowsIn[0].h()
                    b = self.flowsIn[0].h() + deltah*(self.runBounds[1])
            else:
                deltah = self.flowsIn[0].h() - minWf.h()
                b = self.flowsIn[0].h() - deltah*self.runBounds[0]
                
                if self.flowsIn[1].T() < minWf.T():
                    a = self.flowsIn[0].h() - deltah*self.runBounds[1]
                else:
                    deltah = self.flowsIn[0].h() - self.flowsIn[0].copyState(CP.PT_INPUTS, self.flowsIn[0].p(), self.flowsIn[1].T()).h()
                    a = self.flowsIn[0].h() - deltah*self.runBounds[1]
           
            sizedValue = opt.brentq(self._f_runHxBasicPlanar,
                                    a,
                                    b,
                                    args=(saveL),
                                    rtol=self.config.tolRel,
                                    xtol=self.config.tolAbs)
            """
            sizedValue = opt.brentq(self._f_runHxBasicPlanar,
                                    *self.runBounds,
                                    args=(saveL),
                                    rtol=self.config.tolRel,
                                    xtol=self.config.tolAbs)
        except AssertionError as err:
            raise err
        except AttributeError as err:
            raise err
        except Exception as exc:
            raise StopIteration(
                "{}.run() failed to converge. Check bounds for solution: runBounds={}. ".format(
                    self.__class__.__name__, self.runBounds), exc)
        finally:
            
            self.update({"L": saveL})

            
    @property
    def A(self):
        """float: Heat transfer surface area. A = L * W.
        Setter preserves the ratio of L/W."""
        return self.L * self.W

    @A.setter
    def A(self, value):
        if self.L and self.W:
            a = self.L * self.W
            self.L *= (value / a)**0.5
            self.W *= (value / a)**0.5
        else:
            pass

