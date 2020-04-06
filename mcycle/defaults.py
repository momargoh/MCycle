from .logger import log
from .constants import *
import CoolProp as CP

TOLATTR = 'h'
TOLABS = 1e-7
TOLREL = 1e-7
DIV_T = 5.
DIV_X = 0.1
MAXITER_CYCLE = 50
MAXITER_COMPONENT = 50
MAX_WALLS = 200
TRY_BUILD_PHASE_ENVELOPE = True
GRAVITY = 9.80665
DP_PORT_IN_FACTOR = 1.0
DP_PORT_OUT_FACTOR = 0.4
COOLPROP_EOS = 'HEOS'
MPL_BACKEND = 'TkAgg'
PLOT_DIR = '.'
PLOT_DPI = 600
PLOT_FORMAT = 'png'
PLOT_COLOR = ['C0', 'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'C7', 'C8', 'C9']
#PLOT_COLOR = ['0', '0.5', '0.2', '0.7', '0.4', '0.1', '0.8', '0.3'] #grayscale
LINESTYLES = {
    'solid': (0, ()),
    'loosely dotted': (0, (1, 10)),
    'dotted': (0, (1, 5)),
    'densely dotted': (0, (1, 1)),
    'loosely dashed': (0, (5, 10)),
    'dashed': (0, (5, 5)),
    'densely dashed': (0, (5, 1)),
    'loosely dashdotted': (0, (3, 10, 1, 10)),
    'dashdotted': (0, (3, 5, 1, 5)),
    'densely dashdotted': (0, (3, 1, 1, 1)),
    'loosely dashdotdotted': (0, (3, 10, 1, 10, 1, 10)),
    'dashdotdotted': (0, (3, 5, 1, 5, 1, 5)),
    'densely dashdotdotted': (0, (3, 1, 1, 1, 1, 1))
}  # https://matplotlib.org/gallery/lines_bars_and_markers/linestyles.html
PLOT_LINESTYLE = [
    LINESTYLES[style] for style in [
        'solid', 'densely dashdotted', 'densely dashed', 'densely dotted',
        'densely dashdotdotted', 'dashed'
    ]
]
PLOT_MARKER = ['']  #['.', 'x', 's', 'v', '^', 'x', 'p', 'D', '']
#
UNITS_SEPARATOR_NUMERATOR = '.'
UNITS_SEPARATOR_DENOMINATOR = '.'
UNITS_FORMAT = 'comma'  # '', 'parentheses', 'brackets', 'braces', 'comma', with or without suffix '-nospace'
PRINT_FORMAT_FLOAT = '{: .4e}'
RST_HEADINGS = ['=', '-', '^', '"']

CONFIG = None
METHODS = {
    'GeomHxPlateCorrugatedChevron': {
        TRANSFER_HEAT: {
            UNITPHASE_ALL: "chisholmWannairachchi_sp",
            UNITPHASE_TWOPHASE_EVAPORATING: "yanLin_tpEvap",
            UNITPHASE_TWOPHASE_CONDENSING: "hanLeeKim_tpCond"
        },
        TRANSFER_FRICTION: {
            UNITPHASE_ALL: "chisholmWannairachchi_sp",
            UNITPHASE_TWOPHASE_EVAPORATING: "yanLin_tpEvap",
            UNITPHASE_TWOPHASE_CONDENSING: "hanLeeKim_tpCond"
        }
    },
    'GeomHxPlateFinStraight': {
        TRANSFER_HEAT: {
            UNITPHASE_ALL: "petukhovPopov_sp_h",
            UNITPHASE_ALL_TWOPHASE: ""
        },
        TRANSFER_FRICTION: {
            UNITPHASE_ALL: "bhattiShah_sp_f",
            UNITPHASE_ALL_TWOPHASE: ""
        }
    },
    'GeomHxPlateFinOffset': {
        TRANSFER_HEAT: {
            UNITPHASE_ALL: "manglikBergles_offset_sp",
            UNITPHASE_ALL_TWOPHASE: ""
        },
        TRANSFER_FRICTION: {
            UNITPHASE_ALL: "manglikBergles_offset_sp",
            UNITPHASE_ALL_TWOPHASE: ""
        }
    },
    'GeomHxPlateSmooth': {
        TRANSFER_HEAT: {
            UNITPHASE_ALL: "shibani_sp_h",
            UNITPHASE_TWOPHASE_EVAPORATING: "huang_tpEvap_h",
            UNITPHASE_TWOPHASE_CONDENSING: ""
        },
        TRANSFER_FRICTION: {
            UNITPHASE_ALL: "rothfus_sp_f",
            UNITPHASE_ALL_TWOPHASE: ""
        }
    },
    'Geom Name Here': {
        TRANSFER_HEAT: {
            UNITPHASE_ALL: "",
            UNITPHASE_VAPOUR: "",
            UNITPHASE_TWOPHASE_EVAPORATING: "",
            UNITPHASE_TWOPHASE_CONDENSING: "",
            WORKING_FLUID: {
                UNITPHASE_VAPOUR: "",
                UNITPHASE_TWOPHASE_CONDENSING: ""
            },
            SECONDARY_FLUID: {
                UNITPHASE_VAPOUR: ""
            }
        },
        TRANSFER_FRICTION: {
            UNITPHASE_ALL: "",
            WORKING_FLUID: {
                UNITPHASE_LIQUID: "",
            },
            SECONDARY_FLUID: {
                UNITPHASE_LIQUID: "",
            }
        }
    },
}

DIMENSIONS = {
    'A': {
        '': 'length^2'
    },
    'ARatio': {
        '': ''
    },
    'arrangement': {
        '': ''
    },
    'b': {
        '': 'length'
    },
    'beta': {
        '': 'angle'
    },
    'cp': {
        '': '"energy/mass-temperature'
    },
    'D': {
        '': 'length'
    },
    'data': {
        '': ''
    },
    'deg': {
        '': ''
    },
    'dp': {
        '': 'pressure'
    },
    'dpAcc': {
        '': 'pressure'
    },
    'dpF': {
        '': 'pressure'
    },
    'dpPort': {
        '': 'pressure'
    },
    'efficiencyExergy': {
        '': ''
    },
    'efficiencyIsentropic': {
        '': ''
    },
    'efficiencyThermal': {
        '': ''
    },
    'eos': {
        '': ''
    },
    'fluid': {
        '': ''
    },
    'h': {
        '': 'power/area-temperature',
        'GeomHxPlateFinStraight': 'length',
        'GeomHxPlateFinOffset': 'length',
        'FlowState': 'energy/mass',
        'FlowStatePoly': 'energy/mass'
    },
    'I': {
        '': 'energy'
    },
    '_iphase': {
        '': ''
    },
    'isEvap': {
        '': ''
    },
    'k': {
        '': 'power/length-temperature'
    },
    'l': {
        '': 'length'
    },
    'L': {
        '': 'length'
    },
    'm': {
        '': 'mass/time'
    },
    'N': {
        '': ''
    },
    'name': {
        '': ''
    },
    'p': {
        '': 'pressure'
    },
    'passes': {
        '': ''
    },
    'phi': {
        '': ''
    },
    'P': {
        '': 'power'
    },
    'pitchCorr': {
        '': 'length'
    },
    'Pr': {
        '': ''
    },
    'pRatio': {
        '': ''
    },
    'Q': {
        '': 'power'
    },
    'QCool': {
        '': 'power'
    },
    'QHeat': {
        '': 'power'
    },
    'Rf': {
        '': 'fouling'
    },
    'rho': {
        '': 'density'
    },
    'roughness': {
        '': 'length/length'
    },
    's': {
        '': 'energy/mass-temperature',
        'GeomHxPlateFinStraight': 'length',
        'GeomHxPlateFinOffset': 'length'
    },
    'sense': {
        '': ''
    },
    'subcool': {
        '': 'temperature'
    },
    'superheat': {
        '': 'temperature'
    },
    't': {
        '': 'length'
    },
    'T': {
        '': 'temperature'
    },
    'vertical': {
        '': ''
    },
    'V': {
        '': 'length^3/time'
    },
    'visc': {
        '': 'force-time/area'
    },
    'W': {
        '': 'length'
    },
    'x': {
        '': ''
    },
}


def setupREFPROP(ALTERNATIVE_REFPROP_PATH='',
                 ALTERNATIVE_REFPROP_LIBRARY_PATH='',
                 ALTERNATIVE_REFPROP_HMX_BNC_PATH=''):
    """Configures CoolProp to find your REFPROP files. Note the FLUIDS folder must be renamed to lowercase ``fluids`` and MIXTURES folder must be renamed to lowercase ``mixtures`` to be found by CoolProp (on Linux, not tested for Windows). See http://www.coolprop.org/coolprop/REFPROP.html#path-issues for more info about each configuration parameter."""
    CP.CoolProp.set_config_string(CP.ALTERNATIVE_REFPROP_PATH,
                                  ALTERNATIVE_REFPROP_PATH)
    log('info', 'CoolProp.ALTERNATIVE_REFPROP_PATH set to: "{}"'.format(
        ALTERNATIVE_REFPROP_PATH))
    CP.CoolProp.set_config_string(CP.ALTERNATIVE_REFPROP_LIBRARY_PATH,
                                  ALTERNATIVE_REFPROP_LIBRARY_PATH)
    log('info',
        'CoolProp.ALTERNATIVE_REFPROP_LIBRARY_PATH set to: "{}"'.format(
            ALTERNATIVE_REFPROP_LIBRARY_PATH))
    CP.CoolProp.set_config_string(CP.ALTERNATIVE_REFPROP_HMX_BNC_PATH,
                                  ALTERNATIVE_REFPROP_HMX_BNC_PATH)
    log('info',
        'CoolProp.ALTERNATIVE_REFPROP_HMX_BNC_PATH set to: "{}"'.format(
            ALTERNATIVE_REFPROP_HMX_BNC_PATH))


def makePlotDir(plotDir='default'):
    """str: Return string of plots directory. Creates the directory if it does not yet exist."""
    import os
    cwd = os.getcwd()
    if plotDir == "":
        plotDir = "."
    if plotDir == 'default':
        plotDir = PLOT_DIR
    else:
        globals()['PLOT_DIR'] = plotDir
    if not os.path.exists(plotDir):
        os.makedirs(plotDir)
    return plotDir


dimensionUnits = {
    "": "",
    "angle": "deg",
    "area": "m^2",
    "energy": "J",
    "force": "N",
    "length": "m",
    "mass": "kg",
    "power": "W",
    "pressure": "Pa",
    "temperature": "K",
    "time": "s",
    "volume": "m^3"
}

dimensionsEquiv = {
    "htc": "power/area-temperature",
    "conductivity": "power/length-temperature",
    "fouling": "area-temperature/power",
    "velocity": "length/time",
    "acceleration": "length/time^2",
    "density": "mass/volume",
}

attributeSuffixes = [
    'Wf', 'Sf', 'Wall', 'Plate', 'Port', 'Acc', 'Head', 'F', 'Vert', 'In',
    'Out', 'Net', 'Evap', 'Exp', 'Cond', 'Comp'
]


def getDimensions(attribute, className=''):
    """str : Returns attribute dimensions from DIMENSIONS for a given class

Parameters
-----------
attribute : str
    Class attribute name
className : str, optional
    Class name as string. Defaults to ''.
    """
    if attribute.startswith('coeffs_'):
        return ''
    for suffix in attributeSuffixes:
        if suffix in attribute:
            attribute = attribute.split(suffix)[0]
    try:
        dimension_lookup = DIMENSIONS[attribute]
        if className in dimension_lookup:
            return dimension_lookup[className]
        else:
            return dimension_lookup['']
    except Exception as exc:
        log('debug',
            'defaults.getDimensions: did not find dimensions for "{}". Consider raising an issue on Github.'.
            format(attribute), exc)
        return ''


def _formatUnits(dimensions, separator):
    dimList = dimensions.split("-")
    units = []
    for dim in dimList:
        dimSplit = dim.split("^")
        if len(dimSplit) == 1:
            units.append(dimensionUnits[dimSplit[0]])
        else:
            units.append(dimensionUnits[dimSplit[0]] + "^" + dimSplit[1])
    return separator.join(units)


def getUnits(dimension):
    """str : Returns units for desired dimension (eg. "length"), a composite dimension (eg. "power/length-temperature") or an equivalent dimension (eg. "density")."""
    if dimension == "":
        return dimensionUnits[dimension]
    else:
        if dimension in dimensionsEquiv:
            dimension = dimensionsEquiv[dimension]
        dimSplit = dimension.split("/")
        assert len(
            dimSplit
        ) <= 2, "Dimension may not contain more than one divide symbol '/'"
        output = _formatUnits(dimSplit[0], UNITS_SEPARATOR_NUMERATOR)
        if len(dimSplit) == 2:
            output += "/" + _formatUnits(dimSplit[1],
                                         UNITS_SEPARATOR_DENOMINATOR)
        return output


def getUnitsFormatted(dimension):
    """str : Returns formatted units for desired dimension based on UNITS_FORMAT.
Eg, if UNITS_FORMAT=='brackets-nospace': return '[units]', if UNITS_FORMAT=='braces': return ' {units}'."""
    units = getUnits(dimension)
    if units == "":
        return ""
    else:
        if UNITS_FORMAT == "brackets":
            units = " (" + units + ")"
        elif UNITS_FORMAT == "parentheses":
            units = " [" + units + "]"
        elif UNITS_FORMAT == "braces":
            units = " {" + units + "}"
        elif UNITS_FORMAT == "comma":
            units = ", " + units
        if 'nospace' in UNITS_FORMAT:
            units.replace(' ', '')
        return units


def check():
    """Checks all defaults are valid, called when mcycle is imported."""
    from warnings import warn
    import matplotlib
    import os

    validPlotFormats = ['png', 'PNG', 'jpg', 'JPG']
    assert PLOT_FORMAT in validPlotFormats, "PLOT_FORMAT must be in {}, '{}' is invalid.".format(
        validPlotFormats, PLOT_FORMAT)
    try:
        matplotlib.use(MPL_BACKEND)
    except Exception as exc:
        msg = "Unable to use {} as Matplotlib backend: remains as {}".format(
            MPL_BACKEND, matplotlib.get_backend())
        log('warning', msg, exc)
        warn(msg)
    assert MAXITER_CYCLE > 0, "MAXITER_CYCLE must be >0, {} is invalid.".format(
        MAXITER_CYCLE)
    assert MAXITER_COMPONENT > 0, "MAXITER_COMPONENT must be >0, {} is invalid.".format(
        MAXITER_COMPONENT)
    assert MAX_WALLS > 1, "MAX_WALLS must be >1, {} is invalid.".format(
        MAX_WALLS)
    unitsepnum = [".", "-"]
    if UNITS_SEPARATOR_NUMERATOR not in unitsepnum:
        print(
            "It is recommended to select UNITS_SEPARATOR_NUMERATOR from {}, (given: {})".
            format(unitsepnum, UNITS_SEPARATOR_NUMERATOR))
    unitsepdenom = [".", "-", "/"]
    if UNITS_SEPARATOR_DENOMINATOR not in unitsepdenom:
        print(
            "It is recommended to select UNITS_SEPARATOR_DENOMINATOR from {}, (given: {})".
            format(unitsepdenom, UNITS_SEPARATOR_DENOMINATOR))

    if globals()['COOLPROP_EOS'] == "REFPROP":
        try:
            CP.CoolProp.PropsSI("T", "P", 101325, "Q", 0, "REFPROP::Water")
        except Exception as exc:
            msg = "Failed to use REFPROP backend, setting back to 'HEOS'. Check error message in log and consider specifying your REFPROP directory using setupREFPROP()"
            globals()['COOLPROP_EOS'] = "HEOS"
            log('warning', msg, exc)
            warn(msg)
