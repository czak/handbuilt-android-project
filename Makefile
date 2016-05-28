# Environment variables
ANDROID_HOME ?=

# Build tools & SDK versions
build_tools := 24.0.0-preview
target      := android-n

# Variables
project     := handbuilt
package     := pl.czak.handbuilt

src_dir     := src
res_dir     := res

lib_dir     := build/libraries
gen_dir     := build/generated
int_dir     := build/intermediate
out_dir     := build/output

sources     := $(shell find $(src_dir) -name '*.java')
resources   := $(shell find $(res_dir) -type f)
generated   := $(gen_dir)/pl/czak/handbuilt/R.java
libraries   := $(lib_dir)/com/squareup/picasso/picasso/2.5.2/picasso-2.5.2.jar

# Final zipaligned APK
$(out_dir)/$(project).apk: $(out_dir)/$(project)-unaligned.apk
	@echo -n Zipaligning...
	@zipalign -f 4 $< $@
	@echo Done.

# Packaging the APK
$(out_dir)/$(project)-unaligned.apk: $(out_dir) AndroidManifest.xml $(resources) $(int_dir)/classes.dex
	@echo -n Packaging...
	@aapt package -f \
		-M AndroidManifest.xml \
		-I $(ANDROID_HOME)/platforms/$(target)/android.jar \
		-S $(res_dir) \
		-F $@
	@cd $(int_dir) && aapt add $(abspath $@) classes.dex > /dev/null
	@echo Done.
	@echo -n Signing the APK...
	@jarsigner -verbose \
		-keystore ~/.android/debug.keystore \
		-storepass android \
		-keypass android \
		$@ \
		androiddebugkey \
		> /dev/null
	@echo Done.

# Compilation & dexing w/ Jack
$(int_dir)/classes.dex: $(int_dir) $(sources) $(generated) $(libraries)
	@echo -n Compiling with Jack...
	@java -jar $(ANDROID_HOME)/build-tools/$(build_tools)/jack.jar \
		--classpath $(ANDROID_HOME)/platforms/$(target)/android.jar \
		$(foreach lib,$(libraries),--import $(lib)) \
		--output-dex $(int_dir) \
		$(sources) $(generated)
	@echo Done.

# Generating R.java based on the manifest and resources
$(generated): $(gen_dir) AndroidManifest.xml $(resources)
	@echo -n Generating R.java... 
	@aapt package -f \
		-M AndroidManifest.xml \
		-I $(ANDROID_HOME)/platforms/$(target)/android.jar \
		-S $(res_dir) \
		-J $(gen_dir) \
		-m
	@echo Done.

# Fetching dependencies from Maven Central
$(libraries):
	@echo -n Fetching dependency $(notdir $@)... 
	@curl --silent \
		    --location \
        --output $@ \
        --create-dirs \
        http://search.maven.org/remotecontent?filepath=$(subst $(lib_dir)/,,$@)
	@echo Done.

# Subfolders in build/
$(gen_dir) $(out_dir) $(int_dir):
	@mkdir -p $@

.PHONY: clean
clean:
	rm -rf build

.PHONY: install
install: $(out_dir)/$(project).apk
	adb install -r $<

.PHONY: uninstall
uninstall:
	adb uninstall $(package)

.PHONY: run
run:
	adb shell am start $(package)/.MainActivity
