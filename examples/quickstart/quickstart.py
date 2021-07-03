"""Quick start example of basic MCycle features."""

import mcycle as mc
from math import nan
import CoolProp as CP
import numpy as np

print("Begin quickstart example...")

# ************************************************
# Set MCycle defaults
# ************************************************
print("Set MCycle defaults...")
mc.defaults.PLOT_DIR = ""
mc.defaults.PLOT_DPI = 200
mc.defaults.check()
print("defaults done.")

print("Begin Rankine cycle setup...")
wf = mc.FlowState(
    fluid="R245fa",
    m=1.0,
    inputPair=mc.PT_INPUTS,
    input1=mc.atm2Pa(1),
    input2=298)
print("  - created working fluid")
exp = mc.ExpBasic(pRatio=1, efficiencyIsentropic=0.9, sizeAttr="pRatio")
print("  - created expander")
cond = mc.ClrBasic(constraint=mc.CONSTANT_P, QCool=1, efficiencyThermal=1.0, sizeAttr="Q")
print("  - created condenser")
comp = mc.CompBasic(pRatio=1, efficiencyIsentropic=0.85, sizeAttr="pRatio")
print("  - created compressor")
evap = mc.HtrBasic(constraint=mc.CONSTANT_P, QHeat=1, efficiencyThermal=1.0, sizeAttr="Q")
print("  - created evaporator")
config = mc.Config()
print("  - created configuration object")
cycle = mc.RankineBasic(
    wf=wf, evap=evap, exp=exp, cond=cond, comp=comp, config=config)
cycle.update({
    "pEvap": mc.bar2Pa(10),
    "superheat": 10.,
    "TCond": mc.degC2K(25),
    "subcool": 5.
})
print("  - created cycle")
print("setup done.")


@mc.timer
def plot_cycle():
    cycle.sizeSetup(unitiseEvap=False, unitiseCond=False)
    cycle.plot(
        graph='Ts',  # either 'Ts' or 'ph'
        title='Quick start RankineBasic plot',  # graph title
        satCurve=True,  # display saturation curve
        newFig=True,  # create a new figure
        show=False,  # show the figure
        savefig=True,  # save the figure
        savefig_name='quickstart_plot_RankineBasic')


@mc.timer
def cycle_summary():
    cycle.size()
    cycle.summary(
        printSummary=True,
        propertyKeys='all',
        cycleStateKeys='all',
        componentKeys='all',
        title="Quick start RankineBasic cycle")


@mc.timer
def run_off_design():
    cycle.sizeSetup(False, False)
    Qfraction_vals = np.linspace(0.8, 1.2, 11, True)
    Q_vals = Qfraction_vals * cycle.QIn()

    runLowerBound = cycle.evap.flowInWf.copyUpdateState(
        CP.PQ_INPUTS, cycle.evap.flowInWf.p(), 0.4).h()

    runUpperBound = cycle.evap.flowInWf.copyUpdateState(
        CP.PT_INPUTS, cycle.evap.flowInWf.p(), 420.).h()
    cycle.evap.update({'runBounds': [runLowerBound, runUpperBound]})

    state3_vals = []
    efficiencyThermal_vals = []
    newFigFlag = True
    for QHeat in Q_vals:
        cycle.evap.QHeat = QHeat
        cycle.evap.run()
        cycle.set_state3(cycle.evap.flowOutWf)
        cycle.exp.run()
        cycle.set_state4(cycle.exp.flowOutWf)
        state3_vals.append(cycle.state3)
        efficiencyThermal_vals.append(cycle.efficiencyThermal())
        cycle.plot(
            graph='Ts',  # either 'Ts' or 'ph'
            title='run',  # graph title
            satCurve=True,  # display saturation curve
            newFig=newFigFlag,  # append to existing figure
            show=False,  # show the figure
            savefig=True,  # save the figure
            savefig_name='quickstart_run')
        newFigFlag = False

    print("Q/Q_design | state3.T() | state3.x() | efficiencyThermal()")
    for i in range(len(Qfraction_vals)):
        print("{:1.2f} | {:3.2f} | {: 2.2f} | {:1.4f}".format(
            Qfraction_vals[i], state3_vals[i].T(), state3_vals[i].x(),
            efficiencyThermal_vals[i]))


if __name__ == "__main__":
    plot_cycle()
    cycle_summary()
    run_off_design()
