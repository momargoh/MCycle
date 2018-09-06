import mcycle as mc
import os
import numpy as np
from math import nan
import CoolProp as CP
import matplotlib as mpl
import matplotlib.pyplot as plt

print("Begin zarati2017 example...")
# ************************************************
# Set up formatting
# ************************************************
# cycle.plot parameters
mc.DEFAULTS.PLOT_DIR = 'plots'  # directory to save plots into
mc.DEFAULTS.PLOT_FORMAT = 'png'  # change to "jpg" if preferred
mc.DEFAULTS.PLOT_DPI = 600  # dpi (resolution) of plots
mc.DEFAULTS.updateDefaults()  # check the defaults are OK
# custom format for matplotlib
mpl.rc("lines", lw=2.0)
mpl.rc("lines", markersize=2)
colours = ["blue", "red", "green", "black"]
linestyles = ["-", "--", "-.", ":"]
markerstyles = ["o", "v", "s", "^"]

# ************************************************
# Set up default cycle parameters
# ************************************************
print("Begin setting up cycle...")
# Create configuration object
config = mc.Config()
config.update({
    'dpEvap': False,  # ignore dp in evap for cycle
    'dpCond': False,  # ignore dp in condenser
    'dpF': True,  # dp includes friction term
    'dpAcc': False,  # dp includes acceleration term
    'dpPort': False,  # dp includes port loss term
    'dpHead': False
})  # dp includes head loss term
# select heat transfer methods
config.set_method("shah_sp_h", ["GeomHxPlateSmooth"], ["heat"], ["all-sp"],
                  ["wf"])
config.set_method("gungorWinterton_tpEvap_h", ["GeomHxPlateSmooth"], ["heat"],
                  ["tpEvap"], ["wf"])
config.set_method("manglikBergles_offset_sp", ["GeomHxPlateFinOffset"],
                  ["all"], ["all-sp"], ["sf"])

# Create basic compressor object
comp = mc.CompBasic(
    pRatio=nan, effIsentropic=0.9, sizeAttr="pRatio", config=config)
# Create basic expander object
exp = mc.ExpBasic(
    pRatio=nan, effIsentropic=0.85, sizeAttr="pRatio", config=config)
# Define initial evaporator heat source
sourceFluid = "Air"
sourceIn_m = 5.5  # [kg/s]
sourceIn_T = 744.  # [K], from Table 9
sourceIn_p = mc.bar2Pa(0.37)  # [Pa], from cp=1085.4
# Create FlowState of initial heat source
sourceIn = mc.FlowState(sourceFluid, -1, sourceIn_m, CP.PT_INPUTS, sourceIn_p,
                        sourceIn_T)
# Define geometries for evaporator channels
evapGeomPlateWf = mc.GeomHxPlateSmooth(b=0.024375)
evapGeomPlateSf = mc.GeomHxPlateFinOffset(s=0.008, h=0.03, t=0.0002, l=0.02)
# Define plate material & temp to take properties at
plateMaterial = mc.stainlessSteel_316(T=293.15)
# Define ambient conditions
altitude = mc.ft2m(20000)
mach = 0.49  # Mach number of aircraft
stillAmbient = mc.isa(altitude)  # ISA conditions at 20,000 ft
ambient_T = stillAmbient.T() / mc.TTotalRatio(gamma=1.4, M=mach)
ambient_p = stillAmbient.p() / mc.pTotalRatio(gamma=1.4, M=mach)
ambient = mc.FlowState('air', -1, 0, CP.PT_INPUTS, ambient_p, ambient_T)
# Create evaporator object
evap = mc.HxPlate(
    flowSense='counter',
    NPlate=17,  # total number of plates
    RfWf=0,  # no fouling in working fluid channels
    RfSf=0,  # no fouling in secondary fluid channels
    plate=plateMaterial,
    tPlate=0.2e-3,  # plate thickness [m]
    geomPlateWf=evapGeomPlateWf,
    geomPlateSf=evapGeomPlateSf,
    L=0.2,  # heat trans. length [m]
    W=0.44,  # heat trans. width [m]
    effThermal=1.0,  # thermal efficiency
    ambient=ambient,  # FlowState of ambient
    config=config)
# Create basic condenser object
cond = mc.ClrBasicConstP(
    QCool=nan, effThermal=1, sizeAttr="QCool", config=config)

# Create cycle object
cycle = mc.RankineBasic(
    wf=mc.FlowState("R245fa", -1),  # working fluid
    evap=evap,
    exp=exp,
    cond=cond,
    comp=comp,
    superheat=1.,  # degree of superheating
    pCond=180.e3,  # condensing pressure
    subcool=3.,  # degree of subcooling
    config=config)
cycle.update({
    'TEvap': 416.18,  # set evaporating temperature
    'sourceIn': sourceIn
})
print("done.")

# ************************************************
# Computations
# ************************************************


def evaluate_size():
    print("Begin sizing heat exchanger for different mass flow rates...")
    mWf_vals = np.linspace(0.1, 2., 20)  #0.1, 1.0, 20)
    plot_x = []
    plot_y0 = []
    plot_y1 = []
    plot_y2 = []
    plot_y3 = []
    for m in mWf_vals:
        cycle.update({'mWf': m})
        cycle.sizeSetup(True, False)
        try:
            print()
            print("m = ", cycle.evap._mWf(), " kg/s")
            cycle.evap.size()
            plot_x.append(m)
            plot_y0.append(cycle.evap.L)
            plot_y1.append(cycle.evap.weight())
            plot_y2.append(cycle.evap.flowOutSf.T())
            plot_y3.append(cycle.evap.dpSf() / cycle.evap.flowInSf.p() * 100)
            '''hWf, hSf, U = [], [], []
            for unit in cycle.evap._units:
                hWf.append(unit._hWf())
                hSf.append(unit._hSf())
                U.append(unit.U())
            print("heat trans coeff, wf : ", hWf)
            print("heat trans coeff, sf : ", hSf)
            print("overall heat trans coeff: ", U)'''
        except Exception as exc:
            print("No convergence for m={}, exc={}".format(m, exc))
    print("done.")
    print("Creating plots...")
    ylabels = [
        "Required heat exchanger length [m]",
        "Required heat exchanger weight [kg]",
        "Temperature of outgoing air flow in evaporator [K]",
        "Pressure drop of air flow over evaporator [%]"
    ]
    for i in range(4):
        plt.figure()
        plt.plot(plot_x, locals()['plot_y' + str(i)])
        plt.xlabel('working fluid mass flow rate [kg/s]')
        plt.ylabel(ylabels[i])
        plt.tight_layout()
        plt.savefig("{}/plot_size{}.{}".format(mc.DEFAULTS.PLOT_DIR, i,
                                               mc.DEFAULTS.PLOT_FORMAT))
    print("done.")


def evaluate_run():
    print("Begin running heat exchanger for different mass flow rates...")
    mWf_vals = np.linspace(1.0, 10., 20)  #0.1, 1.0, 20)
    plot_x = []
    plot_y0 = []
    plot_y1 = []
    plot_y2 = []
    plot_y3 = []
    cycle.evap.update({"L": 0.2})
    for m in mWf_vals:
        cycle.update({'mWf': m})
        cycle.sizeSetup(True, False)
        # select runBounds (solution must lie between them)
        pIn = cycle.evap.flowInWf.p()  #incoming pressure
        TIn = cycle.evap.flowInWf.T()  #incoming temperature
        hLower = cycle.wf.copyState(CP.PT_INPUTS, pIn, TIn + 1).h()
        hUpper = cycle.wf.copyState(CP.PT_INPUTS, pIn, TIn + 40).h()
        cycle.evap.update({'runBounds': [hLower, hUpper]})
        try:
            print()
            print("m = ", cycle.evap._mWf(), " kg/s")
            cycle.evap.run()
            plot_x.append(m)
            plot_y0.append(cycle.evap.flowOutSf.cp())
            plot_y1.append(cycle.evap.flowOutWf.T())
            plot_y2.append(cycle.evap.flowOutSf.T())
            plot_y3.append(cycle.evap.dpSf() / cycle.evap.flowInSf.p() * 100)
            '''hWf, hSf, U = [], [], []
            for unit in cycle.evap._units:
                hWf.append(unit._hWf())
                hSf.append(unit._hSf())
                U.append(unit.U())
            print("heat trans coeff, wf : ", hWf)
            print("heat trans coeff, sf : ", hSf)
            print("overall heat trans coeff: ", U)'''
        except Exception as exc:
            print("No convergence for m={}, exc={}".format(m, exc))
    print("done.")
    print("Creating plots...")
    ylabels = [
        "cp of outgoing evaporator air flow [J/Kg.K]",
        "Temperature of outgoing working fluid in evaporator [K]",
        "Temperature of outgoing air flow in evaporator [K]",
        "Pressure drop of air flow over evaporator [%]"
    ]
    for i in range(4):
        plt.figure()
        plt.plot(plot_x, locals()['plot_y' + str(i)])
        plt.xlabel('working fluid mass flow rate [kg/s]')
        plt.ylabel(ylabels[i])
        plt.tight_layout()
        plt.savefig("{}/plot_run{}.{}".format(mc.DEFAULTS.PLOT_DIR, i,
                                              mc.DEFAULTS.PLOT_FORMAT))
    print("done.")


if __name__ == "__main__":
    evaluate_size()
    evaluate_run()
