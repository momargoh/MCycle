import unittest
import mcycle as mc
import numpy as np
import CoolProp as CP


class TestRankineBasic(unittest.TestCase):
    wf = mc.FlowState("R123", "HEOS", None)
    pEvap = 10.e5
    superheat = 30.
    TCond = 300.
    subcool = None
    comp = mc.CompBasic(None, 0.7, solveAttr="pRatio")
    sourceIn = mc.FlowState("Air", "HEOS", None, 0.09, CP.PT_INPUTS, 1.116e5,
                            1170.)
    evap = mc.library.alfaLaval_AC30EQ()
    evap.update(solveAttr="NPlate")
    exp = mc.ExpBasic(None, 0.7, solveAttr="pRatio")
    sinkIn = mc.FlowState("Air", "HEOS", None, 0.20, CP.PT_INPUTS, 0.88260e5,
                          281.65)
    sinkDead = sinkIn.copy()
    sourceDead = sinkIn.copy()
    #cond = mc.library.alfaLaval_CBXP27, solveAttr="NPlate")
    cond = mc.ClrBasicConstP(None, 1, solveAttr="Q")
    config = mc.Config(
        dpEvap=False, dpCond=False, dpAcc=False, dpPort=False, dpHead=False)
    cycle = mc.RankineBasic(
        wf,
        evap,
        exp,
        cond,
        comp,
        pEvap,
        superheat,
        None,
        subcool,
        config,
        TCond=TCond,
        sourceIn=sourceIn,
        sinkIn=sinkIn,
        sourceDead=sourceDead,
        sinkDead=sinkDead)
    cycle.pptdEvap = 10.

    def test_0_setup_cycle(self):
        self.assertAlmostEqual(self.cycle.pCond, 97797.60828695059, 5)
        self.assertIs(self.cycle.exp.config, self.config)
        self.assertAlmostEqual(self.cycle.mWf, 0.34307814292524513, 10)

    def test_1_solve(self):
        self.cycle.config.dpEvap = False
        self.cycle.solve()
        self.assertAlmostEqual(
            abs(self.cycle.evap.L - 0.268278920236407), 0, 2)
        self.assertAlmostEqual(self.cycle.comp.pRatio, 10.22519893, 4)
        self.assertAlmostEqual(self.cycle.exp.pRatio, 10.22519893, 4)
        self.assertAlmostEqual(self.cycle.evap.Q, 83891.17350428084, 6)

    def test_1_solve_dpEvap_True(self):
        self.cycle.config.dpEvap = True
        self.cycle.solve()
        self.assertAlmostEqual(
            abs(self.cycle.evap.L - 0.268278920236407), 0, 2)
        self.assertAlmostEqual(
            (self.cycle.comp.pRatio - 10.22519893) / 10.22519893, 0, 4)
        self.assertAlmostEqual(self.cycle.exp.pRatio,
                               (self.cycle.pEvap - 39607.4552153897) /
                               self.cycle.pCond, 4)
        self.assertAlmostEqual(self.cycle.evap.Q, 83891.17350428084, 4)

    def test_cycle_plot(self):
        import os
        self.cycle.solveSetup()
        self.cycle.plot(
            title="test_cycle_plot",
            show=False,
            savefig=True,
            savefig_name="test_cycle_plot",
            savefig_format="png",
            savefig_folder="")
        cwd = os.getcwd()
        os.remove(cwd + "/test_cycle_plot.png")


if __name__ == "__main__":
    unittest.main()
