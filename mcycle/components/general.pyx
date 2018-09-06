from ..bases.component cimport Component11
from ..bases.config cimport Config
from ..bases.flowstate cimport FlowState
from ..bases.mcabstractbase cimport MCAttr
from ..logger import log
from math import nan, isnan
import CoolProp as CP


cdef class FixedOut(Component11):
    r"""Fixed outgoing working fluid flowstate.

Parameters
-----------
inputPairCP : int, optional
    CoolProp input pair key. See `documentation <http://www.coolprop.org/_static/doxygen/html/namespace_cool_prop.html#a58e7d98861406dedb48e07f551a61efb>`_. Eg. CoolProp.HmassP_INPUTS. Defaults to 0 (INPUT_PAIR_INVALID).

input1, input2 : double, optional
    Repective values of inputs corresponding to inputPairCP [in SI units]. Both default to nan.
flowIn : FlowState, optional
    Incoming FlowState of the working fluid. Defaults to None.
name : string, optional
    Description of component. Defaults to "FixedOut instance".
notes : string, optional
    Additional notes on the component such as model numbers. Defaults to "No notes/model info.".
config : Config, optional
    Configuration parameters. Defaults to the default Config object.

Properties
-----------
flowOut : FlowState, optional
    Outgoing FlowState of the working fluid.
    """
    
    def __init__(self,
                 inputPairCP,
                 double input1,
                 double input2,
                 FlowState flowIn=None,
                 str name="FixedOut instance",
                 str  notes="No notes/model info.",
                 Config config=Config()):
        super().__init__(flowIn, None, name=name, notes=notes, config=config)
        self.inputPairCP = inputPairCP
        self.input1 = input1
        self.input2 = input2
        self._inputs = {"inputPairCP": MCAttr(int, "none"),
                        "input1": MCAttr(float, "none"), "input2": MCAttr(float, "none"), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
        self._properties = {"m": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "dp()": MCAttr( "pressure")}
        self.run()

    cpdef public void run(self):
        """Compute outgoing FlowState from component attributes."""
        if self.inputPairCP == CP.INPUT_PAIR_INVALID or isnan(self.input1) or isnan(self.input2):
            msg = "FixedOut.run(): inputPairCP, input1 and input2 attributes must all be defined (given: inputPairCP={}, input1={}, input2={})".format(self.inputPairCP, self.input1, self.input2)
            log("error", msg)
            raise ValueError(msg)
        else:
            self.flowsOut[0] = self.flowsIn[0].copyState(self.inputPairCP, self.input1, self.input2)

    cpdef public void _size(self, str attr, list bounds, list unitsBounds) except *:
        log("info", "FixedOut component cannot be sized, hence _size() method is skipped")
        pass
    
    cpdef public double Q(self):
        return self.flowsIn[0].m * (self.flowsOut[0].h() - self.flowsIn[0].h())
    
    cpdef public double dp(self):
        return self.flowsIn[0].m * (self.flowsOut[0].p() - self.flowsIn[0].p())
    
    cpdef public double dpWf(self):
        return self.dp()
