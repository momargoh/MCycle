cpdef public double TOLABS
cpdef public double TOLREL
cpdef public double TOLABS_X
cpdef public int MAXITER_CYCLE
cpdef public int MAXITER_COMPONENT
cpdef public int MAX_WALLS
#cpdef public double RUN_BRACKET_MIN_H
#cpdef public double RUN_BRACKET_MAX_H

#cpdef public double DP_PORT_IN_FACTOR
#cpdef public double DP_PORT_OUT_FACTOR
cpdef public double GRAVITY
cpdef public str COOLPROP_EOS
cpdef public str MPL_BACKEND
#cpdef public str PLOT_DIR
#cpdef public int PLOT_DPI
#cpdef public str PLOT_FORMAT
cpdef public str UNITS_SEPARATOR_NUMERATOR
cpdef public str UNITS_SEPARATOR_DENOMINATOR
cpdef public str PRINT_FORMAT_FLOAT
cpdef public list RST_HEADINGS
# cpdef public dict METHODS

cdef public dict dimensionUnits
cdef dict dimensionsEquiv
cdef str _formatUnits(str dimensions, str separator)
cpdef public str getUnits(str dimension)
cpdef void updateDefaults()

cdef public str _GITHUB_SOURCE_URL
cdef public str _HOSTED_DOCS_URL
