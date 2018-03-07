import unittest
import mcycle as mc
import CoolProp as CP


class TestExpBasic(unittest.TestCase):
    def test_ExpBasic_run(self):
        flowIn = mc.FlowState("water", "HEOS", None, 10., CP.PT_INPUTS, 3.e6,
                              mc.degC2K(500))
        exp = mc.ExpBasic(6, 0.8, flowIn)
        exp.run()
        self.assertAlmostEqual(exp.flowOut.T, 563.74, 2)
        self.assertAlmostEqual(exp.P_out / 1000, 4121.11, 2)

    def test_ExpBasic_solve_effIsentropic(self):
        flowIn = mc.FlowState("water", "HEOS", None, None, CP.PT_INPUTS, 2.e6,
                              mc.degC2K(350))
        flowOut = mc.FlowState("water", "HEOS", None, None, CP.PQ_INPUTS,
                               50000., 1)

        exp = mc.ExpBasic(40, 1.0, flowIn, flowOut, m=1.0)
        exp.solve("effIsentropic", [0.5, 0.8])
        self.assertAlmostEqual(exp.effIsentropic, 0.686, 3)

    def test_ExpBasic_solve_pRatio(self):
        flowIn = mc.FlowState("water", "HEOS", None, None, CP.PT_INPUTS, 2.e6,
                              mc.degC2K(350))
        flowOut = mc.FlowState("water", "HEOS", None, None, CP.PQ_INPUTS,
                               50000., 1)

        exp = mc.ExpBasic(None, 0.686, flowIn, flowOut, m=1.0)
        exp.solve()  # defaults to solveAttr=pRatio,solveBracket=[1,50]
        self.assertAlmostEqual(exp.pRatio, 40.0, 5)


if __name__ == "__main__":
    unittest.main()
