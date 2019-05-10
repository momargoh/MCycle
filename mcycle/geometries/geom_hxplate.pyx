from ..bases.geom cimport Geom
from ..bases.mcabstractbase cimport MCAttr

cdef dict _inputsHxPlateCorrugatedChevron = {'b': MCAttr(float, 'length'), 'beta': MCAttr(float, 'angle'), 'pitchCorr': MCAttr(float, 'length'),
                'phi': MCAttr(float, 'none')}
cdef dict _propertiesHxPlateCorrugatedChevron = {}
cdef class GeomHxPlateCorrugatedChevron(Geom):
    r"""Geometry of chevron corrugations for a plate heat exchanger.

Parameters
----------
b : float
    Plate spacing for fluid channels [m].
beta : float
    Plate corrugation chevron angle [deg].
pitchCorr : float
    Plate corrugation pitch [m] (distance between corrugation 'bumps').
      .. note:: Not to be confused with the plate pitch (pitchPlate) which is defined as the sum of the plate channel spacing and one plate thickness.
phi : float
    Corrugated plate surface enlargement factor; ratio of developed length to projected length.
    """


    def __init__(self,
                 b,
                 beta,
                 pitchCorr,
                 phi,
                 name="GeomHxPlateCorrugatedChevron instance"):
        self.b = b
        self.beta = beta
        self.pitchCorr = pitchCorr
        self.phi = phi
        self.name = name
        self.validClasses = ('HxPlate', 'HxUnitPlate')
        self._inputs = _inputsHxPlateCorrugatedChevron
        self._properties = _propertiesHxPlateCorrugatedChevron

cdef dict _inputsHxPlateFinStraight = {"s": MCAttr(float, "length"), "b": MCAttr(float, "length"), "t": MCAttr(float, "length")}
cdef dict _propertiesHxPlateFinStraight = {"h()": MCAttr(float, "length")}
        
cdef class GeomHxPlateFinStraight(Geom):
    r"""Geometry of straight fins for a plate heat exchanger.

Parameters
-----------
s : float
    Lateral fin spacing [m].
b : float
    Channel spacing [m].
t : float
    Fin thickness [m].
    """

    def __init__(self,
                 s,
                 b,
                 t,
                 name="GeomHxPlateFinStraight instance"):
        self.s = s
        self.b = b
        self.t = t
        self.name = name
        self.validClasses = ("HxPlateFin", "HxUnitPlate")
        self._inputs = _inputsHxPlateFinStraight
        self._properties = _propertiesHxPlateFinStraight

    cpdef public double h(self):
        """float: Plate spacing; h = b - t. Setter works only if either b or t == -1."""
        return self.b - self.t

    cpdef public void set_h(self, value):
        from warnings import warn
        if self.b == -1 and self.t > 0:
            self.b = self.t + value
        elif self.t == -1 and self.b > 0:
            self.t = self.b - value
        else:
            warn("Cannot set h, given b={}, t={}, one must set to -1".format(self.b, self.t))

    cpdef public double areaPerWidth(self):
        return (self.s + self.b)/(self.s/self.t + 1)

cdef dict _inputsHxPlateFinOffset = {"s": MCAttr(float, "length"), "b": MCAttr(float, "length"), "t": MCAttr(float, "length"),
                "l": MCAttr(float, "length")}
cdef dict _propertiesHxPlateFinOffset = {"h()": MCAttr(float, "length")}
        
cdef class GeomHxPlateFinOffset(GeomHxPlateFinStraight):
    r"""Geometry of offset fins for a plate heat exchanger. Refer to Figure 1 in [Manglik1995]_.

Parameters
-----------
s : float
    Lateral fin spacing [m].
b : float
    Channel spacing [m].
t : float
    Fin thickness [m].
l : float
    Individual fin length [m].

References
---------------

.. [Manglik1995] Manglik and Bergles, Heat transfer and pressure drop correlations for the rectangular offset strip fin compact heat exchanger, Experimental Thermal and Fluid Science, Elsevier, 1995, 10, pp. 171-180.

Bibtex::

@Article{manglik1995heat,
  author    = {Raj M. Manglik and Arthur E. Bergles},
  title     = {Heat transfer and pressure drop correlations for the rectangular offset strip fin compact heat exchanger},
  journal   = {Experimental Thermal and Fluid Science},
  year      = {1995},
  volume    = {10},
  number    = {2},
  pages     = {171--180},
  month     = {feb},
  doi       = {10.1016/0894-1777(94)00096-q},
  publisher = {Elsevier {BV}},
}
    """

    def __init__(self,
                 s,
                 b,
                 t,
                 l,
                 name="GeomHxPlateFinOffset instance"):
        super().__init__(s, b, t, name)
        self.l = l
        self.validClasses = ("HxPlate", "HxUnitPlate")
        self._inputs = _inputsHxPlateFinOffset
        self._properties = _propertiesHxPlateFinOffset

            
cdef dict _inputsHxPlateRough = {"b": MCAttr(float, "length"), "roughness": MCAttr(float, "length/length")}
cdef dict _propertiesHxPlateRough = {}

cdef class GeomHxPlateRough(Geom):
    r"""Geometry of heat exchanger plate with a rough surface.

Parameters
-----------
b : float
    Plate channel spacing [m].
roughness : float
    Surface roughness factor. (As is used on the Moody chart)
"""

    def __init__(self,
                 b,
                 roughness,
                 name="GeomHxPlateRough instance"):
        self.b = b
        self.roughness = roughness
        self.name = name
        self.validClasses = ("HxPlate", "HxUnitPlate")
        self._inputs = _inputsHxPlateRough
        self._properties = _propertiesHxPlateRough

    cpdef public double areaPerWidth(self):
        return 0

        
cdef dict _inputsHxPlateSmooth = {"b": MCAttr(float, "length")}
cdef dict _propertiesHxPlateSmooth = {"roughness": MCAttr(float, "length/length")}

cdef class GeomHxPlateSmooth(GeomHxPlateRough):
    """Geometry of smooth heat exchanger plate (roughness factor is always None).

Parameters
-----------
b : float
    Plate channel spacing [m].
"""

    def __init__(self,
                 b,
                 name="GeomHxPlateSmooth instance"):
        super(GeomHxPlateSmooth, self).__init__(b, 0, name)
        self._inputs = _inputsHxPlateSmooth
        self._properties = _propertiesHxPlateSmooth
