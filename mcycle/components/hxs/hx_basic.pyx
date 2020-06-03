from ...bases.component cimport Component22
from ...bases.config cimport Config
from ...bases.flowstate cimport FlowState
from ...bases.solidmaterial cimport SolidMaterial
from ... import defaults
from ...logger import log
from .hxunit_basic cimport HxUnitBasic
from .flowconfig cimport HxFlowConfig
from ..._constants cimport *
from warnings import warn
from math import nan
import numpy as np
cimport numpy as np
import scipy.optimize as opt

cdef tuple _inputs = ('flowConfig', 'NWf', 'NSf', 'NWall', 'hWf_liq', 'hWf_tp', 'hWf_vap', 'hSf', 'RfWf', 'RfSf', 'wall', 'tWall', 'A', 'ARatioWf', 'ARatioSf', 'ARatioWall', 'efficiencyThermal', 'flowInWf', 'flowInSf', 'flowOutWf', 'flowOutSf', 'ambient', 'sizeAttr', 'sizeBounds', 'sizeUnitsBounds', 'runBounds', 'runUnitsBounds', 'name', 'notes', 'config')
cdef tuple _properties = ('mWf', 'mSf', 'Q()', 'dpWf()', 'dpSf()', 'isEvap()')
        
cdef class HxBasic(Component22):
    r"""Characterises a basic heat exchanger consisting of working fluid and secondary fluid flows separated by a solid wall with single-phase or multi-phase working fluid but only single-phase secondary fluid.

Parameters
----------
flowConfig : HxFlowConfig, optional
    Flow configuration/arrangement information. See :meth:`mcycle.bases.component.HxFlowConfig`.
NWf : int, optional
    Number of parallel working fluid channels [-]. Defaults to 1.
NSf : int, optional
    Number of parallel secondary fluid channels [-]. Defaults to 1.
NWall : int, optional
    Number of parallel walls [-]. Defaults to 1.
hWf_liq : float, optional
    Heat transfer coefficient of the working fluid in the single-phase liquid region (subcooled). Defaults to nan.
hWf_tp : float, optional
    Heat transfer coefficient of the working fluid in the two-phase liquid/vapour region. Defaults to nan.
hWf_vap : float, optional
    Heat transfer coefficient of the working fluid in the single-phase vapour region (superheated). Defaults to nan.
hSf : float, optional
    Heat transfer coefficient of the secondary fluid in a single-phase region. Defaults to nan.
RfWf : float, optional
    Thermal resistance factor due to fouling on the working fluid side [m^2K/W]. Defaults to 0.
RfSf : float, optional
    Thermal resistance factor due to fouling on the secondary fluid side [m^2K/W]. Defaults to 0.
wall : SolidMaterial, optional
    Wall material. Defaults to None.
tWall : float, optional
    Thickness of the wall [m]. Defaults to nan.
A : float, optional
    Heat transfer surface area [m^2]. Defaults to nan.
ARatioWf : float, optional
    Multiplier for the heat transfer surface area of the working fluid [-]. Defaults to 1.
ARatioSf : float, optional
    Multiplier for the heat transfer surface area of the secondary fluid [-]. Defaults to 1.
ARatioWall : float, optional
    Multiplier for the heat transfer surface area of the wall [-]. Defaults to 1.
efficiencyThermal : float, optional
    Thermal efficiency [-]. Defaults to 1.
flowInWf : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
flowInSf : FlowState, optional
    Incoming FlowState of the secondary fluid. Defaults to None.
flowOutWf : FlowState, optional
    Outgoing FlowState of the working fluid. Defaults to None.
flowOutSf : FlowState, optional
    Outgoing FlowState of the secondary fluid. Defaults to None.
ambient : FlowState, optional
    Ambient environment flow state. Defaults to None.
sizeAttr : string, optional
    Default attribute used by size(). Defaults to ''.
sizeBounds : list len=2, optional
    Bracket containing solution of size(). Defaults to []. (Passed to scipy.optimize.brentq as ``bounds`` argument)
sizeUnitsBounds : list len=2, optional
    Bracket containing solution of sizeUnits(). Defaults to []. (Passed to scipy.optimize.brentq as ``bounds`` argument)
runBounds : list len=2, optional
    Bracket containing value of :meth:`TOLATTR <mcycle.defaults.TOLATTR>` for the outgoing working fluid FlowState. Defaults to [nan, nan]. 
runUnitsBounds : list len=2, optional
    Bracket containing value of :meth:`TOLATTR <mcycle.defaults.TOLATTR>` for the outgoing working fluid FlowState when ``run()`` method of component units is called. Defaults to [nan, nan]. 
name : string, optional
    Description of object. Defaults to "HxBasic instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults "no notes".
config : Config, optional
    Configuration parameters. Defaults to None which sets it to :meth:`defaults.CONFIG <mcycle.defaults.CONFIG>`.
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 unsigned int NWf=1,
                 unsigned int NSf=1,
                 unsigned int NWall=1,
                 double hWf_liq=nan,
                 double hWf_tp=nan,
                 double hWf_vap=nan,
                 double hSf=nan,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial wall=None,
                 double tWall=nan,
                 double A=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioWall=1,
                 double efficiencyThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[1, 100],
                 list sizeUnitsBounds=[1e-5, 1.],
                 runBounds=[nan, nan],
                 runUnitsBounds=[nan, nan],
                 str name="HxBasic instance",
                 str notes="No notes/model info.",
                 Config config=None,
                 _unitClass=HxUnitBasic):
        self.flowConfig = flowConfig
        self.NWf = NWf
        self.NSf = NSf
        self.NWall = NWall
        self.hWf_liq = hWf_liq
        self.hWf_tp = hWf_tp
        self.hWf_vap = hWf_vap
        self.hSf = hSf
        self.RfWf = RfWf
        self.RfSf = RfSf
        self.wall = wall
        self.tWall = tWall
        self.A = A
        self.ARatioWf = ARatioWf
        self.ARatioSf = ARatioSf
        self.ARatioWall = ARatioWall
        self.efficiencyThermal = efficiencyThermal
        super().__init__(flowInWf, flowInSf, flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, runUnitsBounds, name, notes, config)
        self._units = []
        self._unitClass = _unitClass
        self._inputs = _inputs
        self._properties = _properties
        
    cpdef public void update(self, dict kwargs):
        """Update (multiple) variables using keyword arguments."""
        cdef HxUnitBasic unit
        cdef str key, keyBase
        for key, value in kwargs.items():
            if '.' in key:
                keyBase = key.split('.', 1)[0]
            else:
                keyBase = key
            if keyBase not in [
                    "L", "flowInWf", "flowInSf", "flowOutWf", "flowOutSf", "sizeBounds", "sizeUnitsBounds", "sizeAttr"]:
                super(Component22, self).update({key: value})
                for unit in self._units:
                    unit.update({key: value})
            elif key == "sizeUnitsBounds":
                super(Component22, self).update({key: value})
                for unit in self._units:
                    unit.update({'sizeBounds': value})
            else:
                super(Component22, self).update({key: value})
                        
    cpdef public double _A(self):
        return self.A

    cpdef public bint isEvap(self):
        """bool: True if the Hx is an evaporator; heat transfer from secondary fluid to working fluid."""
        if self.flowsIn[1].T() > self.flowsIn[0].T():
            return True
        else:
            return False

    cpdef public unsigned int _NWf(self):
        return self.NWf

    cpdef public unsigned int _NSf(self):
        return self.NSf


    cpdef public double _hWf(self):
        return self.hWf

    cpdef public double _hSf(self):
        return self.hSf
    
    cpdef public double _efficiencyFactorWf(self):
        if self.isEvap():
            return 1
        else:
            return self.efficiencyThermal

    cpdef public double _efficiencyFactorSf(self):
        if not self.isEvap():
            return 1
        else:
            return self.efficiencyThermal

    cpdef public double dpWf(self):
        return 0
    
    cpdef public double dpSf(self):
        return 0

    cdef public double _QWf(self):
        """float: Heat transfer to the working fluid [W]."""
        if abs(self.flowsOut[0].h() - self.flowsIn[0].h()) > self.config.tolAbs:
            return (self.flowsOut[0].h() - self.flowsIn[0].h()
                    ) * self._mWf() * self._efficiencyFactorWf()
        else:
            return 0

    cdef public double _QSf(self):
        """float: Heat transfer to the secondary fluid [W]."""
        if abs(self.flowsOut[1].h() - self.flowsIn[1].h()) > self.config.tolAbs:
            return (self.flowsOut[1].h() - self.flowsIn[1].h()
                    ) * self._mSf() * self._efficiencyFactorSf()
        else:
            return 0

    cpdef public double Q(self):
        """float: Heat transfer to the working fluid from the secondary fluid [W]."""
        cdef str err_msg
        cdef double qWf = self._QWf()
        cdef double qSf = self._QSf()
        cdef double tolAbs = self.config.tolAbs
        if abs(qWf) < tolAbs and abs(qSf) < tolAbs:
            return 0
        elif abs((qWf + qSf) / (qWf)) < self.config.tolRel:
            return qWf
        else:
            msg = """{}.Q(), QWf*{}={},QSf*{}={}. Check efficiencyThermal={} is correct.""".format(self.__class__.__name__,
            self._efficiencyFactorWf(), qWf, self._efficiencyFactorSf(), qSf,
            self.efficiencyThermal)
            log("error", msg)
            warn(msg)
            return qWf

    cpdef public double mass(self):
        """float: Estimate of mass [kg], based purely on wall properties."""
        cdef HxUnitBasic unit
        cdef double w8 = 0
        for unit in self._units:
            w8 += unit.mass()
        return w8


    cdef bint _checkContinuous(self):
        cdef int i
        cdef bint ifbool = True
        for i in range(1, len(self._units)):
            if self._units[i].flowsIn[0] != self._units[i - 1].flowsOut[0]:
                ifbool = False
        #if all(self._units[i].flowsIn[0] == self._units[i - 1].flowsOut[0] for i in range(1, len(self._units))):
        if ifbool:
            if self.flowConfig.sense == COUNTERFLOW and all(
                    self._units[i].flowsOut[1] == self._units[i - 1].flowsIn[1]
                    for i in range(1, len(self._units))):
                return True
            elif self.flowConfig.sense == PARALLELFLOW and all(
                    self._units[i].flowsIn[1] == self._units[i - 1].flowsOut[1]
                    for i in range(1, len(self._units))):
                return True
            else:
                return False
        else:
            return False

    cpdef public void run(self) except *:
        """Abstract method: must be defined by subclasses."""
        pass


    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to single-phase liquid HxUnits in unitise()."""
        return (self.flowConfig, self.NWf, self.NSf, self.NWall,
                self.hWf_liq, self.hSf, self.RfWf, self.RfSf, self.wall,
                self.tWall, nan, self.ARatioWf, self.ARatioSf,
                self.ARatioWall, self.efficiencyThermal)

    cdef public tuple _unitArgsTp(self):
        """Arguments passed to two-phase HxUnits in unitise()."""
        return (self.flowConfig, self.NWf, self.NSf, self.NWall, self.hWf_tp,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, nan,
                self.ARatioWf, self.ARatioSf, self.ARatioWall, self.efficiencyThermal)

    cdef public tuple _unitArgsVap(self):
        """Arguments passed to single-phase vapour HxUnits in unitise()."""
        return (self.flowConfig, self.NWf, self.NSf, self.NWall, self.hWf_vap,
                self.hSf, self.RfWf, self.RfSf, self.wall, self.tWall, nan,
                self.ARatioWf, self.ARatioSf, self.ARatioWall, self.efficiencyThermal)

    cdef public void _unitiseExtra(self):
        pass

    cpdef public void unitise(self):
        """Divides the Hx into HxUnits according to divT and divX defined in the configuration parameters, for calculating accurate heat transfer properties."""
        self._units = []
        _unitClass = self._unitClass
        cdef:
            list _units = []
            FlowState inWf = self.flowsIn[0].copy()
            FlowState outWf = self.flowsOut[0].copy()
            FlowState inSf = self.flowsIn[1].copy()
            FlowState outSf = self.flowsOut[1].copy()
            FlowState liqWf = self.flowsIn[0].copyUpdateState(PQ_INPUTS, self.flowsIn[0].p(), 0)
            FlowState vapWf = self.flowsIn[0].copyUpdateState(PQ_INPUTS, self.flowsIn[0].p(), 1)
            FlowState leftWf = None
            FlowState leftSf = None
            FlowState rightWf = None
            FlowState rightSf = None
            FlowState endLeftWf = None
            FlowState endLeftSf = None
            FlowState endRightWf = None
            FlowState endRightSf = None
            FlowState leftNodeWf, rightNodeWf, leftNodeSf, rightNodeSf
            double liqWf_h = liqWf.h()
            double vapWf_h = vapWf.h()
            double pWf = self.flowsIn[0].p()
            double pSf = self.flowsIn[1].p()
            double mWf = self._mWf()
            double mSf = self._mSf()
            double effWf = self._efficiencyFactorWf()
            double effSf = self._efficiencyFactorSf()
            double senseFactorSf, hFactorSf, hRightSf, endLeftWf_h, endRightWf_h, endLeftSf_h, endRightSf_h
            double[:] hNodesWf, hNodesSf
            unsigned int i, nodesSection, nodesTotal = 0
            unsigned char sense = self.flowConfig.sense
            bint endFound = False 
            bint skipSection = False
            bint isEvap = self.isEvap()
            str leftKeyWf, rightKeyWf, leftKeySf, rightKeySf
        # Assign flow ends
        if isEvap:
            leftWf = inWf
            endLeftWf = inWf
            endRightWf = outWf
            leftKeyWf = "flowInWf"
            rightKeyWf = "flowOutWf"
            if sense == PARALLELFLOW:
                leftSf = inSf
                endLeftSf = inSf
                endRightSf = outSf
                senseFactorSf = -1
                leftKeySf = "flowInSf"
                rightKeySf = "flowOutSf"
            else:
                leftSf = outSf
                endLeftSf = outSf
                endRightSf = inSf
                senseFactorSf = 1
                leftKeySf = "flowOutSf"
                rightKeySf = "flowInSf"
        else:
            leftWf = outWf
            endLeftWf = outWf
            endRightWf = inWf
            leftKeyWf = "flowOutWf"
            rightKeyWf = "flowInWf"
            if sense == PARALLELFLOW:
                leftSf = outSf
                endLeftSf = outSf
                endRightSf = inSf
                senseFactorSf = -1
                leftKeySf = "flowOutSf"
                rightKeySf = "flowInSf"
            else:
                leftSf = inSf
                endLeftSf = inSf
                endRightSf = outSf
                senseFactorSf = 1
                leftKeySf = "flowInSf"
                rightKeySf = "flowOutSf"
        hFactorSf = senseFactorSf * mWf * effWf / mSf / effSf
        endLeftWf_h = endLeftWf.h()
        endLeftSf_h = endLeftSf.h()
        endRightWf_h = endRightWf.h()
        endRightSf_h = endRightSf.h()

        # Section A
        #if not endFound and leftWf.phase() == PHASE_LIQUID:
        if not endFound and endLeftWf_h < liqWf_h and endLeftWf.x() < TOLABS_X:
            skipSection = False
            if endRightWf_h > liqWf_h:
                rightWf = liqWf
                hRightSf = leftSf.h() + hFactorSf * (liqWf_h - leftWf.h())
                rightSf = inSf.copyUpdateState(HmassP_INPUTS, hRightSf, pSf)
            else:
                endFound = True
                rightWf = endRightWf
                rightSf = endRightSf
        else:
            skipSection = True
        #
        if not skipSection:
            nodesSection = int(np.ceil((rightWf.T() - leftWf.T()) / self.config.divT)) + 1
            hNodesWf = np.linspace(leftWf.h(), rightWf.h(), nodesSection, True)
            hNodesSf = np.linspace(leftSf.h(), rightSf.h(), nodesSection, True)
            for i in range(nodesSection - 1):
                leftNodeWf = inWf.copyUpdateState(HmassP_INPUTS, hNodesWf[i], pWf)
                leftNodeSf = inSf.copyUpdateState(HmassP_INPUTS, hNodesSf[i], pSf)
                rightNodeWf = inWf.copyUpdateState(HmassP_INPUTS, hNodesWf[i+1], pWf)
                rightNodeSf = inSf.copyUpdateState(HmassP_INPUTS, hNodesSf[i+1], pSf)
                unit = _unitClass(
                    *self._unitArgsLiq(),
                    **{leftKeyWf: leftNodeWf},
                    **{rightKeyWf: rightNodeWf},
                    **{leftKeySf: leftNodeSf},
                    **{rightKeySf: rightNodeSf},
                    sizeBounds=self.sizeUnitsBounds,
                    config=self.config) 
                _units.append(unit)   
            nodesTotal += nodesSection-1
            leftWf = rightWf
            leftSf = rightSf
        # Section B
        #if not endFound and leftWf.phase() in [PHASE_SATURATED LIQUID, PHASE_TWOPHASE]:
        if not endFound and leftWf.h() < vapWf_h:
            skipSection = False
            if endRightWf_h > vapWf_h:
                rightWf = vapWf
                hRightSf = leftSf.h() + hFactorSf * (vapWf_h - leftWf.h())
                rightSf = inSf.copyUpdateState(HmassP_INPUTS, hRightSf, pSf)
            else:
                endFound = True
                rightWf = endRightWf
                rightSf = endRightSf
        else:
            skipSection = True
        #
        if not skipSection:
            nodesSection = int(np.ceil((rightWf.x() - leftWf.x()) / self.config.divX)) + 1
            hNodesWf = np.linspace(leftWf.h(), rightWf.h(), nodesSection, True)
            hNodesSf = np.linspace(leftSf.h(), rightSf.h(), nodesSection, True)
            for i in range(nodesSection - 1):
                leftNodeWf = inWf.copyUpdateState(HmassP_INPUTS, hNodesWf[i], pWf)
                leftNodeSf = inSf.copyUpdateState(HmassP_INPUTS, hNodesSf[i], pSf)
                rightNodeWf = inWf.copyUpdateState(HmassP_INPUTS, hNodesWf[i+1], pWf)
                rightNodeSf = inSf.copyUpdateState(HmassP_INPUTS, hNodesSf[i+1], pSf)
                unit = _unitClass(
                    *self._unitArgsTp(),
                    **{leftKeyWf: leftNodeWf},
                    **{rightKeyWf: rightNodeWf},
                    **{leftKeySf: leftNodeSf},
                    **{rightKeySf: rightNodeSf},
                    sizeBounds=self.sizeUnitsBounds,
                    config=self.config)  
                _units.append(unit)   
            nodesTotal += nodesSection-1
            leftWf = rightWf
            leftSf = rightSf
        # Section C
        #if endFound is False and leftWf.phase() in [PHASE_SATURATED VAPOUR, PHASE_GAS, PHASE_SUPERCRITICAL_GAS]:
        if not endFound:# and (leftWf.h() - vapWf_h) / vapWf_h >= self.config._tolRel_h or (1 - leftWf.x()) < TOLABS_X:
            skipSection = False
            endFound = True
            rightWf = endRightWf
            rightSf = endRightSf
        else:
            skipSection = True
        if not skipSection:# and (endRightWf.h() - vapWf_h) / vapWf_h >= self.config._tolRel_h:
            nodesSection = int(np.ceil((rightWf.T() - leftWf.T()) / self.config.divT)) + 1
            hNodesWf = np.linspace(leftWf.h(), rightWf.h(), nodesSection, True)
            hNodesSf = np.linspace(leftSf.h(), rightSf.h(), nodesSection, True)
            for i in range(nodesSection - 1):
                leftNodeWf = inWf.copyUpdateState(HmassP_INPUTS, hNodesWf[i], pWf)
                leftNodeSf = inSf.copyUpdateState(HmassP_INPUTS, hNodesSf[i], pSf)
                rightNodeWf = inWf.copyUpdateState(HmassP_INPUTS, hNodesWf[i+1], pWf)
                rightNodeSf = inSf.copyUpdateState(HmassP_INPUTS, hNodesSf[i+1], pSf)
                unit = _unitClass(
                    *self._unitArgsVap(),
                    **{leftKeyWf: leftNodeWf},
                    **{rightKeyWf: rightNodeWf},
                    **{leftKeySf: leftNodeSf},
                    **{rightKeySf: rightNodeSf},
                    sizeBounds=self.sizeUnitsBounds,
                    config=self.config)  
                _units.append(unit)       
            nodesTotal += nodesSection - 1
        if nodesTotal == 0:
            msg = "HxBasic.unitise(): Entire HX has been skipped, check phases of the working fluid; must not be supercritical liquid or at supercritical point"
            log('error', msg)
            raise ValueError(msg)
        else:
            if isEvap:
                self._units = _units
            else:
                _units.reverse()
                self._units = _units
            self._unitiseExtra()

        
    cpdef double _f_sizeHxBasic(self, double value, str attr):
        self.update({attr: value})
        A_units = 0.
        for unit in self._units:
            unit.sizeUnits()
            A_units += unit.A
        return A_units - self._A()
                
    cpdef public void size(self) except *:
        """Solves for the value of the nominated component attribute required to return the defined outgoing FlowState.
        """
        cdef double hOutSf, A_unitstol
        cdef HxUnitBasic unit
        cdef str attr = self.sizeAttr
        try:
            if attr == "A":
                self.unitise()
                A_units = 0.
                for unit in self._units:
                    unit.sizeUnits()
                    A_units += unit._A()
                self.A = A_units
                # return self._A()
            elif attr == "flowOutSf":
                hOutSf = self.flowsIn[1].h() + (
                    self.flowsIn[0].h() - self.flowsOut[0].h()
                ) * self._mWf() * self._efficiencyFactorWf() / self._mSf() / self._efficiencyFactorSf()
                self.flowsOut[1] = self.flowsIn[1].copyUpdateState(HmassP_INPUTS, hOutSf,
                                                    self.flowsIn[1].p())
                self.unitise()
                # return self.flowsOut[1]
            else:
                self.unitise()

                tol = self.config.tolAbs + self.config.tolRel * abs(self.Q())
                sizedValue = opt.brentq(
                        self._f_sizeHxBasic,
                        *self.sizeBounds,
                        args=(attr),
                        rtol=self.config.tolRel,
                        xtol=self.config.tolAbs)
                self.update({attr, sizedValue})
                #return sizedValue
        except Exception as exc:
            msg = 'HxBasic.size(): failed to converge.'
            log('error', msg, exc)
            raise exc
        
    @property
    def hWf(self):
        """float: Average of hWf_liq, hWf_tp & hWf_vap.
        Setter makes all equal to desired value."""
        return (self.hWf_liq + self.hWf_tp + self.hWf_vap) / 3

    @hWf.setter
    def hWf(self, value):
        self.hWf_liq = value
        self.hWf_tp = value
        self.hWf_vap = value

    @property
    def hWf_sp(self):
        """float: Average of hWf_liq & hWf_vap.
        Setter makes both equal to desired value."""
        return (self.hWf_liq + self.hWf_vap) / 2

    @hWf_sp.setter
    def hWf_sp(self, value):
        self.hWf_liq = value
        self.hWf_vap = value

    @property
    def Rf(self):
        """float: Average of RfWf & RfSf.
        Setter makes both equal to desired value."""
        return (self.RfWf + self.RfSf) / 2

    @Rf.setter
    def Rf(self, value):
        self.RfWf = value
        self.RfSf = value

