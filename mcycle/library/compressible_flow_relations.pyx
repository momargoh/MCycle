"""A brief collection of ideal, compressible flow relations."""
from warnings import warn

cpdef double speedOfSound(double gamma, double p=0, double rho=0, double R=0, double T=0):
    """float: speed of sound from gamma and either static pressure & mass density or; gas constant & static temperature.

Parameters
-----------
gamma : double
    Ratio of specific heats.
p : double
    Static pressure [Pa]. Defaults to 0.
rho : double
    Mass density [kg/m^3]. Defaults to 0.
R : double
    Gas constant [J/kg/K]. Defaults to 0.
T : double
    Static temperature [K]. Defaults to 0.
    """
    assert p != 0 or R != 0, "p (given: {}) or R (given: {}) must be provided".format(p, R)
    if p != 0:
       assert rho != 0, "rho (given: {}) must be provided".format(rho)
       return (gamma*p/rho)**0.5
    else:
       assert T != 0, "T (given: {}) must be provided".format(T)
       return (gamma*R*T)**0.5
        
    
cpdef double pTotalRatio(double gamma, double TTotalRatio=0, double M=0):
    """float: ratio of static pressure to total pressure (also called absolute or stagnation pressure) calculated from gamma and either static to total temperature ratio or Mach number.

Parameters
-----------
gamma : double
    Ratio of specific heats.
TTotalRatio : double, optional
    Ratio of static temperature to total temperature. Defaults to O.
M : double, optional
    Mach number. Defaults to 0.
    """
    assert M != 0 or TTotalRatio != 0, "TTotalRatio (given: {}) or M (given: {}) must be provided".format(TTotalRatio, M)
    if TTotalRatio != 0 and M == 0:
        return TTotalRatio**(gamma / (gamma - 1))
    elif M != 0 and TTotalRatio == 0:
        return (1 + 0.5 * (gamma - 1) * M**2)**(-gamma / (gamma - 1))
    else:
        warn(
            "TTotalRatio and M provided, pTotalRatio calculated from TTotalRatio"
        )
        return TTotalRatio**(gamma / (gamma - 1))


cpdef double TTotalRatio(double gamma, double pTotalRatio=0, double M=0):
    """float: ratio of static temperature to total temperature (also called absolute or stagnation temperature) calculated from gamma and either static to total pressure ratio or Mach number.

Parameters
-----------
gamma : double
    Ratio of specific heats.
pTotalRatio : double, optional
    Ratio of static pressure to total pressure. Defaults to O.
M : double, optional
    Mach number. Defaults to 0.
    """
    assert M != 0 or pTotalRatio != 0, "pTotalRatio (given: {}) or M (given: {}) must be provided".format(pTotalRatio, M)
    if pTotalRatio != 0 and M == 0:
        return pTotalRatio**((gamma - 1) / gamma)
    elif M != 0 and pTotalRatio == 0:
        return (1 + 0.5 * (gamma - 1) * M**2)**-1
    else:
        warn(
            "pTotalRatio and M provided, TTotalRatio calculated from pTotalRatio"
        )
        return pTotalRatio**((gamma - 1) / gamma)

cpdef double chokedAreaRatio(double gamma, double M):
    """float: ratio of flow area to choked area.

Parameters
-----------
gamma : double
    Ratio of specific heats.
M : double
    Mach number. Defaults to 0.
    """
    return ((gamma+1)/2.)**(-(gamma+1)/(2*gamma-2.))*(1+(gamma-1)/2.*M**2)**((gamma+1)/(2*gamma-2.))/M
