from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.geom cimport Geom
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from ...methods import heat_transfer as ht
from ...geometries.geom_hxplate cimport GeomHxPlateCorrugatedChevron, GeomHxPlateFinOffset, GeomHxPlateFinStraight, GeomHxPlateSmooth
from .hxunit_basicplanar cimport HxUnitBasicPlanar
from .flowconfig cimport HxFlowConfig
from warnings import warn
from math import nan
import CoolProp as CP
import numpy as np
import scipy.optimize as opt

cdef str method
cdef dict _inputs = {"flowConfig": MCAttr(HxFlowConfig, "none"), "NPlate": MCAttr(int, "none"), "RfWf": MCAttr(float, "fouling"),
                        "RfSf": MCAttr(float, "fouling"), "plate": MCAttr(SolidMaterial, "none"), "tPlate": MCAttr(float, "length"), "geomWf": MCAttr(Geom, "none"), "geomSf": MCAttr(Geom, "none"), "L": MCAttr(float, "length"), "W": MCAttr(float, "length"),
                        "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioPlate": MCAttr(float, "none"), "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"),
                        "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"), 
                        "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"),
                        "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "U()": MCAttr(float, "htc"), "A()": MCAttr(float, "area"), "dpWf()": MCAttr(float, "pressure"), "dpSf()": MCAttr(float, "pressure"), "isEvap()": MCAttr(bool, "none")}

cdef class HxUnitPlate(HxUnitBasicPlanar):
    r"""Characterises a basic plate heat exchanger unit consisting of alternating working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowConfig : HxFlowConfig, optional
    Flow configuration/arrangement information. See :meth:`mcycle.bases.component.HxFlowConfig`.
NPlate : int, optional
    Number of parallel plates [-]. Defaults to 3.
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
beta : float, optional
     Plate corrugation chevron angle [deg]. Defaults to nan.
phi : float, optional
     Corrugated plate surface enlargement factor; ratio of developed length to projected length. Defaults to 1.2.
pitchCor : float, optional
     Plate corrugation pitch [m] (distance between corrugation 'bumps'). Defaults to nan.
     .. note: Not to be confused with the plate pitch which is usually defined as the sum of the plate channel spacing and one plate thickness.
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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "L".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to [1e-5, 10.0].

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of object. Defaults to "HxUnitPlateCorrugated instance".
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
                 double tPlate=float("nan"),
                 Geom geomWf=None,
                 Geom geomSf=None,
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
                 str name="HxUnitPlate instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(flowConfig, -1, -1, NPlate, nan, nan, RfWf, RfSf,
                         plate, tPlate, L, W, ARatioWf, ARatioSf, ARatioPlate,
                         effThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         sizeAttr, sizeBounds, name, notes, config)
        self.geomWf = geomWf
        self.geomSf = geomSf
        self._inputs = _inputs
        self._properties = _properties
        
    cpdef public int _NWf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NWall & 1:  # NPlate is odd
            return int((self.NWall - 1) / 2)
        else:
            if self.config.evenPlatesWf:
                return int(self.NWall / 2)
            else:
                return int(self.NWall / 2 - 1)

    cpdef public int _NSf(self):
        """int: Number of secondary fluid flow channels. Setter may not be used.

    - if NPlate is odd: NWf = NSf = (NPlate - 1) / 2
    - if NPlate is even: the extra flow channel is assigned according to config.evenPlatesWf.
        """
        if self.NWall & 1:  # NPlate is odd
            return int((self.NWall - 1) / 2)
        else:
            if self.config.evenPlatesWf:
                return int(self.NWall / 2 - 1)
            else:
                return int(self.NWall / 2)

    cpdef public double _hWf(self):
        """float: Heat transfer coefficient of a working fluid channel [W/m^2.K]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomWf.__class__.__name__, "heat",
                                             self.phaseWf(), "wf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[0],
            flowOut=self.flowsOut[0],
            N=self._NWf(),
            geom=self.geomWf,
            L=self.L,
            W=self.W,
            flowConfig=self.flowConfig,
            is_wf=False,
            geom2=self.geomSf)["h"]

    cpdef public double _hSf(self):
        """float: Heat transfer coefficient of a secondary fluid channel [W/m^2.K]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomSf.__class__.__name__, "heat",
                                             self.phaseSf(), "sf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[1],
            flowOut=self.flowsOut[1],
            N=self._NSf(),
            geom=self.geomSf,
            L=self.L,
            W=self.W,
            flowConfig=self.flowConfig,
            is_wf=True,
            geom2=self.geomSf)["h"]

    cpdef public double _fWf(self):
        """float: Fanning friction factor of a working fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomWf.__class__.__name__,
                                            "friction", self.phaseWf(), "wf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[0],
            flowOut=self.flowsOut[0],
            N=self._NWf(),
            geom=self.geomWf,
            L=self.L,
            W=self.W,
            flowConfig=self.flowConfig,
            is_wf=True,
            geom2=self.geomSf)["f"]

    cpdef public double _fSf(self):
        """float: Fanning friction factor of a secondary fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomSf.__class__.__name__,
                                             "friction", self.phaseSf(), "sf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[1],
            flowOut=self.flowsOut[1],
            N=self._NSf(),
            geom=self.geomSf,
            L=self.L,
            W=self.W,
            flowConfig=self.flowConfig,
            is_wf=False,
            geom2=self.geomSf)["f"]

    cpdef public double _dpFWf(self):
        """float: Frictional pressure drop of a working fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__,
                                            (self.geomWf.__class__.__name__,
                                             "friction", self.phaseWf(), "wf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[0],
            flowOut=self.flowsOut[0],
            N=self._NWf(),
            geom=self.geomWf,
            L=self.L,
            W=self.W,
            flowConfig=self.flowConfig,
            is_wf=False,
            geom2=self.geomSf)["dpF"]

    cpdef public double _dpFSf(self):
        """float: Frictional pressure drop of a secondary fluid channel [-]. Calculated using the relevant method of mcycle.methods.heat_transfer defined in config.methods."""
        method = self.config.lookupMethod(self.__class__.__name__, (self.geomSf.__class__.__name__, "friction", self.phaseSf(), "sf"))
        return getattr(ht, method)(
            flowIn=self.flowsIn[1],
            flowOut=self.flowsOut[1],
            N=self._NSf(),
            geom=self.geomSf,
            L=self.L,
            W=self.W,
            flowConfig=self.flowConfig,
            is_wf=False,
            geom2=self.geomWf)["dpF"]

    cpdef public double U(self):
        """float: Overall heat transfer coefficient of the unit [W/m^2.K]."""
        cdef double RWf = (1 / self._hWf() + self.RfWf) / self.ARatioWf / self._NWf()
        cdef double RSf = (1 / self._hSf() + self.RfSf) / self.ARatioSf / self._NSf()
        cdef double RPlate = self.tWall / (
            self.NWall - 2) / self.wall.k() / self.ARatioWall
        return (RWf + RSf + RPlate)**-1

    cdef double Re(self, int flowId=0):
        cdef Geom geom
        cdef int N
        if flowId == 0:
            geom = self.geomWf
            N = self._NWf()
        else:
            geom = self.geomSf
            N = self._NSf()
        cdef FlowState flowIn = self.flowsIn[flowId]
        cdef FlowState flowOut = self.flowsOut[flowId]
        cdef double Dh, Ac, a, b
        if type(geom) in [GeomHxPlateCorrugatedChevron]:
            Dh = 2 * geom.b
            Ac = geom.b * self.W
        elif type(geom) in [GeomHxPlateSmooth]:
            Dh = 2 * geom.b
            Ac = geom.b * self.W
        elif type(geom) in [GeomHxPlateFinStraight, GeomHxPlateFinOffset]:
            a = geom.s/2
            b = geom.h()/2
            Dh = 4*a*b/(a+b)
            Dh = Dh*(2./3+11/24*a/b*(2-a/b))
            Ac = geom.h() * geom.s * self.W/(geom.s + geom.t)
        cdef double m_channel = flowIn.m / N
        cdef double G = m_channel / Ac
        cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
        cdef double h_avg = 0.5 * (flowIn.h() + flowOut.h())
        cdef FlowState avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
        return G * Dh / avg.visc()
    

    cpdef public double ReWf(self):
        return self.Re(0)
    
    cpdef public double ReSf(self):
        return self.Re(1)
    
    cpdef double _f_sizeUnitsHxUnitPlate(self, double value, str attr):
        self.update({attr: value})
        return self.Q() - self.Q_lmtd()
    
    cpdef public void sizeUnits(self, str attr, list bounds) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be solved. If None, self.sizeAttr is used. Defaults to None.
bounds : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
        """
        cdef double tol, sizedValue, fa, fb, r
        cdef list boundsOriginal
        if attr == '':
            attr = self.sizeAttr
        if bounds == []:
            bounds = self.sizeBounds
        boundsOriginal = bounds
        try:
            tol = self.config.tolAbs + self.config.tolRel * self.Q()
            if len(bounds) == 2:
                try:
                    sizedValue = opt.brentq(self._f_sizeUnitsHxUnitPlate,
                                            bounds[0],
                                            bounds[1],
                                            args=(attr),
                                            rtol=self.config.tolRel,
                                            xtol=self.config.tolAbs)
                except:
                    a = bounds[0]
                    b = bounds[1]
                    fa = self._f_sizeUnitsHxUnitPlate(a, attr)
                    fb = self._f_sizeUnitsHxUnitPlate(b, attr)
                    r = a - fa*(b-a)/(fb-fa)
                    try:
                        sizedValue = opt.brentq(self._f_sizeUnitsHxUnitPlate,
                                            a,
                                            2*r-a,
                                            args=(attr),
                                            rtol=self.config.tolRel,
                                            xtol=self.config.tolAbs)
                    except:
                        try:
                            sizedValue = opt.brentq(self._f_sizeUnitsHxUnitPlate,
                                            b,
                                            2*r-b,
                                            args=(attr),
                                            rtol=self.config.tolRel,
                                            xtol=self.config.tolAbs)
                        except Exception as exc:
                            warn('Could not find solution in boundss {} or {}.'.format([a, 2*r-a], [b, 2*r-b]))
                            raise exc
            else:
                raise ValueError("bounds is not valid (given: {})".format(bounds))
            self.update({attr: sizedValue})
            # return sizedValue
        except AssertionError as err:
            raise err
        except:
            raise Exception(
                "{}.sizeUnit({},{}) failed to converge".format(
                    self.__class__.__name__, attr, boundsOriginal))


    @property
    def geom(self):
        if self.geomSf is self.geomWf:
            return self.geomWf
        else:
            warn(
                "geom is not valid: geomWf and geomSf are different objects"
            )
            pass

    @geom.setter
    def geom(self, obj):
        self.geomWf = obj
        self.geomSf = obj
    @property
    def plate(self):
        """alias of self.wall."""
        return self.wall

    @plate.setter
    def plate(self, value):
        self.wall = value

    @property
    def tPlate(self):
        """alias of self.tWall."""
        return self.tWall

    @tPlate.setter
    def tPlate(self, value):
        self.tWall = value

    @property
    def ARatioPlate(self):
        """alias of self.ARatioWall."""
        return self.ARatioWall

    @ARatioPlate.setter
    def ARatioPlate(self, value):
        self.ARatioWall = value

    @property
    def NPlate(self):
        """alias of self.NWall."""
        return self.NWall

    @NPlate.setter
    def NPlate(self, value):
        self.NWall = value
