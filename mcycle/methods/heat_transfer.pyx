"""A selection of single-phase and 2-phase heat transfer relations.

Parameters
----------
flowIn : FlowState
    Incoming fluid.
flowOut : FlowState
    Outgoing fluid.
b : float
    Corrugated plate channel spacing [m].
beta : float
    Corrugated plate chevron angle [degrees].
charLength : float
    Characteristic length [m].
De : float
    Equivalent diameter [m].
    .. note: Equivalent diameter may be equal to the hydraulic diameter, such as for circular cross sections.
Dh : float
    Hydraulic diameter [m].
f : float
    Fanning friction factor.
G : float
    Mass flux [Kg/m^2.s ].
geom : Geom
    Main geometry corresponding to the flow.
geom2 : Geom
    Secondary geometry related to the flow (usually a geometry of another flow).
k : float
    Thermal conductivity [W/m.K].
L : float
    Length of heat transfer area parallel to the flow [m] (plate or pipe length).
N : int
    Number of parallel flow channels of the fluid.
Nu : float
    Nusselt number.
phi : float
    Corrugated plate surface enlargement factor; ratio of developed length to projected length.
pitchCorr : float
    Plate corrugation pitch [m] (distance between corrugation 'bumps').
    .. note: Not to be confused with the plate pitch which is usually defined as the sum of the plate channel spacing and one plate thickness.

rho : float
    Mass density [Kg/m^3].
W : float
    Width of heat transfer area perpendicular to the flow [m] (plate or pipe width).

Returns
--------
h: float
    Heat transfer coefficient [W/m^2.K].
f: float
    Fanning friction factor [-].
dpF: float
    Frictional pressure drop of the fluid [Pa].

Library
--------
"""
from ..DEFAULTS import GRAVITY
from ..bases.flowstate cimport FlowState
from ..bases.geom cimport Geom
from ..components.hxs.flowconfig cimport HxFlowConfig
from .. import geometries as gms
from math import nan, sin, cos, pi, log, log10, exp, isnan
from warnings import warn
import numpy as np
import CoolProp as CP


cdef str _assertGeomErrMsg(Geom geom, str method_name):
    try:
        return "Geometry given ({}) is not valid for the method {}".format(
            geom.__class__.__name__, method_name)
    except:
        return "Geometry given is not valid, {}".format(
            geom.__class__.__name__)


# -----------------------------------------------------------------
# General functions
# -----------------------------------------------------------------

cpdef public double htc(double Nu, double k, double charLength) except *:
    """float: h, heat transfer coefficient [W/m^2.K].
"""
    return Nu * k / charLength


cpdef public double dpf(double f, double G, double L, double Dh, double rho, int N) except *:
    """float: dpF, single-phase pressure drop due to friction [Pa].
"""
    return f * 2 * G**2 * L * N / Dh / rho


# -----------------------------------------------------------------
# General heat exchange functions
# -----------------------------------------------------------------

cpdef public double lmtd(double TIn1, double TOut1, double TIn2, double TOut2, str flowSense) except *:
    """float: Log-mean temperature difference [K]."""
    cdef double dT1 = 0
    cdef double dT2 = 0
    cdef double ans
    cdef str msg
    if flowSense == "counter":
        dT1 = TIn2 - TOut1
        dT2 = TOut2 - TIn1
    elif flowSense == "parallel":
        dT1 = TOut2 - TOut1
        dT2 = TIn2 - TIn1
    else:
        msg = "lmtd flowSense not valid/supported (given: {})".format(flowSense)
        log("error", msg)
        raise ValueError(msg)
    ans = (dT1 - dT2) / log(dT1 / dT2)
    if isnan(ans):
        msg = "lmtd found non-valid flow temperatures: TIn1={}, TOut1={}, TIn2={}, TOut2={}".format(TIn1, TOut1, TIn2, TOut2)
        log("warning", msg)
        warn(msg)
    return ans
    

# -----------------------------------------------------------------
# Chevron-type corrugated plate heat exchangers
# single-phase relations
# -----------------------------------------------------------------

cpdef dict chisholmWannairachchi_sp(FlowState flowIn,
                                    FlowState flowOut,
                                    int N,
                                    Geom geom,
                                    double L,
                                    double W,
                                    HxFlowConfig flowConfig,
                                    bint is_wf=True,
                                    Geom geom2=None):
    """Single phase, heat and friction, valid for GeomHxPlateCorrugatedChevron. [Chisholm1992]_ Chisholm D. Wanniarachchi, A. S. Maldistribution in single-pass mixed-channel plate heat exchangers. ASME, 1992, 201, 95-99.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateCorrugatedChevron, _assertGeomErrMsg(
        geom, "chisholmWannairachchi_sp")
    cdef double Dh = 2 * geom.b / geom.phi
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double T_avg = 0.5 * (flowIn.T() + flowOut.T())
    cdef FlowState avg = flowIn.copyState(CP.PT_INPUTS, p_avg, T_avg)
    cdef double Re = G * Dh / avg.visc()
    cdef double Nu = 0.72 * Re**0.59 * avg.Pr()**0.4 * geom.phi**0.41 * (geom.beta /
                                                             30)**0.66
    cdef double h = htc(Nu, avg.k(), Dh)
    cdef double f = 0.8 * Re**-0.25 * geom.phi**1.25 * (geom.beta / 30)**3.6
    cdef double dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    return {"h": h, "f": f, "dpF": dpF}

cpdef dict savostinTikhonov_sp(FlowState flowIn,
                               FlowState flowOut,
                               int N,
                               Geom geom,
                               double L,
                               double W,
                               HxFlowConfig flowConfig,
                               bint is_wf=True,
                               Geom geom2=None):
    """Single phase, heat and friction, valid for GeomHxPlateCorrugatedChevron. [Savostin1970]_ Savostin, A. F. & Tikhonov, A. M. Investigation of the Characteristics of Plate Type Heating Surfaces Thermal Engineering, 1970, 17, 113-117.

Data collected for: air

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateCorrugatedChevron, _assertGeomErrMsg(
        geom, "savostinTikhonov_sp")
    cdef double Dh = 2 * geom.b / geom.phi
    cdef double psi = 2 * np.radians(geom.beta)
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double T_avg = 0.5 * (flowIn.T() + flowOut.T())
    cdef FlowState avg = flowIn.copyState(CP.PT_INPUTS, p_avg, T_avg)
    cdef double Re = G * Dh / avg.visc()
    cdef double a1 = 0.22 * (1 + 1.1 * psi**1.5)
    cdef double a2 = 0.53 * (0.58 + 0.42 * np.cos(1.87 * psi))
    cdef double f, Nu
    if Re / geom.phi < 600:
        f = 6.25 * (1 + 0.95 * psi**1.72) * geom.phi**1.84 * Re**-0.84
        Nu = 1.26 * ((0.62 + 0.38 * cos(2.3 * psi)) * geom.phi**(1 - a1) * avg.Pr()**(1. / 3) * Re**a1)
    else:
        f = 0.95 * (0.62 + 0.38 * cos(2.6 * psi)) * geom.phi**(
            1 + a2) * Re**(-a2)
        Nu = 0.072*geom.phi**0.33*avg.Pr()**(1./3)*Re**0.67 \
            * exp(0.5*psi+0.17*psi**2)
    if Nu < 0.:
        msg = "savostinTikhonov_sp calculated a negative Nu value"
        log("error", msg)
        warn(msg)
    Nu = abs(Nu)
    cdef double h = htc(Nu, avg.k(), Dh)
    cdef double dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    return {"h": h, "f": f, "dpF": dpF}

cpdef dict muleyManglik_sp(FlowState flowIn,
                           FlowState flowOut,
                           int N,
                           Geom geom,
                           double L,
                           double W,
                           HxFlowConfig flowConfig,
                           bint is_wf=True,
                           Geom geom2=None):
    """Single phase, heat and friction, valid for GeomHxPlateCorrugatedChevron. [Muley1999]_ Muley, A. and Manglik, R. M., Experimental Study of Turbulent Flow Heat Transfer and Pressure Drop in a Plate Heat Exchanger with Chevron Plates, Journal of Heat Transfer, vol. 121, no. 1, pp. 110–117, 1999.

Data collected for: steam, 30<=beta<=60, 1<=phi<=1.5

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateCorrugatedChevron, _assertGeomErrMsg(
        geom, "muleyManglik_sp")
    cdef double Dh = 2 * geom.b / geom.phi
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double T_avg = 0.5 * (flowIn.T() + flowOut.T())
    cdef FlowState avg = flowIn.copyState(CP.PT_INPUTS, p_avg, T_avg)
    cdef double Re = G * Dh / avg.visc()
    cdef double C0 = 90-geom.beta
    cdef double Nu = (0.2668-0.006967*C0+7.244e-5*C0**2)*(20.78-50.94*geom.phi+41.16*geom.phi**2-10.51*geom.phi**3)*Re**(0.728+0.0543*sin(pi*C0/45+3.7))*avg.Pr()**(1./3)
    cdef double h = htc(Nu, avg.k(), Dh)
    cdef double f = (2.917-0.1277*C0+2.016e-3*C0**2)*(5.474-19.02*geom.phi+18.93*geom.phi**2-5.341*geom.phi**3)*Re**-(0.2+0.0577*sin(pi*C0/45+2.1))
    cdef double dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    return {"h": h, "f": f, "dpF": dpF}

# -----------------------------------------------------------------
# 2-phase boiling relations, plate exchangers
# -----------------------------------------------------------------


cpdef dict yanLin_tpEvap(FlowState flowIn,
                         FlowState flowOut,
                         int N,
                         Geom geom,
                         double L,
                         double W,
                         HxFlowConfig flowConfig,
                         bint is_wf=True,
                         Geom geom2=None):
    """Two-phase evaporation, heat and friction, valid for GeomHxPlateCorrugatedChevron. [Yan1999]_ Yan, Y.-Y. & Lin, T.-F. Evaporation Heat Transfer and Pressure Drop of Refrigerant R-134a in a Plate Heat Exchanger Journal of Heat Transfer Engineering, 1999, 121, 118-127. `doi:10.1115/1.2825924 <http://doi.org/10.1115/1.2825924>`_

Data collected for: R134a, beta=60deg, 2000<Re<8000.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateCorrugatedChevron, _assertGeomErrMsg(
        geom, "yanLin_tpEvap")
    cdef double Dh = 2 * geom.b / geom.phi
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double x_avg = 0.5 * (flowIn.x() + flowOut.x())
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef FlowState avg = flowIn.copyState(CP.PQ_INPUTS, p_avg, x_avg)
    cdef FlowState liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    cdef FlowState vap = flowIn.copyState(CP.PQ_INPUTS, p_avg, 1)
    cdef double G_eq = G * (1 - x_avg + x_avg * (liq.rho() / vap.rho())**0.5)
    cdef double Re = G * Dh / avg.visc()
    cdef double Re_eq = G_eq * Dh / avg.visc()
    cdef double q = m_channel * (flowOut.h() - flowIn.h()) / (W * L)
    cdef double Bo_eq = abs(q / G_eq / (vap.h() - liq.h()))
    cdef double h = 1.926 * Re_eq / (liq.Pr()**(-1. / 3) * Re**0.5 * Bo_eq**-0.3 * Dh / liq.k())
    cdef double f
    if Re_eq < 6000:
        f = 6.947e5 * Re_eq**-1.109 / Re**0.5
    else:
        f = 31.21 * Re_eq**0.04557 / Re**0.5
    cdef double dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# 2-phase condensing relations, plate exchangers
# -----------------------------------------------------------------


cpdef dict hanLeeKim_tpCond(FlowState flowIn,
                            FlowState flowOut,
                            int N,
                            Geom geom,
                            double L,
                            double W,
                            HxFlowConfig flowConfig,
                            bint is_wf=True,
                            Geom geom2=None):
    r"""Two-phase condensation, heat and friction, valid for GeomHxPlateCorrugatedChevron.Data collected for: R410A and R22, with beta = 45, 35, 20deg. [Han2003]_ Han, D.-H.; Lee, K.-J. & Kim, Y.-H. The Characteristics of Condensation in Brazed Plate Heat Exchangers with Different Chevron Angles Korean Physical Society, 2003, 43, 66-73.

Returns
--------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateCorrugatedChevron, _assertGeomErrMsg(
        geom, "hanLeeKim_tpCond")
    cdef double x_avg = 0.5 * (flowIn.x() + flowOut.x())
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef FlowState avg = flowIn.copyState(CP.PQ_INPUTS, p_avg, x_avg)
    cdef FlowState liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    cdef FlowState vap = flowIn.copyState(CP.PQ_INPUTS, p_avg, 1)
    #
    cdef double beta = np.radians(geom.beta)
    cdef double Dh = 2 * geom.b / geom.phi
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double X0 = (1 - x_avg + x_avg * (liq.rho() / vap.rho())**0.5)
    cdef double G_eq = G * X0
    # Re = G * Dh / avg.visc()
    cdef double Re_eq = G_eq * Dh / liq.visc()
    #
    cdef double X1 = geom.pitchCorr / Dh
    cdef double X2 = np.pi / 2 - beta
    cdef double Ge1 = 11.22 * X1**-2.83 * X2**-4.5
    cdef double Ge2 = 0.35 * X1**0.23 * X2**1.48
    cdef double Ge3 = 3521.1 * X1**4.17 * X2**-7.75
    cdef double Ge4 = -1.024 * X1**0.0925 * X2**-1.3
    cdef double Nu = Ge1 * (Re_eq**Ge2) * (avg.Pr()**(1. / 3))
    cdef double f = Ge3 * Re_eq**Ge4
    cdef double h = htc(Nu, avg.k(), Dh)
    cdef double dpF = f * L * N * G_eq**2 / Dh / avg.rho()
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# single-phase relations, plate-fin exchangers
# -----------------------------------------------------------------


cpdef dict manglikBergles_offset_sp(FlowState flowIn,
                                    FlowState flowOut,
                                    int N,
                                    Geom geom,
                                    double L,
                                    double W,
                                    HxFlowConfig flowConfig,
                                    bint is_wf=True,
                                    Geom geom2=None):
    """Single-phase and two-phase (evaporation and condensation), heat and friction, valid for GeomHxPlateFinOffset. [Manglik1995]_ Manglik and Bergles, Heat transfer and pressure drop correlations for the rectangular offset strip fin compact heat exchanger, Experimental Thermal and Fluid Science, Elsevier, 1995, 10, pp. 171-180. `doi:10.1016/0894-1777(94)00096-Q <http://doi.org/10.1016/0894-1777(94)00096-Q>`_.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateFinOffset, _assertGeomErrMsg(
        geom, "manglikBergles_offset_sp")
    cdef double alpha = geom.s / geom.h
    cdef double delta = geom.t / geom.l
    cdef double gamma = geom.t / geom.s
    cdef double Dh = 4 * geom.s * geom.h * geom.l / (
        2 * (geom.s * geom.l + geom.h * geom.l + geom.t * geom.h
             ) + geom.t * geom.s)
    cdef double m_channel = flowIn.m / N
    cdef double Nfin = W / (geom.s + geom.t)
    cdef double m_fin = m_channel / Nfin
    cdef double G = m_fin / (geom.s * geom.h)
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double h_avg = 0.5 * (flowIn.h() + flowOut.h())
    cdef FlowState avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    cdef double Re = G * Dh / avg.visc()
    #
    cdef double f = 9.6243 * (Re**-0.7422) * (alpha**-0.1856) * (delta**0.3053) * (
        gamma**-0.2656) * (1 + 7.669e-8 * (Re**4.429) * (alpha**0.920) *
                           (delta**3.767) * (gamma**0.236))**0.1

    cdef double j = 0.6522 * (Re**-0.5403) * (alpha**-0.1541) * (delta**0.1499) * (
        gamma**-0.0678) * (1 + 5.269e-5 * (Re**1.340) * (alpha**0.504) *
                           (delta**0.456) * (gamma**-1.055))**0.1
    #cdef double h = j * avg.cp() * G / (avg.Pr()**(2 / 3))
    cdef double Nu = j*Re*(avg.Pr()**(1 / 3))
    cdef double h = htc(Nu, avg.k(), Dh)
    # dpF = dpf(f, G, geom.l, Dh, avg.rho())
    cdef double dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# single-phase relations, smooth parallel plates
# -----------------------------------------------------------------

cpdef dict shibani_sp_h(FlowState flowIn,
                                    FlowState flowOut,
                                    int N,
                                    Geom geom,
                                    double L,
                                    double W,
                                    HxFlowConfig flowConfig,
                                    bint is_wf=True,
                                    Geom geom2=None):
    """Single-phase , heat, valid for GeomHxPlateSmootht. [Shibani1977]_ Shibani and Ozisik, "A solution to heat transfer in turbulent flow between parallel plates", International Journal of Heat and Mass Transfer, vol. 20-5, pp 565--573, 1977, Elsevier.

Returns
-------
dict of float : {"h"}
    """
    assert type(geom) == gms.GeomHxPlateSmooth, _assertGeomErrMsg(
        geom, "shibani_sp_h")
    cdef double De = 2*geom.b() # equivalent diameter
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double h_avg = 0.5 * (flowIn.h() + flowOut.h())
    cdef FlowState avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    cdef double Re = G * De / avg.visc()
    cdef double Pr = avg.Pr()
    cdef double Nu = 0
    if Pr < 1:
        Nu = 8.3 + 0.02*Re**0.82*Pr**(0.52+0.0096/(0.02+Pr))
    else:
        Nu = 12 + 0.03*Re**(0.88-0.24/(3.6+Pr))*Pr**(0.33+0.5*exp(-0.6*Pr))
    cdef double h = htc(Nu, avg.k(), De)
    return {"h": h}

cpdef dict rothfus_sp_f(FlowState flowIn,
                                    FlowState flowOut,
                                    int N,
                                    Geom geom,
                                    double L,
                                    double W,
                                    HxFlowConfig flowConfig,
                                    bint is_wf=True,
                                    Geom geom2=None):
    """Single-phase , friction, valid for GeomHxPlateSmootht. [Rothfus1957]_ Rothfus, R. R., Archer, D. H., Klimas, I. C., & Sikchi, K. G. (1957). Simplified flow calculations for tubes and parallel plates. AIChE Journal, 3(2), pp 208--212.

This correlation comes from data fitting Fig. 4 for the turbulent region, giving the curve: f = 10**(-0.206771314*log10(Re)-1.296108505). For Re<3000, the viscous region relation is used: f = 24/Re. The transitional region, for now, will be treated as the turbulent region.

Returns
-------
dict of float : {"f", "dpF"}
    """
    assert type(geom) == gms.GeomHxPlateSmooth, _assertGeomErrMsg(
        geom, "shibani_sp_h")
    cdef double De = 2*geom.b() # equivalent diameter
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double h_avg = 0.5 * (flowIn.h() + flowOut.h())
    cdef FlowState avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    cdef double Re = G * De / avg.visc()
    cdef double f = 0
    if Re < 3000:
        f = 24/Re
    else:
        f = 10**(-0.206771314*log10(Re)-1.296108505)
    cdef double dpF = dpf(f, G, L, De, avg.rho(), 1)
    return {"f": f, "dpF": dpF}
    

# -----------------------------------------------------------------
# Two-phase relations, smooth parallel plates
# -----------------------------------------------------------------

cpdef dict huang_tpEvap_h(FlowState flowIn,
                         FlowState flowOut,
                         int N,
                         Geom geom,
                         double L,
                         double W,
                         HxFlowConfig flowConfig,
                         bint is_wf=True,
                         Geom geom2=None):
    """Two-phase evaporation, heat, valid for GeomHxPlateSmooth. [Huang2012]_ Huang, Y. P., Huang, J., Ma, J., Wang, Y. L., Wang, J. F., & Wang, Q. W. (2012). Single and Two-Phase Heat Transfer Enhancement Using Longitudinal Vortex Generator in Narrow Rectangular Channel. In An Overview of Heat Transfer Phenomena. IntechOpen,`doi:10.5772/53713 <http://doi.org/10.5772/53713>`_

Returns
-------
dict of float : {"h"}
    """
    assert type(geom) == gms.GeomHxPlateSmooth, _assertGeomErrMsg(
        geom, "huang_tpEvap_h")
    cdef double b = geom.b()
    cdef double Dh = 2 * b
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (b * W)
    cdef double x_avg = 0.5 * (flowIn.x() + flowOut.x())
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef FlowState avg = flowIn.copyState(CP.PQ_INPUTS, p_avg, x_avg)
    cdef FlowState liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    cdef FlowState vap = flowIn.copyState(CP.PQ_INPUTS, p_avg, 1)
    #cdef double G_eq = G * (1 - x_avg + x_avg * (liq.rho() / vap.rho())**0.5)
    cdef double Re = G * Dh / avg.visc()
    #cdef double Re_eq = G_eq * Dh / avg.visc()
    cdef double q = m_channel * (flowOut.h() - flowIn.h()) / (W * L)
    cdef double Bo = abs(q / G / (vap.h() - liq.h()))
    cdef double h = 1.40*Re*Bo**0.349*avg.k()/Dh
    return {"h": h}


# -----------------------------------------------------------------
# single-phase relations, circular smooth ducts
# -----------------------------------------------------------------


def techo_sp_f(flowIn, flowOut, Dh, Ac, L, N=1):
    """Single-phase, friction, valid for GeomDuctCircular, GeomHxPlateSmooth. [Techo1965]_ R. Techo, R. R. Tickner, and R. E. James, "An Accurate Equation for the Computation of the Friction Factor for Smooth Pipes from the Reynolds Number," J. Appl. Mech. (32): 443, 1965.

Returns
-------
dict of float : {"f", "dpF"}
    """
    m_channel = flowIn.m / N
    G = m_channel / Ac
    p_avg = 0.5 * (flowIn.p() + flowOut.p())
    h_avg = 0.5 * (flowIn.h() + flowOut.h())
    avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc()
    f = (0.86859 * np.log(Re / (1.964 * np.log(Re) - 3.8215)))**-2
    dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    return {"f": f, "dpF": dpF}


cpdef dict dittusBoelter_sp_h(FlowState flowIn,
                              FlowState flowOut,
                              int N,
                              Geom geom,
                              double L,
                              double W,
                              HxFlowConfig flowConfig,
                              bint is_wf=True,
                              Geom geom2=None):
    """Single-phase, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Kakaç1998]_ Kakaç, S. & Liu, H. Heat exchangers : selection, rating, and thermal design, CRC Press, 1998.

Returns
-------
dict of float : {"h"}
"""
    assert type(geom) in [gms.GeomHxPlateSmooth], _assertGeomErrMsg(
        geom, "dittusBoelter_sp_h")
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W

    m_channel = flowIn.m / N
    G = m_channel / Ac
    p_avg = 0.5 * (flowIn.p() + flowOut.p())
    h_avg = 0.5 * (flowIn.h() + flowOut.h())
    avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc()
    Nu = 0.023 * Re**0.8 * avg.Pr()**0.4
    h = htc(Nu, avg.k(), De)
    return {"h": h}

def shah_sp_h(flowIn,
              flowOut,
              N,
              geom,
              L,
              W,
              HxFlowConfig flowConfig,
              bint is_wf=True,
              **kwargs):
    """Single-phase, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Kakaç1998]_ Kakaç, S. & Liu, H. Heat exchangers : selection, rating, and thermal design, CRC Press, 1998.

Returns
-------
dict of float : {"h"}
"""
    assert type(geom) in [gms.GeomHxPlateSmooth], _assertGeomErrMsg(
        geom, "shah_sp_h")
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W

    if flowIn.h() > flowOut.h():
        n = 0.3  # condensation mode
    else:
        n = 0.4  # evaporation mode
    m_channel = flowIn.m / N
    G = m_channel / Ac
    p_avg = 0.5 * (flowIn.p() + flowOut.p())
    h_avg = 0.5 * (flowIn.h() + flowOut.h())
    avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc()
    Nu = 0.023 * Re**0.8 * avg.Pr()**n
    h = htc(Nu, avg.k(), De)
    return {"h": h}


cpdef dict gnielinski_sp(FlowState flowIn,
                         FlowState flowOut,
                         int N,
                         Geom geom,
                         double L,
                         double W,
                         HxFlowConfig flowConfig,
                         bint is_wf=True,
                         Geom geom2=None):
    """Single-phase, heat and friction, valid for GeomDuctCircular, GeomHxPlateSmooth. [Gnielinski1976]_ V. Gnielinski, "New Equations for Heat and Mass Transfer in Turbulent Pipe and Channel Flow," Int. Chem. Eng., (16): 359-368, 1976.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) in [gms.GeomHxPlateFinStraight], _assertGeomErrMsg(
        geom, "gnielinski_sp")
    cdef double Dh, De, Ac
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W
                      
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / Ac
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef double T_avg = 0.5 * (flowIn.T() + flowOut.T())
    cdef double h_avg = 0.5 * (flowIn.h() + flowOut.h())
    # avg = flowIn.copyState(CP.PT_INPUTS, p_avg, T_avg)
    cdef FlowState avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    cdef double Re = G * Dh / avg.visc()
    cdef double f = (1.58 * np.log(Re) - 3.28)**-2
    cdef double dpF = dpf(f, G, L, Dh, avg.rho(), 1)
    cdef double Pr = avg.Pr()
    cdef double Nu
    if Pr >= 0.5 and Pr <= 1.5 and Re >= 2300 and Re <= 5e6:
        Nu = 0.0214 * (Re**0.8 - 100) * Pr**0.4
    elif Pr >= 1.5 and Pr <= 500 and Re >= 3e3 and Re <= 1e6:
        Nu = 0.012 * (Re**0.87 - 280) * Pr**0.4
    else:
        Nu = f / 2 * (Re - 1000) * Pr / (1 + 12.7 * np.sqrt(f / 2) *
                                         (Pr**(2 / 3) - 1))
    cdef double h = htc(Nu, avg.k(), De)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# 2-phase boiling relations, circular smooth ducts
# -----------------------------------------------------------------
'''
cpdef dict gungorWinterton_tpEvap_h(FlowState flowIn,
                                    FlowState flowOut,
                                    int N,
                                    Geom geom,
                                    double L,
                                    double W,
                                    Geom geom2=None,
                                    vertical=False):
    r"""TODO see eqn in Zarati paper. Two-phase evaporation, heat, valid for GeomHxPlateSmooth. [Gungor]_

Returns
--------
dict of float : {"h"}
    """
    assert type(geom) == gms.GeomHxPlateSmooth, _assertGeomErrMsg(
        geom, "gungorWinterton_tpEvap_h")
    cdef double x_avg = 0.5 * (flowIn.x() + flowOut.x())
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef FlowState avg = flowIn.copyState(CP.PQ_INPUTS, p_avg, x_avg)
    cdef FlowState liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    cdef FlowState vap = flowIn.copyState(CP.PQ_INPUTS, p_avg, 1)
    #
    cdef double beta = np.radians(geom.beta)
    cdef double Dh = 2 * geom.b / geom.phi
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / (geom.b * W)
    
    cdef double Xtt = (1./x_avg - 1)**0.9*(vap.rho()/liq.rho())**0.5*(liq.visc()/vap.visc())**0.1
    cdef double Re_l = (1.- x_avg)*Gtp*Dh/liq.visc()
    cdef double S = 1./(1+2.53e-6*Re_l**1.17)
    cdef double F = 1
    if Xtt_inv > 0.1:
        F = 2.35*(Xtt_inv+0.213)**0.736
    cdef double h_nb = 
    cdef double h_sp = 
    return {"h": S*h_nb + F*h_sp}
'''
cpdef dict gungorWinterton_tpEvap_h(FlowState flowIn,
                                    FlowState flowOut,
                                    int N,
                                    Geom geom,
                                    double L,
                                    double W,
                                    HxFlowConfig flowConfig,
                                    bint is_wf=True,
                                    Geom geom2=None):
    r"""Two-phase evaporation, heat, valid for GeomHxPlateSmooth. [Gungor1987]_ K. E. Gungor and R. H. S. Winterton, “Simplified general correlation for saturated flow boiling and comparison with data,” Chemical Engineering Research and Design, vol. 65, no. 2, pp. 148-–156, 1987. As cited  in [Zhou2013]_ Z. Zhou, X. Fang , D. Li , "Evaluation of Correlations of Flow Boiling Heat Transfer of R22 in Horizontal Channels,"The Scientific World Journal, vol. 2013, Article ID 458797, 14 pages, doi:10.1155/2013/458797

Returns
--------
dict of float : {"h"}
    """
    assert type(geom) == gms.GeomHxPlateSmooth, _assertGeomErrMsg(
        geom, "gungorWinterton_tpEvap_h")
    cdef double Dh, De, Ac, As
    cdef bint vertical
    if is_wf:
        vertical = flowConfig.verticalWf
    else:
        vertical = flowConfig.verticalSf        
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W
        As = W * L
    cdef double x_avg = 0.5 * (flowIn.x() + flowOut.x())
    cdef double p_avg = 0.5 * (flowIn.p() + flowOut.p())
    cdef FlowState avg = flowIn.copyState(CP.PQ_INPUTS, p_avg, x_avg)
    cdef FlowState liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    cdef FlowState vap = flowIn.copyState(CP.PQ_INPUTS, p_avg, 1)
    #
    cdef double m_channel = flowIn.m / N
    cdef double G = m_channel / Ac
    cdef double G_eq = G * (1 - x_avg + x_avg * (liq.rho() / vap.rho())**0.5)
    cdef double Re = G * Dh / avg.visc()
    cdef double Re_eq = G_eq * Dh / avg.visc()
    cdef double q = m_channel * (flowOut.h() - flowIn.h()) / As
    cdef double Bo_eq = q / G_eq / (vap.h() - liq.h()) 
    cdef double Fr_l = G**2 / (liq.rho()**2 * GRAVITY * Dh)
    #
    cdef double S = 1 + 3000*Bo_eq**0.86
    cdef double F = 1.12*(x_avg/(1-x_avg))**0.75*(liq.rho()/vap.rho())**0.41    
    cdef double S2 = 1
    cdef double F2 = 1
    if Fr_l < 0.05 and vertical is False:
        S2 = Fr_l**(0.1-2*Fr_l)
        F2 = Fr_l**0.5
    cdef double h_spl = dittusBoelter_sp_h(flowIn, flowOut, N, geom, L, W, geom2)["h"]
    cdef h_tp = h_spl*(S*S2 + F*F2)
    return {"h":h_tp}

def shah_tpEvap_h(flowIn,
                  flowOut,
                  N,
                  geom,
                  L,
                  W,
                  HxFlowConfig flowConfig,
                  bint is_wf=True,
                  **kwargs):
    """Two-phase evporation, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Shah1976]_ Shah, M. M. A new correlation for heat transfer during boiling flow through pipes Ashrae Trans., 1976, 82, 66-86.

Returns
-------
dict of float : {"h"}
    """
    assert type(geom) in [gms.GeomHxPlateSmooth], _assertGeomErrMsg(
        geom, "shah_tpEvap_h")
    cdef bint vertical
    if is_wf:
        vertical = flowConfig.verticalWf
    else:
        vertical = flowConfig.verticalSf 
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W
    m_channel = flowIn.m / N
    G = m_channel / Ac
    x_avg = 0.5 * (flowIn.x() + flowOut.x())
    p_avg = 0.5 * (flowIn.p() + flowOut.p())
    liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    vap = flowIn.copyState(CP.PQ_INPUTS, p_avg, 1)
    Fr = G**2 / (liq.rho()**2 * GRAVITY * Dh)
    if Fr > 0.04 or vertical is True:
        K_Fr = 1.
    else:
        K_Fr = (25 * Fr)**-0.3
    Co = (1 / x_avg - 1)**0.8 * (vap.rho() / liq.rho())**0.5 * K_Fr
    q = flowIn.m * (flowOut.h() - flowIn.h()) / (np.pi * De * L)
    Bo = q / G / (vap.h() - liq.h())
    if Bo < 1.9e5:
        if Co < 1.0:
            F = 1.8 * Co**-0.8
        else:
            F = 1.0 + 0.8 * np.exp(1 - Co**0.5)
    else:
        if Co > 1.0:
            F = 231 * Bo**0.5
        else:
            Fnb = 231 * Bo**0.5
            Fcb = 1.8 * Co**-0.8
            F = Fnb * (0.77 + 0.13 * Fcb)
    h_l = shah_sp_h(flowIn=liq, flowOut=liq, N=N, geom=geom, L=L, W=W)["h"]
    h = F * h_l
    return {"h": h}


def chen_tpEvap_h(flowIn,
                        flowOut,
                        Dh,
                        De,
                        Ac,
                        L,
                        N=1,
                        g=9.81,
                        vertical=False):
    """Two-phase evporation, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Chen1962]_ Chen, J. C. A correlation for boiling heat transfer to saturated fluids in convective flow Ind. Eng. Chem. Process Des. Dev., Vol 5, 322-329, 1962.

Method as described in [Kakaç1998]_.

Returns
-------
dict of float : {"h"}
    """
    m_channel = flowIn.m / N
    G = m_channel / Ac
    x = 0.5 * (flowIn.x() + flowOut.x())
    h_avg = 0.5 * (flowIn.h() + flowOut.h())
    p_avg = 0.5 * (flowIn.p() + flowOut.p())
    avg = flowIn.copyState(CP.HmassP_INPUTS, h_avg, p_avg)
    liq = flowIn.copyState(CP.PQ_INPUTS, avg.p(), 0)
    vap = flowIn.copyState(CP.PQ_INPUTS, avg.p(), 1)
    X_tt = (1 / x - 1)**0.9 * (vap.rho() / liq.rho())**0.5 * (liq.visc() /
                                                              vap.visc())**0.1
    if (1 / X_tt) <= 0.1:
        F = 1
    else:
        F = 2.35 * (0.213 + 1 / X_tt)**0.736
    Re_tp = (1 - x) * G * Dh / liq.visc() * F**1.25
    Re_l = G * Dh / liq.visc()
    S = 1 / (1 + 2.53e-6 * Re_tp**1.17)
    h_l = 0.023 * Re_l**0.8 * liq.Pr()**0.4 * liq.k() / Dh
    h_cb = F * h_l
    q = flowIn.m * (flowOut.h() - flowIn.h()) / (np.pi * De * L)
    theta = q / h_cb
    dp_v = theta * (vap.h() - liq.h()) * vap.rho() / liq.T()
    h_nb = 0.00122 * liq.k()**0.079 * liq.cp()**0.45 * liq.rho(
    )**0.49 * theta**0.24 * dp_v**0.75 / avg.s / liq.visc()**0.29 / vap.rho(
    )**0.24 / (vap.h() - liq.h())**0.24
    h = h_cb * F + h_nb * S
    return {"h": h}


# -----------------------------------------------------------------
# 2-phase condensing relations, circular smooth ducts
# -----------------------------------------------------------------


def shah_tpCond_h(flowIn,
                           flowOut,
                           Dh,
                           De,
                           Ac,
                           L,
                           N=1,
                           g=9.81,
                           vertical=False):
    """Two-phase evporation, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Shah2009]_ Shah, M. M. An improved and extended general correlation for heat transfer during condensation in plain tubes Hvac&R Research, Taylor & Francis, 2009, 15, 889-913. `doi:10.1080/10789669.2009.10390871 <https://doi.org/10.1080/10789669.2009.10390871>`_

Returns
-------
dict of float : {"h"}
    """
    assert flowIn.x() >= 0 and flowIn.x() <= 1
    assert flowOut.x() >= 0 and flowOut.x() <= 1
    p_avg = 0.5 * (flowIn.p() + flowOut.p())
    x = 0.5 * (flowIn.x() + flowOut.x())
    liq = flowIn.copyState(CP.PQ_INPUTS, p_avg, 0)
    h_l = shah_sp_h(liq, liq, Dh, De, Ac, L, N)
    p_star = liq.p() / liq._state().pcrit()
    h = h_l * ((1 - x)**0.8 + (3.8 * x**0.76 * (1 - x)**0.04) / (p_star**0.38))
    return {"h": h}
