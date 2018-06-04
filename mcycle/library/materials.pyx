"""A brief library of common component materials."""
from ..bases.solidmaterial cimport SolidMaterial

#: Alumel (Ni, 2%-Al, 2%-Mn, 1%-Si), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial alumel(double T=293.15):
    return SolidMaterial(rho=8600.,
                         data={'T': [373.15, 473.15, 573.15, 673.15], 'k': [30, 32, 35, 38]},
                         deg=-1,
                         T=T,
                         name="alumel",
                         notes="alumel (Ni, 2%-Al, 2%-Mn, 1%-Si), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Aluminium (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial aluminium(double T=293.15):
    return SolidMaterial(rho=2707.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15], 'k': [302, 242, 236, 237, 240, 238, 234, 228, 215]},
                         deg=-1,
                         T=T,
                         name="aluminium",
                         notes="aluminium (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Aluminium alloy 6061-T6, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial aluminium_6061_T6(double T=293.15):
    return SolidMaterial(rho=2700.,
                         data={'T': [273.15, 293.15, 373.15, 473.15, 573.15], 'k': [166, 167, 172, 177, 180]},
                         deg=-1,
                         T=T,
                         name="aluminium_6061_T6",
                         notes="aluminium alloy 6061-T6, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Aluminium alloy 7075-T6, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial aluminium_7075_T6(double T=293.15):
    return SolidMaterial(rho=2800.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15], 'k': [76, 100, 121, 130, 137, 172, 177]},
                         deg=-1,
                         T=T,
                         name="aluminium_7075_T6",
                         notes="aluminium alloy 7075-T6, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Brass, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial brass(double T=293.15):
    return SolidMaterial(rho=8522.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15], 'k': [73, 89, 106, 109, 133, 143, 146, 147]},
                         deg=-1,
                         T=T,
                         name="brass",
                         notes="brass (Cu, 30%-Zn), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Chromel P (Ni, 10%-Cr), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial chromelP(double T=293.15):
    return SolidMaterial(rho=8730.,
                         data={'T': [373.15, 473.15, 573.15, 673.15], 'k': [19, 21, 23, 25]},
                         deg=-1,
                         T=T,
                         name="chromel P",
                         notes="Chromel P (Ni, 10%-Cr), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Chromium, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial chromium(double T=293.15):
    return SolidMaterial(rho=7190.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [158, 120, 95, 90, 88, 85, 82, 77, 69, 64, 62]},
                         deg=-1,
                         T=T,
                         name="chromium",
                         notes="chromium, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Constantan, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial constantan(double T=293.15):
    return SolidMaterial(rho=8922.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15], 'k': [17, 19, 22, 22, 26, 35]},
                         deg=-1,
                         T=T,
                         name="constantan",
                         notes="constantan (Cu, 40%-Ni), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Copper (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial copper(double T=293.15):
    return SolidMaterial(rho=8954.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [483, 420, 401, 398, 391, 389, 384, 378, 366, 352, 336]},
                         deg=-1,
                         T=T,
                         name="copper",
                         notes="copper (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Duralumin, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial duralumin(double T=293.15):
    return SolidMaterial(rho=2787.,
                         data={'T': [173.15, 273.15, 293.15, 373.15, 473.15], 'k': [126, 164, 164, 182, 194]},
                         deg=-1,
                         T=T,
                         name="duralumin",
                         notes="duralumin (4%-Cu, 0.5%-Mg), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Gold (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial gold(double T=293.15):
    return SolidMaterial(rho=19320.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [327, 324, 319, 318, 313, 306, 299, 293, 279, 264, 249]},
                         deg=-1,
                         T=T,
                         name="gold",
                         notes="gold (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Inconel X-750 (73%-Ni, 15%-Cr, 6.75%-Fe, 2.5%-Ti, 0.85%-Nb, 0.8%-Al, 0.7%-Mn, 0.3%-Si), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial inconelX750(double T=293.15):
    return SolidMaterial(rho=8510.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [8.8, 10.6, 11.3, 11.6, 13.0, 14.7, 16.0, 18.3, 21.8, 25.3, 29]},
                         deg=-1,
                         T=T,
                         name="inconelX750",
                         notes="Inconel X-750 (73%-Ni, 15%-Cr, 6.75%-Fe, 2.5%-Ti, 0.85%-Nb, 0.8%-Al, 0.7%-Mn, 0.3%-Si), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Iron (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial iron(double T=293.15):
    return SolidMaterial(rho=7987.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [132, 98, 84, 80, 72, 63, 56, 50, 39, 30, 29.5]},
                         deg=-1,
                         T=T,
                         name="iron",
                         notes="iron (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Lead (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial lead(double T=293.15):
    return SolidMaterial(rho=11373.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15], 'k': [40, 37, 36, 35, 34, 33, 32]},
                         deg=-1,
                         T=T,
                         name="lead",
                         notes="lead (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Magnesium (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial magnesium(double T=293.15):
    return SolidMaterial(rho=1746.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15], 'k': [169, 160, 157, 156, 154, 152, 150, 148, 145]},
                         deg=-1,
                         T=T,
                         name="magnesium",
                         notes="magnesium (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Molybdenum (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial molybdenum(double T=293.15):
    return SolidMaterial(rho=10220.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [175, 146, 139, 138, 135, 131, 127, 123, 116, 109, 103]},
                         deg=-1,
                         T=T,
                         name="molybdenum",
                         notes="molybdenum (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Nichrome (Ni, 23%-Fe, 16%-Cr), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial nichrome(double T=293.15):
    return SolidMaterial(rho=8250.,
                         data={'T': [373.15, 473.15, 573.15, 673.15], 'k': [13, 15, 16, 18]},
                         deg=-1,
                         T=T,
                         name="nichrome",
                         notes="nichrome (Ni, 23%-Fe, 16%-Cr), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Nichrome V (Ni, 20%-Cr, 1.4%-Si), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial nichromeV(double T=293.15):
    return SolidMaterial(rho=8410.,
                         data={'T': [293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [10, 11, 13, 15, 17, 20, 24]},
                         deg=-1,
                         T=T,
                         name="nichromeV",
                         notes="nichrome V (Ni, 20%-Cr, 1.4%-Si), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Nickel (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial nickel(double T=293.15):
    return SolidMaterial(rho=8906.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [156, 114, 94, 91, 83, 74, 6, 64, 69, 73, 78]},
                         deg=-1,
                         T=T,
                         name="nickel",
                         notes="nickel (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Steel AISI 1010, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial steel_1010(double T=293.15):
    return SolidMaterial(rho=7830.,
                         data={'T': [173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15], 'k': [70, 65, 64, 61, 55, 50, 45, 36, 29]},
                         deg=-1,
                         T=T,
                         name="steel_1010",
                         notes="steel AISI 1010, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
)

#: Steel 0.5%-carbon, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial steel_0o5C(double T=293.15):
    return SolidMaterial(rho=7833.,
                         data={'T': [273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [55, 52, 48, 45, 42, 35, 31, 29]},
                         deg=-1,
                         T=T,
                         name="steel_0o5C",
                         notes="steel 0.5%-carbon, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
)

#: Steel 1.0%-carbon, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial steel_1o0C(double T=293.15):
    return SolidMaterial(rho=7801.,
                         data={'T': [273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [43, 43, 42, 40, 36, 33, 29, 28]},
                         deg=-1,
                         T=T,
                         name="steel_1o0C",
                         notes="steel 1.0%-carbon, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Steel 1.5%-carbon, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial steel_1o5C(double T=293.15):
    return SolidMaterial(rho=7753.,
                         data={'T': [273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [36, 36, 36, 35, 33, 31, 28, 28]},
                         deg=-1,
                         T=T,
                         name="steel_1o5C",
                         notes="steel 1.5%-carbon, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Stainless steel AISI 304, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial stainlessSteel_304(double T=293.15):
    return SolidMaterial(rho=8000.,
                         data={'T': [293.15, 373.15, 473.15, 573.15, 673.15, 873.15], 'k': [13.8, 15, 17, 19, 21, 25]},
                         deg=-1,
                         T=T,
                         name="stainlessSteel_304",
                         notes="stainless steel AISI 304, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Stainless steel AISI 316, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial stainlessSteel_316(double T=293.15):
    return SolidMaterial(rho=8000.,
                         data={'T': [173.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [12, 13.5, 15, 16, 17, 19, 21, 24, 26]},
                         deg=-1,
                         T=T,
                         name="stainlessSteel_316",
                         notes="stainless steel AISI 316, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Stainless steel AISI 347, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial stainlessSteel_347(double T=293.15):
    return SolidMaterial(rho=8000.,
                         data={'T': [173.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [13, 15, 16, 18, 19, 20, 23, 26, 28]},
                         deg=-1,
                         T=T,
                         name="stainlessSteel_347",
                         notes="stainless steel AISI 347, from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Silicon (single crystal form), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial silicon(double T=293.15):
    return SolidMaterial(rho=2330.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [856, 342, 168, 153, 112, 82, 66, 54, 38, 29, 25]},
                         deg=-1,
                         T=T,
                         name="silicon",
                         notes="silicon (single crystal form), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )


#: Silver (99.99% pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial silver(double T=293.15):
    return SolidMaterial(rho=10524.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15], 'k': [449, 431, 428, 427, 422, 417, 409, 401, 386, 370]},
                         deg=-1,
                         T=T,
                         name="silver",
                         notes="silver (99.99% pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )


#: Titanium (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial titanium(double T=293.15):
    return SolidMaterial(rho=4540.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [31, 26, 22, 22, 21, 20, 20, 19, 21, 21, 22]},
                         deg=-1,
                         T=T,
                         name="titanium",
                         notes="titanium (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )


#: Titanium (6%-Al, 4%-V), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial titanium_6Al4V(double T=293.15):
    return SolidMaterial(rho=4430.,
                         data={'T': [293.15, 373.15, 473.15, 573.15, 673.15], 'k': [7.1, 7.8, 8.8, 10., 12.]},
                         deg=-1,
                         T=T,
                         name="titanium_6Al4V",
                         notes="titanium (6%-Al, 4%-V), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Tungsten (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial tungsten(double T=293.15):
    return SolidMaterial(rho=19350.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15, 873.15, 1073.15, 1273.15], 'k': [235, 223, 182, 178, 166, 153, 141, 134, 125, 122, 114]},
                         deg=-1,
                         T=T,
                         name="tungsten",
                         notes="tungsten (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )

#: Zinc (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
cpdef SolidMaterial zinc(double T=293.15):
    return SolidMaterial(rho=7144.,
                         data={'T': [103.15, 173.15, 273.15, 293.15, 373.15, 473.15, 573.15, 673.15], 'k': [124, 122, 122, 121, 117, 110, 106, 100]},
                         deg=-1,
                         T=T,
                         name="zinc",
                         notes="zinc (pure), from Table A.1; Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
    )
