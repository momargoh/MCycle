import unittest
import mcycle as mc


class TestHxPlate(unittest.TestCase):
    config = mc.Config()
    config.update({'dpAcc': False, 'dpPort': False, 'dpHead': False})
    config.set_method("savostinTikhonov_sp", "GeomHxPlateChevron",
                      mc.TRANSFER_ALL, mc.UNITPHASE_ALL, mc.SECONDARY_FLUID)
    hx = mc.HxPlate(
        flowConfig=mc.HxFlowConfig(mc.COUNTERFLOW, 1, '', True, True),
        RfWf=0,
        RfSf=0,
        plate=mc.library.stainlessSteel_316(573.15),
        tPlate=0.424e-3,
        geomWf=mc.GeomHxPlateChevron(1.096e-3, 60, 10e-3, 1.117),
        geomSf=mc.GeomHxPlateChevron(1.096e-3, 60, 10e-3, 1.117),
        L=269e-3,
        W=95e-3,
        portWf=mc.Port(d=0.0125),
        portSf=mc.Port(d=0.0125),
        NPlate=23,
        coeffs_LPlate=[0.056, 1],
        coeffs_WPlate=[0, 1],
        efficiencyThermal=1.0,
        config=config)
    flowInWf = mc.FlowState("R123", 0.34307814292524513, mc.PT_INPUTS,
                            1000000., 300.57890653991603)
    flowOutWf = mc.FlowState("R123", 0.34307814292524513, mc.PT_INPUTS,
                             1000000., 414.30198149532583)
    flowInSf = mc.FlowState("Air", 0.09, mc.PT_INPUTS, 111600., 1170.)
    flowOutSf = mc.FlowState("Air", 0.09, mc.PT_INPUTS, 111600.,
                             310.57890653991603)

    def test_0_unitise(self):
        self.hx.update({
            'flowInWf': self.flowInWf,
            'flowInSf': self.flowInSf,
            'flowOutWf': self.flowOutWf,
            'flowOutSf': self.flowOutSf
        })
        self.hx.unitise()

    def test_1_size_L(self):
        self.hx.update({
            'L': 269e-3,
            'NPlate': 23,
            'geomWf.b': 1.096e-3,
            'W': 95e-3
        })
        self.hx.update({'sizeAttr': 'L', 'sizeBounds': [0.005, 0.5]})
        self.hx.size()
        self.assertAlmostEqual(abs(self.hx.L - 269e-3) / 269e-3, 0, 2)
        #
        self.assertAlmostEqual(
            abs(self.hx.dpWf() - 39607.4552153897) / 39607.4552153897, 0, 2)

    def test_1_size_W(self):
        self.hx.update({
            'L': 0.268278920236407,
            'NPlate': 23,
            'geomWf.b': 1.096e-3,
            'W': 95e-3
        })
        self.hx.update({'sizeAttr': 'W', 'sizeBounds': [50e-3, 500e-3]})
        self.hx.size()
        self.assertAlmostEqual(abs(self.hx.W - 95e-3) / 95e-3, 0, 4)

    def test_1_size_geomWf_b(self):
        self.hx.update({
            'L': 0.268278920236407,
            'NPlate': 23,
            'geomWf.b': 0,
            'W': 95e-3
        })
        self.hx.update({'sizeAttr': 'geomWf.b', 'sizeBounds': [0.1e-3, 10e-3]})
        self.hx.size()
        self.assertAlmostEqual(abs(self.hx.geomWf.b - 1.096e-3), 0, 4)

    def test_1_size_NPlate(self):
        self.hx.update({
            'L': 0.268278920236407,
            'NPlate': 23,
            'geomWf.b': 1.096e-3,
            'W': 95e-3
        })
        self.hx.update({'sizeAttr': 'NPlate', 'sizeBounds': [10, 50]})
        self.hx.size()
        self.assertEqual(self.hx.NPlate, 23)

    def test_1_size_L_solution_not_in_bounds_Exception(self):
        self.hx.update({'sizeAttr': 'L', 'sizeBounds': [0.5, 5.]})
        self.hx.size()
        self.assertRaises(Exception)

    def test_run1(self):
        flowInWf = mc.FlowState("R245fa", 2, mc.PT_INPUTS, 2e5, 300.)
        flowInSf = mc.FlowState("water", 5., mc.PT_INPUTS, 1e5, 600.)

        hLowerBound = flowInWf.h() * 1.01
        hUpperBound = flowInWf.copyUpdateState(mc.PT_INPUTS, 2e5, 350.).h()

        self.hx.update({
            'L': 0.269,
            'NPlate': 5,
            'geomWf.b': 1.096e-3,
            'W': 95e-3,
            'flowInWf': flowInWf,
            'flowInSf': flowInSf,
            'sizeUnitsBounds': [1e-5, 1.],
            'runBounds': [hLowerBound, hUpperBound]
        })
        self.hx.run()
        #self.hx.summary(flowKeys='all')
        self.assertAlmostEqual(self.hx.flowOutWf.T(), 318.22, 2)

    def test_run2(self):
        flowInWf = mc.FlowState("water", 0.1, mc.PT_INPUTS, 1.1e5, 700.)
        flowInSf = mc.FlowState("water", 0.1, mc.PT_INPUTS, 1e5, 500.)

        hLowerBound = flowInWf.h() * 0.99
        hUpperBound = flowInWf.copyUpdateState(mc.PT_INPUTS, 1.1e5, 600.).h()

        self.hx.update({
            'L': 0.1,
            'NPlate': 3,
            'geomWf.b': 1.096e-3,
            'W': 95e-3,
            'flowInWf': flowInWf,
            'flowInSf': flowInSf,
            'sizeUnitsBounds': [1e-5, 5.],
            'runBounds': [hLowerBound, hUpperBound]
        })
        self.hx.run()
        #self.hx.summary(flowKeys='all')
        self.assertAlmostEqual(self.hx.flowOutWf.T(), 643.66, 2)


if __name__ == "__main__":
    unittest.main()
