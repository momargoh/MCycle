from .abc cimport ABC
from .component cimport Component
from .config cimport Config
from .flowstate cimport FlowState
from .. import defaults
from ..logger import log


cdef tuple _inputs = ('_componentKeys', '_cycleStateKeys', 'config', 'name')
cdef tuple _properties = ()
        
cdef class Cycle(ABC):
    r"""Abstract base class for cycles.

Parameters
----------
_componentKeys : tuple of string
    Tuple of keywords of the cycle components (in order if applicable to the cycle).
_cycleStateKeys : tuple of string
    Tuple of cycle state numbers, eg. ("1", "20", "21", "3" ...). Used for :meth:`plot <mcycle.bases.cycle.Cycle.plot>` and :meth:`summary <mcycle.bases.cycle.Cycle.summary>`.
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
name : str, optional
    Description of Cycle object. Defaults to "Cycle instance".
    """

    def __init__(self,
                 tuple _componentKeys,
                 tuple _cycleStateKeys,
                 Config config=None,
                 str name="Cycle instance"):
        super().__init__(_inputs, _properties, name)
        self._componentKeys = _componentKeys
        self._cycleStateKeys = _cycleStateKeys
        if config is None:
            config = defaults.CONFIG
        self.config = config

    cdef public list _cycleStateObjs(self):
        """List of the cycle FlowState objects listed in _cycleStateKeys."""
        cdef list css = []
        cdef str key
        for key in self._cycleStateKeys:
            if not key.startswith("state"):
                key = "state" + key
            css.append(getattr(self, key))
        return css

    cdef public list _componentObjs(self):
        """Returns a tuple of the cycle component objects listed in _componentKeys"""
        cdef list cmpnts = []
        cdef str key
        for key in self._componentKeys:
            cmpnts.append(getattr(self, key))
        return cmpnts
    
    cpdef public void update(self, dict kwargs):
        """Update (multiple) class variables from a dictionary of keyword arguments.

Parameters
-----------
kwargs : dict
    Dictionary of attributes and their updated value."""
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

    cpdef public void clearWf_flows(self):
        """Set all working fluid flows (index=0 in flowsIn & flowsOut) to None."""
        cdef Component c
        for c in self._componentObjs():
            c.flowsIn[0] = None
            c.flowsOut[0] = None
            
    cpdef public void clearAll_flows(self):
        """Set all flows to None."""
        cdef Component c
        cdef size_t i
        for c in self._componentObjs():
            for i in len(c.flowsIn):
                c.flowsIn[i] = None
            for i in len(c.flowsOut):
                c.flowsOut[i] = None

    cpdef public void setAll_config(self, Config obj):
        """Set the config object for all cycle components."""
        self.config = obj
        for cmpnt in self._componentObjs():
            cmpnt.update({'config': obj})
            
    cpdef public void updateAll_config(self, dict kwargs):
        """Update all component config objects using kwargs.

.. note: If all components already use the same config object, this method is not necessary."""
        self.config.update(kwargs)
        for cmpnt in self._componentObjs():
            cmpnt.config.update(kwargs)
            
    cpdef public void run(self) except *:
        """Abstract method: Compute all state FlowStates from initial FlowState and set component characteristics.
        """
        pass

    cpdef public void size(self) except *:
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
                str title="",
                int rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list or str, optional
    Keys of cycle properties to be included. The following strings are also accepted as inputs:

  - 'all': all properties in _properties are included,
  - 'none': no properties are included.

    Defaults to 'all'.
cycleStateKeys : list or str, optional
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
title : str, optional
    Title used in summary heading. If '', the :meth:`name <mcycle.abc.ABC.name>` property of the instance is used. Defaults to ''.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from :meth:`RST_HEADINGS <mcycle.defaults.RST_HEADINGS>`. Defaults to 0.
        """
        cdef int index
        cdef tuple i
        cdef str key, cs, output
        if title == "":
            title = self.name
        output = r"{} summary".format(title)
        output += """
{}
working fluid: {}
""".format(defaults.RST_HEADINGS[rstHeading] * len(output), self.wf.fluid)

        cdef list hasSummaryList = []
        for k in self._inputs:
            if k in self._componentKeys:
                pass
            elif k in ["config"]:
                pass
            else:
                output += self.formatAttrForSummary(k, hasSummaryList)
        #
        if propertyKeys == 'all':
            propertyKeys = self._properties
        if propertyKeys == 'none':
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """
Properties
{}
""".format(defaults.RST_HEADINGS[rstHeading + 1] * 10)
            for k in propertyKeys:
                try:
                    if k in self._properties:
                        o = self.formatAttrForSummary(
                            k, [])
                    elif k+"()" in self._properties:
                        o = self.formatAttrForSummary(
                            k+"()", [])
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
                title=cmpnt,
                rstHeading=rstHeading + 1,
                **componentKwargs)
        if cycleStateKeys == 'all':
            cycleStateKeys = self._cycleStateKeys
        if cycleStateKeys == 'none':
            cycleStateKeys = []
        flowKeys = []
        flowPropVals = []
        flowPropKeys = []
        del_flowKeys = []
        if len(cycleStateKeys) > 0:
            for cs in cycleStateKeys:
                if not cs.startswith("state"):
                    cs = "state" + cs
                flowKeys.append(cs)
                try:
                    flowObj = getattr(self, cs)
                    if flowPropKeys == []:
                        flowPropKeys = [k.replace("()","").ljust(4) for k in flowObj._properties]
                    flowPropVals.append(flowObj._propertyValues())
                except AttributeError as exc:
                    log("warning", "{}.summary() could not find flow={}".format(self.__class__.__name__, cs), exc)
                    del_flowKeys.append(flowKeys.index(cs))
                except Exception as exc:
                    log("warning", "{}.summary() unexpected error".format(self.__class__.__name__, cs), exc)
                    del_flowKeys.append(flowKeys.index(cs))
            del_flowKeys.reverse()
            for i in del_flowKeys:
                del flowKeys[i]
            if len(flowKeys) == 0:
                pass
            else:
                output += """
Cycle FlowStates
{}
""".format(defaults.RST_HEADINGS[rstHeading + 1]*16)
                table = ""
                flowPropValsStr = [list(map(lambda x: defaults.PRINT_FORMAT_FLOAT.format(x), li)) for li in flowPropVals]
                max_lens = [len(max(li, key=len)) for li in flowPropValsStr]
                str_formats = ["{:<%s}" % max_lens[x] for x in range(len(max_lens))]
                table_header0 = " {} |"*len(flowPropVals)
                table_header0 = table_header0.format(*str_formats)
                table_header = "|{}|" + table_header0 + """
"""
                table_header = table_header.format("    ", *flowKeys)
                table += table_header
                for x in range(len(flowPropVals[0])):
                    table_row = "|{}|" + " {} |".format(defaults.PRINT_FORMAT_FLOAT)*len(flowPropVals) + """
"""
                    vals = [l[x] for l in flowPropVals]
                    table_row = table_row.format(flowPropKeys[x], *vals)
                    table += table_row
                output += table
        else:
            pass
        if printSummary:
            print(output)
        return output


    def plot(self):
        """Abstract method: Plot the working fluid cycle states and other meaningful cycle properties (such as source and sink properties).
        """
        pass
