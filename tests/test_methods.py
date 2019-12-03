import unittest
import mcycle as mc


class TestMethods(unittest.TestCase):
    configTest = mc.Config()
    methods = configTest.methods

    def test_add_method_success(self):
        def custom_method(p0, p1, p2):
            return {"h": 0}

        mc.add_method(custom_method, "heat_transfer")
        self.assertEqual(
            getattr(mc.methods.heat_transfer, "custom_method"), custom_method)

    def test_add_method_fail_method_is_string(self):
        with self.assertRaises(TypeError):
            mc.add_method("custom_method", "heat_transfer")

    def test_add_method_fail_submodule_not_valid(self):
        with self.assertRaises(ValueError):

            def custom_method(p0, p1, p2):
                return {"h": 0}

            mc.add_method(custom_method, "fail_submodule")

    def test_Methods_lookupMethod_HxPlateCorrugatedChevron_using_args(self):
        self.methods['GeomHxPlateCorrugatedChevron'][mc.TRANSFER_HEAT][
            mc.WORKING_FLUID] = {
                mc.UNITPHASE_TWOPHASE_EVAPORATING: "yanLin_tpEvap"
            }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate",
                ("GeomHxPlateCorrugatedChevron", mc.TRANSFER_HEAT,
                 mc.UNITPHASE_TWOPHASE_EVAPORATING, mc.WORKING_FLUID)),
            "yanLin_tpEvap")

    def test_Methods_lookupMethod_HxPlateCorrugatedChevron_using_fallback_ALL_TWOPHASE(
            self):
        self.methods['GeomHxPlateCorrugatedChevron'][mc.TRANSFER_HEAT][
            mc.WORKING_FLUID] = {
                mc.UNITPHASE_ALL_TWOPHASE: "yanLin_tpEvap"
            }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate",
                ("GeomHxPlateCorrugatedChevron", mc.TRANSFER_HEAT,
                 mc.UNITPHASE_TWOPHASE_EVAPORATING, mc.WORKING_FLUID)),
            "yanLin_tpEvap")

    def test_Methods_lookupMethod_HxPlateCorrugatedChevron_using_fallback_ALL(
            self):
        self.methods['GeomHxPlateCorrugatedChevron'][mc.TRANSFER_HEAT][
            mc.WORKING_FLUID] = {
                mc.UNITPHASE_ALL: "yanLin_tpEvap"
            }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate",
                ("GeomHxPlateCorrugatedChevron", mc.TRANSFER_HEAT,
                 mc.UNITPHASE_TWOPHASE_EVAPORATING, mc.WORKING_FLUID)),
            "yanLin_tpEvap")

    def test_Methods_lookupMethod_HxPlateCorrugatedChevron_using_fallback_ALL_SINGLEPHASE_of_FLOW_ALL(
            self):
        self.methods['GeomHxPlateCorrugatedChevron'][mc.TRANSFER_HEAT] = {
            mc.UNITPHASE_ALL_SINGLEPHASE: "yanLin_tpEvap"
        }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateCorrugatedChevron", mc.TRANSFER_HEAT,
                            mc.UNITPHASE_LIQUID, mc.WORKING_FLUID)),
            "yanLin_tpEvap")

    #"""
    def test_Methods_lookupMethod_HxPlateCorrugatedChevron_Error_method_is_None(
            self):
        self.methods['GeomHxPlateCorrugatedChevron'][mc.TRANSFER_FRICTION] = {}
        with self.assertRaises(KeyError):
            self.configTest.lookupMethod(
                "HxPlate",
                ("GeomHxPlateCorrugatedChevron", mc.TRANSFER_FRICTION,
                 mc.UNITPHASE_LIQUID, mc.WORKING_FLUID))

    def test_Methods_lookupMethod_HxPlateCorrugatedChevron_Error_wrong_number_args(
            self):
        self.configTest.set_method(
            'test_method', 'GeomHxPlateCorrugatedChevron',
            mc.TRANSFER_FRICTION, mc.UNITPHASE_ALL, mc.WORKING_FLUID)
        with self.assertRaises(IndexError):
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateCorrugatedChevron",
                            mc.TRANSFER_FRICTION, mc.UNITPHASE_LIQUID))

    #"""

    def test_Methods_lookupMethod_HxPlateFinOffset_using_args(self):
        self.methods['GeomHxPlateFinOffset'][mc.TRANSFER_FRICTION][
            mc.SECONDARY_FLUID] = {
                mc.UNITPHASE_LIQUID: "manglikBergles_offset_sp",
                mc.UNITPHASE_VAPOUR: "manglikBergles_offset_sp"
            }
        self.assertEqual(
            self.configTest.lookupMethod(
                "HxPlate", ("GeomHxPlateFinOffset", mc.TRANSFER_FRICTION,
                            mc.UNITPHASE_LIQUID, mc.SECONDARY_FLUID)),
            "manglikBergles_offset_sp")


if __name__ == "__main__":
    unittest.main()
