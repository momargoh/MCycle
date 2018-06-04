import unittest
import mcycle as mc
import CoolProp as CP


class TestHxUnitBasic(unittest.TestCase):
    hxUnit = mc.HxUnitBasic(flowSense="counterflow")

    def test_phaseWf_tpEvap_with_x_0(self):
        flowInWf = mc.FlowState("R123", -1, -1, CP.PQ_INPUTS, 1000000., 0)
        flowOutWf = mc.FlowState("R123", -1, -1, CP.PQ_INPUTS, 1000000., 0.3)
        self.hxUnit.update({'flowInWf': flowInWf, 'flowOutWf': flowOutWf})
        self.assertEqual(self.hxUnit.phaseWf(), "tpEvap")

    def test_phaseWf_tpCond_with_x_0(self):
        flowInWf = mc.FlowState("R123", -1, -1, CP.PQ_INPUTS, 1000000., 0.6)
        flowOutWf = mc.FlowState("R123", -1, -1, CP.PQ_INPUTS, 1000000., 0)
        self.hxUnit.update({'flowInWf': flowInWf, 'flowOutWf': flowOutWf})
        self.assertEqual(self.hxUnit.phaseWf(), "tpCond")

    def test_accept_FlowStatePoly(self):
        refData = mc.RefData("air", 2, 101325.,
                             {'T': [200, 250, 300, 350, 400]})
        flow = mc.FlowStatePoly(refData, 1.0, CP.PT_INPUTS, 101325., 293.15)
        self.hxUnit.update({'flowInSf': flow})


if __name__ == "__main__":
    unittest.main()
