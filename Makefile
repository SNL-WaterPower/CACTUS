# This makefile is constructed for GNU make - 4/00.
# Meant for use with a project using modules (with module code in MODDIR)
SRCDIR = ./src
INCDIR = ./src
OBJDIR = ../obj
MODDIR = ./mod
MODINCDIR = ../modinc

# split f95, and module lists... Modules need to be compiled first
SRC = $(wildcard $(SRCDIR)/*.f95)
OBJ = $(SRC:$(SRCDIR)%.f95=$(OBJDIR)%.o)
SRCMOD = $(wildcard $(MODDIR)/*.f95)
OBJMOD = $(SRCMOD:$(MODDIR)%.f95=$(OBJDIR)%.o)
INC = $(wildcard $(SRCDIR)/*.inc) 

#FLAGS = -g -C -r8 # for debugging, debug flag and detailed runtime error checking. 
#FLAGS = -fast -r8 # standard compiler optimization
# Not using compiler optimization for now, because it appears to do something weird with the logic in the dynamic stall model...
FLAGS = -r8

OPT = -I$(INCDIR) -I$(MODINCDIR) $(FLAGS) # includes in INCDIR, .mod files in MODDIR
LINKOPT = $(FLAGS) 
# Include default liblapack.a and libblas.a for LAPACK calculations
LIBS = -llapack -lblas
COMPILER = pgf95

# Primary goal: create executable from object files if object files have changed. Depends on OBJMOD, OBJf, and OBJf95
# Note: Generally, fortran  modules must come first in the compile list... Also, if a module depends on another module in fortran,
# this module must be compiled first so that the subsequent module can see it's .mod file during compile. This appears to be due to the fact that
# the .mod file performs some external function prototyping for the module functions, and since the .mod is autogenerated when a module is compiled,
# these prototypes cant be explicitly included a-priori in the code that uses the module (ala .h files in C).
../cactus : $(OBJMOD) $(OBJ) 
	$(COMPILER) -o $@ $(LINKOPT) $(OBJMOD) $(OBJ)  $(LIBS)

# Secondary goals: rules for OBJ. If Makefile or include files are changed, update
$(OBJMOD) $(OBJ) : Makefile $(INC)

# Further secondary goals for OBJ: If individual source files are changed, update the corresponding OBJ
$(OBJMOD):$(OBJDIR)%.o : $(MODDIR)%.f95 
	$(COMPILER) $(OPT) -c $<
	mv $(@F) ${OBJDIR}
	mv *.mod ${MODINCDIR}

$(OBJ):$(OBJDIR)%.o : $(SRCDIR)%.f95 
	$(COMPILER) $(OPT) -c $<
	mv $(@F) ${OBJDIR}


clean :
	rm -f $(OBJDIR)/*.o
	rm -f $(MODINCDIR)/*.mod
