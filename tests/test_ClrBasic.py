import unittest
import mcycle as mc


class TestClrBasic(unittest.TestCase):
    def test_ClrBasic_ConstP_solve_Q(self):
        flowOut = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 424)
        flowIn = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 1190)

        clr = mc.ClrBasic(mc.CONSTANT_P, -1, 1.0, flowIn, flowOut)
        clr.update({'m': 1.0, 'sizeAttr': 'QCool'})
        clr.size()
        self.assertAlmostEqual(clr.Q() / 1e6, -3.975, 3)

    def test_ClrBasic_ConstP_solve_Q_assert_error(self):
        flowOut = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 424)
        flowIn = mc.FlowState("He", -1, mc.PT_INPUTS, 6.8e6, 1190)

        clr = mc.ClrBasic(mc.CONSTANT_P, -1, 1.0, flowIn, flowOut)
        clr.update({'m': 1.0, 'sizeAttr': 'QCool'})
        with self.assertRaises(AssertionError):
            clr.size()

    def test_ClrBasic_ConstP_solve_m(self):
        flowOut = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 424)
        flowIn = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 1190)

        clr = mc.ClrBasic(mc.CONSTANT_P, 3.975e6, 1.0, flowIn, flowOut)
        clr.update({'sizeAttr': 'm', 'sizeBounds': [0.8, 1.1]})
        clr.size()
        self.assertAlmostEqual(clr.m, 1.000, 3)


if __name__ == "__main__":
    unittest.main()
