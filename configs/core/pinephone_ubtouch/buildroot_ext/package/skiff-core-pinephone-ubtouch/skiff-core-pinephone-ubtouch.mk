################################################################################
#
# skiff-core-pinephone-ubtouch
#
################################################################################

SKIFF_CORE_PINEPHONE_UBTOUCH_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_PINEPHONE_UBTOUCH_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-pinephone-ubtouch
	cp -r $(SKIFF_CORE_PINEPHONE_UBTOUCH_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-pinephone-ubtouch/
	$(INSTALL) -m 0644 $(SKIFF_CORE_PINEPHONE_UBTOUCH_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_PINEPHONE_UBTOUCH_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_PINEPHONE_UBTOUCH_INSTALL_COREENV

$(eval $(generic-package))
