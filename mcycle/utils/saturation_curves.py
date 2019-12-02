from ..bases.flowstate import FlowState
from ..logger import log
from .. import defaults
from .. import constants as c
from warnings import warn
import numpy as np
import matplotlib.pyplot as plt
import re


def saturationCurve(fluid, steps=200, TMinOffset=0):
    """dict: calculate saturation curve properties (T, s, p, h) and return in dict"""
    sat0T = []
    sat0s = []
    sat0p = []
    sat0h = []
    sat1T = []
    sat1s = []
    sat1p = []
    sat1h = []
    try:
        fluid = re.sub('[()-]', '', fluid)
        f = FlowState(fluid)
        TCrit = f.TCrit()
        TMin = f.TMin()
        for T in np.linspace(TMin + TMinOffset, TCrit, steps, False):
            try:
                f.updateState(c.QT_INPUTS, 0, T)
                sat0T.append(T)
                sat0s.append(f.s())
                sat0p.append(f.p())
                sat0h.append(f.h())
                f.updateState(c.QT_INPUTS, 1, T)
                sat1T.append(T)
                sat1s.append(f.s())
                sat1p.append(f.p())
                sat1h.append(f.h())
            except:
                continue
        try:
            f.updateState(c.PT_INPUTS, f.pCrit(), TCrit)
            sat0T.append(TCrit)
            sat0s.append(f.s())
            sat0p.append(f.p())
            sat0h.append(f.h())
        except Exception as exc:
            log("info",
                "saturationCurve(): Could not compute critical point properties for {}.".
                format(fluid), exc)
        sat0T = sat0T + list(reversed(sat1T))
        sat0s = sat0s + list(reversed(sat1s))
        sat0p = sat0p + list(reversed(sat1p))
        sat0h = sat0h + list(reversed(sat1h))
        return {'T': sat0T, 's': sat0s, 'p': sat0p, 'h': sat0h}
    except Exception as exc:
        msg = "Could not produce saturation curve for {}".format(fluid)
        log("warning", msg, exc)
        warn(msg)
        return {'T': [], 's': [], 'p': [], 'h': []}


def plot_saturationCurve(fluids,
                         graph='T-s',
                         steps=200,
                         TMinOffset=0,
                         title='default',
                         legend_loc='best',
                         grid=True,
                         show=True,
                         savefig=True,
                         savefig_name='saturation_curve',
                         savefig_folder='default',
                         savefig_format='default',
                         savefig_dpi='default'):
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
legend_loc : str, optional
    Location of legend, passed as a matplotlib.plot argument. Defaults to 'best'.
show : str, optional
    Show figure in window. Defaults to True.
savefig : bool, optional
    Save figure as '.png' or '.jpg' file in desired folder. Defaults to False.
savefig_name : str, optional
    Name for saved plot file. Defaults to 'plot_RankineBasic'.
savefig_folder : str, optional
    Folder in the current working directory to save figure into. Folder is created if it does not already exist. Figure is saved as "./savefig_folder/savefig_name.savefig_format". If None or '', figure is saved directly into the current working directory. If ``'default'``, :meth:`mcycle.defaults.PLOT_DIR <mcycle.defaults.PLOT_DIR>` is used. Defaults to ``'default'``.
savefig_format : str, optional
    Format of saved plot file. Must be ``'png'`` or ``'jpg'``. If ``'default'``, :meth:`mcycle.defaults.PLOT_FORMAT <mcycle.defaults.PLOT_FORMAT>` is used. Defaults to ``'default'``.
savefig_dpi : int, optional
    Dots per inch / pixels per inch of the saved image. Passed as a matplotlib.plot argument. If ``'default'``, :meth:`mcycle.defaults.PLOT_DPI <mcycle.defaults.PLOT_DPI>` is used. Defaults to ``'default'``.
    """
    graph_formatted = graph.lower().replace('-', '')
    assert graph_formatted in [
        'ts', 'ph', 'temperatureentropy', 'pressureenthalpy'
    ]
    assert savefig_format in [
        'default', 'png', 'PNG', 'jpg', 'JPG'
    ], "savefig format must be 'png' or 'jpg', '{0}' is invalid.".format(
        savefig_format)
    if title == 'default':
        title = "{} saturation curve".format(graph)
        if type(fluids) is list:
            title += 's'
    if graph_formatted == 'ts' or graph_formatted == 'temperatureentropy':
        x = "s"
        y = "T"
        xlabel = 'entropy{}'.format(
            defaults.getUnitsFormatted('energy/mass-temperature'))
        ylabel = 'temperature{}'.format(
            defaults.getUnitsFormatted('temperature'))
    elif graph_formatted == 'ph' or graph_formatted == 'pressureenthalpy':
        x = "h"
        y = "p"
        xlabel = 'enthalpy{}'.format(defaults.getUnitsFormatted('energy/mass'))
        ylabel = 'pressure{}'.format(defaults.getUnitsFormatted('pressure'))
    plt.figure()
    if type(fluids) is list:
        for i in range(len(fluids)):
            sc = saturationCurve(fluids[i], steps, TMinOffset)
            plt.plot(
                sc[x],
                sc[y],
                color=defaults.PLOT_COLOR[i % len(defaults.PLOT_COLOR)],
                linestyle=defaults.PLOT_LINESTYLE[i % len(
                    defaults.PLOT_LINESTYLE)],
                marker=defaults.PLOT_MARKER[i % len(defaults.PLOT_MARKER)],
                label=fluids[i])
    else:
        sc = saturationCurve(fluids, steps, TMinOffset)
        plt.plot(
            sc[x],
            sc[y],
            color=defaults.PLOT_COLOR[0],
            linestyle=defaults.PLOT_LINESTYLE[0],
            marker=defaults.PLOT_MARKER[0],
            label=fluids)
        #
    plt.xlabel(xlabel)
    plt.ylabel(ylabel)
    plt.legend(loc=legend_loc)
    plt.title(title)
    plt.grid(grid)
    if savefig is True:
        if savefig_folder == 'default':
            savefig_folder = defaults.PLOT_DIR
        if savefig_format == 'default':
            savefig_format = defaults.PLOT_FORMAT
        if savefig_dpi == 'default':
            savefig_dpi = defaults.PLOT_DPI
        plt.savefig(
            "{}/{}.{}".format(savefig_folder, savefig_name, savefig_format),
            dpi=savefig_dpi,
            bbox_inches='tight')
    if show is True:
        plt.show()
    plt.close()
