from ..bases import Geom
from .. import components as cps


class GeomHxPlateCorrChevron(Geom):
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

    validClasses = (cps.HxPlate, cps.HxUnitPlate)

    def __init__(self,
                 b,
                 beta,
                 pitchCorr,
                 phi,
                 name="GeomHxPlateCorrChevron instance",
                 notes="no notes",
                 **kwargs):
        self.b = b
        self.beta = beta
        self.pitchCorr = pitchCorr
        self.phi = phi
        super().__init__(name, notes)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("b", "length"), ("beta", "angle"), ("pitchCorr", "length"),
                ("phi", "none"))

    @property
    def _properties(self):
        """List of class properties, along with their units as ("property", "units")."""
        return []


class GeomHxPlateFinOffset(Geom):
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

    validClasses = (cps.HxPlate, cps.HxUnitPlate)

    def __init__(self,
                 s,
                 h,
                 t,
                 l,
                 name="GeomHxPlateFinOffset instance",
                 notes="no notes",
                 **kwargs):
        self.s = s
        self.h = h
        self.t = t
        self.l = l
        super().__init__(name, notes)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("s", "length"), ("h", "length"), ("t", "length"),
                ("l", "length"))

    @property
    def _properties(self):
        """List of class properties, along with their units as ("property", "units")."""
        return [("b", "length")]

    @property
    def b(self):
        """float: Plate spacing; b = h + t. Setter works only if either h or t is None."""
        return self.h + self.t

    @b.setter
    def b(self, value):
        from warnings import warn
        if self.h is None and self.t is not None:
            self.h = value - self.t
        elif self.t is None and self.h is not None:
            self.t = value - self.h
        else:
            warn("Cannot set b, given h={}, t={}".format(self.h, self.t))


class GeomHxPlateRough(Geom):
    r"""Geometry of heat exchanger plate with a rough surface.

Parameters
-----------
b : float
    Plate channel spacing [m].
roughness : float
    Surface roughness factor. (As is used on the Moody chart)
"""

    validClasses = (cps.HxPlate, cps.HxUnitPlate)

    def __init__(self,
                 b,
                 roughness,
                 name="GeomHxPlateRough instance",
                 notes="no notes",
                 **kwargs):
        self.b = b
        self.roughness = roughness
        super().__init__(name, notes)
        for key, value in kwargs.items():
            setattr(self, key, value)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("b", "length"), ("roughness", "length/length"))

    @property
    def _properties(self):
        """List of class properties, along with their units as ("property", "units")."""
        return []


class GeomHxPlateSmooth(GeomHxPlateRough):
    r"""Geometry of smooth heat exchanger plate (roughness factor is always None).

Parameters
-----------
b : float
    Plate channel spacing [m].
"""

    def __init__(self,
                 b,
                 name="GeomHxPlateSmooth instance",
                 notes="no notes",
                 **kwargs):
        super().__init__(b, None, name, notes, **kwargs)

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("b", "length"))

    @property
    def _properties(self):
        """List of class properties, along with their units as ("property", "units")."""
        return [("roughness", "length/length")]
