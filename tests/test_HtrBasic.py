import unittest
import mcycle as mc
import CoolProp as CP


class TestHtrBasic(unittest.TestCase):
    def test_HtrBasicConstP_solve_Q(self):
        flowIn = mc.FlowState("He", "HEOS", None, None, CP.PT_INPUTS, 6.7e6,
                              424)
        flowOut = mc.FlowState("He", "HEOS", None, None, CP.PT_INPUTS, 6.7e6,
                               1190)

        htr = mc.HtrBasicConstP(None, 1.0, flowIn, flowOut, m=1.0)
        htr.solve("Q")
        self.assertAlmostEqual(htr.Q / 1e6, 3.975, 3)

    def test_HtrBasicConstP_solve_Q_assert_error(self):
        flowIn = mc.FlowState("He", "HEOS", None, None, CP.PT_INPUTS, 6.7e6,
                              424)
        flowOut = mc.FlowState("He", "HEOS", None, None, CP.PT_INPUTS, 6.8e6,
                               1190)

        htr = mc.HtrBasicConstP(None, 1.0, flowIn, flowOut, m=1.0)
        with self.assertRaises(AssertionError):
            htr.solve("Q")

    def test_HtrBasicConstP_solve_m(self):
        flowIn = mc.FlowState("He", "HEOS", None, None, CP.PT_INPUTS, 6.7e6,
                              424)
        flowOut = mc.FlowState("He", "HEOS", None, None, CP.PT_INPUTS, 6.7e6,
                               1190)

        htr = mc.HtrBasicConstP(3.975e6, 1.0, flowIn, flowOut)
        htr.solve("m", [0.8, 1.1])
        self.assertAlmostEqual(htr.m, 1.000, 3)


if __name__ == "__main__":
    unittest.main()
