from .abc cimport ABC, MCAttr
from .. import defaults
from .._constants cimport *
from ..logger import log
from math import nan, isnan
import CoolProp as CP
import numpy as np

cdef dict _inputs = {"fluid": MCAttr(str, "none"), 
                "m": MCAttr(float, "mass/time"), "_inputPair": MCAttr(int, "none"),
                        "_input1": MCAttr(float, "none"), "_input2": MCAttr(float, "none"), "_iphase": MCAttr(int, "none"), "eos": MCAttr(str,"none"), "name": MCAttr(str,"none")}
cdef dict _properties = {"T()": MCAttr(float, "temperature"), "p()": MCAttr(float, "pressure"), "rho()": MCAttr(float, "density"),
                "h()": MCAttr(float, "energy/mass"), "s()": MCAttr(float, "energy/mass-temperature"),
                "cp()": MCAttr(float, "energy/mass-temperature"), "visc()": MCAttr(float, "force-time/area"),
                "k()": MCAttr(float, "power/length-temperature"), "Pr()": MCAttr(float, "none"),
                "x()": MCAttr(float, "none")}

cdef class FlowState(ABC):
    """FlowState represents the state of a flow at a point by its state properties and a mass flow rate. This class creates a `CoolProp AbstractState <http://www.coolprop.org/apidoc/CoolProp.CoolProp.html>`_ object to store the state properties and uses the routines of CoolProp.

Parameters
----------
fluid : str
    Fluid name passed to CoolProp (see `CoolProp list of fluids <http://www.coolprop.org/fluid_properties/PurePseudoPure.html#list-of-fluids>`_ and/or `REFPROP list of fluids <https://www.nist.gov/srd/refprop>`_ for available fluids).

    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid_name0[mole_fraction0]&fluid_name1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]".

m : float, optional
    Mass flow rate [kg/s]. Defaults to nan.

inputPair : int, optional
    CoolProp input pair key (see `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_). Can be accessed from ``CoolProp.CoolProp`` or ``mcycle.constants``. Eg. HmassP_INPUTS, PT_INPUTS. Defaults to 0 (INPUT_PAIR_INVALID).

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPair [in SI units]. Both default to nan.

iphase : int, optional
    Coolprop key for imposed phase (see `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_). Can be accessed from ``CoolProp.CoolProp`` or ``mcycle.constants``. Eg, ``PHASE_GAS``. Defaults to ``PHASE_NOT_IMPOSED``.

eos : str, optional
    CoolProp EOS backend, must be 'HEOS' or 'REFPROP'. If empty, defaults to ``mcycle.defaults.COOLPROP_EOS``. Defaults to ''.

name : str, optional
    Descriptive name of instance. Defaults to "FlowState instance".

Examples
----------
import mcycle as mc
>>> air = mc.FlowState("Air",1.0,mc.PT_INPUTS,101325,293.15)
>>> air.rho()
1.2045751824931508
>>> air.cp()
1006.144032087035
    """
        
    def __init__(self,
                 str fluid,
                 double m=nan,
                 unsigned char inputPair=0,
                 double input1=nan,
                 double input2=nan,
                 unsigned short iphase=PHASE_NOT_IMPOSED,
                 str eos='',
                 str name="FlowState instance"):
        super().__init__(_inputs, _properties, name)
        self.fluid = fluid
        self.m = m
        self._inputPair = inputPair
        self._input1 = input1
        self._input2 = input2
        self._iphase = iphase
        if eos == '':
            eos = defaults.COOLPROP_EOS
        self.eos = eos
        self._state = None
        #self._canBuildPhaseEnvelope = True

        # determine if pure or mixture
        cdef list fluidSplit, fSplit, moleFractions
        cdef str fluidString, f, msg
        #cdef list moleFractions
        #cdef str f, msg
        #cdef list fSplit
        if "&" not in fluid: # is a pure or pseudo-pure fluid
            self._state = CP.AbstractState(eos, fluid)
            #self._state.change_EOS(0, defaults.COOLPROP_EOS)
        else: # is a mixture
            if not 0 <= iphase < 8:
                msg = "iphase (given: {}) must be specified for mixtures.".format(iphase)
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
            self._state = CP.AbstractState(eos, fluidString)
            #self._state.change_EOS(0, defaults.COOLPROP_EOS)
            self._state.set_mole_fractions(moleFractions)
            self._state.specify_phase(iphase)
            if defaults.TRY_BUILD_PHASE_ENVELOPE:
                try:
                    self._state.build_phase_envelope("")
                except:
                    log("warning", "CoolProp could not build phase envelope for {}".format(fluid))
                    self._canBuildPhaseEnvelope = False
        if inputPair != 0 and not isnan(input1) and not isnan(input2):
            self._state.update(inputPair, input1, input2)
            #self._iphase = PHASE_NOT_IMPOSED #removed any initially imposed phase

    cdef public bint isMixture(self):
        "bool: True if fluid is a mixture, False if fluid is pure or pseudo-pure."
        return '&' in self.fluid
    
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

    cpdef FlowState copyUpdateState(self, unsigned char inputPair, double input1, double input2, unsigned short iphase=PHASE_NOT_IMPOSED):
        """Creates a new copy of a FlowState object. As a shortcut, args can be passed to update the object copy (see update()).

Parameters
----------
inputPair : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPair [in SI units]. Both default to None.
        """
        if inputPair == 0 or isnan(input1) or isnan(input2):
            return FlowState(*self._inputValues())
        else:
            return FlowState(self.fluid, self.m,
                             inputPair, input1, input2, iphase, self.eos, self.name)

    cpdef void updateState(self, unsigned char inputPair, double input1, double input2, unsigned short iphase=PHASE_NOT_IMPOSED) except *:
        """Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPair : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1, input2 : double
    Repective values of inputs corresponding to inputPair [in SI units]. Both default to None.
        """
        if self.isMixture():
            if defaults.TRY_BUILD_PHASE_ENVELOPE and self._canBuildPhaseEnvelope:
                self._state.build_phase_envelope("")
        self._state.specify_phase(iphase)
        self._state.update(inputPair, input1, input2)
        self._inputPair = inputPair
        self._input1 = input1
        self._input2 = input2
        self._iphase = iphase

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
eos = {}
""".format(defaults.RST_HEADINGS[rstHeading] * len(output), self.eos)
        for k, v in self._properties.items():
            output += self.formatAttrForSummary(k, [])
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
        #cdef double x = self._state.Q()
        #if x < 1.+defaults.TOLABS_X and x > -defaults.TOLABS_X:
        if self.phase() == PHASE_TWOPHASE:
            liq = self.copyUpdateState(PQ_INPUTS, self.p(), 0)
            vap = self.copyUpdateState(PQ_INPUTS, self.p(), 1)
            return liq._state.cpmass() + self._state.Q() * (vap._state.cpmass() - liq._state.cpmass())
        else:
            return self._state.cpmass()
    
    cpdef public double Pr(self):
        r"""double: Prandtl number [-].

.. note:: Linear interpolation in 2-phase region is used due to non-continuities in  CoolProp's routines."""
        cdef FlowState liq, vap
        if self.phase() == PHASE_TWOPHASE:
        #if self._state.Q() < 1.+defaults.TOLABS_X and self._state.Q() > -defaults.TOLABS_X:
            liq = self.copyUpdateState(CP.PQ_INPUTS, self.p(), 0)
            vap = self.copyUpdateState(CP.PQ_INPUTS, self.p(), 1)
            return liq._state.Prandtl() + self._state.Q() * (vap._state.Prandtl() - liq._state.Prandtl())
        else:
            return self._state.Prandtl()
    
    cpdef public double V(self):
        r"""double:  Volumetric flow rate [m^3/s]."""
        return self.m / self.rho()
    
    cpdef public double pCrit(self):
        r"""double: Critical pressure [Pa]."""
        #return CP.CoolProp.PropsSI("pcrit", self.fluid)
        return self._state.p_critical()
    
    cpdef public double pMin(self):
        r"""double: Minimum pressure [Pa]."""
        return CP.CoolProp.PropsSI("pmin", "{}::{}".format(self.eos, self.fluid))
    
    cpdef public double pMax(self):
        r"""double: Maximum pressure [Pa]."""
        return self._state.pmax()
    
    cpdef public double TCrit(self):
        r"""double: Critical temperture [K]."""
        #return CP.CoolProp.PropsSI("Tcrit", self.fluid)
        return self._state.T_critical()
    
    cpdef public double TMin(self):
        r"""double: Minimum temperture [K]."""
        return self._state.Tmin() #CP.CoolProp.PropsSI("Tmin", self.fluid)
    
    cpdef public double TMax(self):
        r"""double: Maximum temperture [K]."""
        return self._state.Tmax()
    
    cpdef public unsigned char phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'satLiq':saturated liquid, 'satVap':saturated vapour, 'tp': two-phase liquid/vapour region."""
        cdef FlowState liq
        cdef unsigned short phase
        cdef double tolabs_x = defaults.TOLABS_X
        cdef double x = self._state.Q()
        cdef double pcrit, Tcrit, p, T
        if self.eos == 'HEOS':
            phase = self._state.phase()
            if phase == PHASE_TWOPHASE:
                if -tolabs_x < x < tolabs_x:
                    phase = PHASE_SATURATED_LIQUID
                if 1 - tolabs_x < x < 1 + tolabs_x:
                    phase = PHASE_SATURATED_VAPOUR
            return phase
        else: #eos=='REFPROP'
            pcrit = self._state.p_critical()
            Tcrit = self._state.T_critical()
            p = self._state.p()
            T = self._state.T()
            if -tolabs_x < x < tolabs_x:
                phase = PHASE_SATURATED_LIQUID
            elif 1 - tolabs_x < x < 1 + tolabs_x:
                phase = PHASE_SATURATED_VAPOUR
            elif 0 < x < 1:
                phase = PHASE_TWOPHASE
            elif x == 999:
                pcrit = self._state.p_critical()
                Tcrit = self._state.T_critical()
                p = self._state.p()
                T = self._state.T()
                if p == pcrit and T == Tcrit:
                    phase = PHASE_CRITICAL_POINT
                elif p > pcrit and T > Tcrit:
                    phase = PHASE_SUPERCRITICAL
                else:
                    phase = PHASE_UNKNOWN
            elif x == 998:
                pcrit = self._state.p_critical()
                Tcrit = self._state.T_critical()
                p = self._state.p()
                T = self._state.T()
                if p < pcrit and T > Tcrit:
                    phase = PHASE_SUPERCRITICAL_GAS
                elif p < pcrit and T < Tcrit:
                    phase = PHASE_VAPOUR
                else:
                    phase = PHASE_UNKNOWN
            elif x == -998:
                pcrit = self._state.p_critical()
                Tcrit = self._state.T_critical()
                p = self._state.p()
                T = self._state.T()
                if p > pcrit and T < Tcrit:
                    phase = PHASE_SUPERCRITICAL_LIQUID
                elif p < pcrit and T < Tcrit:
                    phase = PHASE_LIQUID
                else:
                    phase = PHASE_UNKNOWN
            elif x < 0:
                phase = PHASE_LIQUID
            elif x > 1:
                phase = PHASE_VAPOUR
            else:
                msg = "FlowState.phase() could not determine phase."
                log('warning', msg)
                phase = PHASE_UNKNOWN
            return phase

        
#-----------------------------------------
# Start of FlowStatePoly
#-----------------------------------------

"""        
cdef dict _inputsPoly = {"refData": MCAttr(RefData, "none"), "m": MCAttr(float, "mass/time"),
                "_inputPair": MCAttr(int, "none"), "_input1": MCAttr(float, "none"),
                         "_input2": MCAttr(float, "none"), "_iphase": MCAttr(int, 'none'), "eos": MCAttr(str, "none"), "name": MCAttr(str, "none")}
"""
cdef dict _inputsPoly = {"refData": MCAttr(RefData, "none"), "m": MCAttr(float, "mass/time"),
                "_inputPair": MCAttr(int, "none"), "_input1": MCAttr(float, "none"),
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

inputPair : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to INPUT_PAIR_INVALID == 0.

    .. note:: Only certain inputPair values are valid.
        As FlowStatePoly only supports constant pressure flows, one input variable must be a pressure. Thus, only the following inputPair values are valid:

        - CoolProp.PT_INPUTS == 9
        - CoolProp.DmassP_INPUTS == 18
        - CoolProp.HmassP_INPUTS == 20
        - CoolProp.PSmass_INPUTS == 22

input1,input2 : double, optional
    Repective values of inputs corresponding to inputPair [in SI units]. Both default to nan.


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
                 unsigned char inputPair=0,
                 double input1=nan,
                 double input2=nan,
                 #unsigned short iphase=PHASE_NOT_IMPOSED,
                 #str eos='',
                 str name="FlowStatePoly instance"):
        self.refData = refData
        self.fluid = refData.fluid
        self.m = m
        self._inputPair = inputPair
        self._input1 = input1
        self._input2 = input2
        """if eos == '':
            eos = defaults.COOLPROP_EOS"""
        self._iphase = refData._iphase
        self.eos = refData.eos
        self.name = name
        self._c = {}
        self._inputProperty = ''
        self._inputValue = nan
        self._validateInputs()
        self._inputs = _inputsPoly
        self._properties = _propertiesPoly

        
    cpdef FlowState copyUpdateState(self, unsigned char inputPair, double input1, double input2, unsigned short iphase=PHASE_NOT_IMPOSED):
        """Creates a new copy of a FlowState object. As a shortcut, args can be passed to update the object copy (see update()).

Parameters
----------
inputPair : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPair [in SI units]. Both default to None.
        """
        if inputPair == 0 or isnan(input1) or isnan(input2):
            return FlowStatePoly(*self._inputValues())
        else:
            return FlowStatePoly(self.refData, self.m, inputPair, input1, input2)#, iphase, self.eos)
      
    cpdef void updateState(self, unsigned char inputPair, double input1, double input2, unsigned short iphase=PHASE_NOT_IMPOSED) except *:
        """void: Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPair : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1,input2 : double
    Repective values of inputs corresponding to inputPair [in SI units]. One input must be equal to the pressure of refData. Both default to None.
"""
        self._inputPair = inputPair
        self._input1 = input1
        self._input2 = input2
        self._validateInputs()

    cdef void _findAndSetInputProperty(self):
        """str : Return string of input property that is not pressure."""
        self._inputProperty = list(_validInputPairs.keys())[list(_validInputPairs.values()).index(self._inputPair)]
    
    cdef bint _validateInputs(self) except? False:
        """bint: Validate inputs and call _findAndSetInputProperty."""
        if self._inputPair != -1:
            if self._inputPair in _validInputPairs.values():
                if self._inputPair is CP.PT_INPUTS or self._inputPair is CP.PSmass_INPUTS:
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
                Select from PT_INPUTS=9, DmassP_INPUTS=18, HmassP_INPUTS=20, PSmass_INPUTS=22""".format(self._inputPair))
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

    cpdef public unsigned char phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'sp': unknown single-phase."""
        return self.refData._iphase
        """cdef double liq_h = 0
        try:
            liq_h = CP.CoolProp.PropsSI("HMASS", "P", self.refData.p, "Q", 0,
                                        "{}::{}".format(self.refData.eos, self.refData.fluid))
            if self.h() < liq_h:
                return PHASE_LIQUID
            else:
                return PHASE_VAPOUR
        except ValueError as exc:
            log("warning", "FlowStatePoly.phase() could not calculate phase.", exc)
            return PHASE_UNKNOWN"""


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

iphase : int, optional
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to -1.
    """

    def __cinit__(self,
                  str fluid,
                  unsigned short deg,
                  double p,
                  dict data,
                  short iphase=PHASE_NOT_IMPOSED,
                  str eos=''):
        self.fluid = fluid
        self._iphase = iphase
        if eos == '':
            eos = defaults.COOLPROP_EOS
        self.eos = eos
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
            f = FlowState(self.fluid, nan,
                          PT_INPUTS, self.p, T, self._iphase, self.eos)
            for prop in other_props:
                self.data[prop].append(getattr(f, prop)())
