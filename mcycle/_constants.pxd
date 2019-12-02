# CoolProp input_pairs
cpdef public unsigned char INPUT_PAIR_INVALID = 0
cpdef public unsigned char QT_INPUTS = 1
cpdef public unsigned char PQ_INPUTS = 2
cpdef public unsigned char QSmolar_INPUTS = 3
cpdef public unsigned char QSmass_INPUTS = 4
cpdef public unsigned char HmolarQ_INPUTS = 5
cpdef public unsigned char HmassQ_INPUTS = 6
cpdef public unsigned char DmolarQ_INPUTS = 7
cpdef public unsigned char DmassQ_INPUTS = 8
cpdef public unsigned char PT_INPUTS = 9
cpdef public unsigned char DmassT_INPUTS = 10
cpdef public unsigned char DmolarT_INPUTS = 11
cpdef public unsigned char HmolarT_INPUTS = 12
cpdef public unsigned char HmassT_INPUTS = 13
cpdef public unsigned char SmolarT_INPUTS = 14
cpdef public unsigned char SmassT_INPUTS = 15
cpdef public unsigned char TUmolar_INPUTS = 16
cpdef public unsigned char TUmass_INPUTS = 17
cpdef public unsigned char DmassP_INPUTS = 18
cpdef public unsigned char DmolarP_INPUTS = 19
cpdef public unsigned char HmassP_INPUTS = 20
cpdef public unsigned char HmolarP_INPUTS = 21
cpdef public unsigned char PSmass_INPUTS = 22
cpdef public unsigned char PSmolar_INPUTS = 23
cpdef public unsigned char PUmass_INPUTS = 24
cpdef public unsigned char PUmolar_INPUTS = 25
cpdef public unsigned char HmassSmass_INPUTS = 26
cpdef public unsigned char HmolarSmolar_INPUTS = 27
cpdef public unsigned char SmassUmass_INPUTS = 28
cpdef public unsigned char SmolarUmolar_INPUTS = 29
cpdef public unsigned char DmassHmass_INPUTS = 30
cpdef public unsigned char DmolarHmolar_INPUTS = 31
cpdef public unsigned char DmassSmass_INPUTS = 32
cpdef public unsigned char DmolarSmolar_INPUTS = 33
cpdef public unsigned char DmassUmass_INPUTS = 34
cpdef public unsigned char DmolarUmolar_INPUTS = 35
# CoolProp imposed phases
cpdef public unsigned char iphase_liquid = 0
cpdef public unsigned char iphase_supercritical = 1
cpdef public unsigned char iphase_supercritical_gas = 2
cpdef public unsigned char iphase_supercritical_liquid = 3
cpdef public unsigned char iphase_critical_point = 4
cpdef public unsigned char iphase_gas = 5
cpdef public unsigned char iphase_twophase = 6
cpdef public unsigned char iphase_unknown = 7
cpdef public unsigned char iphase_not_imposed = 8
# MCycle phases
cpdef public unsigned char PHASE_LIQUID = 0
cpdef public unsigned char PHASE_SUPERCRITICAL = 1
cpdef public unsigned char PHASE_SUPERCRITICAL_GAS = 2
cpdef public unsigned char PHASE_SUPERCRITICAL_LIQUID = 3
cpdef public unsigned char PHASE_CRITICAL_POINT = 4
cpdef public unsigned char PHASE_VAPOUR = 5
cpdef public unsigned char PHASE_VAPOR = 5
cpdef public unsigned char PHASE_GAS = 5
cpdef public unsigned char PHASE_TWOPHASE = 6
cpdef public unsigned char PHASE_UNKNOWN = 7
cpdef public unsigned char PHASE_NOT_IMPOSED = 8
cpdef public unsigned char PHASE_SATURATED_LIQUID = 9
cpdef public unsigned char PHASE_SATURATED_VAPOUR = 10
cpdef public unsigned char PHASE_SATURATED_VAPOR = 10
# HxFlowConfig
cpdef public unsigned char FLOWSENSE_UNDEFINED = 0
cpdef public unsigned char COUNTERFLOW = 1
cpdef public unsigned char PARALLELFLOW = 2
cpdef public unsigned char CROSSFLOW = 3
# MCycle
cpdef public str SOURCE_URL = 'https://github.com/momargoh/MCycle'
cpdef public str DOCS_URL = 'https://mcycle.readthedocs.io'
# Units
cpdef public dict dimensionUnits = {
    "none": "",
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
}  #: dict of str : Dimensions and their units.
cpdef public dict dimensionsEquiv = {
    "htc": "power/area-temperature",
    "conductivity": "power/length-temperature",
    "fouling": "area-temperature/power",
    "velocity": "length/time",
    "acceleration": "length/time^2",
    "density": "mass/volume",
}  #: dict of str : Equivalents for composite dimensions.
