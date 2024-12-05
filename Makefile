ASM = nasm

SRC_DIR = src
BUILD_DIR = build


.PHONY: all 

#
#	Floppy image
#
$(BUILD_DIR)/main_floppy.img: $(BUILD_DIR)/main.bin
	cp $(BUILD_DIR)/main.bin $(BUILD_DIR)/main_floppy.img
	truncate -s 1440k $(BUILD_DIR)/main_floppy.img

#
#	BootLoader
#


#
#	Kernel
#
$(BUILD_DIR)/main.bin: $(SRC_DIR)/main.asm | $(BUILD_DIR)
	$(ASM) $(SRC_DIR)/main.asm -f bin -o $(BUILD_DIR)/main.bin




# Add a clean target to remove build artifacts
clean:
	rm -rf $(BUILD_DIR)
