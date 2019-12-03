import unittest
import mcycle as mc


class TestHtrBasic(unittest.TestCase):
    def test_HtrBasicConstP_size_Q(self):
        flowIn = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 424)
        flowOut = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 1190)

        htr = mc.HtrBasicConstP(-1, 1.0, flowIn, flowOut)
        htr.update({'m': 1.0, 'sizeAttr': 'QHeat'})
        htr.size()
        self.assertAlmostEqual(htr.Q() / 1e6, 3.975, 3)

    def test_HtrBasicConstP_size_Q_assert_error(self):
        flowIn = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 424)
        flowOut = mc.FlowState("He", -1, mc.PT_INPUTS, 6.8e6, 1190)

        htr = mc.HtrBasicConstP(-1, 1.0, flowIn, flowOut)
        htr.update({'m': 1.0, 'sizeAttr': 'QHeat'})
        with self.assertRaises(AssertionError):
            htr.size()

    def test_HtrBasicConstP_size_m(self):
        flowIn = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 424)
        flowOut = mc.FlowState("He", -1, mc.PT_INPUTS, 6.7e6, 1190)

        htr = mc.HtrBasicConstP(3.975e6, 1.0, flowIn, flowOut)
        htr.update({'sizeAttr': 'm', 'sizeBounds': [0.8, 1.1]})
        htr.size()
        self.assertAlmostEqual(htr.m, 1.000, 3)


if __name__ == "__main__":
    unittest.main()
