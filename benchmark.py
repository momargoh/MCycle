import timeit
import mcycle as mc


def benchmark_HxPlate():
    config = mc.Config()
    config.update({'dpAcc': False, 'dpPort': False, 'dpHead': False})
    config.set_method("savostinTikhonov_sp", "GeomHxPlateCorrugatedChevron",
                      mc.TRANSFER_ALL, mc.UNITPHASE_ALL, mc.SECONDARY_FLUID)
    hx = mc.HxPlateCorrugated(
        flowConfig=mc.HxFlowConfig(mc.COUNTERFLOW, 1, '', True, True),
        RfWf=0,
        RfSf=0,
        plate=mc.library.stainlessSteel_316(573.15),
        tPlate=0.424e-3,
        geomWf=mc.GeomHxPlateCorrugatedChevron(1.096e-3, 60, 10e-3, 1.117),
        geomSf=mc.GeomHxPlateCorrugatedChevron(1.096e-3, 60, 10e-3, 1.117),
        L=269e-3,
        W=95e-3,
        DPortWf=0.0125,
        DPortSf=0.0125,
        ARatioWf=1,
        ARatioSf=1,
        ARatioPlate=1,
        NPlate=23,
        coeffs_LPlate=[0.056, 1],
        coeffs_WPlate=[0, 1],
        efficiencyThermal=1.0,
        config=config)
    flowInWf = mc.FlowState("R123", 0.34307814292524513,
                            mc.constants.PT_INPUTS, 1000000.,
                            300.57890653991603)
    flowOutWf = mc.FlowState("R123", 0.34307814292524513, mc.PT_INPUTS,
                             1000000., 414.30198149532583)
    flowInSf = mc.FlowState("Air", 0.09, mc.PT_INPUTS, 111600., 1170.)
    flowOutSf = mc.FlowState("Air", 0.09, mc.PT_INPUTS, 111600.,
                             310.57890653991603)
    #
    hx.update({
        'flowInWf': flowInWf,
        'flowInSf': flowInSf,
        'flowOutWf': flowOutWf,
        'flowOutSf': flowOutSf
    })
    hx.unitise()
    hx.update({
        'L': 269e-3,
        'NPlate': 23,
        'geomWf.b': 1.096e-3,
        'W': 95e-3,
        'sizeAttr': 'L',
        'sizeBounds': [0.005, 0.5]
    })
    hx.size()
    assert (abs(hx.L - 269e-3) / 269e-3 < 0.01)
    #
    assert (abs(hx.dpWf() - 39607.4552153897) / 39607.4552153897 < 0.01)

    hx.update({
        'L': 0.268278920236407,
        'NPlate': 23,
        'geomWf.b': 1.096e-3,
        'W': 95e-3,
        'sizeAttr': 'W',
        'sizeBounds': [50e-3, 500e-3]
    })
    hx.size()
    assert (abs(hx.W - 95e-3) / 95e-3 < 0.0001)

    hx.update({
        'L': 0.268278920236407,
        'NPlate': 23,
        'geomWf.b': 0,
        'W': 95e-3,
        'sizeAttr': 'geomWf.b',
        'sizeBounds': [0.1e-3, 10e-3]
    })
    hx.size()
    assert (abs(hx.geomWf.b - 1.096e-3) < 0.0001)

    hx.update({
        'L': 0.268278920236407,
        'NPlate': 23,
        'geomWf.b': 1.096e-3,
        'W': 95e-3,
        'sizeAttr': 'NPlate',
        'sizeBounds': [10, 50]
    })
    hx.size()

    flowInWf = mc.FlowState("R245fa", 2, mc.PT_INPUTS, 2e5, 300.)
    flowInSf = mc.FlowState("water", 5., mc.PT_INPUTS, 1e5, 600.)

    hLowerBound = flowInWf.h() * 1.01
    hUpperBound = flowInWf.copyUpdateState(mc.PT_INPUTS, 2e5, 350.).h()

    hx.update({
        'L': 0.269,
        'NPlate': 5,
        'geomWf.b': 1.096e-3,
        'W': 95e-3,
        'flowInWf': flowInWf,
        'flowInSf': flowInSf,
        'sizeUnitsBounds': [1e-5, 1.],
        'runBounds': [hLowerBound, hUpperBound]
    })
    hx.run()
    assert (abs(hx.flowOutWf.T() - 318.22) < 0.01)

    flowInWf = mc.FlowState("water", 0.1, mc.PT_INPUTS, 1.1e5, 700.)
    flowInSf = mc.FlowState("water", 0.1, mc.PT_INPUTS, 1e5, 500.)

    hLowerBound = flowInWf.h() * 0.99
    hUpperBound = flowInWf.copyUpdateState(mc.constants.PT_INPUTS, 1.1e5,
                                           600.).h()

    hx.update({
        'L': 0.1,
        'NPlate': 3,
        'geomWf.b': 1.096e-3,
        'W': 95e-3,
        'flowInWf': flowInWf,
        'flowInSf': flowInSf,
        'sizeUnitsBounds': [1e-5, 5.],
        'runBounds': [hLowerBound, hUpperBound]
    })
    hx.run()
    assert (abs(hx.flowOutWf.T() - 643.66) < 0.01)


if __name__ == "__main__":
    number = 10
    print("Begin benchmark tests. number={}".format(number))
    print(timeit.timeit(benchmark_HxPlate, number=number))
    print("finished.")
