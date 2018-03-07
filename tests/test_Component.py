import unittest
import mcycle as mc
import CoolProp as CP

flow0 = mc.FlowState("air", "HEOS", None, 2.0, CP.PT_INPUTS, 101325., 298.15)
flow1 = mc.FlowState("air", "HEOS", None, 2.0, CP.PT_INPUTS, 101325., 398.15)
flow2 = mc.FlowState("air", "HEOS", None, 2.0, CP.PT_INPUTS, 101325., 498.15)
flow3 = mc.FlowState("air", "HEOS", None, 2.0, CP.PT_INPUTS, 101325., 598.15)
flow4 = mc.FlowState("air", "HEOS", None, 2.0, CP.PT_INPUTS, 101325., 698.15)
flow5 = mc.FlowState("air", "HEOS", None, 2.0, CP.PT_INPUTS, 101325., 798.15)


class ComponentSubClass(mc.bases.Component):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    @property
    def _inputs(self):
        return super()._inputs

    @property
    def _properties(self):
        return super()._properties

    def run(self):
        pass

    def summary(self):
        pass


class Component11SubClass(mc.bases.Component11):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    @property
    def _inputs(self):
        return super()._inputs

    @property
    def _properties(self):
        return super()._properties

    def run(self):
        pass

    def summary(self):
        pass


class TestComponent(unittest.TestCase):
    def test_Component_copy(self):
        cmpnt = ComponentSubClass([flow0, flow1, flow2], [flow3, flow4, flow5])
        cmpnt_copy = cmpnt.copy()
        for i in range(3):
            self.assertEqual(cmpnt.flowsIn[i], cmpnt_copy.flowsIn[i])
            self.assertEqual(cmpnt.flowsOut[i], cmpnt_copy.flowsOut[i])

    def test_Component11_copy(self):
        cmpnt = Component11SubClass(flow0, flow1)
        cmpnt_copy = cmpnt.copy()
        self.assertEqual(cmpnt.flowIn, cmpnt_copy.flowIn)
        self.assertEqual(cmpnt.flowOut, cmpnt_copy.flowOut)

    def test_Component_update(self):
        cmpnt = ComponentSubClass([flow0, flow1], [flow2, flow3])
        cmpnt_copy = cmpnt.copy()
        self.assertEqual(cmpnt.flowsIn[0], cmpnt_copy.flowInWf)
        self.assertEqual(cmpnt.flowsOut[0], cmpnt_copy.flowOutWf)
        self.assertEqual(cmpnt.flowsIn[1], cmpnt_copy.flowsIn[1])
        self.assertEqual(cmpnt.flowsOut[1], cmpnt_copy.flowsOut[1])


if __name__ == "__main__":
    unittest.main()
