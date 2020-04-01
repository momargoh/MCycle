import unittest
import mcycle as mc


class Testdefaults(unittest.TestCase):
    mc.UNITSEPARATORDENOM = "."
    mc.UNITSEPARATORNUM = "."

    def test_getUnits_htc(self):
        self.assertEqual(mc.getUnits("htc"), "W/m^2.K")

    def test_getUnits_velocity(self):
        self.assertEqual(mc.getUnits("velocity"), "m/s")

    def test_getUnits_acceleration(self):
        self.assertEqual(mc.getUnits("acceleration"), "m/s^2")

    def test_getUnits_none(self):
        self.assertEqual(mc.getUnits(""), "")

    def test_getUnits_power(self):
        self.assertEqual(mc.getUnits("power"), "W")

    def test_changing_default(self):
        mc.defaults.TOLREL = 4  #updateDefaults({'TOLREL': 4})
        print(mc.defaults.TOLREL)
        config = mc.Config()
        print(config.dpPortSf)
        self.assertEqual(config.tolRel, 4)


if __name__ == "__main__":
    unittest.main()
