from ..DEFAULTS import TOLABS_X, RSTHEADINGS, DEFAULT_COOLPROP_LIBRARY
from .mcabstractbase import MCAbstractBase as MCAB
import CoolProp as CP
import numpy as np


class FlowState(MCAB):
    """FlowState represents the state of a flow at a point by its state properties and a mass flow rate. This class creates a `CoolProp AbstractState <http://www.coolprop.org/apidoc/CoolProp.CoolProp.html>`_ object to store the state properties and uses the routines of CoolProp.

Parameters
----------
fluid : string
    Description of fluid passed to CoolProp.

    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid0[mole_fraction0]&fluid1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]".

    .. note:: CoolProp's mixture routines often raise errors; using mixtures should be avoided.

libCP : string, optional
    Library used by CoolProp routines. Must be "HEOS" or "REFPROP". If None or "default", defaults to DEFAULT_COOLPROP_LIBRARY in mcycle.DEFAULTS. Defaults to None.

phaseCP : int, optional
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to None.

m : float, optional
    Mass flow rate [Kg/s]. Defaults to None.

inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1, input2 : float, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.

Attributes
-----------
fluid : string
    Description of fluid passed to CoolProp.

libCP : string
    Library used by CoolProp routines. Must be "HEOS" or "REFPROP". Defaults to "HEOS".

phaseCP : int
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to None.

m : float
    Mass flow rate [Kg/s]. Defaults to None.

Examples
----------
>>> air = FlowState("air","HEOS",None,1.0,CoolProp.PT_INPUTS,101325,293.15)
>>> air.rho
1.2045751824931508
>>> air.cp
1006.144032087035
    """

    def __init__(self,
                 fluid,
                 libCP=None,
                 phaseCP=None,
                 m=None,
                 inputPairCP=None,
                 input1=None,
                 input2=None):
        self._state = None
        self.fluid = fluid
        if libCP is None or libCP.lower() == "default":
            libCP = DEFAULT_COOLPROP_LIBRARY
        self.libCP = libCP
        self.phaseCP = phaseCP
        self.m = m
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2

        # determine if pure or mixture
        if "&" not in fluid:
            self._state = CP.AbstractState(libCP, fluid)
        else:
            fluid = fluid.split("&")
            fluidString = ""
            moleFractions = []
            for f in fluid:
                f = f.replace("]", "[")
                f = f.split("[")
                fluidString += "&" + f[0]
                moleFractions.append(float(f[1]))
            fluidString = fluidString[1:]  # remove inital "&"
            self._state = CP.AbstractState(libCP, fluidString)
            self._state.set_mole_fractions(moleFractions)
            self._state.specify_phase(phaseCP)
            self._state.build_phase_envelope("")
        if all(i is not None for i in [inputPairCP, input1, input2]):
            self._state.update(inputPairCP, input1, input2)

    def __eq__(self, other):
        inputValues = list(self._inputValues)
        other_inputValues = list(other._inputValues)

        if all(inputValues[i] == other_inputValues[i] or
               np.isclose(inputValues[i], other_inputValues[i])
               for i in range(len(inputValues))):
            return True
        elif all(self._propertyValues[i] == other._propertyValues[i] or
                 np.isclose(self._propertyValues[i], other._propertyValues[i])
                 for i in range(len(self._propertyValues))):
            return True
        else:
            return False

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("fluid", "none"), ("libCP", "none"), ("phaseCP", "none"),
                ("m", "mass/time"), ("_inputPairCP", "none"),
                ("_input1", "none"), ("_input2", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return [("T", "temperature"), ("p", "pressure"), ("rho", "density"),
                ("h", "energy/mass"), ("s", "energy/mass-temperature"),
                ("cp", "energy/mass-temperature"), ("visc", "force-time/area"),
                ("k", "power/length-temperature"), ("Pr", "none"),
                ("x", "none")]

    def copy(self, inputPairCP=None, input1=None, input2=None):
        """Creates a new copy of a FlowState object. As a shortcut, args can be passed to update the object copy (see update()).

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1, input2 : float, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.
"""
        if all(i is not None for i in [inputPairCP, input1, input2]):
            return FlowState(self.fluid, self.libCP, self.phaseCP, self.m,
                             inputPairCP, input1, input2)
        else:
            return FlowState(*self._inputValues)

    def update(self, inputPairCP, input1, input2):
        """Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1, input2 : float
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.
"""
        if "&" in self.fluid:
            self._state.build_phase_envelope("")
        self._state.update(inputPairCP, input1, input2)
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2

    def summary(self, printSummary=True, name=None, rstHeading=0):
        """Returns (and prints) a summary of FlowState properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
name : str, optional
    Name of the object, prepended to the summary heading. If None, the class name is used. Defaults to None.
        """
        if name is None or name == "":
            name = self.__class__.__name__
        output = r"{} summary".format(name)
        output += """
{}
""".format(RSTHEADINGS[rstHeading] * len(output))
        for prop in self._properties:
            output += self.formatAttrUnitsForSummary(prop)
        if printSummary:
            print(output)
        return output

    @property
    def T(self):
        r"""float: Static temperture [K]."""
        return self._state.T()

    @property
    def p(self):
        r"""float: Static pressure [Pa]."""
        return self._state.p()

    @property
    def rho(self):
        """float: Mass density [Kg/m^3]."""
        return self._state.rhomass()

    @property
    def h(self):
        """float: Specific mass enthalpy [J/Kg]."""
        return self._state.hmass()

    @property
    def s(self):
        """float: Specific mass entropy [J/Kg.K]."""
        return self._state.smass()

    @property
    def x(self):
        """float: Quality [-]."""
        return self._state.Q()

    @property
    def visc(self):
        """float: Dynamic viscosity [N.s/m^2]."""
        return self._state.viscosity()

    @property
    def k(self):
        """float: Thermal conductivity [W/m.K]."""
        return self._state.conductivity()

    @property
    def cp(self):
        """float: Specific mass heat capacity, const. pressure [J/K].

.. note:: Linear interpolation in 2-phase region is used due to non-continuities in  CoolProp's routines"""
        if self._state.Q() < 1. and self._state.Q() > 0.:
            liq = self.copy(CP.PQ_INPUTS, self.p, 0)
            vap = self.copy(CP.PQ_INPUTS, self.p, 1)
            return liq.cp + self._state.Q() * (vap.cp - liq.cp)
        else:
            return self._state.cpmass()

    @property
    def Pr(self):
        """float: Prandtl number [-].

.. note:: Linear interpolation in 2-phase region is used due to non-continuities in  CoolProp's routines"""
        if self._state.Q() < 1. and self._state.Q() > 0.:
            liq = self.copy(CP.PQ_INPUTS, self.p, 0)
            vap = self.copy(CP.PQ_INPUTS, self.p, 1)
            return liq.Pr + self._state.Q() * (vap.Pr - liq.Pr)
        else:
            return self._state.Prandtl()

    @property
    def twoPhase(self):
        """bool: True if FlowState is in two-phase liquid-vapour region."""
        if self.x > -TOLABS_X and self.x < 1 + TOLABS_X:
            return True
        else:
            return False

    @property
    def phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'satLiq':saturated liquid, 'satVap':saturated vapour, 'tp': two-phase liquid/vapour region."""
        if -TOLABS_X < self.x < TOLABS_X:
            return "satLiq"

        elif 1 - TOLABS_X < self.x < 1 + TOLABS_X:
            return "satVap"
        elif 0 < self.x < 1:
            return "tp"
        elif self.x == -1:
            liq = self.copy(CP.PQ_INPUTS, self.p, 0)
            if self.h < liq.h:
                return "liq"
            else:
                return "vap"
        else:
            raise ValueError(
                "Non-valid quality encountered, x={}".format(self.x))
