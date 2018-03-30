import mcycle as mc
import os
import numpy as np
import CoolProp as CP
import matplotlib as mpl
import matplotlib.pyplot as plt


@mc.timeThis
def run_example():
    """run example: zarati2017.py"""
    # ************************************************
    # Set up formatting
    # ************************************************
    # cycle.plot parameters
    plots_folder = "plots"
    plots_format = "png"  # change to "jpg" if preferred
    plots_dpi = 600
    if not os.path.exists(plots_folder):
        os.makedirs(plots_folder)
    # custom format for matplotlib
    mpl.rc("lines", lw=2.0)
    mpl.rc("lines", markersize=2)
    colours = ["blue", "red", "green", "black"]
    linestyles = ["-", "--", "-.", ":"]
    markerstyles = ["o", "v", "s", "^"]

    # ************************************************
    # Set up default cycle parameters
    # ************************************************
    #
    comp = mc.CompBasic(None, 0.9, sizeAttr="pRatio")
    #
    exp = mc.ExpBasic(None, 0.85, sizeAttr="pRatio")
    #
    sourceFluid = "Air"
    sourceIn_m = 5.5
    sourceIn_T = 744.  # from Table 9
    sourceIn_p = 0.37e5  # from cp=1085.4
    sourceIn = mc.FlowState(sourceFluid, "HEOS", None, sourceIn_m,
                            CP.PT_INPUTS, sourceIn_p, sourceIn_T)
    evapGeomPlateWf = mc.GeomHxPlateSmooth(b=0.024375)
    evapGeomPlateSf = mc.GeomHxPlateFinOffset(
        s=0.008, h=0.03, t=0.0002, l=0.02)
    stainlessSteel = mc.SolidMaterial(rho=8010., k=17.)
    evap = mc.HxPlate(
        flowSense="counterflow",
        NPlate=17,
        RfWf=0,
        RfSf=0,
        plate=stainlessSteel,
        tPlate=0.2e-3,
        geomPlateWf=evapGeomPlateWf,
        geomPlateSf=evapGeomPlateSf,
        L=0.2,
        W=0.44,
        effThermal=1.0)
    #
    ambient = mc.isa(mc.ft2m(20000))
    sinkFluid = "Air"
    sinkIn_m = None
    sinkIn_T = ambient.T / mc.TTotalRatio(
        gamma=1.4, M=0.49)  # from alt=20000ft
    sinkIn_p = ambient.p / mc.pTotalRatio(
        gamma=1.4, M=0.49)  # TODO from alt=20000ft
    sinkIn = mc.FlowState(sinkFluid, "HEOS", None, sinkIn_m, CP.PT_INPUTS,
                          sinkIn_p, sinkIn_T)
    sinkDead = sinkIn.copy()
    sourceDead = mc.FlowState(sourceFluid, "HEOS", None, None, CP.PT_INPUTS,
                              sinkIn_p, sinkIn_T)
    cond = mc.ClrBasicConstP(None, 1, sizeAttr="Q")
    #
    config = mc.Config(
        dpEvap=False,
        dpCond=False,
        dpF=True,
        dpAcc=False,
        dpPort=False,
        dpHead=False)
    config.methods.set("shah_1phase_h", ["GeomHxPlateSmooth"], ["heat"],
                       ["wf"], "all-sp")
    cycle = mc.RankineBasic(
        wf=mc.FlowState("R245fa", "HEOS", None),
        evap=evap,
        exp=exp,
        cond=cond,
        comp=comp,
        TEvap=416.18,
        superheat=1.,
        pCond=180.e3,
        subcool=3.,
        config=config,
        sourceIn=sourceIn,
        sinkIn=sinkIn,
        sourceDead=sourceDead,
        sinkDead=sinkDead)

    # ************************************************
    # Computations
    # ************************************************
    mWf_vals = np.linspace(1.0, 10.0, 20)
    plot_x = []
    plot_y0 = []
    plot_y1 = []
    plot_y2 = []
    for m in mWf_vals:
        cycle.update(mWf=m)
        cycle.sizeSetup(True, False)
        try:
            cycle.evap.run()
            print("---------")
            print(cycle.evap.L)
            plot_x.append(m)
            plot_y0.append(cycle.evap.flowOutSf.cp)
            plot_y1.append(cycle.evap.flowOutWf.T)
            plot_y2.append(cycle.evap.dpSf / cycle.evap.flowInSf.p)
        except:
            print("No convergence for m={}".format(m))

    plt.figure()
    plt.plot(plot_x, plot_y0)
    plt.savefig("{}/cp_vs_mWf.{}".format(plots_folder, plots_format))
    plt.figure()
    plt.plot(plot_x, plot_y1)
    plt.savefig("{}/T3Wf_vs_mWf.{}".format(plots_folder, plots_format))
    plt.figure()
    plt.plot(plot_x, plot_y2)
    plt.savefig("{}/dpSf/pSf_vs_mWf.{}".format(plots_folder, plots_format))
    """
    cycle.evap.flowOutSf.summary()
    print("---------")
    print(cycle.evap.dpSf)
    print(cycle.evap.dpSf / cycle.evap.flowInSf.p)
    print("There are # units :", len(cycle.evap._units))
    cycle.evap.size("L", [0.1, 1])
    print("---------")
    print(cycle.evap.L)
    print(cycle.evap.dpSf)
    print(cycle.evap.dpSf / cycle.evap.flowInSf.p)
    """


if __name__ == "__main__":
    run_example()
