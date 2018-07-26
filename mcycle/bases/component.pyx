from ..DEFAULTS cimport MAXITER_COMPONENT, RST_HEADINGS, PRINT_FORMAT_FLOAT, getUnits
from ..logger import log
from .mcabstractbase cimport MCAB, MCAttr
from .flowstate cimport FlowState
from .config cimport Config
from math import nan


cdef class Component(MCAB):
    """Basic component with incoming and outgoing flows. The first flow in and out (index=0) should be allocated to the working fluid.

Parameters
----------
flowsIn : list of FlowState
    Incoming FlowStates. Defaults to None.
flowsOut : list of FlowState, optional
    Outgoing FlowStates. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to None.
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to None.

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "Component instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    
    def __init__(self,
                 list flowsIn,
                 list flowsOut=[None],
                 FlowState ambient=None,
                 str sizeAttr='',
                 list sizeBracket=[],
                 list sizeUnitsBracket=[],
                 runBracket = [nan, nan],
                 str name='Component instance',
                 str notes='No notes/model info.',
                 Config config=Config()):
        self.flowsIn = flowsIn
        self.flowsOut = flowsOut
        self.ambient = ambient
        self.sizeAttr = sizeAttr
        self.sizeBracket = sizeBracket
        self.runBracket = runBracket
        self.sizeUnitsBracket = sizeUnitsBracket
        self.name = name
        self.notes = notes
        self.config = config
        self._inputs = {"flowsIn": MCAttr(list, "none"), "flowsOut": MCAttr(list, "none"), "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBracket": MCAttr(list, "none"), "sizeUnitsBracket": MCAttr(list, "none"), "runBracket": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
        self._properties = {"mWf": MCAttr(float, "mass/time")}
                
    cpdef public void run(self):
        """Compute the outgoing working fluid FlowState from component attributes."""
        pass

    cpdef double _f_sizeComponent(self, double value, FlowState flowOutTarget, str attr, list bracket, list unitsBracket):
        self.update({attr: value, 'sizeBracket': bracket, 'sizeUnitsBracket': unitsBracket})
        self.run()
        return getattr(self.flowsOut[0], self.config.tolAttr)() - getattr(flowOutTarget, self.config.tolAttr)()
    
    cpdef public void _size(self, str attr, list bracket, list unitsBracket) except *:
        """Solve for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used. Defaults to None.
bracket : float or list of float, optional
    Bracket containing solution of size(). If None, self.sizeBracket is used. Defaults to None.

    - if bracket=[a,b]: scipy.optimize.brentq is used.

    - if bracket=a or [a]: scipy.optimize.newton is used.
        """
        cdef double tol
        try:
            import scipy.optimize as opt
            if attr == '':
                attr = self.sizeAttr
            if bracket == []:
                bracket = self.sizeBracket
            if unitsBracket == []:
                unitsBracket = self.sizeUnitsBracket
            flowOutTarget = self.flowsOut[0]._copy({})

            tol = self.config.tolAbs + self.config.tolRel * getattr(flowOutTarget, self.config.tolAttr)()
            if len(bracket) == 2:
                sizedValue = opt.brentq(
                    self._f_sizeComponent,
                    bracket[0],
                    bracket[1],
                    args=(flowOutTarget, attr, bracket, unitsBracket),
                    rtol=self.config.tolRel,
                    xtol=self.config.tolAbs,
                    maxiter=MAXITER_COMPONENT)
            elif len(bracket) == 1:
                sizedValue = opt.newton(
                    self._f_sizeComponent,
                    bracket[0],
                    args=(flowOutTarget, attr, bracket, unitsBracket),
                    tol=tol,
                    maxiter=MAXITER_COMPONENT)
            else:
                raise ValueError("bracket is not valid (given: {})".format(bracket))
            self.update({attr: sizedValue, 'flowsOut[0]': flowOutTarget})
        except:
            raise StopIteration("{}.size({},{},{}) failed to converge.".format(
                self.__class__.__name__, attr, bracket, unitsBracket))

    cpdef public void sizeUnits(self, str attr, list bracket) except *:
        pass
    
    def size(self, str attr='', list bracket=[], list unitsBracket=[]):
        self._size(attr, bracket, unitsBracket)
        
    def summary(self,
                bint printSummary=True,
                propertyKeys='all',
                flowKeys='none',
                str name="",
                int rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list or str, optional
    Keys of component properties to be included. The following strings are also accepted as inputs:

  - 'all': all properties in _properties are included,
  - 'none': no properties are included.

    Defaults to 'all'.
flowKeys : list or str, optional
    Keys of component flows to be included. The following strings are also accepted as inputs:

  - 'all': all flows are included,
  - 'none': no flows are included.

    Defaults to 'none'.
name : str, optional
    Name of instance used in summary heading. If None, the name property of the instance is used. Defaults to None.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RSTHEADINGS. Defaults to 0.
        """
        if name == "":
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
Notes: {}
""".format(RST_HEADINGS[rstHeading] * len(output), self.notes)

        hasSummaryList = []
        for k, v in self._inputs.items():
            if k in [
                    "flowsIn", "flowsOut", "flowIn", "flowOut", "flowInWf",
                    "flowOutWf", "flowInSf", "flowOutSf"
            ]:
                pass
            elif k in ["sizeAttr", "sizeBracket", "sizeUnitsBracket", 'runBracket']:
                pass
            elif k in ["name", "notes", "config"]:
                pass
            else:
                output += self.formatAttrForSummary({k: v}, hasSummaryList)
        #
        for i in hasSummaryList:
            obj = getattr(self, i)
            output += """
""" + obj.summary(
                printSummary=False, name=i, rstHeading=rstHeading + 1)
        #
        if propertyKeys == 'all':
            propertyKeys = self._propertyKeys()
        if propertyKeys == 'none':
            propertyKeys = []
        if len(propertyKeys) > 0:
            outputProperties = r"{} properties".format(name)
            output += """
{}
{}
""".format(outputProperties, RST_HEADINGS[rstHeading+1] * len(outputProperties))
            
            for k in propertyKeys:
                if k in self._propertyKeys():
                    output += self.formatAttrForSummary({k: self._properties[k]}, [])
                else:
                    output += k + """: property not found,
"""
        if flowKeys == 'all':
            flowKeys = []
            for i in range(len(self.flowsIn)):
                if i == 0:
                    flowKeys.append("flowInWf")
                elif i == 1:
                    flowKeys.append("flowInSf")
                else:
                    flowKeys.append("flowsIn[{}]".format(i))
            for i in range(len(self.flowsOut)):
                if i == 0:
                    flowKeys.append("flowOutWf")
                elif i == 1:
                    flowKeys.append("flowOutSf")
                else:
                    flowKeys.append("flowsOut[{}]".format(i))
        if flowKeys == 'none':
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
                    added_output = r"""
{} summary""".format(key)
                    added_output += """
{}
flowstate not defined
""".format(RST_HEADINGS[rstHeading + 1] * len(added_output))
                    output += added_output
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

    cpdef public double _mWf(self):
        return self.flowsIn[0].m
    
    @property
    def mWf(self):
        """Alias for self.flowsIn[0].m"""
        return self.flowsIn[0].m

    @mWf.setter
    def mWf(self, value):
        for flow in [self.flowsIn[0], self.flowsOut[0]]:
            if flow is not None:
                flow.m = value
                
    cdef public bint hasInAndOut(self, int flowIndex):
        """Returns True if inlet and outlet flows have been defined; ie. are not None."""
        try:
            if type(self.flowsIn[flowIndex]) is FlowState and type(
                    self.flowsOut[flowIndex]) is FlowState:
                return True
            else:
                return False
        except:
            raise


cdef class Component11(Component):
    """Component with 1 incoming and 1 outgoing flow of the working fluid.

Parameters
----------
flowIn : FlowState
    Incoming FlowState.
flowOut : FlowState, optional
    Outgoing FlowState. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to None.
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to None.

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "Component instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    
    def __init__(self,
                 FlowState flowIn,
                 FlowState flowOut=None,
                 FlowState ambient=None,
                 str sizeAttr="",
                 list sizeBracket=[],
                 list sizeUnitsBracket=[],
                 runBracket = [nan, nan],
                 str name="Component11 instance",
                 str notes="No notes/model info.",
                 config=Config()):
        if flowOut is not None and flowIn is not None:
            assert flowOut.m == flowIn.m, "mass flow rate of flowIn and flowOut must be equal"
        super().__init__([flowIn], [flowOut], ambient, sizeAttr, sizeBracket, sizeUnitsBracket, runBracket, name, notes, config)
        self._inputs = {"flowIn": MCAttr(FlowState, "none"), "flowOut": MCAttr(FlowState, "none"), "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBracket": MCAttr(list, "none"), "sizeUnitsBracket": MCAttr(list, "none"), "runBracket": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
        self._properties = {"m": MCAttr(str, "mass/time")}

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
    def flowInSf(self):
        """Alias for self.flowsIn[1]"""
        log("warning", "flowInSf is not valid for {} (getter called)".format(self.__class__.__name__))
        return None

    @flowInSf.setter
    def flowInSf(self, obj):
        log("warning", "flowInSf is not valid for {} (setter called)".format(self.__class__.__name__))
        pass

    @property
    def flowOutSf(self):
        """Alias for self.flowsOut[1]"""
        log("warning", "flowOutSf is not valid for {} (getter called)".format(self.__class__.__name__))
        return None

    @flowOutSf.setter
    def flowOutSf(self, obj):
        log("warning", "flowOutSf is not valid for {} (setter called)".format(self.__class__.__name__))
        pass

    cpdef public double _m(self):
        return self.flowsIn[0].m
    
    @property
    def m(self):
        """Alias for self.flowsIn[0].m"""
        return self.flowsIn[0].m

    @m.setter
    def m(self, value):
        for flow in [self.flowIn, self.flowOut]:
            if flow is not None:
                flow.m = value


cdef class Component22(Component):
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
sizeAttr : string, optional
    Default attribute used by size(). Defaults to None.
sizeBracket : float or list of float, optional
    Bracket containing solution of size(). Defaults to None.

    - if sizeBracket=[a,b]: scipy.optimize.brentq is used.

    - if sizeBracket=a or [a]: scipy.optimize.newton is used.
name : string, optional
    Description of Component object. Defaults to "Component instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to default Config object.
kwargs : optional
    Arbitrary keyword arguments.
    """

    
    def __init__(self,
                 FlowState flowInWf,
                 FlowState flowInSf,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="",
                 list sizeBracket=[],
                 list sizeUnitsBracket=[],
                 runBracket = [nan, nan],
                 str name="Component22 instance",
                 str notes="No notes/model info.",
                 Config config=Config()):
        cdef list flows = [[flowInWf, flowOutWf], [flowInSf, flowOutSf]]
        cdef int i
        for i in range(2):
            if flows[i][0] is not None and flows[i][1] is not None:
                assert flows[i][0].m == flows[i][
                    1].m, "mass flow rate of flowsIn[{0}] and flowsOut[{0}] must be equal".format(
                        i)
        
        super().__init__([flowInWf, flowInSf], [flowOutWf, flowOutSf], ambient, sizeAttr, sizeBracket, sizeUnitsBracket, runBracket, name, notes, config)
        self._inputs = {"flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"), "flowOutWf": MCAttr(FlowState, "none"), "flowOutsf": MCAttr(FlowState, "none"), "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBracket": MCAttr(list, "none"), "sizeUnitsBracket": MCAttr(list, "none"), "runBracket": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
        self._properties = {"mWf": MCAttr(float, "mass/time"),"mSf": MCAttr(float, "mass/time")}
        
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

    cpdef public double _mSf(self):
        return self.flowsIn[1].m
    
    @property
    def mSf(self):
        """Alias for self.flowsIn[1].m"""
        return self.flowsIn[1].m

    @mSf.setter
    def mSf(self, value):
        for flow in [self.flowInSf, self.flowOutSf]:
            if flow is not None:
                flow.m = value

