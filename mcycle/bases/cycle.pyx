from .mcabstractbase cimport MCAB, MCAttr
from .component cimport Component
from .config cimport Config
from .flowstate cimport FlowState
from ..DEFAULTS cimport RST_HEADINGS


cdef class Cycle(MCAB):
    r"""Abstract base class for all cycles.

Parameters
----------
_componentKeys : tuple of string
    Tuple of keywords of the cycle components.
_cycleStateKeys : tuple of string
    Tuple of cycle state numbers, eg. ("1", "20", "21", "3" ...).
config : Config, optional
    Configuration parameters. Defaults to default Config object.
    """

    def __init__(self,
                 tuple _componentKeys,
                 tuple _cycleStateKeys,
                 Config config=Config(),
                 str name="Cycle"):
        self._componentKeys = _componentKeys
        self._cycleStateKeys = _cycleStateKeys
        self.config = config
        self._inputs = {"_componentKeys": MCAttr(list, "none"), "_cycleStateKeys": MCAttr(list, "none"), "config": MCAttr(str, "none"), "name": MCAttr(str, "none")}
        self._properties = {}
        self.name = name

    cdef public list _cycleStateObjs(self):
        """List of cycle flow state objects."""
        cdef list css = []
        cdef str key
        for key in self._cycleStateKeys:
            if not key.startswith("state"):
                key = "state" + key
            css.append(getattr(self, key))
        return css

    cdef public list _componentObjs(self):
        """Returns a tuple of cycle component objects."""
        cdef list cmpnts = []
        cdef str key
        for key in self._componentKeys:
            cmpnts.append(getattr(self, key))
        return cmpnts
    
    cpdef public void update(self, dict kwargs):
        cdef str key
        cdef list key_split
        cdef dict store = {}
        for key, value in kwargs.items():
            if hasattr(self, 'set_{}'.format(key)):
                getattr(self, 'set_{}'.format(key))(value)
            else:
                store[key] = value
        if store != {}:        
            super(Cycle, self).update(store)

    cpdef public void clearWfFlows(self):
        cdef Component c
        for c in self._componentObjs():
            c.flowsIn[0] = None
            c.flowsOut[0] = None
            
    cpdef public void clearAllFlows(self):
        cdef Component c
        cdef size_t i
        for c in self._componentObjs():
            for i in len(c.flowsIn):
                c.flowsIn[i] = None
            for i in len(c.flowsOut):
                c.flowsOut[i] = None

    cpdef public void set_config(self, Config obj):
        self.config = obj
        for cmpnt in self._componentObjs():
            cmpnt.update({'config': obj})
            
    cpdef public void run(self):
        """Abstract method: Compute all state FlowStates from initial FlowState and set component characteristics.

This function must be overridden by subclasses.
        """
        pass

    cpdef public void size(self):
        """Abstract method: Sets all cycle states from design parameters and executes size() for each component.

.. note: If dpEvap or dpCond is True in self.config, pressure drops will be applied, modifying the original design states.
"""
        pass

    def summary(self,
                bint printSummary=True,
                propertyKeys='all',
                cycleStateKeys='none',
                componentKeys='all',
                dict componentKwargs={"flowKeys": 'none',
                                 "propertyKeys": 'none'},
                str name="",
                int rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Keys of cycle properties to be included. The following strings are also accepted as inputs:

  - 'all': all properties in _properties are included,
  - 'none': no properties are included.

    Defaults to 'all'.
cycleStateKeys : list, optional
    Names of cycle flow states to be included. The following strings are also accepted as inputs:

  - 'all': all flows are included,
  - 'none': no flows are included.

    Defaults to 'none'.
componentKeys : list, optional
    Names of components to be included. The following strings are also accepted as inputs:

  - 'all': all components in _components are included,
  - 'none': no components are included.

    Defaults to 'all'.
componentKwargs : dict, optional
    Kwargs to parse to component summaries. Defaults to {"flowKeys":'none', "propertyKeys":'none'}.
name : str, optional
    Name of instance used in summary heading. If None, the name property of the instance is used. Defaults to None.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RST_HEADINGS. Defaults to 0.
        """
        cdef int index
        cdef tuple i
        cdef str key, cs, output
        if name == "":
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
working fluid: {}
""".format(RST_HEADINGS[rstHeading] * len(output), self.wf.fluid)

        cdef list hasSummaryList = []
        for k, v in self._inputs.items():
            if k in self._componentKeys:
                pass
            elif k in ["config"]:
                pass
            else:
                output += self.formatAttrForSummary({k: v}, hasSummaryList)
        #
        if propertyKeys == 'all':
            propertyKeys = self._propertyKeys()
        if propertyKeys == 'none':
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """
Properties
{}
""".format(RST_HEADINGS[rstHeading + 1] * 10)
            for k in propertyKeys:
                try:
                    if k in self._propertyKeys():
                        o = self.formatAttrForSummary(
                            {k: self._properties[k]}, [])
                    elif k+"()" in self._propertyKeys():
                        o = self.formatAttrForSummary(
                            {k+"()": self._properties[k+"()"]}, [])
                    else:
                        o = k + """: property not found
"""
                    if "not found" not in o:
                        output += o
                    else:
                        output += k + """: nan
"""
                except:
                        output += k + """: nan
"""
                    
        #
        if componentKeys == 'all':
            componentKeys = self._componentKeys
        elif componentKeys == 'none':
            componentKeys = []
        for cmpnt in componentKeys:
            obj = getattr(self, cmpnt)
            output += """
""" + obj.summary(
                printSummary=False,
                name=cmpnt,
                rstHeading=rstHeading + 1,
                **componentKwargs)
        if cycleStateKeys == 'all':
            cycleStateKeys = self._cycleStateKeys
        if cycleStateKeys == 'none':
            cycleStateKeys = []
        if len(cycleStateKeys) > 0:
            for cs in cycleStateKeys:
                if not cs.startswith("state"):
                    cs = "state" + cs
                try:
                    flow = getattr(self, cs)
                    output += """
{}""".format(
                        flow.summary(
                            name=cs,
                            printSummary=False,
                            rstHeading=rstHeading + 1))
                except AttributeError:
                    output += """
cycle {}: flow not found""".format(cs)
                except:
                    output += """{}: {}
""".format(flow, "Error returning summary")
        else:
            pass
        if printSummary:
            print(output)
        return output


    def plot(self):
        """Abstract method: Plots the working fluid cycle states and other meaningful cycle properties (such as source and sink properties).
        """
        pass
