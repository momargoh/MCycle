from .methods import Methods
from .. import DEFAULTS as DEFS


class Config:
    """General configuration parameters containing parameters pertaining to Cycles and Components. It is recommended to pass the same Config object to all Components in a Cycle.

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
solveBracket_L : list of float len==2, optional
    Bracket for solving lengths (particularly of HxUnits). Defaults to [1e-5, 1e2].
maxIterCycle : int, optional
    Max number of iterations for convergence of cycle. Defaults to 50.
maxWalls : int, optional
    Max number of walls a solution may have. Defaults to 200.
methods : Methods, optional
    Methods object, describing any methods to be used. Defaults to default Methds object.
evenPlatesWf : bool, optional
    If there are an even number of plates in a plate heat exchanger, an extra working fluid channel is created rather than an extra secondary fluid channel. Defaults to False.

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
                 dpEvap=False,
                 dpCond=False,
                 dpFWf=True,
                 dpFSf=True,
                 dpAccWf=True,
                 dpAccSf=True,
                 dpHeadWf=True,
                 dpHeadSf=True,
                 dpPortWf=True,
                 dpPortSf=True,
                 g=DEFS.GRAVITY,
                 tolAttr="h",
                 tolAbs=DEFS.TOLABS,
                 tolRel=DEFS.TOLREL,
                 divT=5.,
                 divX=0.1,
                 solveBracket_L=[1e-5, 1e2],
                 methods=Methods(),
                 evenPlatesWf=False,
                 **kwargs):
        self.dpEvap = dpEvap
        self.dpCond = dpCond
        self.dpFWf = dpFWf
        self.dpFSf = dpFSf
        self.dpAccWf = dpAccWf
        self.dpAccSf = dpAccSf
        self.dpHeadWf = dpHeadWf
        self.dpHeadSf = dpHeadSf
        self.dpPortWf = dpPortWf
        self.dpPortSf = dpPortSf
        self.g = g
        self.tolAttr = tolAttr
        self.tolAbs = tolAbs
        self.tolRel = tolRel
        self.divT = divT
        assert divX <= 1
        self.divX = divX
        self.solveBracket_L = solveBracket_L
        #
        self.methods = methods
        #
        self.evenPlatesWf = evenPlatesWf
        #
        self._tolRel_p = DEFS.TOLREL
        self._tolRel_T = DEFS.TOLREL
        self._tolRel_h = DEFS.TOLREL
        self._tolRel_rho = DEFS.TOLREL
        self._tolAbs_x = DEFS.TOLABS_X
        #
        for key, value in kwargs.items():
            setattr(self, key, value)

    def update(self, **kwargs):
        """Update (multiple) Cycle variables using keyword arguments."""
        for key, value in kwargs.items():
            setattr(self, key, value)

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
            print("dpPortWf is {0}, dpPortSf is {1}".format(
                self.dpPortWf, self.dpPortSf))

    @dpPort.setter
    def dpPort(self, value):
        assert type(value) is bool, "Attribute must be True or False"
        self.dpPortWf = value
        self.dpPortSf = value

    def summary(self, printOutput=True):
        """Prints and returns a summary of useful properties.

Parameters
-----------
printOutput : bool, optional
    If true, the summary string is printed as well as returned, otherwise it is only returned. Defaults to True.
name : str, optional
    Name of the Flowstate, prepended to the summary heading. Defaults to "".
        """
        output = r"Config object properties"
        output += """
{}
    dpEvap = {},
    dpCond = {},
    dpFWf = {},
    dpFSf = {},
    dpAccWf = {},
    dpAccSf = {},
    dpHeadWf = {},
    dpHeadSf = {},
    dpPortWf = {},
    dpPortSf = {},
    g = {},
    tolAttr = {},
    tolAbs = {},
    tolRel = {},
    divT = {},
    divX = {},
    solveBracket_L = {},
    #
    evenPlatesWf = {},
    #
    _tolRel_p = {},
    _tolRel_T = {},
    _tolRel_h = {},
    _tolRel_rho = {},
    _tolAbs_x = {}

    """.format('-' * len(output), self.dpEvap, self.dpCond, self.dpFWf,
               self.dpFSf, self.dpAccWf, self.dpAccSf, self.dpHeadWf,
               self.dpHeadSf, self.dpPortWf, self.dpPortSf, self.g,
               self.tolAttr, self.tolAbs, self.tolRel, self.divT, self.divX,
               self.solveBracket_L, self.evenPlatesWf, self._tolRel_p,
               self._tolRel_T, self._tolRel_h, self._tolRel_rho,
               self._tolAbs_x)
        if printOutput:
            print(output)
        return output
