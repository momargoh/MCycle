import unittest
import mcycle as mc


class TestExpBasic(unittest.TestCase):
    def test_ExpBasic_run(self):
        flowIn = mc.FlowState("water", 10., mc.PT_INPUTS, 3.e6, mc.degC2K(500))
        exp = mc.ExpBasic(6, 0.8, flowIn)
        exp.run()
        self.assertAlmostEqual(exp.flowOut.T(), 563.74, 2)
        self.assertAlmostEqual(exp.POut() / 1000, 4121.11, 2)

    def test_ExpBasic_size_efficiencyIsentropic(self):
        flowIn = mc.FlowState("water", -1, mc.PT_INPUTS, 2.e6, mc.degC2K(350))
        flowOut = mc.FlowState("water", -1, mc.PQ_INPUTS, 50000., 1)

        exp = mc.ExpBasic(40, 1.0, flowIn, flowOut)
        exp.update({
            'm': 1.,
            'sizeAttr': "efficiencyIsentropic",
            'sizeBounds': [0.5, 0.8]
        })
        exp.size()
        self.assertAlmostEqual(exp.efficiencyIsentropic, 0.686, 3)

    def test_ExpBasic_size_pRatio(self):
        flowIn = mc.FlowState("water", -1, mc.PT_INPUTS, 2.e6, mc.degC2K(350))
        flowOut = mc.FlowState("water", -1, mc.PQ_INPUTS, 50000., 1)

        exp = mc.ExpBasic(-1, 0.686, flowIn, flowOut)
        exp.update({'m': 1.})
        exp.size()  # defaults to sizeAttr=pRatio,sizeBounds=[1,50]
        self.assertAlmostEqual(exp.pRatio, 40.0, 5)


if __name__ == "__main__":
    unittest.main()
