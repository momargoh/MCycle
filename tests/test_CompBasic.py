import unittest
import mcycle as mc
import CoolProp as CP


class TestCompBasic(unittest.TestCase):
    flowIn = mc.FlowState("air", "HEOS", None, 9.5, CP.PT_INPUTS, 110000., 300)
    comp = mc.CompBasic(5, 1.0, flowIn)

    def test_CompBasic_run(self):
        self.comp.update(pRatio=5, effIsentropic=1.)
        self.comp.run()
        self.assertAlmostEqual(self.comp.flowOut.T, 473.80, 2)
        self.assertAlmostEqual(self.comp.P_in / 1000, 1671.12, 2)

    def test_CompBasic_solve_effIsentropic(self):
        flowOut = mc.FlowState("air", "HEOS", None, None, CP.PT_INPUTS,
                               550000., 520)
        self.comp.update(flowOut=flowOut, m=9.5)
        self.comp.solve("effIsentropic", [0.5, 0.9])
        self.assertAlmostEqual(self.comp.effIsentropic, 0.787, 3)

    def test_CompBasic_solve_pRatio(self):
        flowOut = mc.FlowState("air", "HEOS", None, None, CP.PT_INPUTS,
                               550000., 473.80)
        self.comp.update(flowOut=flowOut, pRatio=None, m=9.5)
        self.comp.solve("pRatio", [4, 8])
        self.assertAlmostEqual(self.comp.pRatio, 5., 5)


if __name__ == "__main__":
    unittest.main()
