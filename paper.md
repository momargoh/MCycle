---
title: 'MCycle: A Python package for 1D sizing and analysis of thermodynamic power cycles'
tags:
- thermodynamics
- power cycle
- component sizing
authors:
- name: Momar G-O Hughes
  orcid: 0000-0002-6928-2187
  affiliation: 1
affiliations:
- name: University of New South Wales, Sydney, Australia
  index: 1
date: 30 March 2018
bibliography: paper.bib
---

# Introduction

MCycle allows users to analyse thermodynamic power cycles and their individual components, as well as size cycle components to defined cycle design parameters. It was developed due to a need for an open source tool with easy scripting for sizing heat exchangers that would allow control over individual component parameters. Users may now analyse a growing collection of thermodynamic power cycles and cycle components, including heat exchangers, expanders, compressors, heaters and coolers. Each type of component has models of varying complexity, allowing MCycle to be equally applicable to simplistic cycle analyses as to detailed sizing optimisations. The project page is found at [https://github.com/momargoh/MCycle](https://github.com/momargoh/MCycle) and the documentation is hosted at [https://mcycle.readthedocs.io](https://mcycle.readthedocs.io).

# Summary

To evaluate a cycle's fluid properties, MCycle uses the Python wrapper of the open-source thermodynamic properties library [CoolProp](http://www.coolprop.org) [@bell2014coolprop]. A library of heat transfer and component analysis methods is provided , containing theoretical relations and semi-empirical correlations sourced from published research articles (refer to the [documentation](https://mcycle.readthedocs.io) for specific references). These methods are simply functions that take key-word arguments and return a dictionary of computed variables. Thus, users also have the freedom of creating and using custom correlations that adhere to these conventions. 
As previously mentioned, component models vary in complexity; for example, a plate heat exchanger could be modelled with a `HxBasicPlanar` or a `HxPlate` object. A `HxBasicPlanar` object requires the heat transfer coefficient of the working and secondary fluid flows to be defined by the user, whereas a `HxPlate` object requires the user to define a plate geometry and subsequently uses a user-selected heat transfer method to evaluate the heat transfer coefficient of each fluid flow. 
MCycle components have two primary analysis functions: `size` and `run`. `size` calculates the required value of a desired attribute for each component in order to satisfy the selected analysis method using defined incoming and outgoing flow-states. `run` calculates the outgoing working fluid flow-state of a fully defined component. Hence, `size` is used for sizing a component or cycle to design conditions whereas `run` is moreso used for analysing components and cycles at off-design conditions. Cycles are initiated by selecting the components (either user-created designs or from the included library based on commercial component designs) and optionally defining the cycle design parameters. MCycle also provides functions for producing customisable cycle plots and outputting formatted text summaries of components or cycles.

# Acknowledgements
Development of this package was supported by an Australian Government Research Training Program (RTP) Scholarship.

# References
