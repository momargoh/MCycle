from .flowstate cimport FlowState
from .._constants cimport *
from ..logger import log

cpdef unsigned char get_unitPhase(FlowState flowIn, FlowState flowOut):
    """unsigned char: Calculate UnitPhase from an incoming and outgoing FlowState."""
    cdef:
        unsigned char flowInPhase = flowIn.phase()
        unsigned char flowOutPhase = flowOut.phase()
    try:
        if flowInPhase == PHASE_SATURATED_LIQUID:
            if flowOutPhase == PHASE_TWOPHASE:
                return UNITPHASE_TWOPHASE_EVAPORATING
            elif flowOutPhase == PHASE_LIQUID:
                return UNITPHASE_LIQUID
            else:
                msg = "get_unitPhase(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
                log('error', msg)
                raise ValueError(msg)
        elif flowInPhase == PHASE_SATURATED_VAPOUR:
            if flowOutPhase == PHASE_TWOPHASE:
                return UNITPHASE_TWOPHASE_CONDENSING
            elif flowOutPhase == PHASE_VAPOUR:
                return UNITPHASE_GAS
            else:
                msg = "get_unitPhase(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
                log('error', msg)
                raise ValueError(msg)
        elif flowInPhase == PHASE_TWOPHASE:
            if flowOutPhase == PHASE_SATURATED_LIQUID:
                return UNITPHASE_TWOPHASE_CONDENSING
            elif flowOutPhase == PHASE_SATURATED_VAPOUR:
                return UNITPHASE_TWOPHASE_EVAPORATING
            elif flowOutPhase == PHASE_TWOPHASE:
                if flowIn.h() < flowOut.h():
                    return UNITPHASE_TWOPHASE_EVAPORATING
                else:
                    return UNITPHASE_TWOPHASE_CONDENSING
            else:
                msg = "get_unitPhase(): Unit spanning twophase and single states unsupported, node required at saturation point."
                log('error', msg)
                raise NotImplementedError(msg)
        elif flowInPhase == PHASE_LIQUID or flowOutPhase == PHASE_LIQUID:
            return UNITPHASE_LIQUID
        elif flowInPhase == PHASE_VAPOUR or flowOutPhase == PHASE_VAPOUR:
            return UNITPHASE_GAS
        elif flowInPhase == PHASE_SUPERCRITICAL_LIQUID or flowOutPhase == PHASE_SUPERCRITICAL_LIQUID:
            return UNITPHASE_LIQUID
        elif flowInPhase == PHASE_SUPERCRITICAL_GAS or flowOutPhase == PHASE_SUPERCRITICAL_GAS:
            return UNITPHASE_GAS
        else:
            msg = "get_unitPhase(): Could not determine unit phase given phases: flowIn={}, flowOut={}".format(flowInPhase, flowOutPhase)
            log('error', msg)
            raise ValueError(msg)
    except Exception as exc:
        msg = "get_unitPhase(): Could not determine UnitPhase."
        log("error", msg, exc)
        raise exc