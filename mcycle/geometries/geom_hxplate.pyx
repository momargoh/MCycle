from ..bases.geom cimport Geom
from ..bases.mcabstractbase cimport MCAttr

cdef dict _inputsHxPlateCorrChevron = {'b': MCAttr(float, 'length'), 'beta': MCAttr(float, 'angle'), 'pitchCorr': MCAttr(float, 'length'),
                'phi': MCAttr(float, 'none')}
cdef dict _propertiesHxPlateCorrChevron = {}
cdef class GeomHxPlateCorrChevron(Geom):
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
                 name="GeomHxPlateCorrChevron instance"):
        self.b = b
        self.beta = beta
        self.pitchCorr = pitchCorr
        self.phi = phi
        self.name = name
        self.validClasses = ('HxPlate', 'HxUnitPlate')
        self._inputs = _inputsHxPlateCorrChevron
        self._properties = _propertiesHxPlateCorrChevron

cdef dict _inputsHxPlateFinStraight = {"s": MCAttr(float, "length"), "h": MCAttr(float, "length"), "t": MCAttr(float, "length")}
cdef dict _propertiesHxPlateFinStraight = {"b()": MCAttr(float, "length")}
        
cdef class GeomHxPlateFinStraight(Geom):
    r"""Geometry of straight fins for a plate heat exchanger.

Parameters
-----------
s : float
    Lateral fin spacing [m].
h : float
    Fin channel height [m].
t : float
    Fin thickness [m].
    """

    def __init__(self,
                 s,
                 h,
                 t,
                 name="GeomHxPlateFinStraight instance"):
        self.s = s
        self.h = h
        self.t = t
        self.name = name
        self.validClasses = ("HxPlateFin", "HxUnitPlateFin")
        self._inputs = _inputsHxPlateFinStraight
        self._properties = _propertiesHxPlateFinStraight

    cpdef public double b(self):
        """float: Plate spacing; b = h + t. Setter works only if either h or t == -1."""
        return self.h + self.t

    cpdef public void set_b(self, value):
        from warnings import warn
        if self.h == -1 and self.t > 0:
            self.h = value - self.t
        elif self.t == -1 and self.h > 0:
            self.t = value - self.h
        else:
            warn("Cannot set b, given h={}, t={}, one must set to -1".format(self.h, self.t))

cdef dict _inputsHxPlateFinOffset = {"s": MCAttr(float, "length"), "h": MCAttr(float, "length"), "t": MCAttr(float, "length"),
                "l": MCAttr(float, "length")}
cdef dict _propertiesHxPlateFinOffset = {"b()": MCAttr(float, "length")}
        
cdef class GeomHxPlateFinOffset(Geom):
    r"""Geometry of offset fins for a plate heat exchanger. Refer to Figure 1 in [Manglik1995]_.

Parameters
-----------
s : float
    Lateral fin spacing [m].
h : float
    Fin channel height [m].
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
                 h,
                 t,
                 l,
                 name="GeomHxPlateFinOffset instance"):
        self.s = s
        self.h = h
        self.t = t
        self.l = l
        self.name = name
        self.validClasses = ("HxPlate", "HxUnitPlate")
        self._inputs = _inputsHxPlateFinOffset
        self._properties = _propertiesHxPlateFinOffset

    cpdef public double b(self):
        """float: Plate spacing; b = h + t. Setter works only if either h or t == -1."""
        return self.h + self.t

    cpdef public void set_b(self, value):
        from warnings import warn
        if self.h == -1 and self.t > 0:
            self.h = value - self.t
        elif self.t == -1 and self.h > 0:
            self.t = value - self.h
        else:
            warn("Cannot set b, given h={}, t={}, one must set to -1".format(self.h, self.t))

            
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
