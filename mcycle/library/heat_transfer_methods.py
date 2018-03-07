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
N : int
    Number of parallel flow channels of the fluid.
Nu : float
    Nusselt number.
De : float
    Equivalent diameter [m].
    .. note: Equivalent diameter may be equal to the hydraulic diameter, such as for circular cross sections.
Dh : float
    Hydraulic diameter [m].
f : float
    Fanning friction factor.
G : float
    Mass flux [Kg/m^2.s ].
k : float
    Thermal conductivity [W/m.K].
L : float
    Length of heat transfer area parallel to the flow [m] (plate or pipe length).
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
from ..bases import Geom
from .. import geometries as gms
import numpy as np
import CoolProp as CP


def _assertGeomErrMsg(geom, method_name):
    if issubclass(geom, Geom):
        return "Geometry given ({}) is not valid for the method {}".format(
            geom.__name__, method_name)
    elif type(geom) is str:
        return "Geometry given ({}) is not valid for the method {}".format(
            geom, method_name)
    else:
        return "Geometry given is not valid, {}".format(geom)


# -----------------------------------------------------------------
# common functions
# -----------------------------------------------------------------
def htc(Nu, k, De):
    """float: h, heat transfer co-efficient [W/m^2.K].
"""
    return Nu * k / De


def dpf(f, G, L, Dh, rho, N=1):
    """float: dpF, single-phase pressure drop due to friction [Pa].
"""
    return f * 2 * G**2 * L * N / Dh / rho


# -----------------------------------------------------------------
# single-phase relations, plate exchangers
# -----------------------------------------------------------------


def chisholmWannairachchi_1phase(flowIn=None,
                                 flowOut=None,
                                 N=None,
                                 geom=None,
                                 L=None,
                                 W=None,
                                 **kwargs):
    """Single phase, heat and friction, valid for GeomHxPlateCorrChevron. [CHISHOLM1992]_ Chisholm D. Wanniarachchi, A. S. Maldistribution in single-pass mixed-channel plate heat exchangers. ASME, 1992, 201, 95-99.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) is gms.GeomHxPlateCorrChevron, _assertGeomErrMsg(
        geom, "chisholmWannairachchi_1phase")
    Dh = 2 * geom.b / geom.phi
    m_channel = flowIn.m / N
    G = m_channel / (geom.b * W)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    T_avg = 0.5 * (flowIn.T + flowOut.T)
    avg = flowIn.copy(CP.PT_INPUTS, p_avg, T_avg)
    Re = G * Dh / avg.visc
    Nu = 0.72 * Re**0.59 * avg.Pr**0.4 * geom.phi**0.41 * (geom.beta /
                                                           30)**0.66
    h = htc(Nu, avg.k, Dh)
    f = 0.8 * Re**-0.25 * geom.phi**1.25 * (geom.beta / 30)**3.6
    dpF = dpf(f, G, L, Dh, avg.rho)
    return {"h": h, "f": f, "dpF": dpF}


def savostinTikhonov_1phase(flowIn=None,
                            flowOut=None,
                            N=None,
                            geom=None,
                            L=None,
                            W=None,
                            **kwargs):
    """Single phase, heat and friction, valid for GeomHxPlateCorrChevron. [Savostin1970]_ Savostin, A. F. & Tikhonov, A. M. Investigation of the Characteristics of Plate Type Heating Surfaces Thermal Engineering, 1970, 17, 113-117.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) is gms.GeomHxPlateCorrChevron, _assertGeomErrMsg(
        geom, "savostinTikhonov_1phase")
    Dh = 2 * geom.b / geom.phi
    psi = 2 * np.radians(geom.beta)
    m_channel = flowIn.m / N
    G = m_channel / (geom.b * W)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    T_avg = 0.5 * (flowIn.T + flowOut.T)
    avg = flowIn.copy(CP.PT_INPUTS, p_avg, T_avg)
    Re = G * Dh / avg.visc
    a1 = 0.22 * (1 + 1.1 * psi**1.5)
    a2 = 0.53 * (0.58 + 0.42 * np.cos(1.87 * psi))
    if Re / geom.phi < 600:
        f = 6.25 * (1 + 0.95 * psi**1.72) * geom.phi**1.84 * Re**-0.84
        Nu = 1.26 * (0.62 + 0.38 * np.cos(2.3 * psi) * geom.phi**
                     (1 - a1) * avg.Pr**(1. / 3) * Re**a1)
    else:
        f = 0.95 * (0.62 + 0.38 * np.cos(2.6 * psi)) * geom.phi**(
            1 + a2) * Re**(-a2)
        Nu = 0.072*geom.phi**0.33*avg.Pr**(1./3)*Re**0.67 \
            * np.exp(0.5*psi+0.17*psi**2)
    h = htc(Nu, avg.k, Dh)
    dpF = dpf(f, G, L, Dh, avg.rho)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# 2-phase boiling relations, plate exchangers
# -----------------------------------------------------------------


def yanLin_2phase_boiling(flowIn=None,
                          flowOut=None,
                          N=None,
                          geom=None,
                          L=None,
                          W=None,
                          **kwargs):
    """Two-phase evaporation, heat and friction, valid for GeomHxPlateCorrChevron. [Yan1999]_ Yan, Y.-Y. & Lin, T.-F. Evaporation Heat Transfer and Pressure Drop of Refrigerant R-134a in a Plate Heat Exchanger Journal of Heat Transfer Engineering, 1999, 121, 118-127. `doi:10.1115/1.2825924 <http://doi.org/10.1115/1.2825924>`_

Data collected for: R134a, 60deg, 2000<Re<8000.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) is gms.GeomHxPlateCorrChevron, _assertGeomErrMsg(
        geom, "yanLin_2phase_boiling")
    Dh = 2 * geom.b / geom.phi
    m_channel = flowIn.m / N
    G = m_channel / (geom.b * W)
    x_avg = 0.5 * (flowIn.x + flowOut.x)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    avg = flowIn.copy(CP.PQ_INPUTS, p_avg, x_avg)
    liq = flowIn.copy(CP.PQ_INPUTS, p_avg, 0)
    vap = flowIn.copy(CP.PQ_INPUTS, p_avg, 1)
    G_eq = G * (1 - x_avg + x_avg * (liq.rho / vap.rho)**0.5)
    Re = G * Dh / avg.visc
    Re_eq = G_eq * Dh / avg.visc
    q = m_channel * (flowOut.h - flowIn.h) / (W * L)
    Bo_eq = q / G_eq / (vap.h - liq.h)
    h = 1.926 * Re_eq / (liq.Pr**(-1. / 3) * Re**0.5 * Bo_eq
                         **-0.3 * Dh / liq.k)
    if Re_eq < 6000:
        f = 6.947e5 * Re_eq**-1.109 / Re**0.5
    else:
        f = 31.21 * Re_eq**0.04557 / Re**0.5
    dpF = dpf(f, G, L, Dh, avg.rho)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# 2-phase condensing relations, plate exchangers
# -----------------------------------------------------------------


def hanLeeKim_2phase_condensing(flowIn=None,
                                flowOut=None,
                                N=None,
                                geom=None,
                                L=None,
                                W=None,
                                **kwargs):
    r"""Two-phase condensation, heat and friction, valid for GeomHxPlateCorrChevron.Data collected for: R410A and R22, with beta = 45, 35, 20deg. [Han2003]_ Han, D.-H.; Lee, K.-J. & Kim, Y.-H. The Characteristics of Condensation in Brazed Plate Heat Exchangers with Different Chevron Angles Korean Physical Society, 2003, 43, 66-73.

Returns
--------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) is gms.GeomHxPlateCorrChevron, _assertGeomErrMsg(
        geom, "hanLeeKim_2phase_condensing")
    x_avg = 0.5 * (flowIn.x + flowOut.x)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    avg = flowIn.copy(CP.PQ_INPUTS, p_avg, x_avg)
    liq = flowIn.copy(CP.PQ_INPUTS, p_avg, 0)
    vap = flowIn.copy(CP.PQ_INPUTS, p_avg, 1)
    #
    beta = np.radians(geom.beta)
    Dh = 2 * geom.b / geom.phi
    m_channel = flowIn.m / N
    G = m_channel / (geom.b * W)
    X0 = (1 - x_avg + x_avg * (liq.rho / vap.rho)**0.5)
    G_eq = G * X0
    # Re = G * Dh / avg.visc
    Re_eq = G_eq * Dh / liq.visc
    #
    X1 = geom.pitchCorr / Dh
    X2 = np.pi / 2 - beta
    Ge1 = 11.22 * X1**-2.83 * X2**-4.5
    Ge2 = 0.35 * X1**0.23 * X2**1.48
    Ge3 = 3521.1 * X1**4.17 * X2**-7.75
    Ge4 = -1.024 * X1**0.0925 * X2**-1.3
    Nu = Ge1 * (Re_eq**Ge2) * (avg.Pr**(1. / 3))
    f = Ge3 * Re_eq**Ge4
    h = htc(Nu, avg.k, Dh)
    dpF = f * L * N * G_eq**2 / Dh / avg.rho
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# single-phase relations, plate-fin exchangers
# -----------------------------------------------------------------


def manglikBergles_offset_allphase(flowIn=None,
                                   flowOut=None,
                                   N=None,
                                   geom=None,
                                   L=None,
                                   W=None):
    """Single-phase and two-phase (evaporation and condensation), heat and friction, valid for GeomHxPlateFinOffset. [Manglik1995]_ Manglik and Bergles, Heat transfer and pressure drop correlations for the rectangular offset strip fin compact heat exchanger, Experimental Thermal and Fluid Science, Elsevier, 1995, 10, pp. 171-180. `doi:10.1016/0894-1777(94)00096-q <http://doi.org/10.1016/0894-1777(94)00096-q>`_.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    assert type(geom) is gms.GeomHxPlateFinOffset, _assertGeomErrMsg(
        geom, "manglikBergles_offset_allphase")
    alpha = geom.s / geom.h
    delta = geom.t / geom.l
    gamma = geom.t / geom.s
    Dh = 4 * geom.s * geom.h * geom.l / (2 * (
        geom.s * geom.l + geom.h * geom.l + geom.t * geom.h) + geom.t * geom.s)
    m_channel = flowIn.m / N
    m_fin = m_channel / (W / (geom.s + geom.t))
    G = m_fin / (geom.s * geom.h)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    h_avg = 0.5 * (flowIn.h + flowOut.h)
    avg = flowIn.copy(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc
    #
    f = 9.6243 * (Re**-0.7422) * (alpha**-0.1856) * (delta**0.3053) * (
        gamma**-0.2656) * (1 + 7.669e-8 * (Re**4.429) * (alpha**0.920) *
                           (delta**3.767) * (gamma**0.236))**0.1

    j = 0.6522 * (Re**-0.5403) * (alpha**-0.1541) * (delta**0.1499) * (
        gamma**-0.0678) * (1 + 5.269e-5 * (Re**1.340) * (alpha**0.504) *
                           (delta**0.456) * (gamma**-1.055))**0.1
    h = j * avg.cp * G / (avg.Pr**(2 / 3))
    # dpF = dpf(f, G, geom.l, Dh, avg.rho)
    dpF = dpf(f, G, L, Dh, avg.rho)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# single-phase relations, circular smooth ducts
# -----------------------------------------------------------------


def techo_1phase_f(flowIn, flowOut, Dh, Ac, L, N=1):
    """Single-phase, friction, valid for GeomDuctCircular, GeomHxPlateSmooth. [Techo1965]_ R. Techo, R. R. Tickner, and R. E. James, "An Accurate Equation for the Computation of the Friction Factor for Smooth Pipes from the Reynolds Number," J. Appl. Mech. (32): 443, 1965.

Returns
-------
dict of float : {"f", "dpF"}
    """
    m_channel = flowIn.m / N
    G = m_channel / Ac
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    h_avg = 0.5 * (flowIn.h + flowOut.h)
    avg = flowIn.copy(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc
    f = (0.86859 * np.log(Re / (1.964 * np.log(Re) - 3.8215)))**-2
    dpF = dpf(f, G, L, Dh, avg.rho)
    return {"f": f, "dpF": dpF}


def shah_1phase_h(flowIn=None,
                  flowOut=None,
                  N=None,
                  geom=None,
                  L=None,
                  W=None,
                  **kwargs):
    """Single-phase, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Kakaç1998]_ Kakaç, S. & Liu, H. Heat exchangers : selection, rating, and thermal design, CRC Press, 1998.

Returns
-------
dict of float : {"h"}
"""
    assert type(geom) in [gms.GeomHxPlateSmooth], _assertGeomErrMsg(
        geom, "shah_1phase_h")
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W

    if flowIn.h > flowOut.h:
        n = 0.3  # condensation mode
    else:
        n = 0.4  # evaporation mode
    m_channel = flowIn.m / N
    G = m_channel / Ac
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    h_avg = 0.5 * (flowIn.h + flowOut.h)
    avg = flowIn.copy(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc
    Nu = 0.023 * Re**0.8 * avg.Pr**n
    h = htc(Nu, avg.k, De)
    return {"h": h}


def gnielinski_1phase(flowIn, flowOut, Dh, De, Ac, L, N=1):
    """Single-phase, heat and friction, valid for GeomDuctCircular, GeomHxPlateSmooth. [Gnielinski1976]_ V. Gnielinski, "New Equations for Heat and Mass Transfer in Turbulent Pipe and Channel Flow," Int. Chem. Eng., (16): 359-368, 1976.

Returns
-------
dict of float : {"h", "f", "dpF"}
    """
    m_channel = flowIn.m / N
    G = m_channel / Ac
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    T_avg = 0.5 * (flowIn.T + flowOut.T)
    h_avg = 0.5 * (flowIn.h + flowOut.h)
    # avg = flowIn.copy(CP.PT_INPUTS, p_avg, T_avg)
    avg = flowIn.copy(CP.HmassP_INPUTS, h_avg, p_avg)
    Re = G * Dh / avg.visc  # /N, moved to G
    print("Re = ", Re)
    f = (1.58 * np.log(Re) - 3.28)**-2
    dpF = dpf(f, G, L, Dh, avg.rho)
    Pr = avg.Pr
    if Pr >= 0.5 and Pr <= 1.5 and Re >= 2300 and Re <= 5e6:
        Nu = 0.0214 * (Re**0.8 - 100) * Pr**0.4
    elif Pr >= 1.5 and Pr <= 500 and Re >= 3e3 and Re <= 1e6:
        Nu = 0.012 * (Re**0.87 - 280) * Pr**0.4
    else:
        Nu = f / 2 * (Re - 1000) * Pr / (1 + 12.7 * np.sqrt(f / 2) *
                                         (Pr**(2 / 3) - 1))
    h = htc(Nu, avg.k, De)
    return {"h": h, "f": f, "dpF": dpF}


# -----------------------------------------------------------------
# 2-phase boiling relations, circular smooth ducts
# -----------------------------------------------------------------


def shah_2phase_boiling(flowIn=None,
                        flowOut=None,
                        N=None,
                        geom=None,
                        L=None,
                        W=None,
                        vertical=False,
                        **kwargs):
    """Two-phase evporation, heat, valid for GeomDuctCircular, GeomHxPlateSmooth. [Shah1976]_ Shah, M. M. A new correlation for heat transfer during boiling flow through pipes Ashrae Trans., 1976, 82, 66-86.

Returns
-------
dict of float : {"h"}
    """
    assert type(geom) in [gms.GeomHxPlateSmooth], _assertGeomErrMsg(
        geom, "shah_2phase_boiling")
    if type(geom) in [gms.GeomHxPlateSmooth, gms.GeomHxPlateSmooth]:
        Dh = 2 * geom.b  # *W/(geom.b+W)
        De = Dh
        Ac = geom.b * W
    m_channel = flowIn.m / N
    G = m_channel / Ac
    x_avg = 0.5 * (flowIn.x + flowOut.x)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    liq = flowIn.copy(CP.PQ_INPUTS, p_avg, 0)
    vap = flowIn.copy(CP.PQ_INPUTS, p_avg, 1)
    Fr = G**2 / (liq.rho**2 * GRAVITY * Dh)
    if Fr > 0.04 or vertical is True:
        K_Fr = 1.
    else:
        K_Fr = (25 * Fr)**-0.3
    Co = (1 / x_avg - 1)**0.8 * (vap.rho / liq.rho)**0.5 * K_Fr
    q = flowIn.m * (flowOut.h - flowIn.h) / (np.pi * De * L)
    Bo = q / G / (vap.h - liq.h)
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
    # [f, dp] = techo_1phase_f(flowIn, flowOut, Dh, Ac, L)
    # h_l = gnielinski_1phase_h(flowIn, flowOut, Dh, De, Ac, L, f)
    h_l = shah_1phase_h(flowIn=liq, flowOut=liq, N=N, geom=geom, L=L, W=W)["h"]
    h = F * h_l
    return {"h": h}


def chen_2phase_boiling(flowIn,
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
    x = 0.5 * (flowIn.x + flowOut.x)
    h_avg = 0.5 * (flowIn.h + flowOut.h)
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    avg = flowIn.copy(CP.HmassP_INPUTS, h_avg, p_avg)
    liq = flowIn.copy(CP.PQ_INPUTS, avg.p, 0)
    vap = flowIn.copy(CP.PQ_INPUTS, avg.p, 1)
    X_tt = (1 / x - 1)**0.9 * (vap.rho / liq.rho)**0.5 * (liq.visc /
                                                          vap.visc)**0.1
    if (1 / X_tt) <= 0.1:
        F = 1
    else:
        F = 2.35 * (0.213 + 1 / X_tt)**0.736
    Re_tp = (1 - x) * G * Dh / liq.visc * F**1.25
    Re_l = G * Dh / liq.visc
    S = 1 / (1 + 2.53e-6 * Re_tp**1.17)
    h_l = 0.023 * Re_l**0.8 * liq.Pr**0.4 * liq.k / Dh
    h_cb = F * h_l
    q = flowIn.m * (flowOut.h - flowIn.h) / (np.pi * De * L)
    theta = q / h_cb
    dp_v = theta * (vap.h - liq.h) * vap.rho / liq.T
    h_nb = 0.00122 * liq.k**0.079 * liq.cp**0.45 * liq.rho**0.49 * theta**0.24 * dp_v**0.75 / avg.s / liq.visc**0.29 / vap.rho**0.24 / (
        vap.h - liq.h)**0.24
    h = h_cb * F + h_nb * S
    return {"h": h}


# -----------------------------------------------------------------
# 2-phase condensing relations, circular smooth ducts
# -----------------------------------------------------------------


def shah_2phase_condensing(flowIn,
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
    assert flowIn.x >= 0 and flowIn.x <= 1
    assert flowOut.x >= 0 and flowOut.x <= 1
    p_avg = 0.5 * (flowIn.p + flowOut.p)
    x = 0.5 * (flowIn.x + flowOut.x)
    liq = flowIn.copy(CP.PQ_INPUTS, p_avg, 0)
    h_l = shah_1phase_h(liq, liq, Dh, De, Ac, L, N)
    p_star = liq.p / liq.state.pcrit()
    h = h_l * ((1 - x)**0.8 + (3.8 * x**0.76 * (1 - x)**0.04) / (p_star**0.38))
    return {"h": h}
