# Tolerances
cdef public double TOLABS_X = 1e-10
# CoolProp input_pairs
cdef public unsigned char INPUT_PAIR_INVALID = 0
cdef public unsigned char QT_INPUTS = 1
cdef public unsigned char PQ_INPUTS = 2
cdef public unsigned char QSmolar_INPUTS = 3
cdef public unsigned char QSmass_INPUTS = 4
cdef public unsigned char HmolarQ_INPUTS = 5
cdef public unsigned char HmassQ_INPUTS = 6
cdef public unsigned char DmolarQ_INPUTS = 7
cdef public unsigned char DmassQ_INPUTS = 8
cdef public unsigned char PT_INPUTS = 9
cdef public unsigned char DmassT_INPUTS = 10
cdef public unsigned char DmolarT_INPUTS = 11
cdef public unsigned char HmolarT_INPUTS = 12
cdef public unsigned char HmassT_INPUTS = 13
cdef public unsigned char SmolarT_INPUTS = 14
cdef public unsigned char SmassT_INPUTS = 15
cdef public unsigned char TUmolar_INPUTS = 16
cdef public unsigned char TUmass_INPUTS = 17
cdef public unsigned char DmassP_INPUTS = 18
cdef public unsigned char DmolarP_INPUTS = 19
cdef public unsigned char HmassP_INPUTS = 20
cdef public unsigned char HmolarP_INPUTS = 21
cdef public unsigned char PSmass_INPUTS = 22
cdef public unsigned char PSmolar_INPUTS = 23
cdef public unsigned char PUmass_INPUTS = 24
cdef public unsigned char PUmolar_INPUTS = 25
cdef public unsigned char HmassSmass_INPUTS = 26
cdef public unsigned char HmolarSmolar_INPUTS = 27
cdef public unsigned char SmassUmass_INPUTS = 28
cdef public unsigned char SmolarUmolar_INPUTS = 29
cdef public unsigned char DmassHmass_INPUTS = 30
cdef public unsigned char DmolarHmolar_INPUTS = 31
cdef public unsigned char DmassSmass_INPUTS = 32
cdef public unsigned char DmolarSmolar_INPUTS = 33
cdef public unsigned char DmassUmass_INPUTS = 34
cdef public unsigned char DmolarUmolar_INPUTS = 35
# CoolProp imposed phases
cdef public unsigned char iphase_liquid = 0
cdef public unsigned char iphase_supercritical = 1
cdef public unsigned char iphase_supercritical_gas = 2
cdef public unsigned char iphase_supercritical_liquid = 3
cdef public unsigned char iphase_critical_point = 4
cdef public unsigned char iphase_gas = 5
cdef public unsigned char iphase_twophase = 6
cdef public unsigned char iphase_unknown = 7
cdef public unsigned char iphase_not_imposed = 8
# MCycle phases
cdef public unsigned char PHASE_LIQUID = 0
cdef public unsigned char PHASE_SUPERCRITICAL = 1
cdef public unsigned char PHASE_SUPERCRITICAL_GAS = 2
cdef public unsigned char PHASE_SUPERCRITICAL_LIQUID = 3
cdef public unsigned char PHASE_CRITICAL_POINT = 4
cdef public unsigned char PHASE_VAPOUR = 5
cdef public unsigned char PHASE_VAPOR = 5
cdef public unsigned char PHASE_GAS = 5
cdef public unsigned char PHASE_TWOPHASE = 6
cdef public unsigned char PHASE_UNKNOWN = 7
cdef public unsigned char PHASE_NOT_IMPOSED = 8
cdef public unsigned char PHASE_SATURATED_LIQUID = 9
cdef public unsigned char PHASE_SATURATED_VAPOUR = 10
cdef public unsigned char PHASE_SATURATED_VAPOR = 10
# Unit Phases
cdef public unsigned char UNITPHASE_NONE = 0
cdef public unsigned char UNITPHASE_ALL = 1
cdef public unsigned char UNITPHASE_LIQUID = 2
cdef public unsigned char UNITPHASE_VAPOUR = 3
cdef public unsigned char UNITPHASE_VAPOR = 3
cdef public unsigned char UNITPHASE_GAS = 3
cdef public unsigned char UNITPHASE_TWOPHASE_EVAPORATING = 4
cdef public unsigned char UNITPHASE_TP_EVAP = 4
cdef public unsigned char UNITPHASE_TWOPHASE_CONDENSING = 5
cdef public unsigned char UNITPHASE_TP_COND = 5
cdef public unsigned char UNITPHASE_SUPERCRITICAL = 6
cdef public unsigned char UNITPHASE_ALL_SINGLEPHASE = 7
cdef public unsigned char UNITPHASE_ALL_SP = 7
cdef public unsigned char UNITPHASE_ALL_TWOPHASE = 8
cdef public unsigned char UNITPHASE_ALL_TP = 8
# Transfer mechanisms
cdef public unsigned char TRANSFER_NONE = 0
cdef public unsigned char TRANSFER_ALL = 1
cdef public unsigned char TRANSFER_HEAT = 2
cdef public unsigned char TRANSFER_FRICTION = 3
# Flows
cdef public unsigned char FLOW_NONE = 0
cdef public unsigned char FLOW_ALL = 1
cdef public unsigned char WORKING_FLUID = 2
cdef public unsigned char FLOW_PRIMARY = 2
cdef public unsigned char FLOW1 = 2
cdef public unsigned char SECONDARY_FLUID = 3
cdef public unsigned char FLOW_SECONDARY = 3
cdef public unsigned char FLOW2 = 3
# HxFlowConfig
cdef public unsigned char FLOWSENSE_UNDEFINED = 0
cdef public unsigned char COUNTERFLOW = 1
cdef public unsigned char PARALLELFLOW = 2
cdef public unsigned char CROSSFLOW = 3
# Constraints
cdef public unsigned char NO_CONSTRAINT = 0
cdef public unsigned char CONSTANT_P = 1
cdef public unsigned char CONSTANT_V = 2
# MCycle
cdef public str SOURCE_URL = 'https://github.com/momargoh/MCycle'
cdef public str DOCS_URL = 'https://mcycle.readthedocs.io'
