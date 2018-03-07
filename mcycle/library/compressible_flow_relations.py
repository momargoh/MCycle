"""A brief collection of ideal, compressible flow relations."""
from warnings import warn


def pTotalRatio(gamma=None, TTotalRatio=None, M=None):
    """float: ratio of static pressure to total pressure (also called absolute or stagnation pressure)."""
    if TTotalRatio is not None and M is None:
        return TTotalRatio**(gamma / (gamma - 1))
    elif M is not None and TTotalRatio is None:
        return (1 + 0.5 * (gamma - 1) * M**2)**(-gamma / (gamma - 1))
    else:
        warn(
            "TTotalRatio and M provided, pTotalRatio calculated from TTotalRatio"
        )
        return TTotalRatio**(gamma / (gamma - 1))


def TTotalRatio(gamma=None, pTotalRatio=None, M=None):
    """float: ratio of static temperature to total temperature (also called absolute or stagnation temperature)."""
    if pTotalRatio is not None and M is None:
        return pTotalRatio**((gamma - 1) / gamma)
    elif M is not None and pTotalRatio is None:
        return (1 + 0.5 * (gamma - 1) * M**2)**-1
    else:
        warn(
            "pTotalRatio and M provided, TTotalRatio calculated from pTotalRatio"
        )
        return pTotalRatio**((gamma - 1) / gamma)
