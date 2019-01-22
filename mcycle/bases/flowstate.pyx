from .mcabstractbase cimport MCAB, MCAttr
from .. import DEFAULTS
from ..DEFAULTS import TOLABS_X
from ..logger import log
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
                 short phaseCP=-1,
                 double m=nan,
                 unsigned short inputPairCP=0,
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
        cdef str f, msg
        cdef list fSplit
        if "&" not in fluid:
            self._state = CP.AbstractState(DEFAULTS.COOLPROP_EOS, fluid)
            #self._state.change_EOS(0, DEFAULTS.COOLPROP_EOS)
        else:
            if not 0 <= phaseCP < 8:
                msg = "phaseCP (given: {}) must be specified for mixtures.".format(phaseCP)
                log("error", msg)
                raise ValueError(msg)
            fluidSplit = fluid.split("&")
            fluidString = ""
            moleFractions = []
            for f in fluidSplit:
                f = f.replace("]", "[")
                fSplit = f.split("[")
                fluidString += "&" + fSplit[0]
                moleFractions.append(float(fSplit[1]))
            fluidString = fluidString[1:]  # remove inital "&"
            self._state = CP.AbstractState(DEFAULTS.COOLPROP_EOS, fluidString)
            #self._state.change_EOS(0, DEFAULTS.COOLPROP_EOS)
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

        
#-----------------------------------------
# Start of FlowStatePoly
#-----------------------------------------

        
cdef dict _inputsPoly = {"refData": MCAttr(RefData, "none"), "m": MCAttr(float, "mass/time"),
                "_inputPairCP": MCAttr(int, "none"), "_input1": MCAttr(float, "none"),
                        "_input2": MCAttr(float, "none"), "name": MCAttr(str, "none")}
cdef dict _propertiesPoly = {"T()": MCAttr(float, "temperature"), "p()": MCAttr(float, "pressure"), "rho()": MCAttr(float, "density"),
                "h()": MCAttr(float, "energy/mass"), "s()": MCAttr(float, "energy/mass-temperature"),
                "cp()": MCAttr(float, "energy/mass-temperature"), "visc()": MCAttr(float, "force-time/area"),
                "k()": MCAttr(float, "power/length-temperature"), "Pr()": MCAttr(float, "none"),
                "x()": MCAttr(float, "none")}

cdef dict _validInputPairs
_validInputPairs = {'T': CP.PT_INPUTS, 'rho': CP.DmassP_INPUTS, 'h': CP.HmassP_INPUTS, 's': CP.PSmass_INPUTS}
        
cdef class FlowStatePoly(FlowState):
    """FlowStatePoly represents the state of a flow at a point by its state properties and a mass flow rate. It is an alternative to FlowState that uses polynomial interpolation of a crude constant pressure reference data map to evaluate the state properties, instead of calling them from a CoolProp AbstractState object. This class was created purely to overcome short comings with CoolProp's mixture processes. Apart from creating new objects, FlowStatePoly has been built to be used in exactly the same way as FlowState.

.. note:: FlowStatePoly only supports constant pressure flows and assumes no phase changes occur.
   It may not be used for the working fluid in a cycle, but may be used as the working fluid in certain constant pressure components.

Parameters
----------
refData : RefData
    Constant pressure fluid reference data map.

m : double, optional
    Mass flow rate [Kg/s]. Defaults to nan.

inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to INPUT_PAIR_INVALID == 0.

    .. note:: Only certain inputPairCP values are valid.
        As FlowStatePoly only supports constant pressure flows, one input variable must be a pressure. Thus, only the following inputPairCP values are valid:

        - CoolProp.PT_INPUTS == 9
        - CoolProp.DmassP_INPUTS == 18
        - CoolProp.HmassP_INPUTS == 20
        - CoolProp.PSmass_INPUTS == 22

input1,input2 : double, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to nan.


Examples
----------
>>> refData = RefData("air", 2, 101325., [200, 250, 300, 350, 400])
>>> air = FlowStatePoly(refData, 1, CoolProp.PT_INPUTS,101325.,293.15)
>>> air.rho
1.20530995019
>>> air.cp
1006.12622976
    """

    def __init__(self,
                  RefData refData,
                  double m=nan,
                  unsigned short inputPairCP=0,
                  double input1=nan,
                  double input2=nan,
                  str name="FlowStatePoly instance"):
        self.refData = refData
        self.fluid = refData.fluid
        self.phaseCP = refData.phaseCP
        self.m = m
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self.name = name
        self._c = {}
        self._inputProperty = ''
        self._inputValue = nan
        self._validateInputs()
        self._inputs = _inputsPoly
        self._properties = _propertiesPoly

        
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
            return FlowStatePoly(*self._inputValues())
        else:
            return FlowStatePoly(self.refData, self.m, inputPairCP, input1, input2)
      
    cpdef public void updateState(self, int inputPairCP, double input1, double input2):
        """void: Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1,input2 : double
    Repective values of inputs corresponding to inputPairCP [in SI units]. One input must be equal to the pressure of refData. Both default to None.
"""
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self._validateInputs()

    cdef void _findAndSetInputProperty(self):
        """str : Return string of input property that is not pressure."""
        self._inputProperty = list(_validInputPairs.keys())[list(_validInputPairs.values()).index(self._inputPairCP)]
    
    cdef bint _validateInputs(self) except? False:
        """bint: Validate inputs and call _findAndSetInputProperty."""
        if self._inputPairCP != -1:
            if self._inputPairCP in _validInputPairs.values():
                if self._inputPairCP is CP.PT_INPUTS or self._inputPairCP is CP.PSmass_INPUTS:
                    if self._input1 == self.refData.p:
                        self._inputValue = self._input2
                        self._findAndSetInputProperty()
                        if self.refData.deg >= 0:
                            self.populate_c()
                        return True
                    else:
                        raise ValueError(
                            """Input pressure does not match reference data pressure: {} != {}""".format(self._input1, self.refData.p))
                elif self._input2 == self.refData.p:
                    self._inputValue = self._input1
                    self._findAndSetInputProperty()
                    if self.refData.deg >= 0:
                        self.populate_c()
                    return True
                else:
                    raise ValueError(
                        "Input pressure does not match reference data pressure: {} != {}".
                        format(self._input2, self.refdata.p))
            else:
                raise ValueError(
                    """{0} is not a valid input pair for FlowStatePoly
                Select from PT_INPUTS=9, DmassP_INPUTS=18, HmassP_INPUTS=20, PSmass_INPUTS=22""".format(self._inputPairCP))
        else:
            return False

    cpdef public void populate_c(self):
        self._c = {}
        cdef str key
        for key in self.refData.data.keys():
            self._c[key] = list(
                    np.polyfit(self.refData.data[self._inputProperty], self.refData.data[key], self.refData.deg))


    cpdef public double p(self):
        """double: Static pressure [Pa]."""
        return self.refData.p

    cpdef public double T(self):
        "double: Static temperture [K]."
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['T'])
        else:
            return np.polyval(self._c['T'], self._inputValue)

    cpdef public double h(self):
        """double: Specific mass enthalpy [J/Kg]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['h'])
        else:
            return np.polyval(self._c['h'], self._inputValue)

    cpdef public double rho(self):
        """double: Mass density [Kg/m^3]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['rho'])
        else:
            return np.polyval(self._c['rho'], self._inputValue)

    cpdef public double s(self):
        """double: Specific mass entropy [J/Kg.K]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['s'])
        else:
            return np.polyval(self._c['s'], self._inputValue)

    cpdef public double visc(self):
        """double: Dynamic viscosity [N.s/m^2]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['visc'])
        else:
            return np.polyval(self._c['visc'], self._inputValue)

    cpdef public double k(self):
        """double: Thermal conductivity [W/m.K]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['k'])
        else:
            return np.polyval(self._c['k'], self._inputValue)

    cpdef public double cp(self):
        """double: Specific mass heat capacity, const. pressure [J/K]."""
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['cp'])
        else:
            return np.polyval(self._c['cp'], self._inputValue)

    cpdef public double Pr(self):
        """double: Prandtl number [-]."""
        return self.cp()*self.visc()/self.k()
    """
        if self.refData.deg == -1:
            return np.interp(self._inputValue, self.refData.data[self._inputProperty], self.refData.data['Pr'])
        else:
            return np.polyval(self._c['Pr'], self._inputValue)"""

    cpdef public double x(self):
        """double: Quality [-]. By definition, x = -1 for all FlowStatePoly objects."""
        return -1
    
    cpdef public double pCrit(self):
        r"""double: Critical pressure [Pa]."""
        log("warning", "FlowStatePoly, critical pressure is not defined for mixtures")
        return nan
    
    cpdef public double pMin(self):
        r"""double: Minimum pressure [Pa]."""
        log("warning", "FlowStatePoly, minimum pressure is not defined for mixtures")
        return nan
    
    cpdef public double TCrit(self):
        r"""double: Critical temperture [K]."""
        log("warning", "FlowStatePoly, critical temperature is not defined for mixtures")
        return nan
    
    cpdef public double TMin(self):
        r"""double: Minimum temperture [K]."""
        log("warning", "FlowStatePoly, minimum temperature is not defined for mixtures")
        return nan

    cpdef public str phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'sp': unknown single-phase."""
        cdef double liq_h = 0
        try:
            liq_h = CP.CoolProp.PropsSI("HMASS", "P", self.refData.p, "Q", 0,
                                        self.refData.fluid)
            if self.h() < liq_h:
                return "liq"
            else:
                return "vap"
        except ValueError:
            return "sp"


#-----------------------------------------
# Start of RefData
#-----------------------------------------


cdef class RefData:
    """cdef class. RefData stores constant pressure thermodynamic properties of a 'pure' fluid or mixture thereof. Property data can be directly input, or, if only temperature data is provided, RefData will call CoolProp to compute the remaining properties.

Parameters
----------
fluid : str
    Description of fluid passed to CoolProp.

    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid0[mole_fraction0]&fluid1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]".

    .. note:: CoolProp's mixture routines often raise errors; using mixtures should be avoided.


deg : int
    Polynomial degree used to fit the data using `numpy.polyfit <https://docs.scipy.org/doc/numpy-1.14.0/reference/generated/numpy.polyfit.html>`_. If -1, properties will be linearly interpolated between the data values using `numpy.interp <https://docs.scipy.org/doc/numpy-1.14.0/reference/generated/numpy.interp.html>`_.

p: double
    Constant static pressure [Pa] of the property data.

data : dict
    Dictionary of data map values. Data must be given as a list of floats for each of the following keys:
    
    - 'T' : static temperature [K]. Must be provided.
    - 'h' : specific mass enthalpy [J/Kg]. Optional.
    - 'rho' : mass density [Kg/m^3]. Optional.
    - 's' : specific mass entropy [J/Kg.K]. Optional.
    - 'visc' : dynamic viscosity [N.s/m^2]. Optional.
    - 'k' : thermal conductivity [W/m.K]. Optional.
    - 'cp' : specific mass heat capacity, const. pressure [J/K]. Optional.

    A complete map must be provided or if only temperature values are provided, MCycle will attempt to populate the data using CoolProp.

phaseCP : int, optional
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to -1.
    """

    def __cinit__(self,
                  str fluid,
                  unsigned short deg,
                  double p,
                  dict data,
                  short phaseCP=-1):
        self.fluid = fluid
        self.phaseCP = phaseCP
        self.deg = deg
        self.p = p
        if data['T'] == []:
            msg = "data parameter must contain list of temperature values, key='T'"
            log("error", msg)
            raise ValueError(msg)
        self.data = {'T': data['T'], 'h': [], 'rho': [], 's': [], 'visc': [], 'k': [], 'cp': []}#, 'Pr': []}     
        cdef list other_props = ['h', 'rho', 's', 'visc', 'k', 'cp']#, 'Pr']
        cdef str prop
        cdef size_t lenDataT = len(data['T'])
        if data.keys() == self.data.keys():
            if all(data[prop] == [] for prop in other_props):
                self.populateData()
            elif not all(len(data[prop]) == lenDataT for prop in other_props):
                msg = "Not all data lists have same length as data['T']: len={}".format(lenDataT)
                log("error", msg)
                raise ValueError(msg)
            else:
                self.data = data
        else:
            self.populateData()

    cpdef public void populateData(self) except *:
        """void: Populate property data list from data['T'] using CoolProp."""
        if self.data['T'] == []:
            raise ValueError("data['T'] must not be empty.")
        cdef list other_props = ['h', 'rho', 's', 'visc', 'k', 'cp']#, 'Pr']
        cdef str prop
        for prop in other_props:
            self.data[prop] = []
        cdef double T
        cdef FlowState f
        for T in self.data['T']:
            f = FlowState(self.fluid, self.phaseCP, nan,
                          CP.PT_INPUTS, self.p, T)
            for prop in other_props:
                self.data[prop].append(getattr(f, prop)())
