from ..DEFAULTS cimport GRAVITY
from ..bases.flowstate cimport FlowState
from ..bases.geom cimport Geom
from .. import geometries as gms
from math import nan
import numpy as np
import CoolProp as CP

"""
cdef str _assertGeomErrMsg(Geom geom, str method_name)
cpdef double htc(double Nu, double k, double De)
cpdef double dpf(double f, double G, double L, double Dh, double rho, int N)

cpdef dict chisholmWannairachchi_1phase(FlowState flowIn,
                                        FlowState flowOut,
                                        int N,
                                        Geom geom,
                                        double L,
                                        double W)
cpdef dict savostinTikhonov_1phase(FlowState flowIn,
                                        FlowState flowOut,
                                        int N,
                                        Geom geom,
                                        double L,
                                        double W)
cpdef dict yanLin_2phase_boiling(FlowState flowIn,
                                        FlowState flowOut,
                                        int N,
                                        Geom geom,
                                        double L,
                                        double W)
cpdef dict hanLeeKim_2phase_condensing(FlowState flowIn,
                                        FlowState flowOut,
                                        int N,
                                        Geom geom,
                                        double L,
                                        double W)
cpdef dict manglikBergles_offset_sp(FlowState flowIn,
                                        FlowState flowOut,
                                        int N,
                                        Geom geom,
                                        double L,
                                        double W)
"""
