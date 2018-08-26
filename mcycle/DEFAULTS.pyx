import timeit
import numpy as np

cpdef public double TOLABS = 1e-7
cpdef public double TOLREL = 1e-7
cpdef public double TOLABS_X = 1e-10
DIV_T = 5.
DIV_X = 0.1
cpdef public int MAXITER_CYCLE = 50
cpdef public int MAXITER_COMPONENT = 50
cpdef public int MAX_WALLS = 200
cpdef public double GRAVITY = 9.80665
cpdef public str COOLPROP_EOS = 'HEOS'
cpdef public str MPL_BACKEND = 'TkAgg'
#cpdef public str PLOT_DIR = 'plots'
#cpdef public int PLOT_DPI = 600 
#cpdef public str PLOT_FORMAT = 'png'
PLOT_DIR = 'plots'
PLOT_DPI = 600 
PLOT_FORMAT = 'png'
cpdef public str UNITS_SEPARATOR_NUMERATOR = '.'
cpdef public str UNITS_SEPARATOR_DENOMINATOR = '.'
cpdef public str PRINT_FORMAT_FLOAT = '{:.4e}'
cpdef public list RST_HEADINGS = ['=', '-', '^', '"']

METHODS = {'HxPlateCorrChevronHeatWf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp",
                     "tpEvap": "yanLin_tpEvap",
                     "tpCond": "hanLeeKim_tpCond"
                 },
                 'HxPlateCorrChevronFrictionWf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp",
                     "tpEvap": "yanLin_tpEvap",
                     "tpCond": "hanLeeKim_tpCond"
                 },
                 'HxPlateCorrChevronHeatSf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp"
                 },
                 'HxPlateCorrChevronFrictionSf': {
                     "sp": "chisholmWannairachchi_sp",
                     "liq": "chisholmWannairachchi_sp",
                     "vap": "chisholmWannairachchi_sp"
                 },
                 'HxPlateFinOffsetHeatWf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp",
                     "tpEvap": "",
                     "tpCond": ""
                 },
                 'HxPlateFinOffsetFrictionWf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp",
                     "tpEvap": "",
                     "tpCond": ""
                 },
                 'HxPlateFinOffsetHeatSf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp"
                 },
                 'HxPlateFinOffsetFrictionSf': {
                     "sp": "manglikBergles_offset_sp",
                     "liq": "manglikBergles_offset_sp",
                     "vap": "manglikBergles_offset_sp"
                 },
                 'HxPlateSmoothHeatWf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp",
                     "tpEvap": "shah_tpEvap",
                     "tpCond": "shah_tpCond"
                 },
                 'HxPlateSmoothFrictionWf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp",
                     "tpEvap": '',
                     "tpCond": ''
                 },
                 'HxPlateSmoothHeatSf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp"
                 },
                 'HxPlateSmoothFrictionSf': {
                     "sp": "gnielinski_sp",
                     "liq": "gnielinski_sp",
                     "vap": "gnielinski_sp"
                 }}

cdef public str _GITHUB_SOURCE_URL = 'https://github.com/momargoh/MCycle'
cdef public str _HOSTED_DOCS_URL = 'https://mcycle.readthedocs.io'

cdef public dict dimensionUnits = {
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

cdef dict dimensionsEquiv = {
    "htc": "power/area-temperature",
    "conductivity": "power/length-temperature",
    "fouling": "area-temperature/power",
    "velocity": "length/time",
    "acceleration": "length/time^2",
    "density": "mass/volume",
}  #: dict of str : Equivalents for composite dimensions.

cdef str _formatUnits(str dimensions, str separator):
    cdef list dimList = dimensions.split("-")
    cdef list units = []
    cdef str dim
    cdef list dimSplit
    for dim in dimList:
        dimSplit = dim.split("^")
        if len(dimSplit) == 1:
            units.append(dimensionUnits[dimSplit[0]])
        else:
            units.append(dimensionUnits[dimSplit[0]] + "^" + dimSplit[1])
    return separator.join(units)

cpdef public str getUnits(str dimension):
    """str : Returns formatted units for desired unit type which may either be a single dimension (eg. "length"), a composite dimension (eg. "power/length-temperature") or an equivalent dimension (eg. "density")."""
    cdef list dimSplit
    cpdef str output
    if dimension == "none":
        return dimensionUnits[dimension]
    else:
        if dimension in dimensionsEquiv:
            dimension = dimensionsEquiv[dimension]
        dimSplit = dimension.split("/")
        assert len(
            dimSplit
        ) <= 2, "Unit type may not contain more than one divide symbol '/'"
        output = _formatUnits(dimSplit[0], UNITS_SEPARATOR_NUMERATOR)
        if len(dimSplit) == 2:
            output += "/" + _formatUnits(dimSplit[1], UNITS_SEPARATOR_DENOMINATOR)
        return output

def getPlotDir(plotDir='default'):
    """str: Return string of plots directory. Creates the directory if it does not yet exist."""
    import os
    cwd = os.getcwd()
    if plotDir == 'default':
        plotDir = PLOT_DIR
    if plotDir is None or plotDir == "":
        plotDir = cwd
    else:
        if not os.path.exists(plotDir):
            os.makedirs(plotDir)
        plotDir = "{}/{}".format(cwd, plotDir)
    return plotDir

cpdef void updateDefaults():
    """Checks all defaults are valid and updates any that have changed, called when mcycle is imported."""
    from warnings import warn
    import matplotlib
    import os

    cpdef validPlotFormats = np.array(['png', 'PNG', 'jpg', 'JPG'], 'U')
    assert PLOT_FORMAT in validPlotFormats, "PLOT_FORMAT must be in {}, '{}' is invalid.".format(
        validPlotFormats, PLOT_FORMAT)
    try:
        matplotlib.use(MPL_BACKEND)
    except:
        warn("Unable to use {} as Matplotlib backend: remains as {}".format(
            MPL_BACKEND, matplotlib.get_backend()))
        
    #if not os.path.exists(PLOT_DIR):
    #    os.makedirs(PLOT_DIR)
    assert MAXITER_CYCLE > 0, "MAXITER_CYCLE must be >0, {} is invalid.".format(
        MAXITER_CYCLE)
    assert MAXITER_COMPONENT > 0, "MAXITER_COMPONENT must be >0, {} is invalid.".format(
        MAXITER_COMPONENT)
    assert MAX_WALLS > 1, "MAX_WALLS must be >1, {} is invalid.".format(MAX_WALLS)
    cpdef unitsepnum = np.array([".", "-"], dtype='U')
    if UNITS_SEPARATOR_NUMERATOR not in unitsepnum:
        print(
            "It is recommended to select UNITS_SEPARATOR_NUMERATOR from {}, (given: {})".
            format(unitsepnum, UNITS_SEPARATOR_NUMERATOR))
    cpdef unitsepdenom = np.array([".", "-", "/"], dtype='U')
    if UNITS_SEPARATOR_DENOMINATOR not in unitsepdenom:
        print(
            "It is recommended to select UNITS_SEPARATOR_DENOMINATOR from {}, (given: {})".
            format(unitsepdenom, UNITS_SEPARATOR_DENOMINATOR))

def timeThis(func):
    "Basic decorator to time runs."
    def func_wrapper(*args, **kwargs):
        cdef float start = timeit.default_timer()
        ret = func(*args, **kwargs)
        cdef float runTime = timeit.default_timer() - start
        cdef float m, s, h
        if runTime < 60.:
            print("{}() took {} seconds to run.".format(func.__name__, runTime))
        elif runTime < 3600.:
            m, s = divmod(runTime, 60)
            print("{}() took {} mins {} s to run.".format(func.__name__, m, s))
        else:
            m, s = divmod(runTime, 60)
            h, m = divmod(m, 60)
            print("{}() took {} hrs {} mins {} s to run.".format(func.__name__, h, m, s))
        return ret
    return func_wrapper
