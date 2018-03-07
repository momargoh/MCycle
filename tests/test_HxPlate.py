import unittest
import mcycle as mc
import CoolProp as CP


class TestHxPlateCorrChevron(unittest.TestCase):
    hx = mc.HxPlate(
        flowSense="counterflow",
        RfWf=0,
        RfSf=0,
        plate=mc.library.stainlessSteel_316,
        tPlate=0.424e-3,
        geomPlateWf=mc.GeomHxPlateCorrChevron(1.096e-3, 60, 10e-3, 1.117),
        geomPlateSf=mc.GeomHxPlateCorrChevron(1.096e-3, 60, 10e-3, 1.117),
        L=269e-3,
        W=95e-3,
        DPortWf=0.0125,
        DPortSf=0.0125,
        ARatioWf=1,
        ARatioSf=1,
        ARatioPlate=1,
        NPlate=23,
        coeffs_LPlate=[0.056, 1],
        coeffs_WPlate=[0, 1],
        effThermal=1.0,
        config=mc.Config(
            dpAcc=False, dpPort=False, dpHead=False))
    flowInWf = mc.FlowState("R123", "HEOS", None, 0.34307814292524513,
                            CP.PT_INPUTS, 1000000., 300.57890653991603)
    flowOutWf = mc.FlowState("R123", "HEOS", None, 0.34307814292524513,
                             CP.PT_INPUTS, 1000000., 414.30198149532583)
    flowInSf = mc.FlowState("Air", "HEOS", None, 0.09, CP.PT_INPUTS, 111600.,
                            1170.)
    flowOutSf = mc.FlowState("Air", "HEOS", None, 0.09, CP.PT_INPUTS, 111600.,
                             310.57890653991603)

    def test_0_unitise(self):
        self.hx.update(
            flowInWf=self.flowInWf,
            flowInSf=self.flowInSf,
            flowOutWf=self.flowOutWf,
            flowOutSf=self.flowOutSf)

        self.hx.unitise()

    def test_1_solve_L(self):
        self.hx.update(L=269e-3, NPlate=23, geomPlateWf__b=1.096e-3, W=95e-3)
        self.hx.solve("L", [0.005, 0.5])
        self.assertAlmostEqual(abs(self.hx.L - 269e-3) / 269e-3, 0, 2)
        #
        self.assertAlmostEqual(
            abs(self.hx.dpWf - 39607.4552153897) / 39607.4552153897, 0, 2)

    def test_1_solve_W(self):
        self.hx.update(
            L=0.268278920236407, NPlate=23, geomPlateWf__b=1.096e-3, W=95e-3)
        self.hx.solve("W", [50e-3, 500e-3])
        self.assertAlmostEqual(abs(self.hx.W - 95e-3) / 95e-3, 0, 4)

    def test_1_solve_geomPlateWf_b(self):
        self.hx.update(
            L=0.268278920236407, NPlate=23, geomPlateWf__b=1.096e-3, W=95e-3)
        self.hx.solve("geomPlateWf__b", [0.1e-3, 10e-3])
        self.assertAlmostEqual(abs(self.hx.geomPlateWf.b - 1.096e-3), 0, 4)

    def test_1_solve_NPlate(self):
        self.hx.update(
            L=0.268278920236407, NPlate=23, geomPlateWf__b=1.096e-3, W=95e-3)
        self.hx.solve("NPlate", [10, 50])
        self.assertEqual(self.hx.NPlate, 23)

    def test_1_solve_L_solution_not_in_bracket_Exception(self):
        self.hx.solve("L", [0.5, 5.])
        self.assertRaises(Exception)


if __name__ == "__main__":
    unittest.main()
