from ..DEFAULTS cimport getUnits
from .. import DEFAULTS 
from ..logger import log
from .mcabstractbase cimport MCAB, MCAttr
from .flowstate cimport FlowState
from .config cimport Config
from math import nan


cdef dict _inputs = {"flowsIn": MCAttr(list, "none"), "flowsOut": MCAttr(list, "none"), "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "sizeUnitsBounds": MCAttr(list, "none"), "runBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time")}
        
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
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to None.

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
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
                 list sizeBounds=[],
                 list sizeUnitsBounds=[],
                 runBounds = [nan, nan],
                 str name='Component instance',
                 str notes='No notes/model info.',
                 Config config=Config()):
        self.flowsIn = flowsIn
        self.flowsOut = flowsOut
        self.ambient = ambient
        self.sizeAttr = sizeAttr
        self.sizeBounds = sizeBounds
        self.runBounds = runBounds
        self.sizeUnitsBounds = sizeUnitsBounds
        self.name = name
        self.notes = notes
        self.config = config
        self._inputs = _inputs
        self._properties = _properties
    
    cpdef public MCAB _copy(self, dict kwargs):
        """Return a new copy of a class object. Kwargs (as dict) are passed to update() as a shortcut of simultaneously copying and updating.

Parameters
-----------
kwargs : dict
    Dictionary of attributes and their updated value."""
        copy = self.__class__(*self._inputValues())
        if kwargs != {}:
            copy.update(kwargs)
        try: # copy _units if relevant
            copy._units = []
            for unit in self._units:
                copy._units.append(unit._copy({}))
        except:
            pass
        return copy

    cpdef public void clearWfFlows(self):
        self.flowsIn[0] = None
        self.flowsOut[0] = None
            
    cpdef public void clearAllFlows(self):
        cdef size_t i
        for i in len(self.flowsIn):
            self.flowsIn[i] = None
        for i in len(self.flowsOut):
            self.flowsOut[i] = None
                
    cpdef public void run(self):
        """Compute the outgoing working fluid FlowState from component attributes."""
        pass

    cpdef double _f_sizeComponent(self, double value, FlowState flowOutTarget, str attr, list bounds, list unitsBounds):
        self.update({attr: value, 'sizeBounds': bounds, 'sizeUnitsBounds': unitsBounds})
        self.run()
        return getattr(self.flowsOut[0], self.config.tolAttr)() - getattr(flowOutTarget, self.config.tolAttr)()
    
    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        """Solve for the value of the nominated component attribute required to return the defined outgoing FlowState.

Parameters
-----------
attr : string, optional
    Attribute to be sized. If None, self.sizeAttr is used.
bounds : float or list of float
    Bracket containing solution of size(). If None, self.sizeBounds is used.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
unitsBounds : float or list of float
    Bracket parsed to _units attribute, if relevant, containing solutions of sizeUnits(). If None, self.sizeUnitsBounds is used.

    - if bounds=[a,b]: scipy.optimize.brentq is used.

    - if bounds=a or [a]: scipy.optimize.newton is used.
        """
        cdef double tol
        try:
            import scipy.optimize as opt
            if attr == '':
                attr = self.sizeAttr
            if bounds == []:
                bounds = self.sizeBounds
            if unitsBounds == []:
                unitsBounds = self.sizeUnitsBounds
            flowOutTarget = self.flowsOut[0]._copy({})

            tol = self.config.tolAbs + self.config.tolRel * getattr(flowOutTarget, self.config.tolAttr)()
            if len(bounds) == 2:
                sizedValue = opt.brentq(
                    self._f_sizeComponent,
                    bounds[0],
                    bounds[1],
                    args=(flowOutTarget, attr, bounds, unitsBounds),
                    rtol=self.config.tolRel,
                    xtol=self.config.tolAbs,
                    maxiter=DEFAULTS.MAXITER_COMPONENT)
            elif len(bounds) == 1:
                sizedValue = opt.newton(
                    self._f_sizeComponent,
                    bounds[0],
                    args=(flowOutTarget, attr, bounds, unitsBounds),
                    tol=tol,
                    maxiter=DEFAULTS.MAXITER_COMPONENT)
            else:
                raise ValueError("bounds is not valid (given: {})".format(bounds))
            self.update({attr: sizedValue, 'flowsOut[0]': flowOutTarget})
        except:
            raise StopIteration("{}.size({},{},{}) failed to converge.".format(
                self.__class__.__name__, attr, bounds, unitsBounds))

    cpdef public void sizeUnits(self, str attr, list bounds) except *:
        pass
    
    def size(self, str attr='', list bounds=[], list unitsBounds=[]):
        """Alias of _size(), giving default values of attr='', bounds=[], unitsBounds=[]."""
        self._size(attr, bounds, unitsBounds)
        
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
""".format(DEFAULTS.RST_HEADINGS[rstHeading] * len(output), self.notes)

        hasSummaryList = []
        for k, v in self._inputs.items():
            if k in [
                    "flowsIn", "flowsOut", "flowIn", "flowOut", "flowInWf",
                    "flowOutWf", "flowInSf", "flowOutSf"
            ]:
                pass
            elif k in ["sizeAttr", "sizeBounds", "sizeUnitsBounds", 'runBounds']:
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
""".format(outputProperties, DEFAULTS.RST_HEADINGS[rstHeading+1] * len(outputProperties))
            
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
        flowPropVals = []
        flowPropKeys = []
        del_flowKeys = []
        if len(flowKeys) > 0:
            for key in flowKeys:
                try:
                    if "[" in key:
                        keyList, keyId = key.replace("]", "").split("[")
                        flowObj = getattr(self, keyList)[int(keyId)]
                    else:
                        flowObj = getattr(self, key)
                    print("fpk = ", flowPropKeys)
                    if flowPropKeys == []:
                        flowPropKeys = [k.replace("()","").ljust(4) for k in flowObj._propertyKeys()]
                    flowPropVals.append(flowObj._propertyValues())
                except AttributeError as exc:
                    log("warning", "{}.summary() could not find flow={}".format(self.__class__.__name__, key), exc)
                    del_flowKeys.append(flowKeys.index(key))
                except Exception as exc:
                    log("warning", "{}.summary() unexpected error".format(self.__class__.__name__, key), exc)
                    del_flowKeys.appendflowKeys.index((key))
            del_flowKeys.reverse()
            for i in del_flowKeys:
                del flowKeys[i]
            if len(flowKeys) == 0:
                pass
            else:
                output += """
FlowStates
{}
""".format(DEFAULTS.RST_HEADINGS[rstHeading + 1]*10)
                table = ""
                flowPropValsStr = [list(map(lambda x: DEFAULTS.PRINT_FORMAT_FLOAT.format(x), li)) for li in flowPropVals]
                max_lens = [len(max(li, key=len)) for li in flowPropValsStr]
                str_formats = ["{:<%s}" % max_lens[i] for i in range(len(max_lens))]
                table_header0 = " {} |"*len(flowPropVals)
                table_header0 = table_header0.format(*str_formats)
                table_header = "|{}|" + table_header0 + """
"""
                table_header = table_header.format("    ", *flowKeys)
                table += table_header
                for i in range(len(flowPropVals[0])):
                    table_row = "|{}|" + " {} |".format(DEFAULTS.PRINT_FORMAT_FLOAT)*len(flowPropVals) + """
"""
                    vals = [l[i] for l in flowPropVals]
                    table_row = table_row.format(flowPropKeys[i], *vals)
                    table += table_row
                output += table
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

cdef dict _inputs11 = {"flowIn": MCAttr(FlowState, "none"), "flowOut": MCAttr(FlowState, "none"), "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "sizeUnitsBounds": MCAttr(list, "none"), "runBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
cdef dict _properties11 = {"m": MCAttr(str, "mass/time")}
        
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
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to None.

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
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
                 list sizeBounds=[],
                 list sizeUnitsBounds=[],
                 runBounds = [nan, nan],
                 str name="Component11 instance",
                 str notes="No notes/model info.",
                 config=Config()):
        if flowOut is not None and flowIn is not None:
            assert flowOut.m == flowIn.m, "mass flow rate of flowIn and flowOut must be equal"
        super().__init__([flowIn], [flowOut], ambient, sizeAttr, sizeBounds, sizeUnitsBounds, runBounds, name, notes, config)
        self._inputs = _inputs11
        self._properties = _properties11

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

cdef dict _inputs22 = {"flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"), "flowOutWf": MCAttr(FlowState, "none"), "flowOutsf": MCAttr(FlowState, "none"), "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "sizeUnitsBounds": MCAttr(list, "none"), "runBounds": MCAttr(list, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
cdef dict _properties22 = {"mWf": MCAttr(float, "mass/time"),"mSf": MCAttr(float, "mass/time")}
        
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
sizeBounds : float or list of float, optional
    Bracket containing solution of size(). Defaults to None.

    - if sizeBounds=[a,b]: scipy.optimize.brentq is used.

    - if sizeBounds=a or [a]: scipy.optimize.newton is used.
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
                 list sizeBounds=[],
                 list sizeUnitsBounds=[],
                 runBounds = [nan, nan],
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
        
        super().__init__([flowInWf, flowInSf], [flowOutWf, flowOutSf], ambient, sizeAttr, sizeBounds, sizeUnitsBounds, runBounds, name, notes, config)
        self._inputs = _inputs22
        self._properties = _properties22
        
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

