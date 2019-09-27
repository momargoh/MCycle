from ..bases.flowstate cimport FlowState
from ..logger import log
from .. import DEFAULTS
from ..DEFAULTS import *
from warnings import warn
import numpy as np
import matplotlib.pyplot as plt
import CoolProp as CP

cpdef dict saturationCurve(str fluid, int steps=200):
    """dict: calculate saturation curve properties (T, s, p, h) and return in dict"""
    cdef FlowState f
    cdef double Tcrit, Tmin, pCrit
    cdef list sat0T = []
    cdef list sat0s = []
    cdef list sat0p = []
    cdef list sat0h = []
    cdef list sat1T = []
    cdef list sat1s = []
    cdef list sat1p = []
    cdef list sat1h = []
    try:
        f = FlowState(fluid)
        TCrit = f.TCrit()
        TMin = f.TMin()
        for T in np.linspace(TMin, TCrit, steps, False):
            f.updateState(CP.QT_INPUTS, 0, T)
            sat0T.append(T)
            sat0s.append(f.s())
            sat0p.append(f.p())
            sat0h.append(f.h())
            f.updateState(CP.QT_INPUTS, 1, T)
            sat1T.append(T)
            sat1s.append(f.s())
            sat1p.append(f.p())
            sat1h.append(f.h())
        try:
            f.updateState(CP.PT_INPUTS, f.pCrit(), TCrit)
            sat0T.append(TCrit)
            sat0s.append(f.s())
            sat0p.append(f.p())
            sat0h.append(f.h())
        except:
            log("info", "saturationCurve(): Could not compute critical point properties for {}.".format(fluid))
        sat0T = sat0T + list(reversed(sat1T))
        sat0s = sat0s + list(reversed(sat1s))
        sat0p = sat0p + list(reversed(sat1p))
        sat0h = sat0h + list(reversed(sat1h))
        return {'T': sat0T, 's': sat0s, 'p': sat0p, 'h': sat0h}
        
    except:
        msg = "Could not produce saturation curve for {}".format(fluid)
        log("warning", msg)
        warn(msg)
        return {'T': [], 's': [], 'p': [], 'h': []}

def plot_saturationCurve(fluids, 
                         graph='T-s', steps=200,
                         title='default',
                         show=True,
                         savefig=False,
                         savefig_name='saturation_curve',
                         savefig_folder='default',
                         savefig_format='default',
                         savefig_dpi='default',
                         linestyle='-',
                         legend_loc='best'):
    """void: plot saturation curve(s)

Parameters
    ----------
fluids : str or list
    Name of fluid or list of names of fluids.
graph : str, optional
    Type of saturation curve to plot. Must be 'T-s' or 'p-h'. Defaults to 'T-s'.
steps : int, optional
    steps parameter parsed to numpy.linspace for resolution of saturation curve. Defaults to 200.
title : str, optional
    Title to display on graph. Defaults to '{graph} saturation curve(s)'.
show : str, optional
    Show figure in window. Defaults to True.
savefig : bool, optional
    Save figure as '.png' or '.jpg' file in desired folder. Defaults to False.
savefig_name : str, optional
    Name for saved plot file. Defaults to 'plot_RankineBasic'.
savefig_folder : str, optional
    Folder in the current working directory to save figure into. Folder is created if it does not already exist. Figure is saved as "./savefig_folder/savefig_name.savefig_format". If None or '', figure is saved directly into the current working directory. If ``'default'``, :meth:`mcycle.DEFAULTS.PLOT_DIR <mcycle.DEFAULTS.PLOT_DIR>` is used. Defaults to ``'default'``.
savefig_format : str, optional
    Format of saved plot file. Must be ``'png'`` or ``'jpg'``. If ``'default'``, :meth:`mcycle.DEFAULTS.PLOT_FORMAT <mcycle.DEFAULTS.PLOT_FORMAT>` is used. Defaults to ``'default'``.
savefig_dpi : int, optional
    Dots per inch / pixels per inch of the saved image. Passed as a matplotlib.plot argument. If ``'default'``, :meth:`mcycle.DEFAULTS.PLOT_DPI <mcycle.DEFAULTS.PLOT_DPI>` is used. Defaults to ``'default'``.
linestyle : str, optional
    Style of line used for working fluid plot points. Passed as a matplotlib.plot argument. Defaults to '-'.
    """
    graph_formatted = graph.lower().replace('-', '')
    assert graph_formatted in ['ts', 'ph', 'temperatureentropy', 'pressureenthalpy']
    assert savefig_format in ['default',
                              'png', 'PNG', 'jpg', 'JPG'
    ], "savefig format must be 'png' or 'jpg', '{0}' is invalid.".format(
        savefig_format)
    if title == 'default':
        title = "{} saturation curve".format(graph)
        if type(fluids) is list:
            title += 's'
    if graph_formatted == 'ts' or graph_formatted == 'temperatureentropy':
        x = "s"
        y = "T"
        xlabel = 'entropy, J/kg.K'
        ylabel = 'temperature, K'
    elif graph_formatted == 'ph' or graph_formatted == 'pressureenthalpy':
        x = "h"
        y = "p"
        xlabel = 'enthalpy, J/kg'
        ylabel = 'pressure, Pa'
    plt.figure()
    if type(fluids) is list:
        for fluid in fluids:
            sc = saturationCurve(fluid, steps)
            plt.plot(
            sc[x],
            sc[y],
                linestyle=linestyle,
                label=fluid)
    else:
        sc = saturationCurve(fluids, steps)
        plt.plot(
            sc[x],
            sc[y],
            linestyle=linestyle, label=fluids)
        #
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend(loc=legend_loc)
    plt.title(title)
    plt.grid(True)
    if savefig is True:
        if savefig_folder == 'default':
            savefig_folder = DEFAULTS.PLOT_DIR
        if savefig_format == 'default':
            savefig_format = DEFAULTS.PLOT_FORMAT
        if savefig_dpi == 'default':
            savefig_dpi = DEFAULTS.PLOT_DPI
        plt.savefig(
                "{}/{}.{}".format(savefig_folder, savefig_name, savefig_format),
                dpi=savefig_dpi,
                bbox_inches='tight')
    if show is True:
        plt.show()
    plt.close()
    
