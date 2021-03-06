###########################################
# http://github.com/bluemir/cpp-makefile  #
#                                         #
# AUTHOR  : bluemir <iam@bluemir.me>      #
# LICENSE : MIT                           #
###########################################

SRC_DIR = src
TEST_DIR = test
OBJ_DIR = build
LIB_DIR = lib

TARGET = main
CPPFLAGS = -std=c++11

#LIB = -Llib/curl-7.32.0/lib -lcurl
#INCLUDE = -Ilib/curl-7.32.0/include

TESTFLAGS = -D__TEST__ -g
TESTLIB = -lgtest

ifeq ($(MAKECMDGOALS), test)
-include .gtest
endif

GTEST_VER = 1.7.0
GTEST_DOWNLOAD_URL=https://googletest.googlecode.com/files/gtest-$(GTEST_VER).zip

EXT = cpp

MAIN_SOURCES = $(notdir $(wildcard $(SRC_DIR)/*.$(EXT)))
TEST_SOURCES = $(notdir $(wildcard $(TEST_DIR)/*.$(EXT)))

MAIN_OBJECTS = $(MAIN_SOURCES:.$(EXT)=.o)
TEST_OBJECTS = $(TEST_SOURCES:.$(EXT)=.test)

MAIN_DEP = $(MAIN_SOURCES:.$(EXT)=.d)
TEST_DEP = $(TEST_SOURCES:.$(EXT)=.d)

.PHONY : all clean run test debug init clean-all

NODEPS := clean clean-all

all : $(TARGET)
$(TARGET) : $(addprefix $(OBJ_DIR)/release/, $(MAIN_OBJECTS))
	$(CXX) -o $(TARGET) $(LIB) \
		$(addprefix $(OBJ_DIR)/release/, $(MAIN_OBJECTS))

test : $(TARGET).test
	@./$(TARGET).test
$(TARGET).test : $(addprefix $(OBJ_DIR)/test/, $(MAIN_OBJECTS)) \
                 $(addprefix $(OBJ_DIR)/test/, $(TEST_OBJECTS))
	$(CXX) -o $(TARGET).test $(LIB) \
		$(TESTLIB) \
		$(addprefix $(OBJ_DIR)/test/, $(MAIN_OBJECTS)) \
		$(addprefix $(OBJ_DIR)/test/, $(TEST_OBJECTS))
.gtest :
	@read -p "Do you want install gtest library in $(LIB_DIR) for test? (y,n)" confirm ; \
	if [ $$confirm = "y" ] ; then \
		echo -e '$(subst $(newline),\n,$(TEST_VAR))' > .gtest; \
		mkdir -p lib ;\
		wget -O $(LIB_DIR)/gtest-$(GTEST_VER).zip $(GTEST_DOWNLOAD_URL) ; \
		unzip $(LIB_DIR)/gtest-$(GTEST_VER).zip -d lib ; \
		rm $(LIB_DIR)/gtest-$(GTEST_VER).zip ; \
		cd $(LIB_DIR)/gtest-$(GTEST_VER); ./configure; make ; \
		echo "gtest-$(GTEST_VER) is installed!" ; \
	else \
		echo "" > .gtest ; \
	fi

debug : $(addprefix $(OBJ_DIR)/debug/, $(MAIN_OBJECTS))
	$(CXX) -o $(TARGET) $(LIB) -g \
		$(addprefix $(OBJ_DIR)/debug/, $(MAIN_OBJECTS))

#Make dependency file
$(OBJ_DIR)/dep/main/%.d : $(SRC_DIR)/%.$(EXT)
	$(CXX) -MM \
		-MT $(OBJ_DIR)/release/$*.o \
		-MT $(OBJ_DIR)/debug/$*.o \
		-MT $(OBJ_DIR)/test/$*.o \
		-MF $@ \
		$<
$(OBJ_DIR)/dep/test/%.d : $(TEST_DIR)/%.$(EXT)
	$(CXX) -M \
		-I$(SRC_DIR) \
		-MT $(OBJ_DIR)/test/$*.test \
		-MF $@ \
		$<

#Make object file
##Release
$(OBJ_DIR)/release/%.o : $(SRC_DIR)/%.$(EXT)
	$(CXX) -c $(CPPFLAGS) $(INCLUDE) $< -o $@

##Test
$(OBJ_DIR)/test/%.o : $(SRC_DIR)/%.$(EXT)
	$(CXX) -c $(CPPFLAGS) $(INCLUDE) $(TESTFLAGS) $< -o $@
$(OBJ_DIR)/test/%.test : $(TEST_DIR)/%.$(EXT)
	$(CXX) -c $(CPPFLAGS) $(INCLUDE) -I$(SRC_DIR) $(TESTFLAGS) $< -o $@

##Dedug
$(OBJ_DIR)/debug/%.o : $(SRC_DIR)/%.$(EXT)
	$(CXX) -c $(CPPFLAGS) $(INCLUDE) -g $< -o $@

clean :
	rm -rf \
		$(OBJ_DIR)/release/* \
		$(OBJ_DIR)/test/* \
		$(OBJ_DIR)/debug/* \
		$(OBJ_DIR)/dep/main/* \
		$(OBJ_DIR)/dep/test/* \
		$(TARGET) \
		$(TARGET).test
clean-all : clean
	rm -rf \
		$(LIB_DIR)/gtest-$(GTEST_VER) \
		.gtest

run : $(TARGET)
	./$(TARGET)

init :
	@echo "make directory"
	$(call mkdirp,$(OBJ_DIR))
	$(call mkdirp,$(OBJ_DIR)/release)
	$(call mkdirp,$(OBJ_DIR)/test)
	$(call mkdirp,$(OBJ_DIR)/debug)
	$(call mkdirp,$(OBJ_DIR)/dep/main)
	$(call mkdirp,$(OBJ_DIR)/dep/test)
	$(call mkdirp,$(SRC_DIR))
	$(call mkdirp,$(TEST_DIR))
	$(call mkdirp,$(LIB_DIR))
	@echo "copy default c++ files"
	$(call printFile,$(srcExample),$(SRC_DIR)/main.$(EXT))
	$(call printFile,$(testExample),$(TEST_DIR)/test.$(EXT))

##include dependency
ifeq (0, $(words $(findstring $(MAKECMDGOALS), $(NODEPS))))

-include $(addprefix $(OBJ_DIR)/dep/main/, $(MAIN_DEP))

ifeq ($(MAKECMDGOALS), test)
-include $(addprefix $(OBJ_DIR)/dep/test/, $(TEST_DEP))
endif

endif

##example sources
define srcExample
#ifdef __TEST__
#include <gtest/gtest.h>
#endif

#include <iostream>

using namespace std;

int main(int argc, char ** argv) {
#ifdef __TEST__
	testing::InitGoogleTest(&argc, argv);
	return RUN_ALL_TESTS();
#endif
	// TODO write your code
}
endef

define testExample
#include <gtest/gtest.h>

TEST(TestSuite, TestCase) {
	ASSERT_TRUE(true);
}
endef

define newline


endef

define printFile
	@if [ -s $(2) ]; then \
		echo -en "\t";\
		read -p "$(strip $(2)) already exist! Will you overwrite? (y/N) " confirm; \
		if [ "$$confirm" = "y" -o "$$confirm" = "Y" ]; then \
			echo -e '$(subst $(newline),\n,$(1))' > $(2); \
		fi; \
	else \
		echo -en "\t"; \
		echo -E "$(strip $(2))"; \
		echo -e '$(subst $(newline),\n,$(1))' > $(2); \
	fi;
endef

define mkdirp
	@echo -en "\t"
	@echo -E "$(strip $(1))"
	@mkdir -p $(1)
endef

define TEST_VAR
TESTFLAGS += -I$(LIB_DIR)/gtest-$(GTEST_VER)/include
TESTLIB += -L$(LIB_DIR)/gtest-$(GTEST_VER)/lib
endef
