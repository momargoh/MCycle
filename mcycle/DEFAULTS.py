import timeit


def timeThis(func):
    def func_wrapper(*args, **kwargs):
        start = timeit.default_timer()
        ret = func(*args, **kwargs)
        runTime = timeit.default_timer() - start
        if runTime < 60.:
            print(
                "{}() took {} seconds to run.".format(func.__name__, runTime))
        elif runTime < 3600:
            m, s = divmod(runTime, 60)
            print("{}() took {} mins {} s to run.".format(func.__name__, m, s))
        else:
            m, s = divmod(runTime, 60)
            h, m = divmod(m, 60)
            print("{}() took {} hrs {} mins {} s to run.".format(func.__name__,
                                                                 h, m, s))

        return ret

    return func_wrapper


TOLABS = 1e-7  #: float : Generic absolute tolerance (usually called for FlowState properties).
TOLREL = 1e-7  #: float : Generic relative tolerance (usually called for FlowState properties).
TOLABS_X = 1e-10  #: float : absolute tolerance for FlowState qualities.
GRAVITY = 9.80665  #: float : Vertical acceleration due to gravity [m/s^2].
MAXITERATIONSCYCLE = 50  #: int : Maximum number of iterations to find convergence of a cycle process.
MAXITERATIONSCOMPONENT = 50  #: int : Maximum number of iterations to find convergence of a component process.
MAXWALLS = 200  #: Maximum number of walls/plates for a heat exchanger.
DEFAULT_COOLPROP_LIBRARY = "HEOS"  #: str : Library used by CoolProp. Must be "HEOS" or "REFPROP".
MPLBACKEND = "TkAgg"  #: str : Matplotlib backend.
DEFAULT_PLOT_FOLDER = "plots"  #: str : Subfolder for saving plot images.
DEFAULT_PLOT_FORMAT = "png"  #: str : Image format for saving plots.
DEFAULT_PLOT_DPI = 600  #: int : dpi of plot images.
UNITSEPARATORNUM = "."  #: str : Symbol to separate units in the numerator.
UNITSEPARATORDENOM = "."  #: str : Symbol to separate units in the denomenator.

PRINTFORMATFLOAT = "{:.4e}"  #: Formatting used in summary() for floats. Must be wrapped by {}. Refer to `<https://docs.python.org/3/library/string.html#formatspec>`_
RSTHEADINGS = ['=', '-', '^', '"']  #: Used in summary() to stagger headings

dimensionUnits = {
    "none": "",
    "angle": "deg",
    "area": "m^2",
    "energy": "J",
    "force": "N",
    "length": "m",
    "mass": "Kg",
    "power": "W",
    "pressure": "Pa",
    "temperature": "K",
    "time": "s",
    "volume": "m^3"
}  #: dict of str : Dimensions and their units.

dimensionsEquiv = {
    "htc": "power/area-temperature",
    "conductivity": "power/length-temperature",
    "fouling": "area-temperature/power",
    "velocity": "length/time",
    "acceleration": "length/time^2",
    "density": "mass/volume",
}  #: dict of str : Equivalents for composite dimensions.


def _formatUnits(dimensions, separator):
    dimensions = dimensions.split("-")
    units = []
    for i in dimensions:
        i = i.split("^")
        if len(i) == 1:
            units.append(dimensionUnits[i[0]])
        else:
            units.append(dimensionUnits[i[0]] + "^" + i[1])
    return separator.join(units)

def getUnits(dimension):
    """str: Returns formatted units for desired unit type which may either be a single unit (eg. "length") or a combined unit (eg. density)."""
    if dimension == "none":
        return dimensionUnits[dimension]
    else:
        if dimension in dimensionsEquiv:
            dimension = dimensionsEquiv[dimension]
        dimension = dimension.split("/")
        assert len(
            dimension
        ) <= 2, "Unit type may not contain more than one divide symbol '/'"
        output = _formatUnits(dimension[0], UNITSEPARATORNUM)
        if len(dimension) == 2:
            output += "/" + _formatUnits(dimension[1], UNITSEPARATORDENOM)
        return output


# Do not change below
def _checkDefaults():
    """Checks all defaults are valid, called when mcycle is imported."""
    from warnings import warn
    import matplotlib

    validPlotFormats = ['png', 'PNG', 'jpg', 'JPG']
    assert DEFAULT_PLOT_FORMAT in validPlotFormats, "DEFAULT_PLOT_FORMAT must be in {}, '{}' is invalid.".format(
        validPlotFormats, DEFAULT_PLOT_FORMAT)
    try:
        matplotlib.use(MPLBACKEND)
    except:
        warn("Unable to use {} as Matplotlib backend: remains as {}".format(
            MPLBACKEND, matplotlib.get_backend()))
    assert MAXITERATIONSCYCLE > 0, "MAXITERATIONSCYCLE must be >0, {} is invalid.".format(
        MAXITERATIONSCYCLE)
    assert MAXITERATIONSCOMPONENT > 0, "MAXITERATIONSCOMPONENT must be >0, {} is invalid.".format(
        MAXITERATIONSCOMPONENT)
    assert MAXWALLS > 1, "MAXWALLS must be >1, {} is invalid.".format(MAXWALLS)
    unitsepnum = [".", "-"]
    if UNITSEPARATORNUM not in unitsepnum:
        print(
            "It is recommended to select UNITSEPARATORNUM from {}, (given: {})".
            format(unitsepnum, UNITSEPARATORNUM))
    unitsepdenom = [".", "-", "/"]
    if UNITSEPARATORDENOM not in unitsepdenom:
        print(
            "It is recommended to select UNITSEPARATORDENOM from {}, (given: {})".
            format(unitsepdenom, UNITSEPARATORDENOM))


_checkDefaults()
