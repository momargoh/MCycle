import unittest
import mcycle as mc
import CoolProp as CP


class TestDEFAULTS(unittest.TestCase):
    mc.UNITSEPARATORDENOM = "."
    mc.UNITSEPARATORNUM = "."

    def test_getUnits_htc(self):
        self.assertEqual(mc.getUnits("htc"), "W/m^2.K")

    def test_getUnits_velocity(self):
        self.assertEqual(mc.getUnits("velocity"), "m/s")

    def test_getUnits_acceleration(self):
        self.assertEqual(mc.getUnits("acceleration"), "m/s^2")

    def test_getUnits_none(self):
        self.assertEqual(mc.getUnits("none"), "")

    def test_getUnits_power(self):
        self.assertEqual(mc.getUnits("power"), "W")


if __name__ == "__main__":
    unittest.main()
