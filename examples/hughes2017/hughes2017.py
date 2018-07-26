"""hughes2017.py : Basic organic Rankine cycle with a corrugated-plate evaporator. This example is found in examples/hughes2017 and is an update to the analysis found in the paper *On the potential of organic Rankine cycles for recovering waste heat from the exhaust gases of a piston aero-engine* by Hughes and Olsen, presented at Asia-Pacific Symposium on Aerospace Technology 2017, Seoul, Korea (`hyperlink <https://www.unsworks.unsw.edu.au/primo-explore/fulldisplay?docid=unsworks_modsunsworks_47631&context=L&vid=UNSWORKS&search_scope=unsworks_search_scope&tab=default_tab&lang=en_US>`_) [Hughes2017]_."""

import mcycle as mc
import os
from math import nan
import numpy as np
import CoolProp as CP
import matplotlib as mpl
import matplotlib.pyplot as plt
import timeit

print("Begin hughes2017 example...")
# ************************************************
# Set up formatting
# ************************************************
print("Set MCycle defaults and formatting...")
mc.DEFAULTS.PLOT_DIR = 'plots'
mc.DEFAULTS.PLOT_FORMAT = "png"  # change to "jpg" if preferred
mc.DEFAULTS.PLOT_DPI = 600
mc.updateDefaults()
# custom formatting for matplotlib
mpl.rc("lines", lw=2.0)
mpl.rc("lines", markersize=2)
colours = ["blue", "red", "green", "black"]
linestyles = ["-", "--", "-.", ":"]
markerstyles = ["o", "v", "s", "^"]
print("defaults and formatting done.")

# ************************************************
# Set up default cycle
# ************************************************
print("Begin Rankine cycle setup...")
wf = mc.FlowState("R123")
pEvap = 10.e5
superheat = 0
TCond = 300.
subcool = 0
comp = mc.CompBasic(nan, 0.7, sizeAttr="pRatio")
print("  - created compressor")
sourceIn_m = 0.09
sourceIn_T = 1170.
sourceIn_p = 1.116e5
sourceFluid = "N2[{0}]&CO2[{1}]".format(0.75, 0.25)
TData = [300, 500, 700, 900, sourceIn_T]
sourceRefData = mc.RefData(
    sourceFluid, 2, sourceIn_p, {'T': TData}, phaseCP=CP.iphase_gas)
sourceIn = mc.FlowStatePoly(sourceRefData, 0.09, CP.PT_INPUTS, sourceIn_p,
                            sourceIn_T)
sourceAmbient = mc.FlowState(sourceFluid, CP.iphase_gas, -1, CP.PT_INPUTS,
                             0.88260e5, 281.65)

evap = mc.library.alfaLaval_AC30EQ(sizeAttr="NPlate")
print("  - created evaporator")
exp = mc.ExpBasic(-1, 0.7, sizeAttr="pRatio")
print("  - created expander")
sinkIn = mc.FlowState("Air", -1, -1, CP.PT_INPUTS, 0.88260e5, 281.65)
sinkAmbient = sinkIn._copy({})
cond = mc.ClrBasicConstP(-1, 1, sizeAttr="Q")
print("  - created condenser")
config = mc.Config()
config.update({
    'dpEvap': False,
    'dpCond': False,
    'dpF': True,
    'dpAcc': False,
    'dpPort': False,
    'dpHead': False
})
config.set_method("chisholmWannairachchi_sp", ["GeomHxPlateCorrChevron"],
                  ["all"], ["all-sp"], ["wf"])
config.set_method("yanLin_tpEvap", ["GeomHxPlateCorrChevron"], ["all"],
                  ["tpEvap"], ["wf"])
config.set_method("savostinTikhonov_sp", ["GeomHxPlateCorrChevron"], ["all"],
                  ["all-sp"], ["sf"])
print("  - created configuration object")
cycle = mc.RankineBasic(wf, evap, exp, cond, comp, pEvap, superheat, nan,
                        subcool, config)
cycle.update({
    'TCond': TCond,
    'sourceIn': sourceIn,
    'sourceAmbient': sourceAmbient,
    #'sinkIn': sinkIn,
    #'sinkDead': sinkDead
})

print("  - created cycle")
print("setup done.")


@mc.timeThis
def run_plot():
    """Example of RankineBasic.plot()."""
    print("Begin plotting design cycle ...")
    cycle.update({
        'cond': mc.library.alfaLaval_CBXP27(),
        'pptdEvap': 300,
        'sinkIn': sinkIn,
        'sinkIn.m': 100.
    })
    #cycle.sinkIn.m = 100.
    cycle.sizeSetup(False, False)
    print("Create plots in ./{} folder...".format(mc.DEFAULTS.PLOT_DIR))
    cycle.plot(
        graph='Ts',
        title='Design conditions plot',
        linestyle='-',
        marker='.',
        satCurve=True,
        newFig=True,
        show=False,
        savefig=True,
        savefig_name='hughes2017_plot_RankineBasic')
    print("  - plot saved in {}/plot_RankineBasic.{}".format(
        mc.DEFAULTS.PLOT_DIR, mc.DEFAULTS.PLOT_FORMAT))
    cycle.sinkIn.m = nan
    cycle.cond = mc.ClrBasicConstP(-1, 0.7, sizeAttr="pRatio")
    print("End plotting design cycle")


@mc.timeThis
def run_superheat():
    """Superheating analysis."""
    print("Begin superheating analysis...")
    pptdEvap = 20.  # K
    p_vals = [5, 10, 20, 25]  # bar
    superheat_vals = [range(0, 200)] * len(p_vals)  # K
    plot_eff, plot_Pnet = [], []  # lists to store results
    for i in range(len(p_vals)):
        plot_eff.append([])
        plot_Pnet.append([])
        cycle.update({'pEvap': p_vals[i] * 10**5})
        for superheat in superheat_vals[i]:
            cycle.update({'superheat': superheat, 'pptdEvap': pptdEvap})
            cycle.sizeSetup(False, False)
            plot_eff[i].append(cycle.effExergy())
            plot_Pnet[i].append(cycle.PNet() / 1000)  # kW
    print("Create plots in ./{} folder...".format(mc.DEFAULTS.PLOT_DIR))
    plt.figure()
    for i in range(len(p_vals)):
        plt.plot(
            superheat_vals[i],
            plot_eff[i],
            label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
            color=colours[i],
            linestyle=linestyles[i])
    plt.ylabel('exergy efficiency [-]')
    plt.legend(loc='lower right')
    plt.xlabel('degree of superheating [K]')
    plt.savefig(
        "./{}/hughes2017_superheat_eff.{}".format(mc.DEFAULTS.PLOT_DIR,
                                                  mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    print("  - exergy efficiency v superheating")
    #
    plt.figure()  # power v superheating
    for i in range(len(p_vals)):
        plt.plot(
            superheat_vals[i],
            plot_Pnet[i],
            label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
            color=colours[i],
            linestyle=linestyles[i])
    plt.ylabel('net Power output [kW]')
    plt.legend(loc='lower right')
    plt.xlabel('degree of superheating [K]')
    plt.savefig(
        "./{}/hughes2017_superheat_Pnet.{}".format(mc.DEFAULTS.PLOT_DIR,
                                                   mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    print("  - net power v superheating")
    print("Superheating analysis done.")


@mc.timeThis
def run_pptd():
    """Pinch-point temperature difference analysis."""
    print("Begin pinch-point temperature difference analysis...")
    cycle.superheat = 0.  # K
    p_vals = [5, 10, 20, 25]  # bar
    pptd_vals = [np.logspace(1, np.log10(200), 40)] * len(p_vals)  # K
    plot_eff, plot_NPlate, plot_weight, plot_dpWf = [], [], [], []
    #
    for i in range(len(p_vals)):
        plot_eff.append([])
        plot_NPlate.append([])
        plot_weight.append([])
        plot_dpWf.append([])
        cycle.update({'pEvap': p_vals[i] * 10**5})
        NPlateLowerBound = 3
        for pptd in pptd_vals[i]:
            cycle.update({
                'pptdEvap': pptd,
                'evap.L': mc.library.alfaLaval_AC30EQ().L
            })
            cycle.sizeSetup(False, False)
            cycle.evap._size("NPlate",
                             [NPlateLowerBound, cycle.evap.sizeBounds[1]], [])
            plot_eff[i].append(cycle.effExergy())
            plot_NPlate[i].append(cycle.evap.NPlate)
            plot_weight[i].append(cycle.evap.weight())
            plot_dpWf[i].append(cycle.evap.dpWf() / (10**5))
            NPlateLowerBound = max(3, cycle.evap.NPlate - 2)
    #
    print("Create plots in ./{} folder...".format(mc.DEFAULTS.PLOT_DIR))
    plt.figure()
    for i in range(len(p_vals)):
        plt.plot(
            pptd_vals[i],
            plot_eff[i],
            label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
            color=colours[i],
            linestyle=linestyles[i])
    plt.ylabel('exergy efficieny [-]')
    plt.legend(loc='best')
    plt.xlabel('PPTD [K]')
    plt.savefig(
        "./{}/hughes2017_pptd_eff.{}".format(mc.DEFAULTS.PLOT_DIR,
                                             mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    # plt.show()
    print("  - exergy efficiency v pptd")
    #
    plt.figure()
    for i in range(len(p_vals)):
        plt.scatter(
            pptd_vals[i],
            plot_dpWf[i],
            label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
            color=colours[i],
            marker=markerstyles[i])
    plt.ylabel('Working fluid pressure drop [-]')
    plt.legend(loc='upper right')
    plt.xlabel('PPTD [K]')
    plt.savefig(
        "./{}/hughes2017_pptd_dpWf.{}".format(mc.DEFAULTS.PLOT_DIR,
                                              mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    # plt.show()
    print("  - wf pressure drop v pptd")
    #
    fig, ax1 = plt.subplots()
    j = 0
    for i in range(len(p_vals)):
        ax1.scatter(
            pptd_vals[i],
            plot_NPlate[i],
            label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
            color=colours[i],
            marker=markerstyles[i])
        j += 1
    ax1.set_xlabel('PPTD [K]')
    ax1.set_ylabel('Number of plates [-]')
    ax1.legend(loc='upper right')
    ax2 = ax1.twinx()
    mn, mx = ax1.get_ylim()
    vol = mc.library.alfaLaval_AC30EQ().LPlate() * mc.library.alfaLaval_AC30EQ(
    ).WPlate() * mc.library.alfaLaval_AC30EQ().tPlate
    c0 = cycle.evap.coeffs_weight[0] * vol
    c1 = cycle.evap.coeffs_weight[1] * vol
    ax2.set_ylim(mn * c1 + c0, mx * c1 + c0)
    ax2.set_ylabel('empty weight [Kg]')
    plt.savefig(
        "./{}/hughes2017_pptd_NPlate.{}".format(mc.DEFAULTS.PLOT_DIR,
                                                mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    # plt.show()
    print("  - N and weight v pptd")
    print("Pinch-point temperature difference analysis done.")


@mc.timeThis
def run_pressure():
    """Evaporating pressure analysis"""
    print("Begin evaporating pressure analysis...")
    cycle.superheat = 0.
    p_vals = np.linspace(5, 25, 50, True)
    plot_NPlate, plot_dpWf, plot_dpSf = [], [], []
    NPlateLowerBound = 3
    for i in range(len(p_vals)):
        cycle.update({'pEvap': p_vals[i] * 10**5, 'pptdEvap': 10.})
        cycle.sizeSetup(True, False)
        cycle.evap.update({
            'L': mc.library.alfaLaval_AC30EQ().L,
            'sizeBounds[0]':
            NPlateLowerBound  # use previous solution for better bounds
        })
        cycle.evap.size_NPlate()
        plot_NPlate.append(cycle.evap.NPlate)
        plot_dpWf.append(cycle.evap.dpWf() / (10**5))
        plot_dpSf.append(cycle.evap.dpSf() / (10**5))
        NPlateLowerBound = cycle.evap.NPlate - 1

    print("Create plots in ./{} folder...".format(mc.DEFAULTS.PLOT_DIR))
    plt.figure()
    plt.scatter(
        p_vals,
        plot_dpWf,
        label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
        color=colours[0],
        marker=markerstyles[0])
    plt.ylabel('working fluid pressure drop [bar]')
    plt.legend(loc='best')
    plt.xlabel('evaporation pressure [bar]')
    plt.savefig(
        "./{}/hughes2017_pressure_dpWf.{}".format(mc.DEFAULTS.PLOT_DIR,
                                                  mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    # plt.show()
    print("  - wf pressure drop v evap pressure")

    plt.figure()
    plt.scatter(
        p_vals,
        plot_dpSf,
        label=r"$p_{}$={}bar".format("{evap}", p_vals[i]),
        color=colours[1],
        marker=markerstyles[1])
    plt.ylabel('exhaust gas pressure drop [bar]')
    plt.legend(loc='best')
    plt.xlabel('evaporation pressure [bar]')
    plt.savefig(
        "./{}/hughes2017_pressure_dpSf.{}".format(mc.DEFAULTS.PLOT_DIR,
                                                  mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    # plt.show()
    print("  - sf pressure drop v evap pressure")
    print("Pressure analysis done.")


@mc.timeThis
def run_mass():
    """Mass flow rate analysis."""
    print("Begin mass flow rate analysis...")
    superheat = 0.
    pEvap = 25
    pptdEvap = 10.
    fraction_vals = np.linspace(0.001, 0.2)
    plot_dpSf = []
    cycle.update({'superheat': superheat, 'pEvap': pEvap * 1e5})
    mSource = cycle.evap.mSf
    NPlateLowerBound = 3
    for frac in fraction_vals:
        cycle.evap.mSf = mSource * frac
        cycle.update({'pptdEvap': pptdEvap})
        cycle.evap.update({
            'L': mc.library.alfaLaval_AC30EQ().L,
            'sizeBounds[0]': NPlateLowerBound
        })
        cycle.sizeSetup(True, False)
        cycle.evap.size_NPlate()
        plot_dpSf.append(cycle.evap.dpSf() / (10**5))
        NPlateLowerBound = cycle.evap.NPlate

    print("Create plots in ./{} folder...".format(mc.DEFAULTS.PLOT_DIR))
    plt.figure()
    plt.scatter(
        fraction_vals,
        plot_dpSf,
        label=r"$p_{}$={}bar".format("{evap}", pEvap),
    )
    plt.ylabel('exhaust gas pressure drop [bar]')
    plt.xlabel('proportion of total exhaust gases [-]')
    plt.legend(loc='best')
    plt.savefig(
        "./{}/hughes2017_mSf_dpSf.{}".format(mc.DEFAULTS.PLOT_DIR,
                                             mc.DEFAULTS.PLOT_FORMAT),
        dpi=mc.DEFAULTS.PLOT_DPI,
        bbox_inches='tight')
    # plt.show()
    print("  - sf pressure drop v fraction of sf mass")
    print("Mass flow rate analysis done.")


if __name__ == "__main__":
    run_plot()
    run_superheat()
    run_pptd()
    run_pressure()
    run_mass()
