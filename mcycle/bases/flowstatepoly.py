from .flowstate import FlowState
import CoolProp as CP
import numpy as np


class FlowStatePoly(FlowState):
    """FlowStatePoly represents the state of a flow at a point by its state properties and a mass flow rate. It is an alternative to FlowState that uses polynomial interpolation of a crude constant pressure reference data map to evaluate the state properties, instead of calling them from a CoolProp AbstractState object. This class was created purely to overcome short comings with CoolProp's mixture processes. Apart from creating new objects, FlowStatePoly has been built to be used in exactly the same way as FlowState.

.. note:: FlowStatePoly only supports constant pressure flows and assumes no phase changes occur.
   It may not be used for the working fluid in a cycle, but may be used as the working fluid in certain constant pressure components.

Parameters
----------
refData : RefData
    Constant pressure fluid reference data map.

m : float, optional
    Mass flow rate [Kg/s]. Defaults to None.

inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

    .. note:: Only certain inputPairCP values are valid.
        As FlowStatePoly only supports constant pressure flows, one input variable must be a pressure. Thus, only the following inputPairCP values are valid:

        - CoolProp.PT_INPUTS == 9
        - CoolProp.DmassP_INPUTS == 18
        - CoolProp.HmassP_INPUTS == 20
        - CoolProp.PSmass_INPUTS == 22

input1,input2 : float, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to None.


Examples
----------
>>> refData = RefData("air", 2, 101325., [200, 250, 300, 350, 400])
>>> air = FlowStatePoly(refData, 1, CoolProp.PT_INPUTS,101325.,293.15)
>>> air.rho
1.20530995019
>>> air.cp
1006.12622976
    """
    inputId = [9, 20, 18, 22]  # [T, Hmass, Dmass, Smass]

    def __init__(self,
                 refData,
                 m=None,
                 inputPairCP=None,
                 input1=None,
                 input2=None):
        self.refData = refData
        self.m = m
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self._c = []
        self._inputVal = None
        try:
            self._valid_inputs()
        except TypeError:  # no inputs given
            pass

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor"""
        return (("refData", "none"), ("m", "mass/time"),
                ("_inputPairCP", "none"), ("_input1", "none"),
                ("_input2", "none"))

    def copy(self, inputPairCP=None, input1=None, input2=None):
        """Creates a new copy of a FlowStatePoly object. As a shortcut, args can be passed to update the object copy (see update()).

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to None.

input1,input2 : float, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. One input must be equal to the pressure of refData. Both default to None.
"""
        if all(i is not None for i in [inputPairCP, input1, input2]):
            return FlowStatePoly(self.refData, self.m, inputPairCP, input1,
                                 input2)
        else:
            return FlowStatePoly(self.refData, self.m, self._inputPairCP,
                                 self._input1, self._input2)

    def update(self, inputPairCP, input1, input2):
        """Calls CoolProp's AbstractState.update function.

Parameters
----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS.

input1,input2 : float
    Repective values of inputs corresponding to inputPairCP [in SI units]. One input must be equal to the pressure of refData. Both default to None.
"""
        self._inputPairCP = inputPairCP
        self._input1 = input1
        self._input2 = input2
        self._valid_inputs()

    def _valid_inputs(self):
        if self._inputPairCP:
            if self._inputPairCP in self.inputId:
                if self._inputPairCP is 9 and self._input1 == self.refData.p:
                    self._inputVal = self._input2
                    self._populate_c()
                elif self._inputPairCP is 9 and self._input1 != self.refData.p:
                    raise ValueError(
                        """input pressure does not match reference data pressure: {0} /= {1}""".
                        format(self._input1, self.refData.p))
                elif self._input2 == self.refData.p:
                    self._inputVal = self._input1
                    self._populate_c()
                else:
                    raise ValueError(
                        "input pressure does not match reference data pressure: {0} /= {1}".
                        format(self._input2, self.refdata.p))
                return True
            else:
                raise ValueError(
                    """{0} is not a valid input pair ID for FlowStatePoly
                Select from 9, 19, 20, 22""".format(self._inputPairCP))
        else:
            raise TypeError("No inputPairCP given")

    def _populate_c(self):
        self._c = []
        for i in range(len(self.refData.data)):
            self._c.append(
                list(
                    np.polyfit(self.refData.
                               data[self.inputId.index(self._inputPairCP)],
                               self.refData.data[i], self.refData.deg)))

    @property
    def fluid(self):
        """Description of fluid passed to CoolProp.
    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid0[mole_fraction0]&fluid1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]"."""
        return self.refData.fluid

    @property
    def phaseCP(self):
        """Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_."""
        return self.refData.phaseCP

    @property
    def lib(self):
        """str: Library used by CoolProp routines. Must be "HEOS" or "REFPROP"."""
        return self.refData.lib

    @property
    def p(self):
        """float: Static pressure [Pa]."""
        return self.refData.p

    @property
    def T(self):
        "float: Static temperture [K]."
        return np.polyval(self._c[0], self._inputVal)

    @property
    def h(self):
        """float: Specific mass enthalpy [J/Kg]."""
        return np.polyval(self._c[1], self._inputVal)

    @property
    def rho(self):
        """float: Mass density [Kg/m^3]."""
        return np.polyval(self._c[2], self._inputVal)

    @property
    def s(self):
        """float: Specific mass entropy [J/Kg.K]."""
        return np.polyval(self._c[3], self._inputVal)

    @property
    def visc(self):
        """float: Dynamic viscosity [N.s/m^2]."""
        return np.polyval(self._c[4], self._inputVal)

    @property
    def k(self):
        """float: Thermal conductivity [W/m.K]."""
        return np.polyval(self._c[5], self._inputVal)

    @property
    def cp(self):
        """float: Specific mass heat capacity, const. pressure [J/K]."""
        return np.polyval(self._c[6], self._inputVal)

    @property
    def Pr(self):
        """float: Prandtl number [-]."""
        return np.polyval(self._c[7], self._inputVal)

    @property
    def x(self):
        """float: Quality [-]. By definition, x = -1 for all FlowStatePoly objects."""
        return -1

    @property
    def phase(self):
        """str: identifier of phase; 'liq':subcooled liquid, 'vap':superheated vapour, 'sp': unknown single-phase."""
        try:
            liq_h = CP.CoolProp.PropsSI("HMASS", "P", self.p, "Q", 0,
                                        self.fluid)
            if self.h < liq_h:
                return "liq"
            else:
                return "vap"
        except ValueError:
            return "sp"


class RefData:
    """RefData stores constant pressure thermodynamic properties of a 'pure' fluid or mixture thereof. Property data can be directly input, or if only temperature data is provided, RefData will call CoolProp to compute the remaining properties.

Parameters
----------
fluid : string
    Description of fluid passed to CoolProp.
    - "fluid_name" for pure fluid. Eg, "air", "water", "CO2" *or*

    - "fluid0[mole_fraction0]&fluid1[mole_fraction1]&..." for mixtures. Eg, "CO2[0.5]&CO[0.5]".

.. note:: CoolProp's mixture routines often raise errors; using mixtures should be avoided.


deg : int
    Polynomial degree used to interpolate the data.

p: float
    Constant static pressure [Pa] of the property data.

TData : list of float
    Static temperature [K] values of the property data.

hData : list of float, optional
    Specific mass enthalpy [J/Kg] values of the property data.

rhoData : list of float, optional
    Mass density [Kg/m^3] values of the property data.

sData : list of float, optional
    Specific mass entropy [J/Kg.K] values of the property data.

viscData : list of float, optional
    Dynamic viscosity [N.s/m^2] values of the property data.

kData : list of float, optional
    Thermal conductivity [W/m.K]Temperature values of the property data.

cpData : list of float, optional
    Specific mass heat capacity, const. pressure [J/K] values of the property data.

PrData : list of float, optional
    Prandtl number values of the property data.

lib : string, optional
    Library used by CoolProp routines. Must be "HEOS" or "REFPROP". Defaults to "HEOS".

phaseCP : int, optional
    Coolprop key for phase. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a99d892f7b3bb9808265335ac1efb858f>`_. Eg, CoolProp.iphase_gas. Defaults to None.
    """

    def __init__(self,
                 fluid,
                 deg,
                 p,
                 TData,
                 hData=None,
                 rhoData=None,
                 sData=None,
                 viscData=None,
                 kData=None,
                 cpData=None,
                 PrData=None,
                 lib="HEOS",
                 phaseCP=None):
        self.fluid = fluid
        self.lib = lib
        self.phaseCP = phaseCP
        self.deg = deg
        self.p = p
        self.TData = TData
        other_data = [hData, rhoData, sData, viscData, kData, cpData, PrData]
        if all(i is None for i in other_data):
            self.populateData()
        elif not all(len(l) == len(self.TData) for l in other_data):
            raise ValueError(
                'Not all data lists have same length as TData. len={0}'.format(
                    len(self.TData)))
        elif all(len(l) == len(self.TData) for l in other_data):
            self.hData = hData
            self.rhoData = rhoData
            self.sData = sData
            self.viscData = viscData
            self.kData = kData
            self.cpData = cpData
            self.PrData = PrData

    @property
    def data(self):
        """Organised tuple of the reference data."""
        return (self.TData, self.hData, self.rhoData, self.sData,
                self.viscData, self.kData, self.cpData, self.PrData)

    def populateData(self, TData=None):
        """Compute remaining properties using CoolProp."""
        if TData is not None:
            self.TData = TData
        self.rhoData, self.hData, self.sData, self.viscData, self.kData, self.cpData, self.PrData = [], [], [], [], [], [], []
        for T in self.TData:
            f = FlowState(self.fluid, self.lib, self.phaseCP, None,
                          CP.PT_INPUTS, self.p, T)
            self.rhoData.append(f.rho)
            self.hData.append(f.h)
            self.sData.append(f.s)
            self.viscData.append(f.visc)
            self.kData.append(f.k)
            self.cpData.append(f.cp)
            self.PrData.append(f.Pr)
