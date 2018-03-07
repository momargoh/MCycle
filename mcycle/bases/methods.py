from .geom import Geom


class Methods:
    """Methods class is used to store all information about selection of computational methods."""

    def __init__(self,
                 HxPlateCorrChevronHeatWf={
                     "sp": "chisholmWannairachchi_1phase",
                     "liq": "chisholmWannairachchi_1phase",
                     "vap": "chisholmWannairachchi_1phase",
                     "tpEvap": "yanLin_2phase_boiling",
                     "tpCond": "hanLeeKim_2phase_condensing"
                 },
                 HxPlateCorrChevronFrictionWf={
                     "sp": "chisholmWannairachchi_1phase",
                     "liq": "chisholmWannairachchi_1phase",
                     "vap": "chisholmWannairachchi_1phase",
                     "tpEvap": "yanLin_2phase_boiling",
                     "tpCond": "hanLeeKim_2phase_condensing"
                 },
                 HxPlateCorrChevronHeatSf={
                     "sp": "savostinTikhonov_1phase",
                     "liq": "savostinTikhonov_1phase",
                     "vap": "savostinTikhonov_1phase"
                 },
                 HxPlateCorrChevronFrictionSf={
                     "sp": "savostinTikhonov_1phase",
                     "liq": "savostinTikhonov_1phase",
                     "vap": "savostinTikhonov_1phase"
                 },
                 HxPlateFinOffsetHeatWf={
                     "sp": "manglikBergles_offset_allphase",
                     "liq": "manglikBergles_offset_allphase",
                     "vap": "manglikBergles_offset_allphase",
                     "tpEvap": "manglikBergles_offset_allphase",
                     "tpCond": "manglikBergles_offset_allphase"
                 },
                 HxPlateFinOffsetFrictionWf={
                     "sp": "manglikBergles_offset_allphase",
                     "liq": "manglikBergles_offset_allphase",
                     "vap": "manglikBergles_offset_allphase",
                     "tpEvap": "manglikBergles_offset_allphase",
                     "tpCond": "manglikBergles_offset_allphase"
                 },
                 HxPlateFinOffsetHeatSf={
                     "sp": "manglikBergles_offset_allphase",
                     "liq": "manglikBergles_offset_allphase",
                     "vap": "manglikBergles_offset_allphase"
                 },
                 HxPlateFinOffsetFrictionSf={
                     "sp": "manglikBergles_offset_allphase",
                     "liq": "manglikBergles_offset_allphase",
                     "vap": "manglikBergles_offset_allphase"
                 },
                 HxPlateSmoothHeatWf={
                     "sp": "gnielinski_1phase",
                     "liq": "gnielinski_1phase",
                     "vap": "gnielinski_1phase",
                     "tpEvap": "shah_2phase_boiling",
                     "tpCond": "shah_2phase_condensing"
                 },
                 HxPlateSmoothFrictionWf={
                     "sp": None,
                     "liq": None,
                     "vap": None,
                     "tpEvap": None,
                     "tpCond": None
                 },
                 HxPlateSmoothHeatSf={
                     "sp": "manglikBergles_offset_allphase",
                     "liq": "manglikBergles_offset_allphase",
                     "vap": "manglikBergles_offset_allphase"
                 },
                 HxPlateSmoothFrictionSf={
                     "sp": "manglikBergles_offset_allphase",
                     "liq": "manglikBergles_offset_allphase",
                     "vap": "manglikBergles_offset_allphase"
                 }):
        self.HxPlateCorrChevronHeatWf = HxPlateCorrChevronHeatWf
        self.HxPlateCorrChevronFrictionWf = HxPlateCorrChevronFrictionWf
        self.HxPlateCorrChevronHeatSf = HxPlateCorrChevronHeatSf
        self.HxPlateCorrChevronFrictionSf = HxPlateCorrChevronFrictionSf
        self.HxPlateFinOffsetHeatWf = HxPlateFinOffsetHeatWf
        self.HxPlateFinOffsetFrictionWf = HxPlateFinOffsetFrictionWf
        self.HxPlateFinOffsetHeatSf = HxPlateFinOffsetHeatSf
        self.HxPlateFinOffsetFrictionSf = HxPlateFinOffsetFrictionSf
        self.HxPlateSmoothHeatWf = HxPlateSmoothHeatWf
        self.HxPlateSmoothFrictionWf = HxPlateSmoothFrictionWf
        self.HxPlateSmoothHeatSf = HxPlateSmoothHeatSf
        self.HxPlateSmoothFrictionSf = HxPlateSmoothFrictionSf

    @property
    def _inputs(self):
        """Tuple of input parameters in order taken by constructor, along with their units as ("parameter", "units")."""
        return (("HxPlateCorrChevronHeatWf", "none"),
                ("HxPlateCorrChevronFrictionWf", "none"),
                ("HxPlateCorrChevronHeatSf", "none"),
                ("HxPlateCorrChevronFrictionSf", "none"),
                ("HxPlateFinOffsetHeatWf", "none"),
                ("HxPlateFinOffsetFrictionWf", "none"),
                ("HxPlateFinOffsetHeatSf", "none"),
                ("HxPlateFinOffsetFrictionSf", "none"),
                ("HxPlateHeatWf", "none"), ("HxPlateSmoothFrictionWf", "none"),
                ("HxPlateSmoothHeatSf", "none"),
                ("HxPlateSmoothFrictionSf", "none"))

    @property
    def _properties(self):
        """List of component properties, along with their units as ("property", "units")."""
        return []

    def lookup(self, cls, *args, **kwargs):
        """looks up method based on the given class and any additional args/ kwargs.

Parameters
------------
cls : mcycle class
    Class requiring the method. Can be a subclass of Component.
args : optional
    Variable arguments
kwargs : optional
    Keyword arguments

  .. note:: Additional arguments required according to cls (must be either all args or all kwargs; combination of args and kwargs is not accepted).

    - HxPlate or HxUnitPlate: args or kwargs must be in the form (geom, transfer, phase, flow).

        """
        from ..bases import Component
        from .. import components as cps
        from ..library import heat_transfer_methods as htms
        if issubclass(cls, Component):
            if cls is cps.HxPlate or cls is cps.HxUnitPlate:
                """args must be in the form [geom, transfer, phase, flow]."""
                listKwargs = ("geom", "transfer", "phase", "flow")
                if len(args) == 4 and len(kwargs.keys()) == 0:
                    geom, transfer, phase, flow = args
                elif len(kwargs.keys()) == 4 and len(args) == 0:
                    assert all(kw in kwargs.keys() for kw in listKwargs
                               ), "kwargs must contain {}, ({} given)".format(
                                   listKwargs, kwargs.keys())
                    geom, transfer, phase, flow = kwargs["geom"], kwargs[
                        "transfer"], kwargs["phase"], kwargs["flow"]
                else:
                    raise TypeError(
                        "lookup() of {} requires {} as {} args or kwargs. (args given: {}. kwargs given: {})".
                        format(cls.__name__, listKwargs,
                               len(listKwargs), args, kwargs.keys()))

                listGeomHxPlate = ("GeomHxPlateCorrChevron",
                                   "GeomHxPlateFinOffset", "GeomHxPlateSmooth")
                listTransfer = ("heat", "friction")
                listPhase = ('sp', 'liq', 'vap', 'tpEvap', 'tpCond')
                listFlows = ("wf", "sf")
                assert geom.__name__ in listGeomHxPlate, "'geom' arg must be in {}, ({} given)".format(
                    listGeomHxPlate, geom)
                assert flow.lower(
                ) in listFlows, "'flow' arg must be in {} ({} given)".format(
                    listFlows, flow)
                assert transfer.lower(
                ) in listTransfer, "'transfer' arg must be in {}, ({} given)".format(
                    listTransfer, transfer)

                if phase[0:2].lower() == "tp":
                    phase = "".join(phase[0:2].lower() + phase[2:].title())
                assert phase in listPhase, "'phase' arg must be in listPhase ({} given)".format(
                    listPhase, phase)
                lookup_dict = geom.__name__.strip(
                    "Geom") + transfer.title() + flow.title()
                method_dict = getattr(self, lookup_dict)
                try:
                    return getattr(htms, method_dict[phase])
                except:
                    raise TypeError(
                        "Method for {} phase of {} not found (is None)".format(
                            phase, method_dict))
            else:
                pass
        else:
            pass

    def set(self, method, geoms, transfers, flows, phases):
        """Set a method to multiple geometries, transfer types, flows and phases.

Parameters
-----------
method : str
    String of method/function name.
geoms : list of str
    List of strings of geometry names that method should be set for.
transfers : list of str
    List of strings of transfer types to be set for. Must be "heat" and or "friction".
flows : list of str
    List of strings of flows to be set for. Must be "wf" and or "sf".
phases : list of str or str
    List of strings of phases to be set for. Must be from "sp", "liq", "vap", "tpEvap", "tpCond". The following string inputs are also accepted:

    - "all" : Equivalent to ["sp", "liq", "vap", "tpEvap", "tpCond"]
    - "all-sp" : Equivalent to ["sp", "liq", "vap"]
    - "all-tp" : Equivalent to ["tpEvap", "tpCond"]
        """
        if transfers == "all":
            transfers = ["heat", "friction"]
        if flows == "all":
            flows = ["wf", "sf"]
        if phases == "all":
            phases = ["sp", "liq", "vap", "tpEvap", "tpCond"]
        if phases == "all-sp":
            phases = ["sp", "liq", "vap"]
        if phases == "all-tp":
            phases = ["tpEvap", "tpCond"]

        for geom in geoms:
            if issubclass(type(geom), Geom):
                geom = geom.__name__
            geom = geom.strip("Geom")
            for transfer in transfers:
                for flow in flows:
                    for phase in phases:
                        lookup_dict = geom + transfer.title() + flow.title()
                        method_dict = getattr(self, lookup_dict)
                        method_dict[phase] = method
