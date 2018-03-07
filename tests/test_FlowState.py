import unittest
import mcycle as mc
import CoolProp as CP


class TestFlowState(unittest.TestCase):
    def test_FlowState(self):
        flow = mc.FlowState("air", "HEOS", None, 1.0, CP.PT_INPUTS, 101325.,
                            293.15)
        self.assertAlmostEqual(flow.rho, 1.205, 3)
        self.assertAlmostEqual(flow.cp / 1000, 1.006, 3)
        self.assertAlmostEqual(flow.k, 0.0257, 3)

    def test_RefData_populate_data(self):
        refData = mc.RefData("air", 2, 101325., [200, 300, 400, 500])
        rhoData = [1.765, 1.177, 0.8824, 0.7060]
        viscData = [1.329e-5, 1.846e-5, 2.286e-5, 2.670e-5]
        all(
            self.assertAlmostEqual(refData.rhoData[i] - rhoData[i], 0, 2)
            for i in range(len(rhoData)))
        all(
            self.assertAlmostEqual(refData.viscData[i] - viscData[i], 0, 2)
            for i in range(len(viscData)))

    def test_RefData_error_len_data(self):
        with self.assertRaises(ValueError):
            refData = mc.RefData("air", 2, 101325., [200, 250, 300, 350, 400],
                                 [0.1, 0.1, 0.1])

    def test_FlowStatePoly(self):
        refData = mc.RefData("air", 2, 101325., [200, 250, 300, 350, 400])
        flow = mc.FlowStatePoly(refData, 1.0, CP.PT_INPUTS, 101325., 293.15)
        self.assertAlmostEqual(flow.rho - 1.205, 0, 3)
        self.assertAlmostEqual(flow.cp / 1000 - 1.006, 0, 3)
        self.assertAlmostEqual(flow.k - 0.0257, 0, 3)

    def test_FlowStatePoly_error_pressure(self):
        refData = mc.RefData("air", 2, 101325., [200, 250, 300, 350, 400])
        with self.assertRaises(ValueError):
            flow = mc.FlowStatePoly(refData, 1.0, CP.PT_INPUTS, 201325.,
                                    293.15)


if __name__ == "__main__":
    unittest.main()
