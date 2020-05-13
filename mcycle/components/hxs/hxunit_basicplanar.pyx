from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from .hxunit_basic cimport HxUnitBasic
from .flowconfig cimport HxFlowConfig

cdef tuple _inputs = ('flowConfig', 'NWf', 'NSf', 'NWall', 'hWf', 'hSf', 'RfWf', 'RfSf', 'wall', 'tWall', 'L', 'W', 'ARatioWf', 'ARatioSf', 'ARatioWall', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'flowDeadSf', 'sizeAttr', 'sizeBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'U()', 'A()', 'dpWf()', 'dpSf()', 'isEvap()')
        
cdef class HxUnitBasicPlanar(HxUnitBasic):
    r"""Characterises a basic planar heat exchanger unit consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowConfig : HxFlowConfig, optional
    Flow configuration/arrangement information. See :meth:`mcycle.bases.component.HxFlowConfig`.
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
hWf : float, optional
    Heat transfer coefficient of the working fluid. Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid. Defaults to nan.
RfWf : float, optional
    Thermal resistance factor due to fouling on the working fluid side [m^2K/W]. Defaults to 0.
RfSf : float, optional
    Thermal resistance factor due to fouling on the secondary fluid side [m^2K/W]. Defaults to 0.
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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to "A".
sizeBounds : float or list of float, optional
    Bracket containing solution of size(), equal to sizeUnitsBounds of the containing Hx object. Defaults to [0.01, 10.0].
name : string, optional
    Description of Component object. Defaults to "HxBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 int NWf=1,
                 int NSf=1,
                 int NWall=1,
                 double hWf=float("nan"),
                 double hSf=float("nan"),
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=float("nan"),
                 double L=float("nan"),
                 double W=float("nan"),
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 str sizeAttr="A",
                 list sizeBounds=[0.01, 10.0],
                 str name="HxUnitBasic instance",
                 str  notes="No notes/model info.",
                 Config config=None):       
        self.L = L
        self.W = W
        super().__init__(flowConfig, NWf, NSf, NWall, hWf, hSf, RfWf, RfSf,
                         wall, tWall, L * W, ARatioWf, ARatioSf, ARatioWall,
                         efficiencyThermal, flowInWf, flowInSf, flowOutWf, flowOutSf,
                         sizeAttr, sizeBounds, name, notes, config)
        
        self._inputs = _inputs
        self._properties = _properties

    cpdef public double _A(self):
        return self.L * self.W

    cpdef public void sizeUnits(self) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bounds : list of float, optional
    Bracket containing solution of size(). If None, self.sizeBounds is used. Defaults to None.
        """
        cdef str attr = self.sizeAttr
        cdef list bounds = self.sizeBounds
        try:
            if attr in ["L", "W", "A"]:
                setattr(self, attr, 1.)
                setattr(self, attr, self.Q() / self.Q_lmtd())
                # return getattr(self, attr)
            else:
                super(HxUnitBasicPlanar, self).sizeUnits()
        except:
            raise StopIteration(
                "HxUnitBasicPlanar.size(): failed to converge".format())
    
    @property
    def A(self):
        """float: A = L * W.
        Setter preserves the ratio of L/W."""
        return self.L * self.W

    @A.setter
    def A(self, value):
        cdef double a = 0
        if self.L and self.W:
            a = self.L * self.W
            self.L *= (value / a)**0.5
            self.W *= (value / a)**0.5
        else:
            pass
