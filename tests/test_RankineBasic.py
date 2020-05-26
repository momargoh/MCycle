import unittest
import mcycle as mc
from math import nan
import numpy as np


class TestRankineBasic(unittest.TestCase):
    wf = mc.FlowState("R123")
    pEvap = 10.e5
    superheat = 30.
    TCond = 300.
    subcool = 0
    comp = mc.CompBasic(nan, 0.7, sizeAttr="pRatio")
    sourceIn = mc.FlowState("Air", 0.09, mc.PT_INPUTS, 1.116e5, 1170.)
    evap = mc.library.alfaLaval_AC30EQ()
    evap.update({'sizeAttr': "NPlate", 'plate.T': 573.15})
    exp = mc.ExpBasic(nan, 0.7, sizeAttr="pRatio")
    sinkIn = mc.FlowState("Air", 0.20, mc.PT_INPUTS, 0.88260e5, 281.65)
    sinkAmbient = sinkIn.copy()
    sourceAmbient = sinkIn.copy()
    cond = mc.ClrBasic(mc.CONSTANT_P, nan, 1, sizeAttr="QCool")
    config = mc.Config()
    config.update({
        'dpEvap': False,
        'dpCond': False,
        'dpAcc': False,
        'dpPort': False,
        'dpHead': False
    })
    config.set_method("savostinTikhonov_sp", "GeomHxPlateChevron",
                      mc.TRANSFER_ALL, mc.UNITPHASE_ALL, mc.SECONDARY_FLUID)
    cycle = mc.RankineBasic(wf, evap, exp, cond, comp, pEvap, superheat, nan,
                            subcool, config)
    cycle.setAll_config(config)
    cycle.update({
        'TCond': TCond,
        'sourceIn': sourceIn,
        #'sinkIn': sinkIn,
        'sourceAmbient': sourceAmbient,
        #'sinkAmbient': sinkAmbient
    })
    cycle.pptdEvap = 10.

    def test_0_setup_cycle(self):
        self.assertAlmostEqual(self.cycle.pCond, 97797.60828695059, 5)
        self.assertIs(self.cycle.exp.config, self.config)
        self.assertAlmostEqual(self.cycle.mWf, 0.34307814292524513, 10)

    def test_1_size(self):
        self.cycle.update({"config.dpEvap": False, "evap.L": 0.269})
        self.cycle.size()
        self.assertEqual(self.cycle.evap.NPlate, 23)
        self.assertAlmostEqual(
            abs(self.cycle.evap.L - 0.268278920236407), 0, 2)
        self.assertAlmostEqual(self.cycle.comp.pRatio, 10.22519893, 4)
        self.assertAlmostEqual(self.cycle.exp.pRatio, 10.22519893, 4)
        self.assertAlmostEqual(self.cycle.evap.Q(), 83891.17350428084, 4)

    def test_1_size_dpEvap_True(self):
        self.cycle.update({"config.dpEvap": True, "evap.L": 0.269})
        self.cycle.size()
        self.assertAlmostEqual(
            abs(self.cycle.evap.L - 0.268278920236407), 0, 2)
        self.assertAlmostEqual(
            (self.cycle.comp.pRatio - 10.22519893) / 10.22519893, 0, 4)
        self.assertAlmostEqual(
            self.cycle.exp.pRatio,
            (self.cycle.pEvap - 39607.4552153897) / self.cycle.pCond, 4)
        self.assertAlmostEqual(self.cycle.evap.Q(), 83891.17350428084, 4)

    def test_1_run_from_comp(self):
        self.cycle.update({
            "config.dpEvap": False,
            "evap.NPlate": 23,
            "evap.L": 0.269,
            "pRatioExp": 10.22519893,
            "pRatioComp": 10.22519893,
            "cond.QCool": 73582.4417680011
        })
        self.cycle.clearWf_flows()
        rb0 = self.wf.copyUpdateState(mc.PT_INPUTS, self.pEvap,
                                      self.cycle.TEvap + 20.).h()
        rb1 = self.wf.copyUpdateState(mc.PT_INPUTS, self.pEvap,
                                      self.cycle.TEvap + 32.).h()
        self.evap.update({"runBounds": [rb0, rb1]})
        self.cycle.set_state6(
            self.wf.copyUpdateState(mc.QT_INPUTS, 0, self.TCond))
        self.cycle.run()
        self.assertAlmostEqual(
            abs(self.cycle.state4.T() / 3.6047e+02) - 1, 0, 3)
        self.assertAlmostEqual(
            abs(self.cycle.state4.p() / self.cycle.pCond) - 1, 0, 5)
        self.assertAlmostEqual(
            abs(self.cycle.state3.T() / (self.cycle.TEvap + 30)) - 1, 0, 3)

    '''
    def test_1_run_from_comp_dpEvap_True(self):
        self.cycle.update({
            "config.dpEvap": True,
            "evap.NPlate": 23,
            "evap.L": 0.269,
            "exp.pRatio": 9.820204742676,
            "comp.pRatio": 10.22519893,
            "cond.QCool": 73582.4417680011
        })
        self.cycle.clearWf_flows()
        rb0 = self.wf.copyUpdateState(mc.PT_INPUTS, self.pEvap,
                                self.cycle.TEvap + 20.).h()
        rb1 = self.wf.copyUpdateState(mc.PT_INPUTS, self.pEvap,
                                self.cycle.TEvap + 32.).h()
        self.evap.update({"runBounds": [rb0, rb1]})
        self.cycle.set_state6(self.wf.copyUpdateState(mc.QT_INPUTS, 0, self.TCond))
        self.cycle.run()
        self.assertAlmostEqual(
            abs(self.cycle.state4.T() / 3.6047e+02) - 1, 0, 3)
        self.assertAlmostEqual(
            abs(self.cycle.state4.p() / self.cycle.pCond) - 1, 0, 5)
        self.assertAlmostEqual(abs(self.cycle.state3.T() / (413.67)) - 1, 0, 2)
        self.assertAlmostEqual(
            abs(self.cycle.state3.p() / (9.6039e5)) - 1, 0, 1)
    '''

    def test_1_run_from_exp(self):
        self.cycle.update({
            "config.dpEvap": False,
            "evap.NPlate": 23,
            "evap.L": 0.269,
            "pRatioExp": 10.22519893,
            "pRatioComp": 10.22519893,
            "cond.QCool": 73582.4417680011
        })
        self.cycle.clearWf_flows()
        rb0 = self.wf.copyUpdateState(mc.PT_INPUTS, self.pEvap,
                                      self.cycle.TEvap + 20.).h()
        rb1 = self.wf.copyUpdateState(mc.PT_INPUTS, self.pEvap,
                                      self.cycle.TEvap + 32.).h()
        self.evap.update({"runBounds": [rb0, rb1]})
        self.cycle.set_state3(
            self.wf.copyUpdateState(mc.PT_INPUTS, self.cycle.pEvap,
                                    self.cycle.TEvap + 30))
        self.cycle.run()
        self.assertAlmostEqual(
            abs(self.cycle.state4.T() / 3.6047e+02) - 1, 0, 3)
        self.assertAlmostEqual(
            abs(self.cycle.state4.p() / self.cycle.pCond) - 1, 0, 5)
        self.assertAlmostEqual(
            abs(self.cycle.state3.T() / (self.cycle.TEvap + 30)) - 1, 0, 3)

    def test_cycle_plot(self):
        import os
        self.cycle.sizeSetup(True, True)
        self.cycle.plot(
            title="test_cycle_plot",
            show=False,
            savefig=True,
            savefig_name="test_cycle_plot",
            savefig_format="png",
            savefig_folder=".")
        cwd = os.getcwd()
        os.remove("./test_cycle_plot.png")


if __name__ == "__main__":
    unittest.main()
