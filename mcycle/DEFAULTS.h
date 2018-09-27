/* Generated by Cython 0.27.3 */

#ifndef __PYX_HAVE__mcycle__DEFAULTS
#define __PYX_HAVE__mcycle__DEFAULTS


#ifndef __PYX_HAVE_API__mcycle__DEFAULTS

#ifndef __PYX_EXTERN_C
  #ifdef __cplusplus
    #define __PYX_EXTERN_C extern "C"
  #else
    #define __PYX_EXTERN_C extern
  #endif
#endif

#ifndef DL_IMPORT
  #define DL_IMPORT(_T) _T
#endif

__PYX_EXTERN_C PyObject *__pyx_f_6mcycle_8DEFAULTS_getUnits(PyObject *, int __pyx_skip_dispatch);

__PYX_EXTERN_C double TOLABS;
__PYX_EXTERN_C double TOLREL;
__PYX_EXTERN_C double TOLABS_X;
__PYX_EXTERN_C int MAXITER_CYCLE;
__PYX_EXTERN_C int MAXITER_COMPONENT;
__PYX_EXTERN_C int MAX_WALLS;
__PYX_EXTERN_C double GRAVITY;
__PYX_EXTERN_C PyObject *COOLPROP_EOS;
__PYX_EXTERN_C PyObject *MPL_BACKEND;
__PYX_EXTERN_C PyObject *dimensionUnits;
__PYX_EXTERN_C PyObject *_GITHUB_SOURCE_URL;
__PYX_EXTERN_C PyObject *_HOSTED_DOCS_URL;

#endif /* !__PYX_HAVE_API__mcycle__DEFAULTS */

/* WARNING: the interface of the module init function changed in CPython 3.5. */
/* It now returns a PyModuleDef instance instead of a PyModule instance. */

#if PY_MAJOR_VERSION < 3
PyMODINIT_FUNC initDEFAULTS(void);
#else
PyMODINIT_FUNC PyInit_DEFAULTS(void);
#endif

#endif /* !__PYX_HAVE__mcycle__DEFAULTS */
