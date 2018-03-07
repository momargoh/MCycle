import unittest
import mcycle as mc
import CoolProp as CP


class TestMethods(unittest.TestCase):
    def test_Methods_lookup_HxPlateCorrChevron_using_args(self):
        method = mc.Methods()
        method.HxPlateCorrChevronHeatWf = {
            "sp": "chisholmWannairachchi_1phase",
            "liq": "chisholmWannairachchi_1phase",
            "vap": "chisholmWannairachchi_1phase",
            "tpEvap": "yanLin_2phase_boiling",
            "tpCond": "hanLeeKim_2phase_condensing"
        }
        self.assertEqual(
            method.lookup(mc.HxPlate, mc.GeomHxPlateCorrChevron, "heat",
                          "tpEvap", "wf").__name__, "yanLin_2phase_boiling")

    def test_Methods_lookup_HxPlateCorrChevron_using_kwargs(self):
        method = mc.Methods()
        method.HxPlateCorrChevronFrictionSf = {
            "sp": "chisholmWannairachchi_1phase",
            "liq": "chisholmWannairachchi_1phase",
            "vap": "chisholmWannairachchi_1phase",
            "tpEvap": "yanLin_2phase_boiling",
            "tpCond": "hanLeeKim_2phase_condensing"
        }
        self.assertEqual(
            method.lookup(
                mc.HxPlate,
                geom=mc.GeomHxPlateCorrChevron,
                transfer="friction",
                phase="liq",
                flow="sf").__name__,
            "chisholmWannairachchi_1phase")

    def test_Methods_lookup_HxPlateCorrChevron_Error_method_is_None(self):
        method = mc.Methods()
        method.HxPlateCorrChevronFrictionWf = None
        with self.assertRaises(TypeError):
            method.lookup(mc.HxPlate, mc.GeomHxPlateCorrChevron, "friction",
                          "sp", "wf")

    def test_Methods_lookup_HxPlateCorrChevron_Error_wrong_number_args(self):
        method = mc.Methods()
        method.HxPlateCorrChevronFrictionWf = None
        with self.assertRaises(TypeError):
            method.lookup(mc.HxPlate, mc.GeomHxPlateCorrChevron, "friction",
                          "sp")

    def test_Methods_lookup_HxPlateFinOffset_using_args(self):
        method = mc.Methods()
        method.HxPlateFinOffsetFrictionSf = {
            "sp": "manglikBergles_offset_allphase",
            "liq": "manglikBergles_offset_allphase",
            "vap": "manglikBergles_offset_allphase"
        }
        self.assertEqual(
            method.lookup(mc.HxPlate, mc.GeomHxPlateFinOffset, "friction",
                          "sp", "sf").__name__,
            "manglikBergles_offset_allphase")


if __name__ == "__main__":
    unittest.main()
