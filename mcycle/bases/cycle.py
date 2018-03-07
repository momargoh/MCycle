from abc import abstractmethod
from ..DEFAULTS import RSTHEADINGS
from .mcabstractbase import MCAbstractBase as MCAB
from .config import Config


class Cycle(MCAB):
    r"""Abstract base class for all cycles.

Parameters
----------
componentKeys : tuple of string
    Tuple of keywords of the cycle components.
config : Config, optional
    Configuration parameters. Defaults to default Config object.
    """

    @abstractmethod
    def __init__(self,
                 componentKeys,
                 cyclestateKeys,
                 config=Config(),
                 **kwargs):
        self._componentKeys = componentKeys
        self._cyclestateKeys = cyclestateKeys
        self._config = config
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    @abstractmethod
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("_componentKeys", "none"), ("config", "none"))

    @property
    @abstractmethod
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return []

    @property
    def _cyclestates(self):
        """List of cycle flow state objects."""
        css = []
        for key in self._cyclestateKeys:
            if not key.startswith("state"):
                key = "state" + cs
            css.append(getattr(self, key))
        return css

    @property
    def config(self):
        """Config: Cycle configuration parameters. Setter sets config object for all cycle components."""
        return self._config

    @config.setter
    def config(self, obj):
        self._config = obj
        for cmpnt in self._components:
            setattr(cmpnt, "config", obj)

    @property
    def _components(self):
        """Returns a tuple of cycle component objects."""
        cmpnts = []
        for key in self._componentKeys:
            cmpnts.append(getattr(self, key))
        return tuple(cmpnts)

    @abstractmethod
    def run(self, flowState=None, component=None):
        """Compute all state FlowStates from initial FlowState and set component characteristics.

This function must be overridden by subclasses.

Parameters
----------
flowState : FlowState, optional
    FlowState to intiate the cycle. Defaults to None. If None, will search components for a non None flowIn and use that to initiate the cycle.
component : string
    Component for which flowState is set as flowInWf
"""
        pass

    @abstractmethod
    def solve(self):
        """Sets all cycle states from design parameters and executes solve() for each component.

.. note: If dpEvap or dpCond is True in self.config, pressure drops will be applied, modifying the original design states.

This function must be overridden by subclasses.
"""
        pass

    def summary(self,
                printSummary=True,
                propertyKeys="all",
                cyclestateKeys="none",
                componentKeys="all",
                componentKwargs={"flowKeys": "none",
                                 "propertyKeys": "none"},
                name=None,
                rstHeading=0):
        """Returns (and prints) a summary of the component attributes/properties/flows.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
propertyKeys : list, optional
    Keys of cycle properties to be included. The following strings are also accepted as inputs:

  - "all": all properties in _properties are included,
  - "none": no properties are included.

    Defaults to "all".
cyclestateKeys : list, optional
    Names of cycle flow states to be included. The following strings are also accepted as inputs:

  - "all": all flows are included,
  - "none": no flows are included.

    Defaults to "none".
componentKeys : list, optional
    Names of components to be included. The following strings are also accepted as inputs:

  - "all": all components in _components are included,
  - "none": no components are included.

    Defaults to "all".
componentKwargs : dict, optional
    Kwargs to parse to component summaries. Defaults to {"flowKeys":"none", "propertyKeys":"none"}.
name : str, optional
    Name of instance used in summary heading. If None, the name property of the instance is used. Defaults to None.
rstHeading : int, optional
    Level of reStructuredText heading to give the summary, 0 being the top heading. Heading style taken from mcycle.DEFAULTS.RSTHEADINGS. Defaults to 0.
        """
        if name is None:
            name = self.__class__.__name__
        output = r"{} summary".format(name)
        output += """
{}
""".format(RSTHEADINGS[rstHeading] * len(output))

        hasSummaryList = []
        for i in self._inputs:
            if i[0] in self._componentKeys:
                pass
            elif i[0] in ["config"]:
                pass
            else:
                output += self.formatAttrUnitsForSummary(i, hasSummaryList)
        #
        if propertyKeys == "all":
            propertyKeys = self._propertyKeys
        if propertyKeys == "none":
            propertyKeys = []
        if len(propertyKeys) > 0:
            output += """
Properties
{}
""".format(RSTHEADINGS[rstHeading + 1] * 10)
            for key in propertyKeys:
                if key in self._propertyKeys:
                    index = self._propertyKeys.index(key)
                    output += self.formatAttrUnitsForSummary(
                        self._properties[index])
                else:
                    output += i + """: property not found,
"""
        #
        if componentKeys == "all":
            componentKeys = self._componentKeys
        elif componentKeys == "none":
            componentKeys = []
        for cmpnt in componentKeys:
            obj = getattr(self, cmpnt)
            output += """
""" + obj.summary(
                printSummary=False,
                name=cmpnt,
                rstHeading=rstHeading + 1,
                **componentKwargs)
        if cyclestateKeys == "all":
            cyclestateKeys = self._cyclestateKeys
        if cyclestateKeys == "none":
            cyclestateKeys = []
        if len(cyclestateKeys) > 0:
            for cs in cyclestateKeys:
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
cycle state{}: flow not found""".format(cs)
                except:
                    output += """{}: {}
""".format(flow, "Error returning summary")
        else:
            pass
        if printSummary:
            print(output)
        return output

    @abstractmethod
    def plot(self):
        """Plots the working fluid cycle states and other meaningful cycle properties (such as source and sink properties).

This function must be overridden by subclasses.
"""
        pass
