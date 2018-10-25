from .mcabstractbase cimport MCAB, MCAttr
from ..DEFAULTS cimport TOLABS_X, COOLPROP_EOS
from .. import DEFAULTS
from math import nan, isnan
import CoolProp as CP
import numpy as np

cdef dict _inputs = {"fluid": MCAttr(str, "none"), "phaseCP": MCAttr(int, "none"),
                "m": MCAttr(float, "mass/time"), "_inputPairCP": MCAttr(int, "none"),
                        "_input1": MCAttr(float, "none"), "_input2": MCAttr(float, "none"), "name": MCAttr(str,"none")}
cdef dict _properties = {"T()": MCAttr(float, "temperature"), "p()": MCAttr(float, "pressure"), "rho()": MCAttr(float, "density"),
                "h()": MCAttr(float, "energy/mass"), "s()": MCAttr(float, "energy/mass-temperature"),
                "cp()": MCAttr(float, "energy/mass-temperature"), "visc()": MCAttr(float, "force-time/area"),
                "k()": MCAttr(float, "power/length-temperature"), "Pr()": MCAttr(float, "none"),
                "x()": MCAttr(float, "none")}

cdef class FlowState(MCAB):
    """FlowState represents the state of a flow at a point by its state properties and a mass flow rate. This class creates a `CoolProp AbstractState <http://www.coolprop.org/apidoc/CoolProp.CoolProp.html>`_ object to store the state properties and uses the routines of CoolProp.

Parameters
----------
fluid : str
    Description of fluid passed to CoolProp.

    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid0[mole_fraction0]&fluid1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]".

    .. note:: CoolProp's mixture routines often raise errors; using mixtures should be avoided.

phaseCP : int, optional
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to -1.
    .. note:: In MCycle, both -1 and 8 can be used for iphase_not_imposed

m : double, optional
    Mass flow rate [Kg/s]. Defaults to nan.

inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to 0 (INPUT_PAIR_INVALID).

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to nan.

name : str, optional
    Descriptive name of instance. Defaults to "FlowState instance".

Examples
----------
import mcycle
import CoolProp
>>> air = FlowState("air",-1,1.0,CoolProp.PT_INPUTS,101325,293.15)
>>> air.rho()
1.2045751824931508
>>> air.cp()
1006.144032087035
    """
        
    def __init__(self,
                 str fluid,
                 int phaseCP=-1,
                 double m=nan,
                 int inputPairCP=0,
                 double input1=nan,
                 double input2=nan,
                 str name="FlowState instance"):
        self.fluid = fluid
        self.phaseCP = phaseCP
        self.m = m
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self.name = name
        self._inputs = _inputs
        self._properties = _properties
        self._state = None

        # determine if pure or mixture
        cdef list fluidSplit
        cdef str fluidString
        cdef list moleFractions
        cdef str f
        cdef list fSplit
        if "&" not in fluid:
            self._state = CP.AbstractState(COOLPROP_EOS, fluid)
            #self._state.change_EOS(0, COOLPROP_EOS)
        else:
            assert 0 <= phaseCP < 8, "phaseCP (given: {}) must be specified for mixtures.".format(phaseCP)
            fluidSplit = fluid.split("&")
            fluidString = ""
            moleFractions = []
            for f in fluidSplit:
                f = f.replace("]", "[")
                fSplit = f.split("[")
                fluidString += "&" + fSplit[0]
                moleFractions.append(float(fSplit[1]))
            fluidString = fluidString[1:]  # remove inital "&"
            self._state = CP.AbstractState(COOLPROP_EOS, fluidString)
            #self._state.change_EOS(0, COOLPROP_EOS)
            self._state.set_mole_fractions(moleFractions)
            self._state.specify_phase(phaseCP)
            self._state.build_phase_envelope("")
        if inputPairCP != 0 and not isnan(input1) and not isnan(input2):
            self._state.update(inputPairCP, input1, input2)

    def __eq__(self, other):
        cdef list inputValues = list(self._inputValues())
        cdef list other_inputValues = list(other._inputValues())

        if all(inputValues[i] == other_inputValues[i] or
               np.isclose(inputValues[i], other_inputValues[i])
               for i in range(len(inputValues))):
            return True
        elif all(self._propertyValues()[i] == other._propertyValues()[i] or
                 np.isclose(self._propertyValues()[i], other._propertyValues()[i])
                 for i in range(len(self._propertyValues()))):
            return True
        else:
            return False

    cpdef public FlowState copyState(self, int inputPairCP, double input1, double input2):
        """Creates a new copy of a FlowState object. As a shortcut, args can be passed to update the object copy (see update()).

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.
        """
        if inputPairCP == 0 or isnan(input1) or isnan(input2):
            return FlowState(*self._inputValues())
        else:
            return FlowState(self.fluid, self.phaseCP, self.m,
                             inputPairCP, input1, input2, self.name)

    cpdef public void updateState(self, int inputPairCP, double input1, double input2):
        """Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1, input2 : double
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.
        """
        if "&" in self.fluid:
            self._state.build_phase_envelope("")
        self._state.update(inputPairCP, input1, input2)
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2

    def summary(self, bint printSummary=True, str name='', int rstHeading=0):
        """Returns (and prints) a summary of FlowState properties.

Parameters
-----------
printSummary : bool, optional
    If true, the summary string is printed as well as returned. Defaults to True.
name : str, optional
    Name of the object, prepended to the summary heading. If None, the class name is used. Defaults to None.
        """
        cdef str output
        if name == '':
            name = self.name
        output = r"{} summary".format(name)
        output += """
{}
""".format(DEFAULTS.RST_HEADINGS[rstHeading] * len(output))
        for k, v in self._properties.items():
            output += self.formatAttrForSummary({k: v}, [])
        if printSummary:
            print(output)
        return output
    
    cpdef public double T(self):
        r"""double: Static temperture [K]."""
        return self._state.T()
    
    cpdef public double p(self):
        r"""double: Static pressure [Pa]."""
        return self._state.p()
    
    cpdef public double rho(self):
        r"""double:  Mass density [Kg/m^3]."""
        return self._state.rhomass()
    
    cpdef public double v(self):
        r"""double:  Specific volume [m^3/Kg]."""
        return 1. / self.rho()

    cpdef public double h(self):
        r"""double:  Specific mass enthalpy [J/Kg]."""
        return self._state.hmass()
    
    cpdef public double s(self):
        r"""double: Specific mass entropy [J/Kg.K]."""
        return self._state.smass()
    
    cpdef public double x(self):
        r"""double: Quality [-]."""
        return self._state.Q()
    
    cpdef public double visc(self):
        r"""double: Dynamic viscosity [N.s/m^2]."""
        return self._state.viscosity()
    
    cpdef public double k(self):
        r"""double: Thermal conductivity [W/m.K]."""
        return self._state.conductivity()
    
    cpdef public double cp(self):
        r"""double: Specific mass heat capacity, const. pressure [J/K].

.. note:: Linear interpolation in 2-phase region is used due to non-continuities in  CoolProp's routines."""
        cdef FlowState liq, vap
        if self._state.Q() < 1.+TOLABS_X and self._state.Q() > -TOLABS_X:
            liq = self.copyState(CP.PQ_INPUTS, self.p(), 0)
            vap = self.copyState(CP.PQ_INPUTS, self.p(), 1)
            return liq._state.cpmass() + self._state.Q() * (vap._state.cpmass() - liq._state.cpmass())
        else:
            return self._state.cpmass()
    
    cpdef public double Pr(self):
        r"""double: Prandtl number [-].

.. note:: Linear interpolation in 2-phase region is used due to non-continuities in  CoolProp's routines."""
        cdef FlowState liq, vap
        if self._state.Q() < 1.+TOLABS_X and self._state.Q() > -TOLABS_X:
            liq = self.copyState(CP.PQ_INPUTS, self.p(), 0)
            vap = self.copyState(CP.PQ_INPUTS, self.p(), 1)
            return liq._state.Prandtl() + self._state.Q() * (vap._state.Prandtl() - liq._state.Prandtl())
        else:
            return self._state.Prandtl()
    
    cpdef public double V(self):
        r"""double:  Volumetric flow rate [m^3/s]."""
        return self.m / self.rho()
    
    cpdef public double pCrit(self):
        r"""double: Critical pressure [Pa]."""
        return CP.CoolProp.PropsSI("pCrit", self.fluid)
    
    cpdef public double pMin(self):
        r"""double: Minimum pressure [Pa]."""
        return CP.CoolProp.PropsSI("pmin", self.fluid)
    
    cpdef public double TCrit(self):
        r"""double: Critical temperture [K]."""
        return CP.CoolProp.PropsSI("Tcrit", self.fluid)
    
    cpdef public double TMin(self):
        r"""double: Minimum temperture [K]."""
        return CP.CoolProp.PropsSI("Tmin", self.fluid)
    
    cpdef public str phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'satLiq':saturated liquid, 'satVap':saturated vapour, 'tp': two-phase liquid/vapour region."""
        cdef FlowState liq
        if -TOLABS_X < self.x() < TOLABS_X:
            return "satLiq"
        elif 1 - TOLABS_X < self.x() < 1 + TOLABS_X:
            return "satVap"
        elif 0 < self.x() < 1:
            return "tp"
        elif self.x() == -1:
            liq = self.copyState(CP.PQ_INPUTS, self.p(), 0)
            if self.h() < liq.h():
                return "liq"
            else:
                return "vap"
        else:
            raise ValueError(
                "Non-valid quality encountered, x={}".format(self.x()))
