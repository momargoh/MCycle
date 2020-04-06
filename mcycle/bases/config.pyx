from .abc cimport ABC
from .. import defaults
from .._constants cimport *
from ..logger import log
import copy
from math import nan, isnan


cdef tuple _inputs = ('dpEvap', 'dpCond', 'evenPlatesWf', 'dpFWf', 'dpFSf', 'dpAccWf', 'dpAccSf', 'dpHeadWf', 'dpHeadSf', 'dpPortWf', 'dpPortSf', 'dpPortInFactor', 'dpPortOutFactor', 'g', 'tolAttr', 'tolAbs', 'tolRel', 'divT', 'divX', 'methods', 'name')
cdef tuple _properties = ('_tolRel_p', '_tolRel_T', '_tolRel_h', '_tolRel_rho')
        
cdef class Config(ABC):
    """General configuration parameters containing parameters pertaining to Cycles and Components. Many attributes have a corresponding default value set in :doc:`defaults </defaults>` 

Attributes
-----------
dpEvap : bool, optional
    Evaluate pressure drop of working fluid in evaporator. Defaults to False.
dpCond : bool, optional
    Evaluate pressure drop of working fluid in condenser. Defaults to False.
evenPlatesWf : bool, optional
    If there are an even number of plates in a plate heat exchanger, an extra working fluid channel is created rather than an extra secondary fluid channel. Defaults to False.
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
gravity : float, optional
    Acceleration due to gravity [m/s^2]. Defaults to 9.81.
maxWalls : int, optional
    Max number of walls a solution may have. Defaults to 200.
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
maxIterCycle : int, optional
    Max number of iterations for convergence of cycle methods. Defaults to 50.
maxIterComponent : int, optional
    Max number of iterations for convergence of component methods. Defaults to 50.
methods : dict, optional
    Dictionary that stores all information about selection of computational methods.
name : string, optional
    Description of Config object. Defaults to "Config instance".

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
"""

    def __cinit__(self,
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
                 bint dpPortSf=True,
                 double dpPortInFactor=nan,
                 double dpPortOutFactor=nan,
                 unsigned short maxWalls = 0,
                 double gravity=nan,
                 str tolAttr='',
                 double tolAbs=nan,
                 double tolRel=nan,
                 double divT=nan,
                 double divX=nan,
                 unsigned short maxIterComponent=0,
                 unsigned short maxIterCycle=0,
                 dict methods={},
                 str name="Config instance"):
        super().__init__(_inputs, _properties, name)
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
            dpPortInFactor = defaults.DP_PORT_IN_FACTOR
        self.dpPortInFactor = dpPortInFactor
        if isnan(dpPortInFactor):
            dpPortOutFactor = defaults.DP_PORT_OUT_FACTOR
        self.dpPortOutFactor = dpPortOutFactor
        if maxWalls == 0:
            maxWalls = defaults.MAX_WALLS
        self.maxWalls = maxWalls
        # general config parameters
        if isnan(gravity):
            gravity = defaults.GRAVITY
        self.gravity = gravity
        # tolerances
        if tolAttr == '':
            tolAttr = defaults.TOLATTR
        self.tolAttr = tolAttr
        if isnan(tolAbs):
            tolAbs = defaults.TOLABS
        self.tolAbs = tolAbs
        if isnan(tolRel):
            tolRel = defaults.TOLREL
        self.tolRel = tolRel
        if isnan(divT):
            divT = defaults.DIV_T
        self.divT = divT
        if isnan(divX):
            divX = defaults.DIV_X
        assert divX <= 1
        self.divX = divX
        #iteration
        if maxIterComponent == 0:
            maxIterComponent = defaults.MAXITER_COMPONENT
        self.maxIterComponent = maxIterComponent
        if maxIterCycle == 0:
            maxIterCycle = defaults.MAXITER_CYCLE
        self.maxIterCycle = maxIterCycle
        # methods
        if methods == {}:
            methods = copy.deepcopy(defaults.METHODS)
        self.methods = methods
        #
        self._tolRel_p = tolRel
        self._tolRel_T = tolRel
        self._tolRel_h = tolRel
        self._tolRel_rho = tolRel

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

    
    def summary(self, bint printSummary=True, str title="", int rstHeading=0):
        """Returns (and prints) a summary of FlowState properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
title : str, optional
    Title used in summary heading. If '', the :meth:`name <mcycle.abc.ABC.name>` property of the instance is used. Defaults to ''.
        """
        cdef str output
        if title == "":
            title = self.name
        output = r"{} summary".format(title)
        output += """
{}
""".format(defaults.RST_HEADINGS[rstHeading] * len(output))
        for k, v in self._inputs:
            output += """{} = {}
""".format(k, getattr(self, k))
        if printSummary:
            print(output)
        return output

    
    cpdef public str lookupMethod(self, str cls, tuple args):
        """str: Return name of method based on the given class and args.

Parameters
------------
cls : str
    Name of class requiring the method.
args : tuple
    Additional arguments in tuple.

    - HxPlate or HxUnitPlate: args must be in the form (geom, transfer, phase, flow).

        """
        cdef tuple listGeom
        cdef str geom, lookup_dict
        cdef str ret = ''
        cdef unsigned char transfer, flow, unitPhase, unitPhaseOrig
        try:
            if cls in ["HxPlate","HxUnitPlate", "HxPlateCorrugated", "HxPlateFin"]:
                """args must be in the form (geom, transfer, phase, flow)."""
                if len(args) == 4:
                    geom, transfer, unitPhase, flow = args
                else:
                    msg = 'lookup(): Class {} requires 4 args in the order: (geom, transfer, unitPhase, flow), (given: {} args)'.format(cls, len(args))
                    log('error', msg)
                    raise IndexError(msg)

                listGeom = ("GeomHxPlateCorrugatedChevron", "GeomHxPlateFinStraight",
                                   "GeomHxPlateFinOffset", "GeomHxPlateSmooth")
                if geom not in listGeom:
                    msg = "'geom' arg must be in {}, (given: {})".format(listGeom, geom)
                    log('error', msg)
                    raise NotImplementedError(msg)
                unitPhaseOrig = unitPhase
                if flow == WORKING_FLUID or flow == SECONDARY_FLUID:
                    
                    try:
                        ret = self.methods[geom][transfer][flow][unitPhase]
                    except:
                        if unitPhase in [UNITPHASE_TWOPHASE_CONDENSING, UNITPHASE_TWOPHASE_EVAPORATING]:
                            unitPhase = UNITPHASE_ALL_TWOPHASE
                        else:
                            unitPhase = UNITPHASE_ALL_SINGLEPHASE
                        try:
                            ret = self.methods[geom][transfer][flow][unitPhase]
                        except:
                            try:
                                ret = self.methods[geom][transfer][flow][UNITPHASE_ALL]
                            except:
                                pass
                if ret == '': #flow not WORKING_FLUID or SECONDARY_FLUID or all trys above failed
                    unitPhase = unitPhaseOrig
                    try:
                        ret = self.methods[geom][transfer][unitPhase]
                    except:
                        if unitPhase in [UNITPHASE_TWOPHASE_CONDENSING, UNITPHASE_TWOPHASE_EVAPORATING]:
                            unitPhase = UNITPHASE_ALL_TWOPHASE
                        else:
                            unitPhase = UNITPHASE_ALL_SINGLEPHASE
                        try:
                            ret = self.methods[geom][transfer][unitPhase]
                        except:
                            try:
                                ret = self.methods[geom][transfer][UNITPHASE_ALL]
                            except:
                                msg = "lookupMethod(): Could not find method for geom:{}, transfer:{}, phase:{}, searched fallbacks.".format(geom, transfer, unitPhaseOrig)
                                log('error', msg)
                                raise KeyError(msg)
                return ret
            if cls in ["HxBasic","HxBasicPlanar"]:
                return None
            else:
                msg = "lookupMethod(): methods for {} class are not yet defined. Consider raising an issue at {}".format(cls, SOURCE_URL)
                log('error', msg)
                raise NotImplementedError(msg)
        except:
            raise
            
    cpdef void set_method(self, str method, str geom, unsigned char transfer, unsigned char unitPhase, unsigned char flow) except *:
        """Set the method for a single geometry, given the transfer type, unitphase and flow.

Parameters
-----------
method : str
    String of method/function name.
geom : str
    Geometry that method should be set for.
transfers : str
    Transfer type to be set for, see :doc:`constants </constants>`.
phases : str
    Unitphase to be set for, see :doc:`constants </constants>`.
flows : str
    Flow to be set for, see :doc:`constants </constants>`.
        """
        cdef unsigned char UP
        cdef list flows
        if transfer == TRANSFER_ALL:
            self.set_method(method, geom, TRANSFER_HEAT, unitPhase, flow)
            self.set_method(method, geom, TRANSFER_FRICTION, unitPhase, flow)
        else:
            if flow == FLOW_ALL:
                flows = [WORKING_FLUID, SECONDARY_FLUID]
            else:
                flows = [flow]
            for fl in flows: #remove equivalent unitphases
                if fl in self.methods[geom][transfer]:
                    if unitPhase == UNITPHASE_ALL:
                        for UP in [UNITPHASE_LIQUID, UNITPHASE_VAPOUR, UNITPHASE_SUPERCRITICAL, UNITPHASE_TWOPHASE_EVAPORATING, UNITPHASE_TWOPHASE_CONDENSING]:
                            self.methods[geom][transfer][fl].pop(UP, None)
                    if unitPhase == UNITPHASE_ALL_SINGLEPHASE:
                        for UP in [UNITPHASE_LIQUID, UNITPHASE_VAPOUR, UNITPHASE_SUPERCRITICAL]:
                            self.methods[geom][transfer][fl].pop(UP, None)
                    if unitPhase == UNITPHASE_ALL_TWOPHASE:
                        for UP in [UNITPHASE_TWOPHASE_EVAPORATING, UNITPHASE_TWOPHASE_CONDENSING]:
                            self.methods[geom][transfer][fl].pop(UP, None)
                    if self.methods[geom][transfer][fl] == {}: # remove entire flow dict if empty
                        self.methods[geom][transfer].pop(fl, None)
                else:
                    continue
            if flow == FLOW_ALL:
                self.methods[geom][transfer][unitPhase] = method
            else:
                self.methods[geom][transfer].setdefault(flow, {})
                self.methods[geom][transfer][flow][unitPhase] = method

