"""A brief library of common component materials."""
from ..bases import SolidMaterial

#: Titanium @ 300degC, from Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
titanium = SolidMaterial(
    rho=4430.,
    k=10.,
    name="titanium",
    notes="titanium@ 300degC, from Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
)

#: Stainless steel 316 @ 300degC, ffrom Lienhard, J. H. I. & Lienhard, J. H. V., *A Heat Transfer Textbook*, Phlogiston Press, 2011.
stainlessSteel_316 = SolidMaterial(
    rho=8000.,
    k=17.,
    name="stainlessSteel_316",
    notes="stainless-steel-316@ 300degC, from Lienhard, J. H. I. & Lienhard, J. H. V. A Heat Transfer Textbook Phlogiston Press, 2011"
)
