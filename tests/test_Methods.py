import unittest
import mcycle as mc
import CoolProp as CP


class TestMethods(unittest.TestCase):
    configTest = mc.Config()
    methods = configTest.methods
    print("METHODS TEST config.methods object", id(configTest.methods))

    def test_Methods_lookupMethod_HxPlateCorrChevron_using_args(self):
        self.methods['GeomHxPlateCorrChevronHeatWf'] = {
            "sp": "chisholmWannairachchi_sp",
            "liq": "chisholmWannairachchi_sp",
            "vap": "chisholmWannairachchi_sp",
            "tpEvap": "yanLin_tpEvap",
            "tpCond": "hanLeeKim_tpCond"
        }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateCorrChevron", "heat", "tpEvap", "wf")),
            "yanLin_tpEvap")

    #"""
    def test_Methods_lookupMethod_HxPlateCorrChevron_Error_method_is_None(
            self):
        self.configTest.set_method('', ['GeomHxPlateCorrChevron'],
                                   ['friction'], ['all'], ['wf'])
        with self.assertRaises(ValueError):
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateCorrChevron", "friction", "sp", "wf"))

    def test_Methods_lookupMethod_HxPlateCorrChevron_Error_wrong_number_args(
            self):
        self.configTest.set_method('', ['GeomHxPlateCorrChevron'],
                                   ['friction'], ['all'], ['wf'])
        with self.assertRaises(IndexError):
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateCorrChevron", "friction", "sp"))

    #"""

    def test_Methods_lookupMethod_HxPlateFinOffset_using_args(self):
        self.methods['GeomHxPlateFinOffsetFrictionSf'] = {
            "sp": "manglikBergles_offset_sp",
            "liq": "manglikBergles_offset_sp",
            "vap": "manglikBergles_offset_sp"
        }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateFinOffset", "friction", "sp", "sf")),
            "manglikBergles_offset_sp")


if __name__ == "__main__":
    unittest.main()
