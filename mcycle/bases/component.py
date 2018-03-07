from abc import abstractmethod
from ..DEFAULTS import MAXITERATIONSCOMPONENT, RSTHEADINGS, PRINTFORMATFLOAT, getUnits
from .mcabstractbase import MCAbstractBase as MCAB
from .flowstate import FlowState
from .config import Config


class Component(MCAB):
    """Basic component with incoming and outgoing flows. The first flow in and out (index=0) should be allocated to the working fluid.

Parameters
----------
flowsIn : list of FlowState
    Incoming FlowStates. Defaults to None.
flowsOut : list of FlowState, optional
    Outgoing FlowStates. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to None.
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to None.

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "Component instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    @abstractmethod
    def __init__(self,
                 flowsIn,
                 flowsOut=[None],
                 solveAttr=None,
                 solveBracket=None,
                 name="Component instance",
                 notes="no notes",
                 config=Config(),
                 **kwargs):
        self.flowsIn = flowsIn
        self.flowsOut = flowsOut
        self.solveAttr = solveAttr
        self.solveBracket = solveBracket
        self.name = name
        self.notes = notes
        self.config = config
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    @abstractmethod
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("flowsIn", "none"), ("flowsOut", "none"),
                ("solveAttr", "none"), ("solveBracket", "none"),
                ("name", "none"), ("notes", "none"), ("config", "none"))

    @property
    @abstractmethod
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("mWf", "mass/time")]

    def copy(self, **kwargs):
        """Creates a new copy of an instance. Kwargs are passed to update() for  a shortcut of simultaneously copying and updating."""
        copy = self.__class__(*self._inputValues)
        copy.update(**kwargs)
        return copy

    def update(self, **kwargs):
        """Update (multiple) Component variables using keyword arguments."""
        for key, value in kwargs.items():
            if "__" in key:
                key_split = key.split("__", 1)
                key_attr = getattr(self, key_split[0])
                key_attr.update(**{key_split[1]: value})
            else:
                setattr(self, key, value)

    @abstractmethod
    def run(self):
        """Compute the outgoing working fluid FlowState from component attributes."""
        pass

    def solve(self, solveAttr=None, solveBracket=None):
        """Solve for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
solveAttr : string, optional
    Attribute to be solved. If None, self.solveAttr is used. Defaults to None.
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). If None, self.solveBracket is used. Defaults to None.

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
        """

        try:
            import scipy.optimize as opt
            if solveAttr is None:
                solveAttr = self.solveAttr
            if solveBracket is None:
                solveBracket = self.solveBracket
            flowOutTarget = self.flowOut.copy()

            def f(value):
                self.update(**{solveAttr: value})
                self.run()
                return getattr(self.flowOut, self.config.tolAttr) - getattr(
                    flowOutTarget, self.config.tolAttr)

            tol = self.config.tolAbs + self.config.tolRel * getattr(
                flowOutTarget, self.config.tolAttr)
            if len(solveBracket) == 2:
                solvedValue = opt.brentq(
                    f,
                    solveBracket[0],
                    solveBracket[1],
                    rtol=self.config.tolRel,
                    xtol=self.config.tolAbs,
                    maxiter=MAXITERATIONSCOMPONENT)
            elif len(solveBracket) == 1:
                solvedValue = opt.newton(
                    f,
                    solveBracket[0],
                    tol=tol,
                    maxiter=MAXITERATIONSCOMPONENT)
            else:
                solvedValue = opt.newton(
                    f, solveBracket, tol=tol, maxiter=MAXITERATIONSCOMPONENT)
            setattr(self, solveAttr, solvedValue)
            self.update(flowOut=flowOutTarget)
        except:
            raise StopIteration("{}.solve({},{}) failed to converge".format(
                self.__class__.__name__, solveAttr, solveBracket))

    def summary(self,
                printSummary=True,
                propertyKeys="all",
                flowKeys="none",
                name=None,
                rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Keys of component properties to be included. The following strings are also accepted as inputs:

  - "all": all properties in _properties are included,
  - "none": no properties are included.

    Defaults to "all".
flowKeys : list, optional
    Keys of component flows to be included. The following strings are also accepted as inputs:

  - "all": all flows are included,
  - "none": no flows are included.

    Defaults to "none".
name : str, optional
    Name of instance used in summary heading. If None, the name property of the instance is used. Defaults to None.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RSTHEADINGS. Defaults to 0.
        """
        if name is None:
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
Notes: {}
""".format(RSTHEADINGS[rstHeading] * len(output), self.notes)

        hasSummaryList = []
        for i in self._inputs:
            if i[0] in [
                    "flowsIn", "flowsOut", "flowIn", "flowOut", "flowInWf",
                    "flowOutWf", "flowInSf", "flowOutSf"
            ]:
                pass
            elif i[0] in ["solveAttr", "solveBracket", "solveBracketUnits"]:
                pass
            elif i[0] in ["name", "notes", "config"]:
                pass
            else:
                output += self.formatAttrUnitsForSummary(i, hasSummaryList)
        #
        for i in hasSummaryList:
            obj = getattr(self, i)
            output += """
""" + obj.summary(
                printSummary=False, name=i, rstHeading=rstHeading + 1)
        #
        if propertyKeys == "all":
            propertyKeys = self._propertyKeys
        if propertyKeys == "none":
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """#
"""
            for i in propertyKeys:
                if i in self._propertyKeys:
                    j = self._propertyKeys.index(i)
                    output += self.formatAttrUnitsForSummary(
                        self._properties[j])
                else:
                    output += i + """: property not found,
"""
        if flowKeys == "all":
            flowKeys = []
            for i in range(len(self.flowsIn)):
                if i == 0:
                    flows.append("flowInWf")
                elif i == 1:
                    flows.append("flowInSf")
                else:
                    flows.append("flowsIn[{}]".format(i))
            for i in range(len(self.flowsOut)):
                if i == 0:
                    flows.append("flowOutWf")
                elif i == 1:
                    flows.append("flowOutSf")
                else:
                    flows.append("flowsOut[{}]".format(i))
        if flowKeys == "none":
            flowKeys = []
        if len(flowKeys) > 0:
            for key in flowKeys:
                try:
                    if "[" in key:
                        keyList, keyId = key.replace("]", "").split("[")
                        flowObj = getattr(self, keyList)[int(keyId)]
                    else:
                        flowObj = getattr(self, key)
                    output += """
{}""".format(
                        flowObj.summary(
                            name=key,
                            printSummary=False,
                            rstHeading=rstHeading + 1))
                except AttributeError:
                    output += """
{}: flow not found""".format(key)
                except:
                    output += """{}: {}
""".format(key, "Error returning summary")
        else:
            pass
        if printSummary:
            print(output)
        return output

    @property
    def flowInWf(self):
        """Alias for self.flowsIn[0]"""
        return self.flowsIn[0]

    @flowInWf.setter
    def flowInWf(self, obj):
        self.flowsIn[0] = obj

    @property
    def flowOutWf(self):
        """Alias for self.flowsOut[0]"""
        return self.flowsOut[0]

    @flowOutWf.setter
    def flowOutWf(self, obj):
        self.flowsOut[0] = obj

    @property
    def mWf(self):
        """Alias for self.flowsIn[0].m"""
        return self.flowsIn[0].m

    @mWf.setter
    def mWf(self, value):
        for flow in [self.flowInWf, self.flowOutWf]:
            if flow is not None:
                flow.m = value


class Component11(Component):
    """Component with 1 incoming and 1 outgoing flow of the working fluid.

Parameters
----------
flowIn : FlowState
    Incoming FlowState.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to None.
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to None.

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "Component instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    @abstractmethod
    def __init__(self,
                 flowIn,
                 flowOut=None,
                 solveAttr=None,
                 solveBracket=None,
                 name="Component11 instance",
                 notes="no notes",
                 config=Config(),
                 **kwargs):
        if flowOut is not None and flowIn is not None:
            assert flowOut.m == flowIn.m, "mass flow rate of flowIn and flowOut must be equal"
        super().__init__([flowIn], [flowOut], solveAttr, solveBracket, name,
                         notes, config)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    @abstractmethod
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor."""
        return (("flowIn", "none"), ("flowOut", "none"), ("solveAttr", "none"),
                ("solveBracket", "none"), ("name", "none"), ("notes", "none"),
                ("config", "none"))

    @property
    @abstractmethod
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("m", "mass/time")]

    @property
    def flowIn(self):
        """Alias for self.flowsIn[0]"""
        return self.flowsIn[0]

    @flowIn.setter
    def flowIn(self, obj):
        self.flowsIn[0] = obj

    @property
    def flowOut(self):
        """Alias for self.flowsOut[0]"""
        return self.flowsOut[0]

    @flowOut.setter
    def flowOut(self, obj):
        self.flowsOut[0] = obj

    @property
    def m(self):
        """Alias for self.flowsIn[0].m"""
        return self.flowsIn[0].m

    @m.setter
    def m(self, value):
        for flow in [self.flowIn, self.flowOut]:
            if flow is not None:
                flow.m = value

    def hasInAndOut(self):
        """Returns True if inlet and outlet flows have been defined; ie. are not None."""
        if type(self.flowIn) is FlowState and type(self.flowOut) is FlowState:
            return True
        else:
            return False


class Component22(Component):
    """Component with 2 incoming and 2 outgoing flows of the working fluid and a secondary fluid.

Parameters
----------
flowInWf : FlowState
    Incoming FlowState of the working fluid.
flowInSf : FlowState
    Incoming FlowState of the secondary fluid.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
solveAttr : string, optional
    Default attribute used by solve(). Defaults to None.
solveBracket : float or list of float, optional
    Bracket containing solution of solve(). Defaults to None.

    - if solveBracket=[a,b]: scipy.optimize.brentq is used.

    - if solveBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "Component instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    @abstractmethod
    def __init__(self,
                 flowInWf,
                 flowInSf,
                 flowOutWf=None,
                 flowOutSf=None,
                 solveAttr=None,
                 solveBracket=None,
                 name="Component22 instance",
                 notes="no notes",
                 config=Config(),
                 **kwargs):
        flows = [[flowInWf, flowOutWf], [flowInSf, flowOutSf]]
        for i in range(2):
            if flows[i][0] is not None and flows[i][1] is not None:
                assert flows[i][0].m == flows[i][
                    1].m, "mass flow rate of flowIn{0} and flowOut{0} must be equal".format(
                        i)
        super().__init__([flowInWf, flowInSf], [flowOutWf, flowOutSf],
                         solveAttr, solveBracket, name, notes, config)

        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    @abstractmethod
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor"""
        return (("flowInWf", "none"), ("flowInSf", "none"), (
            "flowOutWf", "none"), ("flowOutSf", "none"), ("solveAttr", "none"),
                ("solveBracket", "none"), ("name", "none"), ("notes", "none"),
                ("config", "none"))

    @property
    @abstractmethod
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("m", "mass/time")]

    @property
    def flowInSf(self):
        """Alias for self.flowsIn[1]"""
        return self.flowsIn[1]

    @flowInSf.setter
    def flowInSf(self, obj):
        self.flowsIn[1] = obj

    @property
    def flowOutSf(self):
        """Alias for self.flowsOut[1]"""
        return self.flowsOut[1]

    @flowOutSf.setter
    def flowOutSf(self, obj):
        self.flowsOut[1] = obj

    @property
    def mSf(self):
        """Alias for self.flowsIn[1].m"""
        return self.flowsIn[1].m

    @mSf.setter
    def mSf(self, value):
        for flow in [self.flowInSf, self.flowOutSf]:
            if flow is not None:
                flow.m = value

    def hasInAndOut(self, flow="Wf"):
        """Returns True if inlet and outlet flows have been defined; ie. are not None."""
        if flow == 0 or flow.lower() == "wf":
            if type(self.flowInWf) is FlowState and type(
                    self.flowOutWf) is FlowState:
                return True
            else:
                return False
        elif flow == 1 or flow.lower() == "sf":
            if type(self.flowInSf) is FlowState and type(
                    self.flowOutSf) is FlowState:
                return True
            else:
                return False
        else:
            return False
