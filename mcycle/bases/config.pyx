from .mcabstractbase cimport MCAB, MCAttr
from .. import DEFAULTS
import copy
from math import nan, isnan


cdef dict _inputs = {"dpEvap": MCAttr(bool, "none"), "dpCond": MCAttr(bool, "none"), "evenPlatesWf": MCAttr(bool,"none"), "dpFWf": MCAttr(bool,"none"),
               "dpFSf": MCAttr(bool, "none"), "dpAccWf": MCAttr(bool,"none"), "dpAccSf": MCAttr(bool,"none"), "dpHeadWf": MCAttr(bool,"none"),
               "dpHeadSf": MCAttr(bool,"none"), "dpPortWf": MCAttr(bool,"none"), "dpPortSf": MCAttr(bool,"none"), "dpPortInFactor": MCAttr(float,"none"), "dpPortOutFactor": MCAttr(float,"none"), "g": MCAttr(float,"acceleration"),
               "tolAttr": MCAttr(float,"none"), "tolAbs": MCAttr(float,"none"), "tolRel": MCAttr(float,"none"), "divT": MCAttr(float,"temperatures"), "divX": MCAttr(float,"none"), "methods": MCAttr(dict, "none"),
                        "name": MCAttr(str, "none")}
cdef dict _properties = {"_tolRel_p": MCAttr(float,"none"),
               "_tolRel_T": MCAttr(float,"none"), "_tolRel_h": MCAttr(float,"none"), "_tolRel_rho": MCAttr(float, "none")}
        
cdef class Config(MCAB):
    """General configuration parameters containing parameters pertaining to Cycles and Components.

Attributes
-----------
dpEvap : bool, optional
    Evaluate pressure drop of working fluid in evaporator. Defaults to False.
dpCond : bool, optional
    Evaluate pressure drop of working fluid in condenser. Defaults to False.
dpFWf : bool, optional
    Evaluate frictional pressure drops of working fluid. Defaults to True.
dpFSf : bool, optional
    Evaluate frictional pressure drops of secondary fluid. Defaults to True.
dpAccWf : bool, optional
    Evaluate acceleration pressure drops of working fluid. Defaults to True.
dpAccSf : bool, optional
    Evaluate acceleration pressure drops of secondary fluid. Defaults to True.
dpHeadWf : bool, optional
    Evaluate static head drops of working fluid. Defaults to True.
dpHeadSf : bool, optional
    Evaluate static head drops of secondary fluid. Defaults to True.
dpPortWf : bool, optional
    Evaluate port pressure loss of working fluid. Defaults to True.
dpPortSf : bool, optional
    Evaluate port pressure loss of secondary fluid. Defaults to True.
g : float, optional
    Acceleration due to gravity [m/s^2]. Defaults to 9.81.
tolAttr : string, optional
    FlowState attribute for cycle convergence. Defaults to "h".
tolAbs : float, optional
    Absolute tolerance for determining cycle convergence. Defaults to 1e-9.
tolRel : float, optional
    Relative tolerance for determining cycle convergence. Defaults to 1e-7.
divT : float, optional
    Temperature difference for unitising single-phase flows. Defaults to 5 [K].
divX : float, optional
    Quality difference for unitising two-phase flows. Defaults to 0.1.
sizeBounds_L : list of float len==2, optional
    Bracket for solving lengths (particularly of HxUnits). Defaults to [1e-5, 1e2].
maxIterCycle : int, optional
    Max number of iterations for convergence of cycle. Defaults to 50.
maxWalls : int, optional
    Max number of walls a solution may have. Defaults to 200.
evenPlatesWf : bool, optional
    If there are an even number of plates in a plate heat exchanger, an extra working fluid channel is created rather than an extra secondary fluid channel. Defaults to False.
methods : dict, optional
    Dictionary that stores all information about selection of computational methods.

Private Attributes
------------------
_tolRel_p : float, optional
    Relative tolerance used in assert statements for determining equivalence of pressures. Defaults to 1e-7.
_tolRel_T : float, optional
    Relative tolerance used in assert statements for determining equivalence of temperatures. Defaults to 1e-7.
_tolRel_h : float, optional
    Relative tolerance used in assert statements for determining equivalence of specific enthalpies. Defaults to 1e-7.
_tolRel_rho : float, optional
    Relative tolerance used in assert statements for determining equivalence of densities. Defaults to 1e-7.
_tolAbs_x : float, optional
    Absolute tolerance used for determining whether a FlowState is in the two-phase region. Defaults to mcycle.DEFAULTS.TOLABS_X
"""

    def __init__(self,
                 bint dpEvap=False,
                 bint dpCond=False,
                 bint evenPlatesWf=False,
                 bint dpFWf=True,
                 bint dpFSf=True,
                 bint dpAccWf=True,
                 bint dpAccSf=True,
                 bint dpHeadWf=True,
                 bint dpHeadSf=True,
                 bint dpPortWf=True,
                 bint dpPortSf=None,
                 double dpPortInFactor=nan,
                 double dpPortOutFactor=nan,
                 unsigned short maxWalls = 200,
                 double gravity=nan,
                 str tolAttr='',
                 double tolAbs=nan,
                 double tolRel=nan,
                 double divT=DEFAULTS.DIV_T,
                 double divX=DEFAULTS.DIV_X,
                 unsigned short maxIterComponent=0,
                 unsigned short maxIterCycle=0,
                 dict methods=DEFAULTS.METHODS,
                 str name="Config instance"):
        # Cycle config parameters
        self.dpEvap = dpEvap
        self.dpCond = dpCond
        # HxPlate config parameters
        self.evenPlatesWf = evenPlatesWf
        self.dpFWf = dpFWf
        self.dpFSf = dpFSf
        self.dpAccWf = dpAccWf
        self.dpAccSf = dpAccSf
        self.dpHeadWf = dpHeadWf
        self.dpHeadSf = dpHeadSf
        self.dpPortWf = dpPortWf
        self.dpPortSf = dpPortSf
        if isnan(dpPortInFactor):
            dpPortInFactor = DEFAULTS.DP_PORT_IN_FACTOR
        self.dpPortInFactor = dpPortInFactor
        if isnan(dpPortInFactor):
            dpPortOutFactor = DEFAULTS.DP_PORT_OUT_FACTOR
        self.dpPortOutFactor = dpPortOutFactor
        if maxWalls == 0:
            maxWalls = DEFAULTS.MAX_WALLS
        self.maxWalls = maxWalls
        # general config parameters
        if isnan(gravity):
            gravity = DEFAULTS.GRAVITY
        self.gravity = gravity
        # tolerances
        if tolAttr == '':
            tolAttr = DEFAULTS.TOLATTR
        self.tolAttr = tolAttr
        if isnan(tolAbs):
            tolAbs = DEFAULTS.TOLABS
        self.tolAbs = tolAbs
        if isnan(tolRel):
            tolRel = DEFAULTS.TOLREL
        self.tolRel = tolRel
        self.divT = divT
        assert divX <= 1
        self.divX = divX
        #iteration
        if maxIterComponent == 0:
            maxIterComponent = DEFAULTS.MAXITER_COMPONENT
        self.maxIterComponent = maxIterComponent
        if maxIterCycle == 0:
            maxIterCycle = DEFAULTS.MAXITER_CYCLE
        self.maxIterCycle = maxIterCycle
        # methods
        self.methods = copy.deepcopy(methods)
        #
        self._tolRel_p = tolRel
        self._tolRel_T = tolRel
        self._tolRel_h = tolRel
        self._tolRel_rho = tolRel
        self.name = name
        self._inputs = _inputs
        self._properties = _properties

    @property
    def dpF(self):
        """Returns True if dpFWf and dpFSf are True, else prints their values. Setter sets both to True or False."""
        if self.dpFWf and self.dpFSf:
            return True
        else:
            print("dpFWf is {0}, dpFSf is {1}".format(self.dpFWf, self.dpFSf))

    @dpF.setter
    def dpF(self, value):
        assert type(value) is bool, "Attribute must be True or False"
        self.dpFWf = value
        self.dpFWf = value

    @property
    def dpAcc(self):
        """Returns True if dpAccWf and dpAccSf are True, else prints their values. Setter sets both to True or False."""
        if self.dpAccWf and self.dpAccSf:
            return True
        else:
            print("dpAccWf is {0}, dpAccSf is {1}".format(
                self.dpAccWf, self.dpAccSf))

    @dpAcc.setter
    def dpAcc(self, value):
        assert type(value) is bool, "Attribute must be True or False"
        self.dpAccWf = value
        self.dpAccSf = value

    @property
    def dpHead(self):
        """Returns True if dpHeadWf and dpHeadSf are True, else prints their values. Setter sets both to True or False."""
        if self.dpHeadWf and self.dpHeadSf:
            return True
        else:
            print("dpHeadWf is {0}, dpHeadSf is {1}".format(
                self.dpHeadWf, self.dpHeadSf))

    @dpHead.setter
    def dpHead(self, value):
        assert type(value) is bool, "Attribute must be True or False"
        self.dpHeadWf = value
        self.dpHeadSf = value

    @property
    def dpPort(self):
        """Returns True if dpPortWf and dpPortSf are True, else prints their values. Setter sets both to True or False."""
        if self.dpPortWf and self.dpPortSf:
            return True
        else:
            print("dpPortWf is {}, dpPortSf is {}".format(
                self.dpPortWf, self.dpPortSf))

    @dpPort.setter
    def dpPort(self, value):
        assert type(value) is bool, "Attribute must be True or False"
        self.dpPortWf = value
        self.dpPortSf = value

    
    def summary(self, bint printSummary=True, str name="", int rstHeading=0):
        """Returns (and prints) a summary of FlowState properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
name : str, optional
    Name of the object, prepended to the summary heading. If None, the class name is used. Defaults to None.
        """
        cdef str output
        if name == "":
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
""".format(DEFAULTS.RST_HEADINGS[rstHeading] * len(output))
        for k, v in self._inputs:
            output += self.formatAttrForSummary({k: v}, [])
        if printSummary:
            print(output)
        return output

    
    cpdef public str lookupMethod(self, str cls, tuple args):
        """str: Return name of method based on the given class and kwargs.

Parameters
------------
cls : str
    Class requiring the method. Can be a subclass of Component.
args : tuple
    Additional arguments in tuple.

    - HxPlate or HxUnitPlate: kwargs must be in the form (geom, transfer, phase, flow).

        """
        cdef tuple listKwargs, listGeomHxPlate, listTransfer, listPhase ,listFlows
        cdef str geom, transfer, flow, phase, lookup_dict, ret
        try:
            if cls in ["HxPlate","HxUnitPlate"]:
                """args must be in the form (geom, transfer, phase, flow)."""
                listKwargs = ("geom", "transfer", "phase", "flow")
                if len(args) == 4:
                    geom, transfer, phase, flow = args
                else:
                    raise IndexError(
                        "lookup() of {} requires 4 args in the order: {}, (given: {} args)".
                        format(cls, listKwargs, len(args)))

                listGeomHxPlate = ("GeomHxPlateCorrChevron",
                                   "GeomHxPlateFinOffset", "GeomHxPlateSmooth")
                listTransfer = ("heat", "friction")
                listPhase = ('sp', 'liq', 'vap', 'tpEvap', 'tpCond')
                listFlows = ("wf", "sf")
                assert geom in listGeomHxPlate, "'geom' arg must be in {}, ({} given)".format(
                    listGeomHxPlate, geom)
                assert flow.lower(
                ) in listFlows, "'flow' arg must be in {} ({} given)".format(
                    listFlows, flow)
                assert transfer.lower(
                ) in listTransfer, "'transfer' arg must be in {}, ({} given)".format(
                    listTransfer, transfer)
                if phase[0:2].lower() == "tp":
                    phase = "".join(phase[0:2].lower() + phase[2:].title())
                assert phase in listPhase, "'phase' arg must be in listPhase ({} given)".format(
                    listPhase, phase)
                lookup_dict = geom.strip(
                    "Geom") + transfer.title() + flow.title()
                ret = self.methods[lookup_dict][phase]
                if ret == '' or ret is None:
                    raise ValueError(
                        "Method for {} phase of {} not found (found dict: {})".format(
                            phase, lookup_dict, self.methods[lookup_dict]))
                else:
                    return ret
            else:
                raise ValueError("Methods for {} class are not yet defined. Consider raising an issue at {}".format(cls, DEFAULTS._GITHUB_SOURCE_URL))
        except:
            raise
            
    cpdef void set_method(self, str method, list geoms, list transfers, list phases, list flows):
        """Set a method to multiple geometries, transfer types, flows and phases.

Parameters
-----------
method : str
    String of method/function name.
geoms : list of str
    List of strings of geometry names that method should be set for.
transfers : list of str
    List of strings of transfer types to be set for. Must be "heat" and or "friction".
phases : list of str or str
    List of strings of phases to be set for. Must be from "sp", "liq", "vap", "tpEvap", "tpCond". The following string inputs are also accepted:

    - "all" : Equivalent to ["sp", "liq", "vap", "tpEvap", "tpCond"]
    - "all-sp" : Equivalent to ["sp", "liq", "vap"]
    - "all-tp" : Equivalent to ["tpEvap", "tpCond"]
flows : list of str
    List of strings of flows to be set for. Must be "wf" and or "sf".
        """
        cdef str geom, transfer, flow, phase, lookup_dict
        if transfers == ["all"]:
            transfers = ["heat", "friction"]
        if flows == ["all"]:
            flows = ["wf", "sf"]
        if phases == ["all"]:
            phases = ["sp", "liq", "vap", "tpEvap", "tpCond"]
        if phases == ["all-sp"]:
            phases = ["sp", "liq", "vap"]
        if phases == ["all-tp"]:
            phases = ["tpEvap", "tpCond"]

        for geom in geoms:
            geom = geom.strip("Geom")
            for transfer in transfers:
                for phase in phases:
                    for flow in flows:
                        lookup_dict = geom + transfer.title() + flow.title()
                        self.methods[lookup_dict][phase] = method


