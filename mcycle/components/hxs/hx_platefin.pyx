from .hxunit_basic cimport HxUnitBasic
from .hx_plate cimport HxPlate
from .hxunit_platefin cimport HxUnitPlateFin
from .flowconfig cimport HxFlowConfig
from ...bases.config cimport Config
from ...bases.component cimport Component22
from ...bases.geom cimport Geom
from ...bases.flowstate cimport FlowState
from ...bases.mcabstractbase cimport MCAttr
from ...bases.solidmaterial cimport SolidMaterial
from warnings import warn
from math import nan, isnan, pi
import scipy.optimize as opt
import CoolProp as CP

cdef dict _inputs = {"flowConfig": MCAttr(HxFlowConfig, "none"), "NPlate": MCAttr(int, "none"), "RfWf": MCAttr(float, "fouling"), "RfSf": MCAttr(float, "fouling"), "plate": MCAttr(SolidMaterial, "none"), "tPlate": MCAttr(float, "length"), "geomPlateWf": MCAttr(Geom, "none"), "geomPlateSf": MCAttr(Geom, "none"), "L": MCAttr(float, "length"), "W": MCAttr(float, "length"), "ARatioWf": MCAttr(float, "none"), "ARatioSf": MCAttr(float, "none"), "ARatioPlate": MCAttr(float, "none"), "DPortWf": MCAttr(float, "none"), "DPortSf": MCAttr(float, "none"), "LVertPortWf": MCAttr(float, "none"), "LVertPortSf": MCAttr(float, "none"), "coeffs_LPlate": MCAttr(list, "none"), "coeffs_WPlate": MCAttr(list, "none"),"coeffs_mass": MCAttr(list, "none"), "effThermal": MCAttr(float, "none"), "flowInWf": MCAttr(FlowState, "none"), "flowInSf": MCAttr(FlowState, "none"), "flowOutWf": MCAttr(FlowState, "none"), "flowOutSf": MCAttr(FlowState, "none"),  "ambient": MCAttr(FlowState, "none"), "sizeAttr": MCAttr(str, "none"), "sizeBounds": MCAttr(list, "none"), "sizeUnitsBounds": MCAttr(list, "none"), 'runBounds': MCAttr(list, 'none'), "name": MCAttr(str, "none"), "notes": MCAttr(str, "none"), "config": MCAttr(Config, "none")}
cdef dict _properties = {"mWf": MCAttr(float, "mass/time"), "mSf": MCAttr(float, "mass/time"), "Q()": MCAttr(float, "power"), "A": MCAttr( "area"),
                "dpWf()": MCAttr( "pressure"), "dpSf()": MCAttr( "pressure"), "isEvap()": MCAttr( "none")}

cdef class HxPlateFin(HxPlate):
    r"""TODO
    """

    def __init__(self,
                 HxFlowConfig flowConfig=HxFlowConfig(),
                 int NPlate=3,
                 double RfWf=0,
                 double RfSf=0,
                 SolidMaterial plate=None,
                 double tPlate=nan,
                 Geom geomPlateWf=None,
                 Geom geomPlateSf=None,
                 double L=nan,
                 double W=nan,
                 double ARatioWf=1,
                 double ARatioSf=1,
                 double ARatioPlate=1,
                 double DPortWf=nan,
                 double DPortSf=nan,
                 double LVertPortWf=nan,
                 double LVertPortSf=nan,
                 list coeffs_LPlate=[0, 1], # no real meaning for PlateFin, get rid of later
                 list coeffs_WPlate=[0, 1], # no real meaning for PlateFin, get rid of later
                 list coeffs_mass=[],
                 double effThermal=1.0,
                 FlowState flowInWf=None,
                 FlowState flowInSf=None,
                 FlowState flowOutWf=None,
                 FlowState flowOutSf=None,
                 FlowState ambient=None,
                 str sizeAttr="NPlate",
                 list sizeBounds=[3, 100],
                 list sizeUnitsBounds=[1e-5, 10.],
                 runBounds=[nan, nan],
                 str name="HxPlateFin instance",
                 str notes="No notes/model info.",
                 Config config=Config(),
                 _unitClass=HxUnitPlateFin):

        super().__init__(flowConfig, NPlate, RfWf, RfSf, plate, tPlate, geomPlateWf, geomPlateSf, L, W, ARatioWf, ARatioSf,
                         ARatioPlate,  DPortWf, DPortSf, LVertPortWf, LVertPortSf, coeffs_LPlate, coeffs_WPlate, coeffs_mass, effThermal, flowInWf, flowInSf,
                         flowOutWf, flowOutSf, ambient, sizeAttr,
                         sizeBounds, sizeUnitsBounds, runBounds, name, notes, config, _unitClass)
        self._inputs = _inputs
        self._properties = _properties

    cdef public tuple _unitArgsLiq(self):
        """Arguments passed to HxUnits in the liquid region."""
        return (self.flowSense, self.NPlate, self.RfWf, self.RfSf, self.plate,
                self.tPlate, self.geomPlateWf, self.geomPlateSf, self.L,
                self.W, self.ARatioWf, self.ARatioSf, self.ARatioPlate,
                self.effThermal)
                
    cpdef public double LPlate(self):
        """float: Total length of the plate [m]."""
        return self.L

    cpdef public double WPlate(self):
        """float: Total width of the plate [m]."""
        return self.W


    cpdef public double mass(self):
        """float: Approximate total mass of the heat exchanger plates [Kg], calculated as either

    - sum(coeffs_mass[i] * NPlate**i)*(LPlate*WPlate*tPlate) if coeffs_mass is defined,
    - or (LPlate*WPlate - 2(0.25*pi*DPortWf**2 + 0.25*pi*DPortSf**2))*tPlate*plate.rho*NPlate.
        """
        cdef double massPerVol
        cdef int i
        if self.coeffs_mass == []:
            if self.coeffs_LPlate == [0, 1]:
                return (self.L * self.WPlate()) * self.tWall * self.wall.rho * self.NWall
            else:
                return (
                self.LPlate() * self.WPlate() - 2 *
                (0.25 * pi * self.DPortWf**2 + 0.25 * pi * self.DPortSf**
                 2)) * self.tWall * self.wall.rho * self.NWall
        else:
            massPerVol = 0.
            for i in range(len(self.coeffs_mass)):
                massPerVol += self.coeffs_mass[i] * self.NWall**i
            return massPerVol * self.LPlate() * self.WPlate() * self.tWall
