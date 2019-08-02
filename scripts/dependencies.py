##############################################################################
#  Copyright (c) 2019 by Paul Scherrer Institute, Switzerland
#  All rights reserved.
#  Authors: Oliver Bruendler
##############################################################################

from PsiFpgaLibDependencies import *
import sys
import os

THIS_DIR = os.path.dirname(os.path.abspath(__file__))

dependencies = Parse.FromReadme(THIS_DIR + "/../README.md")
repo = os.path.abspath(THIS_DIR + "/..")

Actions.ExecMain(repo, dependencies)