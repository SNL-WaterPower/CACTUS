# This makefile is constructed for GNU make - 4/00.
# Meant for use with a project using modules (with module code in MODDIR)
SRCDIR = ./src
MODDIR = ./mod

# split f95, and module lists... Modules need to be compiled first
# split into F95 (files to be preprocessed), f95, and module lists... Modules need to be compiled first
SRCF95 = $(wildcard $(SRCDIR)/*.F95)
OBJF95 = $(SRCF95:%.F95=%.o)
SRCf95 = $(wildcard $(SRCDIR)/*.f95)
OBJf95 = $(SRCf95:%.f95=%.o)
SRCMODF95 = $(wildcard $(MODDIR)/*.F95)
OBJMODF95 = $(SRCMODF95:%.F95=%.o)
SRCMODf95 = $(wildcard $(MODDIR)/*.f95)
OBJMODf95 = $(SRCMODf95:%.f95=%.o)
INC = $(wildcard $(SRCDIR)/*.inc) 

# for debugging, debug flag and detailed runtime error checking. 
#FLAGS = -g -C -r8 -Mbounds
# standard compiler optimization
FLAGS = -fast -r8
# No compiler optimization
#FLAGS = -r8

# includes in SRCDIR, .mod files in MODDIR
OPT = -I$(SRCDIR) -I$(MODDIR) $(FLAGS)
LINKOPT = $(FLAGS)
# Include default liblapack.a and libblas.a for LAPACK calculations
LIBS = -llapack -lblas
COMPILER = pgf95


# Primary goal: create executable from object files if object files have changed. Depends on OBJMOD, OBJf, and OBJf95
# Note: Generally, fortran  modules must come first in the compile list... Also, if a module depends on another module in fortran,
# this module must be compiled first so that the subsequent module can see it's .mod file during compile. This appears to be due to the fact that
# the .mod file performs some external function prototyping for the module functions, and since the .mod is autogenerated when a module is compiled,
# these prototypes cant be explicitly included a-priori in the code that uses the module (ala .h files in C).
../cactus : $(OBJMODF95) $(OBJMODf95) $(OBJF95) $(OBJf95)  
	$(COMPILER) -o $@ $(LINKOPT) $(OBJMODF95) $(OBJMODf95) $(OBJF95) $(OBJf95)   $(LIBS)

# Secondary goals: rules for OBJ. If Makefile or include files are changed, update
$(OBJMODF95) $(OBJMODf95) $(OBJF95) $(OBJf95) : Makefile $(INC)

# Further secondary goals for OBJ: If individual source files are changed, update the corresponding OBJ
$(OBJMODF95):$(MODDIR)%.o : $(MODDIR)%.F95 
	$(COMPILER) $(OPT) -c $<
	mv $(@F) ${MODDIR}
	mv *.mod ${MODDIR}

$(OBJMODf95):$(MODDIR)%.o : $(MODDIR)%.f95 
	$(COMPILER) $(OPT) -c $<
	mv $(@F) ${MODDIR}
	mv *.mod ${MODDIR}

$(OBJF95):$(SRCDIR)%.o : $(SRCDIR)%.F95 
	$(COMPILER) $(OPT) -c $<
	mv $(@F) ${SRCDIR}

$(OBJf95):$(SRCDIR)%.o : $(SRCDIR)%.f95 
	$(COMPILER) $(OPT) -c $<
	mv $(@F) ${SRCDIR}

clean :
	rm -f $(SRCDIR)/*.o
	rm -f $(MODDIR)/*.o
	rm -f $(MODDIR)/*.mod
