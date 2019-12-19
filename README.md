# General Information

## Maintainer
Jonas Purtschert [jonas.purtschert@psi.ch]

## Author
Oliver Bründler [oli.bruendler@gmx.ch]

## License
This library is published under [PSI HDL Library License](License.txt), which is [LGPL](LGPL2_1.txt) plus some additional exceptions to clarify the LGPL terms in the context of firmware development.

## Detailed Documentation
For details, refer to the [Datasheet](doc/mem_test.pdf)

## Changelog
See [Changelog](Changelog.md)

<!-- DO NOT CHANGE FORMAT: this section is parsed to resolve dependencies -->

## Dependencies

The required folder structure looks as given below (folder names must be matched exactly). 

Alternatively the repository [psi\_fpga\_all](https://github.com/paulscherrerinstitute/psi_fpga_all) can be used. This repo contains all FPGA related repositories as submodules in the correct folder structure.

* TCL
  * [PsiSim](https://github.com/paulscherrerinstitute/PsiSim) (2.1.0 or higher, for development only)
  * [PsiIpPackage](https://github.com/paulscherrerinstitute/PsiIpPackage) (2.0.0, for development only)
* VHDL
  * [psi\_common](https://github.com/paulscherrerinstitute/psi_common) (2.5.0 or higher)
  * [psi\_tb](https://github.com/paulscherrerinstitute/psi_tb) (2.1.1 or higher, for development only)
* VivadoIp
  * [**vivadoIP\_mem\_test**](https://github.com/paulscherrerinstitute/vivadoIP_mem_test)
  
<!-- END OF PARSED SECTION -->
  
Dependencies can also be checked out using the python script *scripts/dependencies.py*. For details, refer to the help of the script:

```
python dependencies.py -help
```

Note that the [dependencies package](https://github.com/paulscherrerinstitute/PsiFpgaLibDependencies) must be installed in order to run the script.

# Description
This IP-core implements a memory tester for memories connected over AXI. It writes patterns, reads them back and checks whether there are no errors.

# Simulations and Testbenches

A regression test script for Modelsim is present. To run the regression test, execute the following command in modelsim from within the directory *sim*

```
source ./run.tcl
``` 
 
