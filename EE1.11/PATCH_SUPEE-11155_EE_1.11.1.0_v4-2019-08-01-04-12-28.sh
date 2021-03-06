#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-11155_EE_11110 | CE_1.6.1.0 | v1 | 1c354e9f8026b57c33a2ef27a0c6607f1354599e | Mon Jul 29 22:10:22 2019 +0000 | b32433877275131fd2fe07b65b4d1fada91e47fc..HEAD

__PATCHFILE_FOLLOWS__
diff --git app/Mage.php app/Mage.php
index 7a587879d10..c9aaefb8eee 100644
--- app/Mage.php
+++ app/Mage.php
@@ -735,9 +735,9 @@ final class Mage
             ',',
             (string) self::getConfig()->getNode('dev/log/allowedFileExtensions', Mage_Core_Model_Store::DEFAULT_CODE)
         );
-        $logValidator = new Zend_Validate_File_Extension($_allowedFileExtensions);
         $logDir = self::getBaseDir('var') . DS . 'log';
-        if (!$logValidator->isValid($logDir . DS . $file)) {
+        $validatedFileExtension = pathinfo($file, PATHINFO_EXTENSION);
+        if (!$validatedFileExtension || !in_array($validatedFileExtension, $_allowedFileExtensions)) {
             return;
         }
 
diff --git app/code/core/Enterprise/Cms/Model/Page/Version.php app/code/core/Enterprise/Cms/Model/Page/Version.php
index 78eb9f8e2f7..b4158f92875 100644
--- app/code/core/Enterprise/Cms/Model/Page/Version.php
+++ app/code/core/Enterprise/Cms/Model/Page/Version.php
@@ -166,18 +166,21 @@ class Enterprise_Cms_Model_Page_Version extends Mage_Core_Model_Abstract
     {
         $resource = $this->_getResource();
         /* @var $resource Enterprise_Cms_Model_Mysql4_Page_Version */
+        $label = Mage::helper('core')->escapeHtml($this->getLabel());
         if ($this->isPublic()) {
             if ($resource->isVersionLastPublic($this)) {
-                Mage::throwException(
-                    Mage::helper('enterprise_cms')->__('Version "%s" could not be removed because it is the last public version for its page.', $this->getLabel())
-                );
+                Mage::throwException(Mage::helper('enterprise_cms')->__(
+                    'Version "%s" could not be removed because it is the last public version for its page.',
+                    $label
+                ));
             }
         }
 
         if ($resource->isVersionHasPublishedRevision($this)) {
-            Mage::throwException(
-                Mage::helper('enterprise_cms')->__('Version "%s" could not be removed because its revision has been published.', $this->getLabel())
-            );
+            Mage::throwException(Mage::helper('enterprise_cms')->__(
+                'Version "%s" could not be removed because its revision has been published.',
+                $label
+            ));
         }
 
         return parent::_beforeDelete();
diff --git app/code/core/Enterprise/GiftCardAccount/Model/Pool.php app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
index 364d4e87a18..fe050817a51 100644
--- app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
+++ app/code/core/Enterprise/GiftCardAccount/Model/Pool.php
@@ -121,8 +121,9 @@ class Enterprise_GiftCardAccount_Model_Pool extends Enterprise_GiftCardAccount_M
         $charset = str_split((string) Mage::app()->getConfig()->getNode(sprintf(self::XML_CHARSET_NODE, $format)));
 
         $code = '';
+        $charsetSize = count($charset);
         for ($i=0; $i<$length; $i++) {
-            $char = $charset[array_rand($charset)];
+            $char = $charset[random_int(0, $charsetSize - 1)];
             if ($split > 0 && ($i%$split) == 0 && $i != 0) {
                 $char = "{$splitChar}{$char}";
             }
diff --git app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
index 4f59c5b3cee..f60fc34f10d 100644
--- app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
+++ app/code/core/Enterprise/GiftRegistry/controllers/IndexController.php
@@ -542,7 +542,7 @@ class Enterprise_GiftRegistry_IndexController extends Mage_Core_Controller_Front
                             $idField = $person->getIdFieldName();
                             if (!empty($registrant[$idField])) {
                                 $person->load($registrant[$idField]);
-                                if (!$person->getId()) {
+                                if (!$person->getId() || $person->getEntityId() != $model->getEntityId()) {
                                     Mage::throwException(Mage::helper('enterprise_giftregistry')->__('Incorrect recipient data.'));
                                 }
                             } else {
diff --git app/code/core/Enterprise/Logging/Model/Config.php app/code/core/Enterprise/Logging/Model/Config.php
index 960367f052f..9eae7cb0edd 100644
--- app/code/core/Enterprise/Logging/Model/Config.php
+++ app/code/core/Enterprise/Logging/Model/Config.php
@@ -83,7 +83,13 @@ class Enterprise_Logging_Model_Config
                 }
             }
             else {
-                $this->_systemConfigValues = unserialize($this->_systemConfigValues);
+                try {
+                    $this->_systemConfigValues = Mage::helper('core/unserializeArray')
+                        ->unserialize($this->_systemConfigValues);
+                } catch (Exception $e) {
+                    $this->_systemConfigValues = array();
+                    Mage::logException($e);
+                }
             }
         }
         return $this->_systemConfigValues;
diff --git app/code/core/Enterprise/Pbridge/etc/system.xml app/code/core/Enterprise/Pbridge/etc/system.xml
index 6e2e101986b..ebf63296e57 100644
--- app/code/core/Enterprise/Pbridge/etc/system.xml
+++ app/code/core/Enterprise/Pbridge/etc/system.xml
@@ -66,6 +66,7 @@
                             <label>Gateway Basic URL</label>
                             <frontend_type>text</frontend_type>
                             <sort_order>40</sort_order>
+                            <backend_model>adminhtml/system_config_backend_gatewayurl</backend_model>
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
diff --git app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
index 0a53464cf5f..dede2f144ed 100644
--- app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
+++ app/code/core/Enterprise/Reminder/controllers/Adminhtml/ReminderController.php
@@ -173,6 +173,9 @@ class Enterprise_Reminder_Adminhtml_ReminderController extends Mage_Adminhtml_Co
                 if (!isset($data['website_ids'])) {
                     $data['website_ids'] = array(Mage::app()->getStore(true)->getWebsiteId());
                 }
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
 
                 $data = $this->_filterDates($data, array('active_from', 'active_to'));
                 $model->loadPost($data);
diff --git app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php
index c84d0aee1a1..e77a77e354b 100644
--- app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php
+++ app/code/core/Enterprise/Rma/Block/Adminhtml/Rma/Create/Order/Grid.php
@@ -67,10 +67,11 @@ class Enterprise_Rma_Block_Adminhtml_Rma_Create_Order_Grid extends Mage_Adminhtm
     protected function _prepareColumns()
     {
         $this->addColumn('real_order_id', array(
-            'header'=> Mage::helper('sales')->__('Order #'),
-            'width' => '80px',
-            'type'  => 'text',
-            'index' => 'increment_id',
+            'header' => Mage::helper('sales')->__('Order #'),
+            'width'  => '80px',
+            'type'   => 'text',
+            'index'  => 'increment_id',
+            'escape' => true,
         ));
 
         if (!Mage::app()->isSingleStoreMode()) {
diff --git app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php
old mode 100755
new mode 100644
index 51e8608c46a..1cb01ba3c00
--- app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php
+++ app/code/core/Enterprise/Staging/Model/Resource/Staging/Action.php
@@ -76,12 +76,34 @@ class Enterprise_Staging_Model_Resource_Staging_Action extends Mage_Core_Model_R
 
     /**
      * Action after delete
-     * Need to delete all backup tables also
      *
      * @param Mage_Core_Model_Abstract $object
-     * @return Enterprise_Staging_Model_Resource_Staging_Action
+     * @return Mage_Core_Model_Resource_Db_Abstract
      */
     protected function _afterDelete(Mage_Core_Model_Abstract $object)
+    {
+        return parent::_afterDelete($object);
+    }
+
+    /**
+     * Action get backup tables
+     *
+     * @param $stagingTablePrefix
+     * @return Enterprise_Staging_Model_Resource_Helper_Mysql4
+     */
+    public function getBackupTables($stagingTablePrefix)
+    {
+        return Mage::getResourceHelper('enterprise_staging')->getTableNamesByPrefix($stagingTablePrefix);
+    }
+
+    /**
+     * Action delete staging backup
+     * Need to delete all backup tables without transaction
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @return Enterprise_Staging_Model_Resource_Staging_Action
+     */
+    public function deleteStagingBackup(Mage_Core_Model_Abstract $object)
     {
         if ($object->getIsDeleteTables() === true) {
             $stagingTablePrefix = $object->getStagingTablePrefix();
@@ -96,15 +118,4 @@ class Enterprise_Staging_Model_Resource_Staging_Action extends Mage_Core_Model_R
         }
         return $this;
     }
-
-    /**
-     * Enter description here ...
-     *
-     * @param unknown_type $stagingTablePrefix
-     * @return unknown
-     */
-    public function getBackupTables($stagingTablePrefix)
-    {
-        return Mage::getResourceHelper('enterprise_staging')->getTableNamesByPrefix($stagingTablePrefix);
-    }
 }
diff --git app/code/core/Enterprise/Staging/Model/Staging/Action.php app/code/core/Enterprise/Staging/Model/Staging/Action.php
index 5da4cde8bf9..3fb6c6238cb 100644
--- app/code/core/Enterprise/Staging/Model/Staging/Action.php
+++ app/code/core/Enterprise/Staging/Model/Staging/Action.php
@@ -255,4 +255,16 @@ class Enterprise_Staging_Model_Staging_Action extends Mage_Core_Model_Abstract
         }
         return $this;
     }
+
+    /**
+     * Action delete
+     * Need to delete all backup tables also without transaction
+     *
+     * @return Enterprise_Staging_Model_Resource_Staging_Action
+     */
+    public function delete()
+    {
+        parent::delete();
+        return Mage::getResourceModel('enterprise_staging/staging_action')->deleteStagingBackup($this);
+    }
 }
diff --git app/code/core/Mage/Admin/Model/Block.php app/code/core/Mage/Admin/Model/Block.php
index a672f4ef350..61c6134964d 100644
--- app/code/core/Mage/Admin/Model/Block.php
+++ app/code/core/Mage/Admin/Model/Block.php
@@ -57,7 +57,7 @@ class Mage_Admin_Model_Block extends Mage_Core_Model_Abstract
         if (in_array($this->getBlockName(), $disallowedBlockNames)) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is disallowed.');
         }
-        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9\/]*$/'))) {
+        if (!Zend_Validate::is($this->getBlockName(), 'Regex', array('/^[-_a-zA-Z0-9]+\/[-_a-zA-Z0-9\/]+$/'))) {
             $errors[] = Mage::helper('adminhtml')->__('Block Name is incorrect.');
         }
 
diff --git app/code/core/Mage/Admin/Model/User.php app/code/core/Mage/Admin/Model/User.php
index f6b1acecc8d..4c96bb31a76 100644
--- app/code/core/Mage/Admin/Model/User.php
+++ app/code/core/Mage/Admin/Model/User.php
@@ -562,7 +562,7 @@ class Mage_Admin_Model_User extends Mage_Core_Model_Abstract
         }
 
         if ($this->userExists()) {
-            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email aleady exists.');
+            $errors[] = Mage::helper('adminhtml')->__('A user with the same user name or email already exists.');
         }
 
         if (count($errors) === 0) {
diff --git app/code/core/Mage/AdminNotification/etc/system.xml app/code/core/Mage/AdminNotification/etc/system.xml
index a3523fbe024..02ee7da3fc2 100644
--- app/code/core/Mage/AdminNotification/etc/system.xml
+++ app/code/core/Mage/AdminNotification/etc/system.xml
@@ -64,6 +64,15 @@
                             <show_in_website>0</show_in_website>
                             <show_in_store>0</show_in_store>
                         </last_update>
+                        <feed_url>
+                            <label>Feed Url</label>
+                            <frontend_type>text</frontend_type>
+                            <backend_model>adminhtml/system_config_backend_protected</backend_model>
+                            <sort_order>3</sort_order>
+                            <show_in_default>0</show_in_default>
+                            <show_in_website>0</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </feed_url>
                     </fields>
                 </adminnotification>
             </groups>
diff --git app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
index fcff46b525f..0aa48545289 100644
--- app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Api/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Api_Role_Grid_User extends Mage_Adminhtml_Block_Widge
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('api/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
index b97a9da96e4..468f8e77c85 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Edit/Tab/Super/Config.php
@@ -134,6 +134,8 @@ class Mage_Adminhtml_Block_Catalog_Product_Edit_Tab_Super_Config extends Mage_Ad
             // Hide price if needed
             foreach ($attributes as &$attribute) {
                 $attribute['label'] = $this->escapeHtml($attribute['label']);
+                $attribute['frontend_label'] = $this->escapeHtml($attribute['frontend_label']);
+                $attribute['store_label'] = $this->escapeHtml($attribute['store_label']);
                 if (isset($attribute['values']) && is_array($attribute['values'])) {
                     foreach ($attribute['values'] as &$attributeValue) {
                         if (!$this->getCanReadPrice()) {
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
index 4988d13b90c..416e1ba96f8 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Queue/Preview.php
@@ -56,6 +56,12 @@ class Mage_Adminhtml_Block_Newsletter_Queue_Preview extends Mage_Adminhtml_Block
         if(!$storeId) {
             $storeId = Mage::app()->getDefaultStoreView()->getId();
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         Varien_Profiler::start("newsletter_queue_proccessing");
         $vars = array();
diff --git app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
index 4879ccc9161..bfcd76e806e 100644
--- app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/Newsletter/Template/Preview.php
@@ -46,6 +46,12 @@ class Mage_Adminhtml_Block_Newsletter_Template_Preview extends Mage_Adminhtml_Bl
             $template->setTemplateText($this->getRequest()->getParam('text'));
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
+        $template->setTemplateText(
+            $this->maliciousCodeFilter($template->getTemplateText())
+        );
 
         $storeId = (int)$this->getRequest()->getParam('store_id');
         if(!$storeId) {
diff --git app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
index b5edc8ba257..38488c35673 100644
--- app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
+++ app/code/core/Mage/Adminhtml/Block/Permissions/Role/Grid/User.php
@@ -157,7 +157,7 @@ class Mage_Adminhtml_Block_Permissions_Role_Grid_User extends Mage_Adminhtml_Blo
     protected function _getUsers($json=false)
     {
         if ( $this->getRequest()->getParam('in_role_user') != "" ) {
-            return $this->getRequest()->getParam('in_role_user');
+            return (int)$this->getRequest()->getParam('in_role_user');
         }
         $roleId = ( $this->getRequest()->getParam('rid') > 0 ) ? $this->getRequest()->getParam('rid') : Mage::registry('RID');
         $users  = Mage::getModel('admin/roles')->setId($roleId)->getRoleUsers();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
index 1aceac0c547..39e7cfcf4dd 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Creditmemo/Grid.php
@@ -76,6 +76,7 @@ class Mage_Adminhtml_Block_Sales_Creditmemo_Grid extends Mage_Adminhtml_Block_Wi
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
index fa2317d8972..5ce64f47fdf 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Invoice/Grid.php
@@ -77,6 +77,7 @@ class Mage_Adminhtml_Block_Sales_Invoice_Grid extends Mage_Adminhtml_Block_Widge
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
index 7a2f5c94a86..126760b6885 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Create/Header.php
@@ -34,7 +34,10 @@ class Mage_Adminhtml_Block_Sales_Order_Create_Header extends Mage_Adminhtml_Bloc
     protected function _toHtml()
     {
         if ($this->_getSession()->getOrder()->getId()) {
-            return '<h3 class="icon-head head-sales-order">'.Mage::helper('sales')->__('Edit Order #%s', $this->_getSession()->getOrder()->getIncrementId()).'</h3>';
+            return '<h3 class="icon-head head-sales-order">' . Mage::helper('sales')->__(
+                'Edit Order #%s',
+                $this->escapeHtml($this->_getSession()->getOrder()->getIncrementId())
+            ) . '</h3>';
         }
 
         $customerId = $this->getCustomerId();
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
index 12fd17884ba..4d2428538b8 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Creditmemo/Create.php
@@ -67,20 +67,17 @@ class Mage_Adminhtml_Block_Sales_Order_Creditmemo_Create extends Mage_Adminhtml_
     public function getHeaderText()
     {
         if ($this->getCreditmemo()->getInvoice()) {
-            $header = Mage::helper('sales')->__('New Credit Memo for Invoice #%s',
-                $this->getCreditmemo()->getInvoice()->getIncrementId()
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Invoice #%s',
+                $this->escapeHtml($this->getCreditmemo()->getInvoice()->getIncrementId())
             );
-        }
-        else {
-            $header = Mage::helper('sales')->__('New Credit Memo for Order #%s',
-                $this->getCreditmemo()->getOrder()->getRealOrderId()
+        } else {
+            $header = Mage::helper('sales')->__(
+                'New Credit Memo for Order #%s',
+                $this->escapeHtml($this->getCreditmemo()->getOrder()->getRealOrderId())
             );
         }
-        /*$header = Mage::helper('sales')->__('New Credit Memo for Order #%s | Order Date: %s | Customer Name: %s',
-            $this->getCreditmemo()->getOrder()->getRealOrderId(),
-            $this->formatDate($this->getCreditmemo()->getOrder()->getCreatedAt(), 'medium', true),
-            $this->getCreditmemo()->getOrder()->getCustomerName()
-        );*/
+
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
index 2f319eed301..c212b02c217 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Grid.php
@@ -65,10 +65,11 @@ class Mage_Adminhtml_Block_Sales_Order_Grid extends Mage_Adminhtml_Block_Widget_
     {
 
         $this->addColumn('real_order_id', array(
-            'header'=> Mage::helper('sales')->__('Order #'),
-            'width' => '80px',
-            'type'  => 'text',
-            'index' => 'increment_id',
+            'header' => Mage::helper('sales')->__('Order #'),
+            'width'  => '80px',
+            'type'   => 'text',
+            'index'  => 'increment_id',
+            'escape' => true,
         ));
 
         if (!Mage::app()->isSingleStoreMode()) {
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
index 740f9371377..79a9274773a 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Invoice/Create.php
@@ -64,8 +64,14 @@ class Mage_Adminhtml_Block_Sales_Order_Invoice_Create extends Mage_Adminhtml_Blo
     public function getHeaderText()
     {
         return ($this->getInvoice()->getOrder()->getForcedDoShipmentWithInvoice())
-            ? Mage::helper('sales')->__('New Invoice and Shipment for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId())
-            : Mage::helper('sales')->__('New Invoice for Order #%s', $this->getInvoice()->getOrder()->getRealOrderId());
+            ? Mage::helper('sales')->__(
+                'New Invoice and Shipment for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            )
+            : Mage::helper('sales')->__(
+                'New Invoice for Order #%s',
+                $this->escapeHtml($this->getInvoice()->getOrder()->getRealOrderId())
+            );
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
index 8468a467ba4..d257c243e2a 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/Shipment/Create.php
@@ -59,7 +59,10 @@ class Mage_Adminhtml_Block_Sales_Order_Shipment_Create extends Mage_Adminhtml_Bl
 
     public function getHeaderText()
     {
-        $header = Mage::helper('sales')->__('New Shipment for Order #%s', $this->getShipment()->getOrder()->getRealOrderId());
+        $header = Mage::helper('sales')->__(
+            'New Shipment for Order #%s',
+            $this->escapeHtml($this->getShipment()->getOrder()->getRealOrderId())
+        );
         return $header;
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
index d5ad46fd02d..327b7732fce 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Order/View.php
@@ -295,6 +295,16 @@ class Mage_Adminhtml_Block_Sales_Order_View extends Mage_Adminhtml_Block_Widget_
     {
         return $this->getUrl('*/*/reviewPayment', array('action' => $action));
     }
+
+    /**
+     * Return header for view grid
+     *
+     * @return string
+     */
+    public function getHeaderHtml()
+    {
+        return '<h3 class="' . $this->getHeaderCssClass() . '">' . $this->escapeHtml($this->getHeaderText()) . '</h3>';
+    }
 //
 //    /**
 //     * Return URL for accept payment action
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
index 683ce24ec5d..ac83328aa81 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Shipment/Grid.php
@@ -88,6 +88,7 @@ class Mage_Adminhtml_Block_Sales_Shipment_Grid extends Mage_Adminhtml_Block_Widg
             'header'    => Mage::helper('sales')->__('Order #'),
             'index'     => 'order_increment_id',
             'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('order_created_at', array(
diff --git app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
index 778e2a803df..c4c40309b27 100644
--- app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
+++ app/code/core/Mage/Adminhtml/Block/Sales/Transactions/Grid.php
@@ -82,7 +82,8 @@ class Mage_Adminhtml_Block_Sales_Transactions_Grid extends Mage_Adminhtml_Block_
         $this->addColumn('increment_id', array(
             'header'    => Mage::helper('sales')->__('Order ID'),
             'index'     => 'increment_id',
-            'type'      => 'text'
+            'type'      => 'text',
+            'escape'    => true,
         ));
 
         $this->addColumn('txn_id', array(
diff --git app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
index 7097b1c8f6a..f64296cee3c 100644
--- app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
+++ app/code/core/Mage/Adminhtml/Block/System/Email/Template/Preview.php
@@ -45,11 +45,12 @@ class Mage_Adminhtml_Block_System_Email_Template_Preview extends Mage_Adminhtml_
             $template->setTemplateStyles($this->getRequest()->getParam('styles'));
         }
 
-        /* @var $filter Mage_Core_Model_Input_Filter_MaliciousCode */
-        $filter = Mage::getSingleton('core/input_filter_maliciousCode');
+        $template->setTemplateStyles(
+            $this->maliciousCodeFilter($template->getTemplateStyles())
+        );
 
         $template->setTemplateText(
-            $filter->filter($template->getTemplateText())
+            $this->maliciousCodeFilter($template->getTemplateText())
         );
 
         Varien_Profiler::start("email_template_proccessing");
diff --git app/code/core/Mage/Adminhtml/Block/Template.php app/code/core/Mage/Adminhtml/Block/Template.php
index 66bf21b56d7..e2344d8ec1c 100644
--- app/code/core/Mage/Adminhtml/Block/Template.php
+++ app/code/core/Mage/Adminhtml/Block/Template.php
@@ -80,4 +80,15 @@ class Mage_Adminhtml_Block_Template extends Mage_Core_Block_Template
         Mage::dispatchEvent('adminhtml_block_html_before', array('block' => $this));
         return parent::_toHtml();
     }
+
+    /**
+     * Deleting script tags from string
+     *
+     * @param string $html
+     * @return string
+     */
+    public function maliciousCodeFilter($html)
+    {
+        return Mage::getSingleton('core/input_filter_maliciousCode')->filter($html);
+    }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
index 65a8ba89226..b719787ee2a 100644
--- app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
+++ app/code/core/Mage/Adminhtml/Block/Widget/Grid/Column/Renderer/Abstract.php
@@ -115,10 +115,10 @@ abstract class Mage_Adminhtml_Block_Widget_Grid_Column_Renderer_Abstract
             }
             $out = '<a href="#" name="' . $this->getColumn()->getId() . '" title="' . $nDir
                    . '" class="' . $className . '"><span class="sort-title">'
-                   . $this->getColumn()->getHeader().'</span></a>';
+                   . $this->escapeHtml($this->getColumn()->getHeader()) . '</span></a>';
         }
         else {
-            $out = $this->getColumn()->getHeader();
+            $out = $this->escapeHtml($this->getColumn()->getHeader());
         }
         return $out;
     }
diff --git app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
index 0a0c78ef5a9..58ca6f67666 100644
--- app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
+++ app/code/core/Mage/Adminhtml/Model/LayoutUpdate/Validator.php
@@ -180,8 +180,11 @@ class Mage_Adminhtml_Model_LayoutUpdate_Validator extends Zend_Validate_Abstract
     protected function _getXpathBlockValidationExpression() {
         $xpath = "";
         if (count($this->_disallowedBlock)) {
-            $xpath = "//block[@type='";
-            $xpath .= implode("'] | //block[@type='", $this->_disallowedBlock) . "']";
+            foreach ($this->_disallowedBlock as $key => $value) {
+                $xpath .= $key > 0 ? " | " : '';
+                $xpath .= "//block[translate(@type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = ";
+                $xpath .= "translate('$value', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')]";
+            }
         }
         return $xpath;
     }
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
index 39e07922e27..c897bf49c70 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Baseurl.php
@@ -35,6 +35,8 @@ class Mage_Adminhtml_Model_System_Config_Backend_Baseurl extends Mage_Core_Model
             $parsedUrl = parse_url($value);
             if (!isset($parsedUrl['scheme']) || !isset($parsedUrl['host'])) {
                 Mage::throwException(Mage::helper('core')->__('The %s you entered is invalid. Please make sure that it follows "http://domain.com/" format.', $this->getFieldConfig()->label));
+            } elseif (('https' != $parsedUrl['scheme']) && ('http' != $parsedUrl['scheme'])) {
+                Mage::throwException(Mage::helper('core')->__('Invalid URL scheme.'));
             }
         }
 
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
index f3ef56ac470..20006a7de03 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Locale.php
@@ -34,6 +34,27 @@
  */
 class Mage_Adminhtml_Model_System_Config_Backend_Locale extends Mage_Core_Model_Config_Data
 {
+    /**
+     * Validate data before save data
+     *
+     * @return Mage_Core_Model_Abstract
+     * @throws Mage_Core_Exception
+     */
+    protected function _beforeSave()
+    {
+        $allCurrenciesOptions = Mage::getSingleton('adminhtml/system_config_source_locale_currency_all')
+            ->toOptionArray(true);
+
+        $allCurrenciesValues = array_column($allCurrenciesOptions, 'value');
+
+        foreach ($this->getValue() as $currency) {
+            if (!in_array($currency, $allCurrenciesValues)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Currency doesn\'t exist.'));
+            }
+        }
+
+        return parent::_beforeSave();
+    }
 
     /**
      * Enter description here...
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
index 5bf3c36929e..a70fb2aa557 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized/Array.php
@@ -31,11 +31,19 @@
 class Mage_Adminhtml_Model_System_Config_Backend_Serialized_Array extends Mage_Adminhtml_Model_System_Config_Backend_Serialized
 {
     /**
-     * Unset array element with '__empty' key
+     * Check object existence in incoming data and unset array element with '__empty' key
      *
+     * @throws Mage_Core_Exception
+     * @return void
      */
     protected function _beforeSave()
     {
+        try {
+            Mage::helper('core/unserializeArray')->unserialize(serialize($this->getValue()));
+        } catch (Exception $e) {
+            Mage::throwException(Mage::helper('adminhtml')->__('Serialized data is incorrect'));
+        }
+
         $value = $this->getValue();
         if (is_array($value)) {
             unset($value['__empty']);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
index 70fd8b07f31..fd8127654e2 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/AttributeController.php
@@ -157,6 +157,7 @@ class Mage_Adminhtml_Catalog_Product_AttributeController extends Mage_Adminhtml_
             /** @var $helperCatalog Mage_Catalog_Helper_Data */
             $helperCatalog = Mage::helper('catalog');
             //labels
+            $data['frontend_label'] = (array) $data['frontend_label'];
             foreach ($data['frontend_label'] as & $value) {
                 if ($value) {
                     $value = $helperCatalog->escapeHtml($value);
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
index 048bd5c27b2..9e529934363 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/Product/ReviewController.php
@@ -41,6 +41,17 @@ class Mage_Adminhtml_Catalog_Product_ReviewController extends Mage_Adminhtml_Con
      */
     protected $_publicActions = array('edit');
 
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions(array('delete', 'massDelete'));
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Catalog'))
diff --git app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
index 96af92ebde8..e4a93b3ed89 100644
--- app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
+++ app/code/core/Mage/Adminhtml/controllers/Catalog/ProductController.php
@@ -541,7 +541,7 @@ class Mage_Adminhtml_Catalog_ProductController extends Mage_Adminhtml_Controller
         catch (Mage_Eav_Model_Entity_Attribute_Exception $e) {
             $response->setError(true);
             $response->setAttribute($e->getAttributeCode());
-            $response->setMessage($e->getMessage());
+            $response->setMessage(Mage::helper('core')->escapeHtml($e->getMessage()));
         } catch (Mage_Core_Exception $e) {
             $response->setError(true);
             $response->setMessage($e->getMessage());
diff --git app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
index 093ee8507fc..2ee59417309 100644
--- app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
+++ app/code/core/Mage/Adminhtml/controllers/Checkout/AgreementController.php
@@ -33,6 +33,17 @@
  */
 class Mage_Adminhtml_Checkout_AgreementController extends Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Controller predispatch method
+     *
+     * @return Mage_Adminhtml_Controller_Action
+     */
+    public function preDispatch()
+    {
+        $this->_setForcedFormKeyActions('delete');
+        return parent::preDispatch();
+    }
+
     public function indexAction()
     {
         $this->_title($this->__('Sales'))->_title($this->__('Terms and Conditions'));
diff --git app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
index 9d2d411e181..9e5a5e7dbfc 100644
--- app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Newsletter/TemplateController.php
@@ -167,6 +167,11 @@ class Mage_Adminhtml_Newsletter_TemplateController extends Mage_Adminhtml_Contro
         }
 
         try {
+            $allowedHtmlTags = ['text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->addData($request->getParams())
                 ->setTemplateSubject($request->getParam('subject'))
                 ->setTemplateCode($request->getParam('code'))
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
index 334295d69b2..ab320e93a17 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/CatalogController.php
@@ -127,6 +127,9 @@ class Mage_Adminhtml_Promo_CatalogController extends Mage_Adminhtml_Controller_A
                     array('request' => $this->getRequest())
                 );
                 $data = $this->getRequest()->getPost();
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 $data = $this->_filterDates($data, array('from_date', 'to_date'));
                 if ($id = $this->getRequest()->getParam('rule_id')) {
                     $model->load($id);
diff --git app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
index fb166ecd769..1e5688396e1 100644
--- app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
+++ app/code/core/Mage/Adminhtml/controllers/Promo/QuoteController.php
@@ -127,7 +127,9 @@ class Mage_Adminhtml_Promo_QuoteController extends Mage_Adminhtml_Controller_Act
                     'adminhtml_controller_salesrule_prepare_save',
                     array('request' => $this->getRequest()));
                 $data = $this->getRequest()->getPost();
-
+                if (Mage::helper('adminhtml')->hasTags($data['rule'], array('attribute'), false)) {
+                    Mage::throwException(Mage::helper('catalogrule')->__('Wrong rule specified'));
+                }
                 //filter HTML tags
                 /** @var $helper Mage_Adminhtml_Helper_Data */
                 $helper = Mage::helper('adminhtml');
diff --git app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
index 169ec37fab3..cd5b4b4f6f2 100644
--- app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
+++ app/code/core/Mage/Adminhtml/controllers/Sales/Order/CreateController.php
@@ -135,6 +135,13 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
          * Saving order data
          */
         if ($data = $this->getRequest()->getPost('order')) {
+            if (
+                array_key_exists('comment', $data)
+                && array_key_exists('reserved_order_id', $data['comment'])
+            ) {
+                unset($data['comment']['reserved_order_id']);
+            }
+
             $this->_getOrderCreateModel()->importPostData($data);
         }
 
@@ -459,10 +466,20 @@ class Mage_Adminhtml_Sales_Order_CreateController extends Mage_Adminhtml_Control
 
     /**
      * Saving quote and create order
+     *
+     * @throws Mage_Core_Exception
      */
     public function saveAction()
     {
         try {
+            $orderData = $this->getRequest()->getPost('order');
+            if (
+                array_key_exists('reserved_order_id', $orderData['comment'])
+                && Mage::helper('adminhtml/sales')->hasTags($orderData['comment']['reserved_order_id'])
+            ) {
+                Mage::throwException($this->__('Invalid order data.'));
+            }
+
             $this->_processActionData('save');
             if ($paymentData = $this->getRequest()->getPost('payment')) {
                 $this->_getOrderCreateModel()->setPaymentData($paymentData);
diff --git app/code/core/Mage/Adminhtml/controllers/SitemapController.php app/code/core/Mage/Adminhtml/controllers/SitemapController.php
index 1f08a36c637..b976263b344 100644
--- app/code/core/Mage/Adminhtml/controllers/SitemapController.php
+++ app/code/core/Mage/Adminhtml/controllers/SitemapController.php
@@ -33,6 +33,11 @@
  */
 class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
 {
+    /**
+     * Maximum sitemap name length
+     */
+    const MAXIMUM_SITEMAP_NAME_LENGTH = 32;
+
     /**
      * Controller predispatch method
      *
@@ -141,6 +146,19 @@ class Mage_Adminhtml_SitemapController extends  Mage_Adminhtml_Controller_Action
             if (!empty($data['sitemap_filename']) && !empty($data['sitemap_path'])) {
                 $path = rtrim($data['sitemap_path'], '\\/')
                       . DS . $data['sitemap_filename'];
+
+                // check filename length
+                if (strlen($data['sitemap_filename']) > self::MAXIMUM_SITEMAP_NAME_LENGTH) {
+                    Mage::getSingleton('adminhtml/session')->addError(
+                        Mage::helper('sitemap')->__(
+                            'Please enter a sitemap name with at most %s characters.',
+                            self::MAXIMUM_SITEMAP_NAME_LENGTH
+                        ));
+                    $this->_redirect('*/*/edit', array(
+                        'sitemap_id' => $this->getRequest()->getParam('sitemap_id')
+                    ));
+                    return;
+                }
                 /** @var $validator Mage_Core_Model_File_Validator_AvailablePath */
                 $validator = Mage::getModel('core/file_validator_availablePath');
                 /** @var $helper Mage_Adminhtml_Helper_Catalog */
diff --git app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
index c1e28b87de0..e694962b913 100644
--- app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
+++ app/code/core/Mage/Adminhtml/controllers/System/Email/TemplateController.php
@@ -89,6 +89,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         $this->renderLayout();
     }
 
+    /**
+     * Save action
+     *
+     * @throws Mage_Core_Exception
+     */
     public function saveAction()
     {
         $request = $this->getRequest();
@@ -102,6 +107,11 @@ class Mage_Adminhtml_System_Email_TemplateController extends Mage_Adminhtml_Cont
         }
 
         try {
+            $allowedHtmlTags = ['template_text', 'styles'];
+            if (Mage::helper('adminhtml')->hasTags($request->getParams(), $allowedHtmlTags)) {
+                Mage::throwException(Mage::helper('adminhtml')->__('Invalid template data.'));
+            }
+
             $template->setTemplateSubject($request->getParam('template_subject'))
                 ->setTemplateCode($request->getParam('template_code'))
 /*
diff --git app/code/core/Mage/Catalog/Helper/Product.php app/code/core/Mage/Catalog/Helper/Product.php
index 80bdb50496c..aa72015bfef 100644
--- app/code/core/Mage/Catalog/Helper/Product.php
+++ app/code/core/Mage/Catalog/Helper/Product.php
@@ -35,6 +35,8 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
     const XML_PATH_PRODUCT_URL_USE_CATEGORY     = 'catalog/seo/product_use_categories';
     const XML_PATH_USE_PRODUCT_CANONICAL_TAG    = 'catalog/seo/product_canonical_tag';
 
+    const DEFAULT_QTY                           = 1;
+
     /**
      * Cache for product rewrite suffix
      *
@@ -441,4 +443,40 @@ class Mage_Catalog_Helper_Product extends Mage_Core_Helper_Url
         return $product;
     }
 
+    /**
+     * Get default product value by field name
+     *
+     * @param string $fieldName
+     * @param string $productType
+     * @return int
+     */
+    public function getDefaultProductValue($fieldName, $productType)
+    {
+        $fieldData = $this->getFieldset($fieldName) ? (array) $this->getFieldset($fieldName) : null;
+        if (
+            count($fieldData)
+            && array_key_exists($productType, $fieldData['product_type'])
+            && (bool)$fieldData['use_config']
+        ) {
+            return $fieldData['inventory'];
+        }
+        return self::DEFAULT_QTY;
+    }
+
+    /**
+     * Return array from config by fieldset name and area
+     *
+     * @param null|string $field
+     * @param string $fieldset
+     * @param string $area
+     * @return array|null
+     */
+    public function getFieldset($field = null, $fieldset = 'catalog_product_dataflow', $area = 'admin')
+    {
+        $fieldsetData = Mage::getConfig()->getFieldset($fieldset, $area);
+        if ($fieldsetData) {
+            return $fieldsetData ? $fieldsetData->$field : $fieldsetData;
+        }
+        return $fieldsetData;
+    }
 }
diff --git app/code/core/Mage/Catalog/controllers/Product/CompareController.php app/code/core/Mage/Catalog/controllers/Product/CompareController.php
index 23e8d67e208..844497f80f1 100644
--- app/code/core/Mage/Catalog/controllers/Product/CompareController.php
+++ app/code/core/Mage/Catalog/controllers/Product/CompareController.php
@@ -78,7 +78,11 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
             $this->_redirectReferer();
             return;
         }
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)
+            && (Mage::getSingleton('log/visitor')->getId() || Mage::getSingleton('customer/session')->isLoggedIn())
+        ) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -102,7 +106,8 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
      */
     public function removeAction()
     {
-        if ($productId = (int) $this->getRequest()->getParam('product')) {
+        $productId = (int) $this->getRequest()->getParam('product');
+        if ($this->isProductAvailable($productId)) {
             $product = Mage::getModel('catalog/product')
                 ->setStoreId(Mage::app()->getStore()->getId())
                 ->load($productId);
@@ -180,4 +185,15 @@ class Mage_Catalog_Product_CompareController extends Mage_Core_Controller_Front_
         $this->_customerId = $id;
         return $this;
     }
+
+    /**
+     * Check if product is available
+     *
+     * @param int $productId
+     * @return bool
+     */
+    public function isProductAvailable($productId)
+    {
+        return Mage::getModel('catalog/product')->load($productId)->isAvailable();
+    }
 }
diff --git app/code/core/Mage/Checkout/Model/Session.php app/code/core/Mage/Checkout/Model/Session.php
index 604ec0d375b..66c6e5e64d2 100644
--- app/code/core/Mage/Checkout/Model/Session.php
+++ app/code/core/Mage/Checkout/Model/Session.php
@@ -107,6 +107,7 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
         if ($this->_quote === null) {
             $quote = Mage::getModel('sales/quote')
                 ->setStoreId(Mage::app()->getStore()->getId());
+            $customerSession = Mage::getSingleton('customer/session');
 
             /** @var $quote Mage_Sales_Model_Quote */
             if ($this->getQuoteId()) {
@@ -115,7 +116,13 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                 } else {
                     $quote->loadActive($this->getQuoteId());
                 }
-                if ($quote->getId()) {
+                if (
+                    $quote->getId()
+                    && (
+                        ($customerSession->isLoggedIn() && $customerSession->getId() == $quote->getCustomerId())
+                        || (!$customerSession->isLoggedIn() && !$quote->getCustomerId())
+                    )
+                ) {
                     /**
                      * If current currency code of quote is not equal current currency code of store,
                      * need recalculate totals of quote. It is possible if customer use currency switcher or
@@ -132,16 +139,16 @@ class Mage_Checkout_Model_Session extends Mage_Core_Model_Session_Abstract
                         $quote->load($this->getQuoteId());
                     }
                 } else {
+                    $quote->unsetData();
                     $this->setQuoteId(null);
                 }
             }
 
-            $customerSession = Mage::getSingleton('customer/session');
-
             if (!$this->getQuoteId()) {
                 if ($customerSession->isLoggedIn() || $this->_customer) {
                     $customer = ($this->_customer) ? $this->_customer : $customerSession->getCustomer();
                     $quote->loadByCustomer($customer);
+                    $quote->setCustomer($customer);
                     $this->setQuoteId($quote->getId());
                 } else {
                     $quote->setIsCheckoutCart(true);
diff --git app/code/core/Mage/Checkout/controllers/OnepageController.php app/code/core/Mage/Checkout/controllers/OnepageController.php
index 96a7e5e62c7..d5cb948dfe0 100644
--- app/code/core/Mage/Checkout/controllers/OnepageController.php
+++ app/code/core/Mage/Checkout/controllers/OnepageController.php
@@ -531,7 +531,7 @@ class Mage_Checkout_OnepageController extends Mage_Checkout_Controller_Action
      */
     public function saveOrderAction()
     {
-        if (!$this->_validateFormKey()) {
+        if ($this->isFormkeyValidationOnCheckoutEnabled() && !$this->_validateFormKey()) {
             return $this->_redirect('*/*');
         }
 
diff --git app/code/core/Mage/Cms/Helper/Data.php app/code/core/Mage/Cms/Helper/Data.php
index ca06a14cd74..245ac2ec26f 100644
--- app/code/core/Mage/Cms/Helper/Data.php
+++ app/code/core/Mage/Cms/Helper/Data.php
@@ -37,6 +37,7 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
     const XML_NODE_PAGE_TEMPLATE_FILTER     = 'global/cms/page/tempate_filter';
     const XML_NODE_BLOCK_TEMPLATE_FILTER    = 'global/cms/block/tempate_filter';
     const XML_NODE_ALLOWED_STREAM_WRAPPERS  = 'global/cms/allowed_stream_wrappers';
+    const XML_NODE_ALLOWED_MEDIA_EXT_SWF    = 'adminhtml/cms/browser/extensions/media_allowed/swf';
 
     /**
      * Retrieve Template processor for Page Content
@@ -74,4 +75,19 @@ class Mage_Cms_Helper_Data extends Mage_Core_Helper_Abstract
 
         return is_array($allowedStreamWrappers) ? $allowedStreamWrappers : array();
     }
+
+    /**
+     * Check is swf file extension disabled
+     *
+     * @return bool
+     */
+    public function isSwfDisabled()
+    {
+        $statusSwf = Mage::getConfig()->getNode(self::XML_NODE_ALLOWED_MEDIA_EXT_SWF);
+        if ($statusSwf instanceof Mage_Core_Model_Config_Element) {
+            $statusSwf = $statusSwf->asArray()[0];
+        }
+
+        return $statusSwf ? false : true;
+    }
 }
diff --git app/code/core/Mage/Cms/Model/Wysiwyg/Config.php app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
index 1a8a6c42dbe..cdb8130fbe0 100644
--- app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
+++ app/code/core/Mage/Cms/Model/Wysiwyg/Config.php
@@ -76,7 +76,8 @@ class Mage_Cms_Model_Wysiwyg_Config extends Varien_Object
             'content_css'                   =>
                 Mage::getBaseUrl('js').'mage/adminhtml/wysiwyg/tiny_mce/themes/advanced/skins/default/content.css',
             'width'                         => '100%',
-            'plugins'                       => array()
+            'plugins'                       => array(),
+            'media_disable_flash'           => Mage::helper('cms')->isSwfDisabled()
         ));
 
         $config->setData('directives_url_quoted', preg_quote($config->getData('directives_url')));
diff --git app/code/core/Mage/Cms/etc/config.xml app/code/core/Mage/Cms/etc/config.xml
index 3539478c7c7..ff1d0d46843 100644
--- app/code/core/Mage/Cms/etc/config.xml
+++ app/code/core/Mage/Cms/etc/config.xml
@@ -122,7 +122,7 @@
                     </image_allowed>
                     <media_allowed>
                         <flv>1</flv>
-                        <swf>1</swf>
+                        <swf>0</swf>
                         <avi>1</avi>
                         <mov>1</mov>
                         <rm>1</rm>
diff --git app/code/core/Mage/Compiler/Model/Process.php app/code/core/Mage/Compiler/Model/Process.php
index 6a1109c2a28..d28b8aa9f61 100644
--- app/code/core/Mage/Compiler/Model/Process.php
+++ app/code/core/Mage/Compiler/Model/Process.php
@@ -43,6 +43,9 @@ class Mage_Compiler_Model_Process
 
     protected $_controllerFolders = array();
 
+    /** $_collectLibs library list array */
+    protected $_collectLibs = array();
+
     public function __construct($options=array())
     {
         if (isset($options['compile_dir'])) {
@@ -128,6 +131,9 @@ class Mage_Compiler_Model_Process
                 || !in_array(substr($source, strlen($source)-4, 4), array('.php'))) {
                 return $this;
             }
+            if (!$firstIteration && stripos($source, Mage::getBaseDir('lib') . DS) !== false) {
+                $this->_collectLibs[] = $target;
+            }
             copy($source, $target);
         }
         return $this;
@@ -341,6 +347,11 @@ class Mage_Compiler_Model_Process
     {
         $sortedClasses = array();
         foreach ($classes as $className) {
+            /** Skip iteration if this class has already been moved to the includes folder from the lib */
+            if (array_search($this->_includeDir . DS . $className . '.php', $this->_collectLibs)) {
+                continue;
+            }
+
             $implements = array_reverse(class_implements($className));
             foreach ($implements as $class) {
                 if (!in_array($class, $sortedClasses) && !in_array($class, $this->_processedClasses) && strstr($class, '_')) {
diff --git app/code/core/Mage/Core/Helper/Abstract.php app/code/core/Mage/Core/Helper/Abstract.php
index f69972b2279..53e5ef7d68b 100644
--- app/code/core/Mage/Core/Helper/Abstract.php
+++ app/code/core/Mage/Core/Helper/Abstract.php
@@ -422,4 +422,42 @@ abstract class Mage_Core_Helper_Abstract
         }
         return $arr;
     }
+
+    /**
+     * Check for tags in multidimensional arrays
+     *
+     * @param string|array $data
+     * @param array $arrayKeys keys of the array being checked that are excluded and included in the check
+     * @param bool $skipTags skip transferred array keys, if false then check only them
+     * @return bool
+     */
+    public function hasTags($data, array $arrayKeys = array(), $skipTags = true)
+    {
+        if (is_array($data)) {
+            foreach ($data as $key => $item) {
+                if ($skipTags && in_array($key, $arrayKeys)) {
+                    continue;
+                }
+                if (is_array($item)) {
+                    if ($this->hasTags($item, $arrayKeys, $skipTags)) {
+                        return true;
+                    }
+                } elseif (
+                    (bool)strcmp($item, $this->removeTags($item))
+                    || (bool)strcmp($key, $this->removeTags($key))
+                ) {
+                    if (!$skipTags && !in_array($key, $arrayKeys)) {
+                        continue;
+                    }
+                    return true;
+                }
+            }
+            return false;
+        } elseif (is_string($data)) {
+            if ((bool)strcmp($data, $this->removeTags($data))) {
+                return true;
+            }
+        }
+        return false;
+    }
 }
diff --git app/code/core/Mage/Core/Helper/Data.php app/code/core/Mage/Core/Helper/Data.php
index 6cf48f68ed1..62a3209d078 100644
--- app/code/core/Mage/Core/Helper/Data.php
+++ app/code/core/Mage/Core/Helper/Data.php
@@ -237,7 +237,7 @@ class Mage_Core_Helper_Data extends Mage_Core_Helper_Abstract
         }
         mt_srand(10000000*(double)microtime());
         for ($i = 0, $str = '', $lc = strlen($chars)-1; $i < $len; $i++) {
-            $str .= $chars[mt_rand(0, $lc)];
+            $str .= $chars[random_int(0, $lc)];
         }
         return $str;
     }
diff --git app/code/core/Mage/Core/Model/Design/Package.php app/code/core/Mage/Core/Model/Design/Package.php
index b6d88661dee..d624260541d 100644
--- app/code/core/Mage/Core/Model/Design/Package.php
+++ app/code/core/Mage/Core/Model/Design/Package.php
@@ -567,7 +567,11 @@ class Mage_Core_Model_Design_Package
             return false;
         }
 
-        $regexps = @unserialize($configValueSerialized);
+        try {
+            $regexps = Mage::helper('core/unserializeArray')->unserialize($configValueSerialized);
+        } catch (Exception $e) {
+            Mage::logException($e);
+        }
 
         if (empty($regexps)) {
             return false;
diff --git app/code/core/Mage/Core/Model/Email/Template/Filter.php app/code/core/Mage/Core/Model/Email/Template/Filter.php
index caa18a8a133..edd03e151fa 100644
--- app/code/core/Mage/Core/Model/Email/Template/Filter.php
+++ app/code/core/Mage/Core/Model/Email/Template/Filter.php
@@ -518,4 +518,24 @@ class Mage_Core_Model_Email_Template_Filter extends Varien_Filter_Template
         }
         return $value;
     }
+
+    /**
+     * Return variable value for var construction
+     *
+     * @param string $value raw parameters
+     * @param string $default default value
+     * @return string
+     */
+    protected function _getVariable($value, $default = '{no_value_defined}')
+    {
+        Mage::register('varProcessing', true);
+        try {
+            $result = parent::_getVariable($value, $default);
+        } catch (Exception $e) {
+            $result = '';
+            Mage::logException($e);
+        }
+        Mage::unregister('varProcessing');
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
index ad304728eed..76559d47207 100644
--- app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
+++ app/code/core/Mage/Core/Model/File/Validator/AvailablePath.php
@@ -230,8 +230,16 @@ class Mage_Core_Model_File_Validator_AvailablePath extends Zend_Validate_Abstrac
         }
 
         //validation
+        $protectedExtensions = Mage::helper('core/data')->getProtectedFileExtensions();
         $value = str_replace(array('/', '\\'), DS, $this->_value);
         $valuePathInfo = pathinfo(ltrim($value, '\\/'));
+        $fileNameExtension = pathinfo($valuePathInfo['filename'], PATHINFO_EXTENSION);
+
+        if (in_array($fileNameExtension, $protectedExtensions)) {
+            $this->_error(self::NOT_AVAILABLE_PATH, $this->_value);
+            return false;
+        }
+
         if ($valuePathInfo['dirname'] == '.' || $valuePathInfo['dirname'] == DS) {
             $valuePathInfo['dirname'] = '';
         }
diff --git app/code/core/Mage/Core/Model/Observer.php app/code/core/Mage/Core/Model/Observer.php
index 11dc0ec7e99..5d1bd832781 100644
--- app/code/core/Mage/Core/Model/Observer.php
+++ app/code/core/Mage/Core/Model/Observer.php
@@ -94,4 +94,19 @@ class Mage_Core_Model_Observer
 
         return $this;
     }
+
+    /**
+     * Checks method availability for processing in variable
+     *
+     * @param Varien_Event_Observer $observer
+     * @throws Exception
+     * @return Mage_Core_Model_Observer
+     */
+    public function secureVarProcessing(Varien_Event_Observer $observer)
+    {
+        if (Mage::registry('varProcessing')) {
+            Mage::throwException(Mage::helper('core')->__('Disallowed template variable method.'));
+        }
+        return $this;
+    }
 }
diff --git app/code/core/Mage/Core/etc/config.xml app/code/core/Mage/Core/etc/config.xml
index cd12e832349..9f0572f5567 100644
--- app/code/core/Mage/Core/etc/config.xml
+++ app/code/core/Mage/Core/etc/config.xml
@@ -147,6 +147,24 @@
                 <writer_model>Zend_Log_Writer_Stream</writer_model>
             </core>
         </log>
+        <events>
+            <model_save_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_save_before>
+            <model_delete_before>
+                <observers>
+                    <secure_var_processing>
+                        <class>core/observer</class>
+                        <method>secureVarProcessing</method>
+                    </secure_var_processing>
+                </observers>
+            </model_delete_before>
+        </events>
     </global>
     <frontend>
         <routers>
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index d9df7f16127..36d5c779662 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -410,3 +410,19 @@ if (!function_exists('hash_equals')) {
         return 0 === $result;
     }
 }
+
+if (version_compare(PHP_VERSION, '7.0.0', '<') && !function_exists('random_int')) {
+    /**
+     * Generates pseudo-random integers
+     *
+     * @param int $min
+     * @param int $max
+     * @return int Returns random integer in the range $min to $max, inclusive.
+     */
+    function random_int($min, $max)
+    {
+        mt_srand();
+
+        return mt_rand($min, $max);
+    }
+}
diff --git app/code/core/Mage/Downloadable/controllers/DownloadController.php app/code/core/Mage/Downloadable/controllers/DownloadController.php
index b04d29bab4b..7659bc22250 100644
--- app/code/core/Mage/Downloadable/controllers/DownloadController.php
+++ app/code/core/Mage/Downloadable/controllers/DownloadController.php
@@ -96,7 +96,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $sampleId = $this->getRequest()->getParam('sample_id', 0);
         $sample = Mage::getModel('downloadable/sample')->load($sampleId);
-        if ($sample->getId()) {
+        if (
+            $sample->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $sample->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($sample->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
@@ -126,7 +131,12 @@ class Mage_Downloadable_DownloadController extends Mage_Core_Controller_Front_Ac
     {
         $linkId = $this->getRequest()->getParam('link_id', 0);
         $link = Mage::getModel('downloadable/link')->load($linkId);
-        if ($link->getId()) {
+        if (
+            $link->getId()
+            && Mage::helper('catalog/product')
+                ->getProduct((int) $link->getProductId(), Mage::app()->getStore()->getId(), 'id')
+                ->isAvailable()
+        ) {
             $resource = '';
             $resourceType = '';
             if ($link->getSampleType() == Mage_Downloadable_Helper_Download::LINK_TYPE_URL) {
diff --git app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
index 69d398636f0..458a3d12da5 100644
--- app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
+++ app/code/core/Mage/SalesRule/Model/Resource/Report/Rule/Createdat.php
@@ -112,14 +112,14 @@ class Mage_SalesRule_Model_Resource_Report_Rule_Createdat extends Mage_Reports_M
                         $adapter->getIfNullSql('base_subtotal_refunded', 0). ') * base_to_global_rate)', 0),
 
                 'discount_amount_actual'  =>
-                    $adapter->getIfNullSql('SUM((base_discount_invoiced - ' .
+                    $adapter->getIfNullSql('SUM((ABS(base_discount_invoiced) - ' .
                         $adapter->getIfNullSql('base_discount_refunded', 0) . ')
                         * base_to_global_rate)', 0),
 
                 'total_amount_actual'     =>
                     $adapter->getIfNullSql('SUM((base_subtotal_invoiced - ' .
                         $adapter->getIfNullSql('base_subtotal_refunded', 0) . ' - ' .
-                        $adapter->getIfNullSql('base_discount_invoiced - ' .
+                        $adapter->getIfNullSql('ABS(base_discount_invoiced) - ' .
                         $adapter->getIfNullSql('base_discount_refunded', 0), 0) .
                         ') * base_to_global_rate)', 0),
             );
diff --git app/code/core/Mage/Sendfriend/etc/config.xml app/code/core/Mage/Sendfriend/etc/config.xml
index 19ddd06e24e..44c07f83c75 100644
--- app/code/core/Mage/Sendfriend/etc/config.xml
+++ app/code/core/Mage/Sendfriend/etc/config.xml
@@ -122,7 +122,7 @@
     <default>
         <sendfriend>
             <email>
-                <enabled>1</enabled>
+                <enabled>0</enabled>
                 <template>sendfriend_email_template</template>
                 <allow_guest>0</allow_guest>
                 <max_recipients>5</max_recipients>
diff --git app/code/core/Mage/Sendfriend/etc/system.xml app/code/core/Mage/Sendfriend/etc/system.xml
index 5f07b9e7542..7211be2f0f7 100644
--- app/code/core/Mage/Sendfriend/etc/system.xml
+++ app/code/core/Mage/Sendfriend/etc/system.xml
@@ -52,6 +52,7 @@
                             <show_in_default>1</show_in_default>
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
+                            <comment><![CDATA[<strong style="color:red">Warning!</strong> This functionality is vulnerable and can be abused to distribute spam.]]></comment>
                         </enabled>
                         <template translate="label">
                             <label>Select Email Template</label>
diff --git app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
index 072a4dfb135..a1366daced7 100644
--- app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/composite/fieldset/configurable.phtml
@@ -34,7 +34,7 @@
     <div class="product-options">
         <dl>
         <?php foreach($_attributes as $_attribute): ?>
-            <dt><label class="required"><em>*</em><?php echo $_attribute->getLabel() ?></label></dt>
+            <dt><label class="required"><em>*</em><?php echo $this->escapeHtml($_attribute->getLabel()) ?></label></dt>
             <dd<?php if ($_attribute->decoratedIsLast){?> class="last"<?php }?>>
                 <div class="input-box">
                     <select name="super_attribute[<?php echo $_attribute->getAttributeId() ?>]" id="attribute<?php echo $_attribute->getAttributeId() ?>" class="required-entry super-attribute-select">
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index f72e3ce6ac4..2c6d2c00ca5 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -59,7 +59,7 @@ $_block = $this;
             <th><?php echo Mage::helper('catalog')->__('Label') ?></th>
             <th><?php echo Mage::helper('catalog')->__('Sort Order') ?></th>
             <?php foreach ($_block->getImageTypes() as $typeId => $type): ?>
-                <th><?php echo $this->escapeHtml($type['label']); ?></th>
+                <th><?php echo $this->escapeHtml($type['label'], array('br')); ?></th>
             <?php endforeach; ?>
             <th><?php echo Mage::helper('catalog')->__('Exclude') ?></th>
             <th class="last"><?php echo Mage::helper('catalog')->__('Remove') ?></th>
diff --git app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
index d1cb641972e..abbb70067e2 100644
--- app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/tab/inventory.phtml
@@ -77,7 +77,7 @@
 
         <tr>
             <td class="label"><label for="inventory_min_sale_qty"><?php echo Mage::helper('catalog')->__('Minimum Qty Allowed in Shopping Cart') ?></label></td>
-            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo $this->getFieldValue('min_sale_qty')*1 ?>" <?php echo $_readonly;?>/>
+            <td class="value"><input type="text" class="input-text validate-number" id="inventory_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][min_sale_qty]" value="<?php echo (bool)$this->getProduct()->getId() ? (int)$this->getFieldValue('min_sale_qty') : Mage::helper('catalog/product')->getDefaultProductValue('min_sale_qty', $this->getProduct()->getTypeId()) ?>" <?php echo $_readonly ?>/>
 
             <?php $_checked = ($this->getFieldValue('use_config_min_sale_qty') || $this->IsNew()) ? 'checked="checked"' : '' ?>
             <input type="checkbox" id="inventory_use_config_min_sale_qty" name="<?php echo $this->getFieldSuffix() ?>[stock_data][use_config_min_sale_qty]" value="1" <?php echo $_checked ?> onclick="toggleValueElements(this, this.parentNode);" class="checkbox" <?php echo $_readonly;?> />
diff --git app/design/adminhtml/default/default/template/customer/tab/addresses.phtml app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
index 27c26c892c4..b1837b83842 100644
--- app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/addresses.phtml
@@ -46,7 +46,7 @@
             </a>
             <?php endif;?>
             <address>
-                <?php echo $_address->format('html') ?>
+                <?php echo $this->maliciousCodeFilter($_address->format('html')) ?>
             </address>
             <div class="address-type">
                 <span class="address-type-line">
diff --git app/design/adminhtml/default/default/template/customer/tab/view.phtml app/design/adminhtml/default/default/template/customer/tab/view.phtml
index 2e1ab28a3bf..00fb287d7bf 100644
--- app/design/adminhtml/default/default/template/customer/tab/view.phtml
+++ app/design/adminhtml/default/default/template/customer/tab/view.phtml
@@ -75,7 +75,7 @@ $createDateStore    = $this->getStoreCreateDate();
         </table>
         <address class="box-right">
             <strong><?php echo $this->__('Default Billing Address') ?></strong><br/>
-            <?php echo $this->getBillingAddressHtml() ?>
+            <?php echo $this->maliciousCodeFilter($this->getBillingAddressHtml()) ?>
         </address>
     </fieldset>
 </div>
diff --git app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml
index 69b60b3b085..dcc7115889b 100644
--- app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml
+++ app/design/adminhtml/default/default/template/enterprise/checkout/manage.phtml
@@ -39,7 +39,7 @@
 <script type="text/javascript">
     checkoutObj = new AdminCheckout(<?php echo $this->getOrderDataJson() ?>);
     checkoutObj.setLoadBaseUrl('<?php echo $this->getLoadBlockUrl() ?>');
-    checkoutObj.setCurrencySymbol('<?php echo $this->getCurrencySymbol($this->getCurrentCurrencyCode()) ?>');
+    checkoutObj.setCurrencySymbol('<?php echo Mage::helper('core')->jsQuoteEscape($this->getCurrencySymbol($this->getCurrentCurrencyCode())) ?>');
 </script>
 
 <div class="content-header">
diff --git app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml
index f44cd3b2d9a..2725d6f673b 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/edit/general/details.phtml
@@ -44,7 +44,11 @@ $customerLink = $this->getCustomerLink();
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Order ID') ?></label></td>
-                    <td class="value"><a href="<?php echo $this->getOrderLink() ?>"><?php echo Mage::helper('enterprise_rma')->__('#') . $this->getOrderIncrementId() ?></a></td>
+                    <td class="value">
+                        <a href="<?php echo $this->getOrderLink() ?>">
+                            <?php echo Mage::helper('enterprise_rma')->__('#') . $this->escapeHtml($this->getOrderIncrementId()) ?>
+                        </a>
+                    </td>
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Customer Name') ?></label></td>
diff --git app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml
index e4de65cfd13..be206da309e 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/edit/general/returnadress.phtml
@@ -36,6 +36,6 @@ $customerLink = $this->getCustomerLink();
         <h4 class="icon-head head-shipping-method"><?php echo Mage::helper('enterprise_rma')->__('Return Address') ?></h4>
     </div>
     <fieldset>
-        <address><?php echo $this->getReturnAddress() ?></address>
+        <address><?php echo $this->maliciousCodeFilter($this->getReturnAddress()) ?></address>
     </fieldset>
 </div>
diff --git app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml
index 78b36f30250..90f26962fcb 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/edit/general/shippingaddress.phtml
@@ -36,7 +36,7 @@
         </div>
         <fieldset>
             <br />
-            <address><?php echo $this->getOrderShippingAddress() ?></address>
+            <address><?php echo $this->maliciousCodeFilter($this->getOrderShippingAddress()) ?></address>
         </fieldset>
     </div>
 <?php endif ?>
diff --git app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml
index 4bc2d3db5ca..75b9ae92fe9 100644
--- app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml
+++ app/design/adminhtml/default/default/template/enterprise/rma/new/general/details.phtml
@@ -40,7 +40,11 @@ $customerLink = $this->getCustomerLink();
             <table cellspacing="0" class="form-list">
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Order ID') ?></label></td>
-                    <td class="value"><a href="<?php echo $this->getOrderLink() ?>"><?php echo Mage::helper('enterprise_rma')->__('#') . $this->getOrderIncrementId() ?></a></td>
+                    <td class="value">
+                        <a href="<?php echo $this->getOrderLink() ?>">
+                            <?php echo Mage::helper('enterprise_rma')->__('#') . $this->escapeHtml($this->getOrderIncrementId()) ?>
+                        </a>
+                    </td>
                 </tr>
                 <tr>
                     <td class="label"><label><?php echo Mage::helper('enterprise_rma')->__('Customer Name') ?></label></td>
diff --git app/design/adminhtml/default/default/template/notification/window.phtml app/design/adminhtml/default/default/template/notification/window.phtml
index 752aa5b1a3e..666eb928de6 100644
--- app/design/adminhtml/default/default/template/notification/window.phtml
+++ app/design/adminhtml/default/default/template/notification/window.phtml
@@ -68,7 +68,7 @@
     </div>
     <div class="message-popup-content">
         <div class="message">
-            <span class="message-icon message-<?php echo $this->getSeverityText();?>" style="background-image:url(<?php echo $this->getSeverityIconsUrl() ?>);"><?php echo $this->getSeverityText();?></span>
+            <span class="message-icon message-<?php echo $this->getSeverityText(); ?>" style="background-image:url(<?php echo $this->escapeUrl($this->getSeverityIconsUrl()); ?>);"><?php echo $this->getSeverityText(); ?></span>
             <p class="message-text"><?php echo $this->getNoticeMessageText(); ?></p>
         </div>
         <p class="read-more"><a href="<?php echo $this->getNoticeMessageUrl(); ?>" onclick="this.target='_blank';"><?php echo $this->getReadDetailsText(); ?></a></p>
diff --git app/design/adminhtml/default/default/template/sales/order/create/data.phtml app/design/adminhtml/default/default/template/sales/order/create/data.phtml
index 03552202890..10dd238ea38 100644
--- app/design/adminhtml/default/default/template/sales/order/create/data.phtml
+++ app/design/adminhtml/default/default/template/sales/order/create/data.phtml
@@ -33,7 +33,9 @@
     <?php endforeach; ?>
 </select>
 </p>
-<script type="text/javascript">order.setCurrencySymbol('<?php echo $this->getCurrencySymbol($this->getCurrentCurrencyCode()) ?>')</script>
+    <script type="text/javascript">
+        order.setCurrencySymbol('<?php echo Mage::helper('core')->jsQuoteEscape($this->getCurrencySymbol($this->getCurrentCurrencyCode())) ?>')
+    </script>
 <table cellspacing="0" width="100%">
 <tr>
     <?php if($this->getCustomerId()): ?>
diff --git app/design/adminhtml/default/default/template/sales/order/view/info.phtml app/design/adminhtml/default/default/template/sales/order/view/info.phtml
index c36e36e4f5f..f5b326aecc0 100644
--- app/design/adminhtml/default/default/template/sales/order/view/info.phtml
+++ app/design/adminhtml/default/default/template/sales/order/view/info.phtml
@@ -39,9 +39,9 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
         endif; ?>
         <div class="entry-edit-head">
         <?php if ($this->getNoUseOrderLink()): ?>
-            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?> (<?php echo $_email ?>)</h4>
+            <h4 class="icon-head head-account"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?> (<?php echo $_email ?>)</h4>
         <?php else: ?>
-            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $_order->getRealOrderId()) ?></a>
+            <a href="<?php echo $this->getViewUrl($_order->getId()) ?>"><?php echo Mage::helper('sales')->__('Order # %s', $this->escapeHtml($_order->getRealOrderId())) ?></a>
             <strong>(<?php echo $_email ?>)</strong>
         <?php endif; ?>
         </div>
@@ -69,7 +69,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the New Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationChildId()) ?>">
-                    <?php echo $_order->getRelationChildRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationChildRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -77,7 +77,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <tr>
                 <td class="label"><label><?php echo Mage::helper('sales')->__('Link to the Previous Order') ?></label></td>
                 <td class="value"><a href="<?php echo $this->getViewUrl($_order->getRelationParentId()) ?>">
-                    <?php echo $_order->getRelationParentRealId() ?>
+                    <?php echo $this->escapeHtml($_order->getRelationParentRealId()) ?>
                 </a></td>
             </tr>
             <?php endif; ?>
@@ -154,7 +154,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <div class="tools"><?php echo $this->getAddressEditLink($_order->getBillingAddress())?></div>
         </div>
         <fieldset>
-            <address><?php echo $_order->getBillingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getBillingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
@@ -167,7 +167,7 @@ $orderStoreDate = $this->formatDate($_order->getCreatedAtStoreDate(), 'medium',
             <div class="tools"><?php echo $this->getAddressEditLink($_order->getShippingAddress())?></div>
         </div>
         <fieldset>
-            <address><?php echo $_order->getShippingAddress()->getFormated(true) ?></address>
+            <address><?php echo $this->maliciousCodeFilter($_order->getShippingAddress()->getFormated(true)) ?></address>
         </fieldset>
     </div>
 </div>
diff --git app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
index c911faff053..1385bf91fc9 100644
--- app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
+++ app/design/adminhtml/default/default/template/system/currency/rate/matrix.phtml
@@ -38,7 +38,7 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <tr class="headings">
                 <th class="a-right">&nbsp;</th>
                 <?php $_i = 0; foreach( $this->getAllowedCurrencies() as $_currencyCode ): ?>
-                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $_currencyCode ?><strong></th>
+                    <th class="<?php echo (( ++$_i == (sizeof($this->getAllowedCurrencies())) ) ? 'last' : '' ) ?> a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?><strong></th>
                 <?php endforeach; ?>
             </tr>
         </thead>
@@ -47,16 +47,16 @@ $_rates = ( $_newRates ) ? $_newRates : $_oldRates;
             <?php if( isset($_rates[$_currencyCode]) && is_array($_rates[$_currencyCode])): ?>
                 <?php foreach( $_rates[$_currencyCode] as $_rate => $_value ): ?>
                     <?php if( ++$_j == 1 ): ?>
-                        <td class="a-right"><strong><?php echo $_currencyCode ?></strong></td>
+                        <td class="a-right"><strong><?php echo $this->escapeHtml($_currencyCode) ?></strong></td>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates) && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
                         </th>
                     <?php else: ?>
                         <td class="a-right">
-                            <input type="text" name="rate[<?php echo $_currencyCode ?>][<?php echo $_rate ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
+                            <input type="text" name="rate[<?php echo $this->escapeHtml($_currencyCode) ?>][<?php echo $this->escapeHtml($_rate) ?>]" value="<?php echo ( $_currencyCode == $_rate ) ? '1.0000' : ($_value>0 ? $_value : (isset($_oldRates[$_currencyCode][$_rate]) ? $_oldRates[$_currencyCode][$_rate] : '')) ?>" <?php echo ( $_currencyCode == $_rate ) ? 'class="input-text input-text-disabled" readonly="true"' : 'class="input-text"' ?> />
                             <?php if( isset($_newRates)  && $_currencyCode != $_rate && isset($_oldRates[$_currencyCode][$_rate]) ): ?>
                             <br /><span class="old-rate"><?php echo $this->__('Old rate:') ?> <?php echo $_oldRates[$_currencyCode][$_rate] ?></span>
                             <?php endif; ?>
diff --git app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
index 4897e6e5c73..81d138abd94 100644
--- app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
+++ app/design/frontend/enterprise/default/template/giftcardaccount/cart/total.phtml
@@ -36,9 +36,15 @@ if (!$_cards) {
         <th colspan="<?php echo $this->getColspan(); ?>" style="<?php echo $this->getTotal()->getStyle() ?>" class="a-right">
             <?php if ($this->getRenderingArea() == $this->getTotal()->getArea()): ?><strong><?php endif; ?>
                 <?php $_title = $this->__('Remove'); ?>
-                <?php $_url = Mage::getUrl('enterprise_giftcardaccount/cart/remove', array('code'=>$_c['c'])); ?>
-                <a href="<?php echo $_url; ?>" title="<?php echo $_title; ?>" class="btn-remove"><img src="<?php echo $this->getSkinUrl('images/btn_remove.gif') ?>" alt="<?php echo $this->__('Remove')?>" /></a>
-
+                <a title="<?php echo Mage::helper('core')->quoteEscape($_title); ?>"
+                   href="#"
+                   class="btn-remove"
+                   onclick="customFormSubmit(
+                           '<?php echo (Mage::getUrl('enterprise_giftcardaccount/cart/remove')); ?>',
+                           '<?php echo ($this->escapeHtml(json_encode(array('code' => $_c['c'])))); ?>',
+                           'post')">
+                    <img src="<?php echo $this->getSkinUrl('images/btn_remove.gif') ?>" alt="<?php echo $this->__('Remove')?>" />
+                </a>
                 <?php echo $this->__('Gift Card (%s)', $_c['c']); ?>
             <?php if ($this->getRenderingArea() == $this->getTotal()->getArea()): ?></strong><?php endif; ?>
         </th>
diff --git app/design/frontend/enterprise/default/template/rma/return/create.phtml app/design/frontend/enterprise/default/template/rma/return/create.phtml
index 91a561b4d67..6844b6a4f05 100644
--- app/design/frontend/enterprise/default/template/rma/return/create.phtml
+++ app/design/frontend/enterprise/default/template/rma/return/create.phtml
@@ -338,7 +338,17 @@
             <div class="field">
                 <label for="rma_comment"><?php echo $this->__('Comments') ?></label>
                 <div class="input-box">
-                    <textarea id="rma_comment" style="height:6em;" cols="5" rows="3" name="rma_comment" class="input-text"><?php if ($_data): ?><?php echo $_data->getRmaComment(); ?><?php endif; ?></textarea>
+                    <textarea
+                              id="rma_comment"
+                              style="height:6em;"
+                              cols="5"
+                              rows="3"
+                              name="rma_comment"
+                              class="input-text">
+                        <?php if ($_data): ?>
+                            <?php echo Mage::helper('core')->escapeHtml($_data->getRmaComment()); ?>
+                        <?php endif; ?>
+                    </textarea>
                 </div>
             </div>
         </li>
diff --git app/locale/en_US/Mage_Adminhtml.csv app/locale/en_US/Mage_Adminhtml.csv
index 7da11b46303..4fa82d1ccd1 100644
--- app/locale/en_US/Mage_Adminhtml.csv
+++ app/locale/en_US/Mage_Adminhtml.csv
@@ -40,7 +40,7 @@
 "2YTD","2YTD"
 "6 Hours","6 Hours"
 "<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>","<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>"
-"A user with the same user name or email aleady exists.","A user with the same user name or email aleady exists."
+"A user with the same user name or email already exists.","A user with the same user name or email already exists."
 "API Key","API Key"
 "API Key Confirmation","API Key Confirmation"
 "ASCII","ASCII"
@@ -229,6 +229,7 @@
 "Credit memo #%s created","Credit memo #%s created"
 "Credit memo\'s total must be positive.","Credit memo\'s total must be positive."
 "Currency","Currency"
+"Currency doesn\'t exist.","Currency doesn\'t exist."
 "Currency Information","Currency Information"
 "Currency Setup Section","Currency Setup Section"
 "Current Configuration Scope:","Current Configuration Scope:"
@@ -815,6 +816,7 @@
 "Self-assigned roles cannot be deleted.","Self-assigned roles cannot be deleted."
 "Sender","Sender"
 "Separate Email","Separate Email"
+"Serialized data is incorrect","Serialized data is incorrect"
 "Shipment #%s comment added","Shipment #%s comment added"
 "Shipment #%s created","Shipment #%s created"
 "Shipment Comments","Shipment Comments"
@@ -923,6 +925,7 @@
 "The email address is empty.","The email address is empty."
 "The email template has been deleted.","The email template has been deleted."
 "The email template has been saved.","The email template has been saved."
+"Invalid template data.","Invalid template data."
 "The flat catalog category has been rebuilt.","The flat catalog category has been rebuilt."
 "The group node name must be specified with field node name.","The group node name must be specified with field node name."
 "The image cache was cleaned.","The image cache was cleaned."
diff --git app/locale/en_US/Mage_Adminhtml.csv.orig app/locale/en_US/Mage_Adminhtml.csv.orig
deleted file mode 100644
index 09248eca9e8..00000000000
--- app/locale/en_US/Mage_Adminhtml.csv.orig
+++ /dev/null
@@ -1,1130 +0,0 @@
-" The customer does not exist in the system anymore."," The customer does not exist in the system anymore."
-" [deleted]"," [deleted]"
-" and "," and "
-"Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv", "Invalid file extension used for log file. Allowed file extensions: log, txt, html, csv"
-" note that the URLs provided below are the correct values for your current website): "," note that the URLs provided below are the correct values for your current website): "
-"%s (Default Template from Locale)","%s (Default Template from Locale)"
-"%s cache type(s) disabled.","%s cache type(s) disabled."
-"%s cache type(s) enabled.","%s cache type(s) enabled."
-"%s cache type(s) refreshed.","%s cache type(s) refreshed."
-"(For Type ""Local Server"" need to use relative path to Magento install var/export or var/import, e.g. var/export, var/import, var/export/some/dir, var/import/some/dir)","(For Type ""Local Server"" need to use relative path to Magento install var/export or var/import, e.g. var/export, var/import, var/export/some/dir, var/import/some/dir)"
-"(For US 2-letter state names)","(For US 2-letter state names)"
-"(If left empty will be auto-generated)","(If left empty will be auto-generated)"
-"(Leave empty for first spreadsheet)","(Leave empty for first spreadsheet)"
-"(Products will be added/updated to this store if 'store' column is blank or missing in the import file.)","(Products will be added/updated to this store if 'store' column is blank or missing in the import file.)"
-"(Shift-)Click or drag to change value","(Shift-)Click or drag to change value"
-"(Starting with)","(Starting with)"
-"(When 'No', only mapped fields will be imported. When mapping, use 'column1', 'column2', etc.)","(When 'No', only mapped fields will be imported. When mapping, use 'column1', 'column2', etc.)"
-"(You have to increase php memory_limit before changing this value)","(You have to increase php memory_limit before changing this value)"
-"(\\t for tab)","(\\t for tab)"
-"* - If indexing is in progress, it will be killed and new indexing process will start.","* - If indexing is in progress, it will be killed and new indexing process will start."
-"- Click on any of the time parts to increase it","- Click on any of the time parts to increase it"
-"- Hold mouse button on any of the above buttons for faster selection.","- Hold mouse button on any of the above buttons for faster selection."
-"- Use the %s buttons to select month","- Use the %s buttons to select month"
-"- Use the %s, %s buttons to select year","- Use the %s, %s buttons to select year"
-"- or Shift-click to decrease it","- or Shift-click to decrease it"
-"- or click and drag for faster selection.","- or click and drag for faster selection."
-"-- Not Selected --","-- Not Selected --"
-"-- Please Select --","-- Please Select --"
-"-- Please Select Billing Agreement--","-- Please Select Billing Agreement--"
-"-- Please Select a Category --","-- Please Select a Category --"
-"Invalid template path used in layout update.","Invalid template path used in layout update."
-"-- Please select --","-- Please select --"
-"--Please Select--","--Please Select--"
-"1 Hour","1 Hour"
-"12 Hours","12 Hours"
-"12h AM/PM","12h AM/PM"
-"2 Hours","2 Hours"
-"24 Hours","24 Hours"
-"24h","24h"
-"2YTD","2YTD"
-"6 Hours","6 Hours"
-"<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>","<h1 class=""page-heading"">404 Error</h1><p>Page not found.</p>"
-"A user with the same user name or email aleady exists.","A user with the same user name or email aleady exists."
-"API Key","API Key"
-"API Key Confirmation","API Key Confirmation"
-"ASCII","ASCII"
-"Abandoned Carts","Abandoned Carts"
-"About the calendar","About the calendar"
-"Access Denied","Access Denied"
-"Access denied","Access denied"
-"Access denied.","Access denied."
-"Account Created in:","Account Created in:"
-"Account Created on (%s):","Account Created on (%s):"
-"Account Created on:","Account Created on:"
-"Account Information","Account Information"
-"Account Status","Account Status"
-"Account status","Account status"
-"Action","Action"
-"Actions","Actions"
-"Actions XML","Actions XML"
-"Active","Active"
-"Add","Add"
-"Add Exception","Add Exception"
-"Add Field Mapping","Add Field Mapping"
-"Add Field with URL:","Add Field with URL:"
-"Add New","Add New"
-"Add New Image","Add New Image"
-"Add New Profile","Add New Profile"
-"Add New Role","Add New Role"
-"Add New Template","Add New Template"
-"Add New URL Rewrite","Add New URL Rewrite"
-"Add New User","Add New User"
-"Add New Variable","Add New Variable"
-"Add URL Rewrite","Add URL Rewrite"
-"Add URL Rewrite for a Category","Add URL Rewrite for a Category"
-"Add URL Rewrite for a Product","Add URL Rewrite for a Product"
-"Add after","Add after"
-"Additional Cache Management","Additional Cache Management"
-"Address Type:","Address Type:"
-"Admin","Admin"
-"Advanced Admin Section","Advanced Admin Section"
-"Advanced Profiles","Advanced Profiles"
-"Advanced Section","Advanced Section"
-"All","All"
-"All Allowed Countries","All Allowed Countries"
-"All Cache","All Cache"
-"All Files","All Files"
-"All Reviews","All Reviews"
-"All Store Views","All Store Views"
-"All Tags","All Tags"
-"All Websites","All Websites"
-"All countries","All countries"
-"All fields","All fields"
-"All possible rates were fetched, please click on ""Save"" to apply","All possible rates were fetched, please click on ""Save"" to apply"
-"All rates were fetched, please click on ""Save"" to apply","All rates were fetched, please click on ""Save"" to apply"
-"All valid rates have been saved.","All valid rates have been saved."
-"Amounts","Amounts"
-"An error has occured while syncronizing media storages.","An error has occured while syncronizing media storages."
-"An error occurred while clearing the JavaScript/CSS cache.","An error occurred while clearing the JavaScript/CSS cache."
-"An error occurred while clearing the image cache.","An error occurred while clearing the image cache."
-"An error occurred while creating the backup.","An error occurred while creating the backup."
-"An error occurred while deleting URL Rewrite.","An error occurred while deleting URL Rewrite."
-"An error occurred while deleting email template data. Please review log and try again.","An error occurred while deleting email template data. Please review log and try again."
-"An error occurred while deleting record(s).","An error occurred while deleting record(s)."
-"An error occurred while deleting this role.","An error occurred while deleting this role."
-"An error occurred while deleting this set.","An error occurred while deleting this set."
-"An error occurred while deleting this template.","An error occurred while deleting this template."
-"An error occurred while finishing process. Please refresh the cache","An error occurred while finishing process. Please refresh the cache"
-"An error occurred while rebuilding the CatalogInventory Stock Status.","An error occurred while rebuilding the CatalogInventory Stock Status."
-"An error occurred while rebuilding the catalog index.","An error occurred while rebuilding the catalog index."
-"An error occurred while rebuilding the flat catalog category.","An error occurred while rebuilding the flat catalog category."
-"An error occurred while rebuilding the flat product catalog.","An error occurred while rebuilding the flat product catalog."
-"An error occurred while rebuilding the search index.","An error occurred while rebuilding the search index."
-"An error occurred while refreshing the Catalog Rewrites.","An error occurred while refreshing the Catalog Rewrites."
-"An error occurred while refreshing the Layered Navigation indices.","An error occurred while refreshing the Layered Navigation indices."
-"An error occurred while refreshing the catalog rewrites.","An error occurred while refreshing the catalog rewrites."
-"An error occurred while refreshing the layered navigation indices.","An error occurred while refreshing the layered navigation indices."
-"An error occurred while saving URL Rewrite.","An error occurred while saving URL Rewrite."
-"An error occurred while saving account.","An error occurred while saving account."
-"An error occurred while saving review.","An error occurred while saving review."
-"An error occurred while saving the customer.","An error occurred while saving the customer."
-"An error occurred while saving this configuration:","An error occurred while saving this configuration:"
-"An error occurred while saving this role.","An error occurred while saving this role."
-"An error occurred while saving this template.","An error occurred while saving this template."
-"An error occurred while updating the selected review(s).","An error occurred while updating the selected review(s)."
-"Any","Any"
-"Any Attribute Set","Any Attribute Set"
-"Any Group","Any Group"
-"Any Status","Any Status"
-"Any Store","Any Store"
-"Any Type","Any Type"
-"Any Visibility","Any Visibility"
-"Archive file name:","Archive file name:"
-"Are you sure that you want to delete this template?","Are you sure that you want to delete this template?"
-"Are you sure that you want to strip tags?","Are you sure that you want to strip tags?"
-"Are you sure you want to do this?","Are you sure you want to do this?"
-"Area","Area"
-"As low as:","As low as:"
-"Assigned","Assigned"
-"Associated Tags","Associated Tags"
-"Attribute Set Name:","Attribute Set Name:"
-"Attributes","Attributes"
-"Automatic","Automatic"
-"Average Order Amount","Average Order Amount"
-"Average Orders","Average Orders"
-"BINARY","BINARY"
-"Back","Back"
-"Back to Login","Back to Login"
-"Backup","Backup"
-"Backup record was deleted.","Backup record was deleted."
-"Backups","Backups"
-"Base currency","Base currency"
-"Bcc","Bcc"
-"Bestsellers","Bestsellers"
-"Billing Address","Billing Address"
-"Billing Address: ","Billing Address: "
-"Billing Agreement","Billing Agreement"
-"Billing Agreements","Billing Agreements"
-"Block Information","Block Information"
-"Both (without and with tax)","Both (without and with tax)"
-"Both IPN and PDT","Both IPN and PDT"
-"Browse Files...","Browse Files..."
-"Bundle with dynamic pricing cannot include custom defined options. Options will not be saved.","Bundle with dynamic pricing cannot include custom defined options. Options will not be saved."
-"CMS","CMS"
-"CRITICAL","CRITICAL"
-"CSV","CSV"
-"CSV / Tab separated","CSV / Tab separated"
-"Cache Control","Cache Control"
-"Cache Control (beta)","Cache Control (beta)"
-"Cache Management","Cache Management"
-"Cache Type","Cache Type"
-"Cancel","Cancel"
-"Cannot add new comment.","Cannot add new comment."
-"Cannot add tracking number.","Cannot add tracking number."
-"Cannot create an invoice without products.","Cannot create an invoice without products."
-"Cannot create credit memo for the order.","Cannot create credit memo for the order."
-"Cannot delete the design change.","Cannot delete the design change."
-"Cannot delete tracking number.","Cannot delete tracking number."
-"Cannot do shipment for the order separately from invoice.","Cannot do shipment for the order separately from invoice."
-"Cannot do shipment for the order.","Cannot do shipment for the order."
-"Cannot initialize shipment for adding tracking number.","Cannot initialize shipment for adding tracking number."
-"Cannot initialize shipment for delete tracking number.","Cannot initialize shipment for delete tracking number."
-"Cannot load track with retrieving identifier.","Cannot load track with retrieving identifier."
-"Cannot retrieve tracking number detail.","Cannot retrieve tracking number detail."
-"Cannot save a new password.","Cannot save a new password."
-"Cannot save shipment.","Cannot save shipment."
-"Cannot save the credit memo.","Cannot save the credit memo."
-"Cannot send shipment information.","Cannot send shipment information."
-"Cannot update item quantity.","Cannot update item quantity."
-"Cannot update the item\'s quantity.","Cannot update the item\'s quantity."
-"Catalog","Catalog"
-"Catalog Price Rules","Catalog Price Rules"
-"Catalog Rewrites","Catalog Rewrites"
-"Categories","Categories"
-"Category:","Category:"
-"Chart is disabled. If you want to enable chart, click <a href=""%s"">here</a>.","Chart is disabled. If you want to enable chart, click <a href=""%s"">here</a>."
-"Checkbox","Checkbox"
-"Child Transactions","Child Transactions"
-"Choose Store View","Choose Store View"
-"Choose an attribute","Choose an attribute"
-"Chosen category does not associated with any website, so url rewrite is not possible.","Chosen category does not associated with any website, so url rewrite is not possible."
-"Chosen product does not associated with any website, so url rewrite is not possible.","Chosen product does not associated with any website, so url rewrite is not possible."
-"Clear","Clear"
-"Close","Close"
-"Comment text field cannot be empty.","Comment text field cannot be empty."
-"Complete","Complete"
-"Configuration","Configuration"
-"Confirm New Password","Confirm New Password"
-"Confirmed email:","Confirmed email:"
-"Connect with the Magento Community","Connect with the Magento Community"
-"Continue","Continue"
-"Convert to Plain Text","Convert to Plain Text"
-"Cookie (unsafe)","Cookie (unsafe)"
-"Country","Country"
-"Country:","Country:"
-"Coupons","Coupons"
-"Create","Create"
-"Create DB Backup","Create DB Backup"
-"Create New Attribute","Create New Attribute"
-"Create URL Rewrite:","Create URL Rewrite:"
-"Created At","Created At"
-"Credit Card %s","Credit Card %s"
-"Credit Memo History","Credit Memo History"
-"Credit Memo Totals","Credit Memo Totals"
-"Credit Memos","Credit Memos"
-"Credit memo #%s comment added","Credit memo #%s comment added"
-"Credit memo #%s created","Credit memo #%s created"
-"Credit memo\'s total must be positive.","Credit memo\'s total must be positive."
-"Currency","Currency"
-"Currency Information","Currency Information"
-"Currency Setup Section","Currency Setup Section"
-"Current Configuration Scope:","Current Configuration Scope:"
-"Current Month","Current Month"
-"Custom","Custom"
-"Custom Variable ""%s""","Custom Variable ""%s"""
-"Custom Variables","Custom Variables"
-"Customer","Customer"
-"Customer Group:","Customer Group:"
-"Customer Groups","Customer Groups"
-"Customer Name","Customer Name"
-"Customer Reviews","Customer Reviews"
-"Customer Shopping Carts","Customer Shopping Carts"
-"Customer Since:","Customer Since:"
-"Customer Tax Classes","Customer Tax Classes"
-"Customer with the same email already exists.","Customer with the same email already exists."
-"Customers","Customers"
-"Customers by Number of Orders","Customers by Number of Orders"
-"Customers by Orders Total","Customers by Orders Total"
-"DHTML Date/Time Selector","DHTML Date/Time Selector"
-"Dashboard","Dashboard"
-"Data Format","Data Format"
-"Data transfer:","Data transfer:"
-"Database","Database"
-"Dataflow - Advanced Profiles","Dataflow - Advanced Profiles"
-"Dataflow - Profiles","Dataflow - Profiles"
-"Date","Date"
-"Date & Time","Date & Time"
-"Date Added","Date Added"
-"Date Updated","Date Updated"
-"Date selection:","Date selection:"
-"Date selector","Date selector"
-"Day","Day"
-"Decimal separator:","Decimal separator:"
-"Default (Admin) Values","Default (Admin) Values"
-"Default Billing Address","Default Billing Address"
-"Default Config","Default Config"
-"Default Template from Locale","Default Template from Locale"
-"Default Values","Default Values"
-"Default display currency ""%s"" is not available in allowed currencies.","Default display currency ""%s"" is not available in allowed currencies."
-"Default scope","Default scope"
-"Delete","Delete"
-"Delete %s","Delete %s"
-"Delete %s '%s'","Delete %s '%s'"
-"Delete File","Delete File"
-"Delete Image","Delete Image"
-"Delete Profile","Delete Profile"
-"Delete Role","Delete Role"
-"Delete Store","Delete Store"
-"Delete Store View","Delete Store View"
-"Delete Template","Delete Template"
-"Delete User","Delete User"
-"Delete Website","Delete Website"
-"Description","Description"
-"Design","Design"
-"Design Section","Design Section"
-"Details","Details"
-"Developer Section","Developer Section"
-"Direction:","Direction:"
-"Disable","Disable"
-"Disabled","Disabled"
-"Display %s first","Display %s first"
-"Display default currency","Display default currency"
-"Distributed under GNU LGPL. See %s for details.","Distributed under GNU LGPL. See %s for details."
-"Do not enable AVS or CSC options.  The do not work when using Payflow Link Silent Mode.","Do not enable AVS or CSC options.  The do not work when using Payflow Link Silent Mode."
-"Do not set any fields in the Billing and Shipping Information block as editable in your Payflow account.","Do not set any fields in the Billing and Shipping Information block as editable in your Payflow account."
-"Do you really want to KILL parallel process and start new indexing process?","Do you really want to KILL parallel process and start new indexing process?"
-"Download","Download"
-"Downloads","Downloads"
-"Drag to move","Drag to move"
-"Drop-down","Drop-down"
-"Edit","Edit"
-"Edit Design Change","Edit Design Change"
-"Edit Email Template","Edit Email Template"
-"Edit Poll","Edit Poll"
-"Edit Queue","Edit Queue"
-"Edit Review","Edit Review"
-"Edit Role","Edit Role"
-"Edit Store View","Edit Store View"
-"Edit System Template","Edit System Template"
-"Edit Template","Edit Template"
-"Edit URL Rewrite","Edit URL Rewrite"
-"Edit User","Edit User"
-"Edit User '%s'","Edit User '%s'"
-"Edit Website","Edit Website"
-"Email","Email"
-"Email Address:","Email Address:"
-"Email Preview","Email Preview"
-"Email to a Friend","Email to a Friend"
-"Email:","Email:"
-"Enable","Enable"
-"Enable Secure Token:","Enable Secure Token:"
-"Enabled","Enabled"
-"Enclose Values In:","Enclose Values In:"
-"Entity Attributes","Entity Attributes"
-"Entity Type","Entity Type"
-"Entity type:","Entity type:"
-"Error","Error"
-"Error URL: ","Error URL: "
-"Excel XML","Excel XML"
-"Excl. Tax","Excl. Tax"
-"Export","Export"
-"Export CSV","Export CSV"
-"Export Filters","Export Filters"
-"Export to:","Export to:"
-"Export:","Export:"
-"FTP Host[:Port]","FTP Host[:Port]"
-"Failed to add a product to cart by id ""%s"".","Failed to add a product to cart by id ""%s""."
-"Failed to cancel the billing agreement.","Failed to cancel the billing agreement."
-"Failed to clear the JavaScript/CSS cache.","Failed to clear the JavaScript/CSS cache."
-"Failed to delete the billing agreement.","Failed to delete the billing agreement."
-"Failed to update the profile.","Failed to update the profile."
-"Field","Field"
-"Field Mapping","Field Mapping"
-"File","File"
-"File Information","File Information"
-"File System","File System"
-"File mode","File mode"
-"File name:","File name:"
-"File size should be more than 0 bytes","File size should be more than 0 bytes"
-"Finished profile execution.","Finished profile execution."
-"First Invoice Created Date","First Invoice Created Date"
-"First Name","First Name"
-"First Name is required field.","First Name is required field."
-"First Name:","First Name:"
-"Fixed","Fixed"
-"Flush Catalog Images Cache","Flush Catalog Images Cache"
-"Flush JavaScript/CSS Cache","Flush JavaScript/CSS Cache"
-"For category","For category"
-"For latest version visit: %s","For latest version visit: %s"
-"For product","For product"
-"Forgot Admin Password","Forgot Admin Password"
-"Forgot your password?","Forgot your password?"
-"Forgot your user name or password?","Forgot your user name or password?"
-"From","From"
-"GLOBAL","GLOBAL"
-"Gb","Gb"
-"General Information","General Information"
-"General Section","General Section"
-"Get Image Base64","Get Image Base64"
-"Get help for this page","Get help for this page"
-"Global Attribute","Global Attribute"
-"Global Record Search","Global Record Search"
-"Global Search","Global Search"
-"Go Today","Go Today"
-"Go to messages inbox","Go to messages inbox"
-"Go to notifications","Go to notifications"
-"Google Base","Google Base"
-"Google Sitemaps","Google Sitemaps"
-"Grand Total","Grand Total"
-"Grid (default) / List","Grid (default) / List"
-"Grid Only","Grid Only"
-"Group:","Group:"
-"Guest","Guest"
-"HTTP (unsecure)","HTTP (unsecure)"
-"HTTPS (SSL)","HTTPS (SSL)"
-"Help Us Keep Magento Healthy - Report All Bugs","Help Us Keep Magento Healthy - Report All Bugs"
-"Helper attributes should not be used in custom layout updates.","Helper attributes should not be used in custom layout updates."
-"Helper for options rendering doesn't implement required interface.","Helper for options rendering doesn't implement required interface."
-"Home","Home"
-"ID","ID"
-"ID Path","ID Path"
-"IP Address","IP Address"
-"IPN (Instant Payment Notification) Only","IPN (Instant Payment Notification) Only"
-"If there is an account associated with %s you will receive an email with a link to reset your password.","If there is an account associated with %s you will receive an email with a link to reset your password."
-"If this message persists, please contact the store owner.","If this message persists, please contact the store owner."
-"If your Magento instance is used for multiple websites, you must configure a separate Payflow Link account for each website.","If your Magento instance is used for multiple websites, you must configure a separate Payflow Link account for each website."
-"Images (.gif, .jpg, .png)","Images (.gif, .jpg, .png)"
-"Images Cache","Images Cache"
-"Import","Import"
-"Import Service","Import Service"
-"Import and Export","Import and Export"
-"Import and Export Tax Rates","Import and Export Tax Rates"
-"Import/Export","Import/Export"
-"Import/Export Advanced","Import/Export Advanced"
-"Import/Export Profile","Import/Export Profile"
-"Important: ","Important: "
-"Imported <strong>%s</strong> records","Imported <strong>%s</strong> records"
-"In","In"
-"In Database:","In Database:"
-"In File:","In File:"
-"Inactive","Inactive"
-"Incl. Tax","Incl. Tax"
-"Incoming Message","Incoming Message"
-"Insert Variable...","Insert Variable..."
-"Interactive","Interactive"
-"Interface Locale: %s","Interface Locale: %s"
-"Invalid Form Key. Please refresh the page.","Invalid Form Key. Please refresh the page."
-"Invalid Import Service Specified","Invalid Import Service Specified"
-"Invalid POST data (please check post_max_size and upload_max_filesize settings in your php.ini file).","Invalid POST data (please check post_max_size and upload_max_filesize settings in your php.ini file)."
-"Invalid Secret Key. Please refresh the page.","Invalid Secret Key. Please refresh the page."
-"Invalid Username or Password.","Invalid Username or Password."
-"Invalid directory: %s","Invalid directory: %s"
-"Invalid email address ""%s"".","Invalid email address ""%s""."
-"Invalid file: %s","Invalid file: %s"
-"Invalid input data for %s => %s rate","Invalid input data for %s => %s rate"
-"Invalid parent block for this block","Invalid parent block for this block"
-"Invalid parent block for this block.","Invalid parent block for this block."
-"Invalid password reset token.","Invalid password reset token."
-"Invalid sender name ""%s"". Please use only visible characters and spaces.","Invalid sender name ""%s"". Please use only visible characters and spaces."
-"Invalid timezone","Invalid timezone"
-"Invalidated","Invalidated"
-"Inventory Stock Status","Inventory Stock Status"
-"Invoice #%s comment added","Invoice #%s comment added"
-"Invoice #%s created","Invoice #%s created"
-"Invoice History","Invoice History"
-"Invoice Totals","Invoice Totals"
-"Invoice canceling error.","Invoice canceling error."
-"Invoice capturing error.","Invoice capturing error."
-"Invoice voiding error.","Invoice voiding error."
-"Invoices","Invoices"
-"Is Closed","Is Closed"
-"Issue Number","Issue Number"
-"Items","Items"
-"JavaScript/CSS","JavaScript/CSS"
-"JavaScript/CSS Cache","JavaScript/CSS Cache"
-"Kb","Kb"
-"Last 24 Hours","Last 24 Hours"
-"Last 5 Orders","Last 5 Orders"
-"Last 5 Search Terms","Last 5 Search Terms"
-"Last 7 Days","Last 7 Days"
-"Last Credit Memo Created Date","Last Credit Memo Created Date"
-"Last Invoice Created Date","Last Invoice Created Date"
-"Last Logged In (%s):","Last Logged In (%s):"
-"Last Logged In:","Last Logged In:"
-"Last Name","Last Name"
-"Last Name is required field.","Last Name is required field."
-"Last Name:","Last Name:"
-"Last updated: %s. To refresh last day\'s <a href=""%s"">statistics</a>, click <a href=""%s"">here</a>.","Last updated: %s. To refresh last day\'s <a href=""%s"">statistics</a>, click <a href=""%s"">here</a>."
-"Latest Message:","Latest Message:"
-"Layered Navigation Indices","Layered Navigation Indices"
-"Layered Navigation Indices were refreshed.","Layered Navigation Indices were refreshed."
-"Leave empty to use tax identifier","Leave empty to use tax identifier"
-"Lifetime Sales","Lifetime Sales"
-"Lifetime statistics have been updated.","Lifetime statistics have been updated."
-"Links","Links"
-"Links with associated products will retain only after saving current product.","Links with associated products will retain only after saving current product."
-"List (default) / Grid","List (default) / Grid"
-"List Only","List Only"
-"Load Template","Load Template"
-"Load default template","Load default template"
-"Loading...","Loading..."
-"Local Server","Local Server"
-"Local/Remote Server","Local/Remote Server"
-"Locale","Locale"
-"Log Out","Log Out"
-"Log in to Admin Panel","Log in to Admin Panel"
-"Log into Magento Admin Page","Log into Magento Admin Page"
-"Logged in as %s","Logged in as %s"
-"Login","Login"
-"Low Stock","Low Stock"
-"MAJOR","MAJOR"
-"MINOR","MINOR"
-"MS Excel XML","MS Excel XML"
-"Magento Admin","Magento Admin"
-"Magento Commerce - Administrative Panel","Magento Commerce - Administrative Panel"
-"Magento Connect","Magento Connect"
-"Magento Connect Manager","Magento Connect Manager"
-"Magento Logo","Magento Logo"
-"Magento is a trademark of Magento Inc. Copyright &copy; %s Magento Inc.","Magento is a trademark of Magento Inc. Copyright &copy; %s Magento Inc."
-"Magento ver. %s","Magento ver. %s"
-"Magento&trade; is a trademark of Magento Inc.<br/>Copyright &copy; %s Magento Inc.","Magento&trade; is a trademark of Magento Inc.<br/>Copyright &copy; %s Magento Inc."
-"Make sure that data encoding in the file is consistent and saved in one of supported encodings (UTF-8 or ANSI).","Make sure that data encoding in the file is consistent and saved in one of supported encodings (UTF-8 or ANSI)."
-"Manage Attribute Sets","Manage Attribute Sets"
-"Manage Attributes","Manage Attributes"
-"Manage Categories","Manage Categories"
-"Manage Content","Manage Content"
-"Manage Currency Rates","Manage Currency Rates"
-"Manage Customers","Manage Customers"
-"Manage Ratings","Manage Ratings"
-"Manage Stores","Manage Stores"
-"Manage Tax Rules","Manage Tax Rules"
-"Manage Tax Zones and Rates","Manage Tax Zones and Rates"
-"Manual","Manual"
-"Matched Expression","Matched Expression"
-"Mb","Mb"
-"Media (.avi, .flv, .swf)","Media (.avi, .flv, .swf)"
-"Media storages synchronization has completed!","Media storages synchronization has completed!"
-"Messages Inbox","Messages Inbox"
-"Month","Month"
-"Most Viewed","Most Viewed"
-"Most Viewed Products","Most Viewed Products"
-"Multiple Select","Multiple Select"
-"My Account","My Account"
-"N/A","N/A"
-"NOTICE","NOTICE"
-"Name","Name"
-"Name:","Name:"
-"New ","New "
-"New API Key","New API Key"
-"New Accounts","New Accounts"
-"New Attribute","New Attribute"
-"New Block","New Block"
-"New Category","New Category"
-"New Class","New Class"
-"New Condition","New Condition"
-"New Custom Variable","New Custom Variable"
-"New Customer","New Customer"
-"New Customers","New Customers"
-"New Design Change","New Design Change"
-"New Email Template","New Email Template"
-"New Group","New Group"
-"New Invoice","New Invoice"
-"New Item Type","New Item Type"
-"New Memo","New Memo"
-"New Memo for #%s","New Memo for #%s"
-"New Page","New Page"
-"New Password","New Password"
-"New Poll","New Poll"
-"New Profile","New Profile"
-"New Rate","New Rate"
-"New Rating","New Rating"
-"New Review","New Review"
-"New Role","New Role"
-"New Rule","New Rule"
-"New Search","New Search"
-"New Set","New Set"
-"New Shipment","New Shipment"
-"New Sitemap","New Sitemap"
-"New Store View","New Store View"
-"New System Template","New System Template"
-"New Tag","New Tag"
-"New Template","New Template"
-"New User","New User"
-"New Variable","New Variable"
-"New Website","New Website"
-"New password field cannot be empty.","New password field cannot be empty."
-"Newsletter","Newsletter"
-"Newsletter Problems","Newsletter Problems"
-"Newsletter Queue","Newsletter Queue"
-"Newsletter Subscribers","Newsletter Subscribers"
-"Newsletter Templates","Newsletter Templates"
-"Next month (hold for menu)","Next month (hold for menu)"
-"Next year (hold for menu)","Next year (hold for menu)"
-"No","No"
-"No (price without tax)","No (price without tax)"
-"No Data","No Data"
-"No Data Found","No Data Found"
-"No Templates Found","No Templates Found"
-"No change","No change"
-"No customer id defined.","No customer id defined."
-"No information available.","No information available."
-"No profile loaded...","No profile loaded..."
-"No records found for this period.","No records found for this period."
-"No records found.","No records found."
-"No report code specified.","No report code specified."
-"No search keywords.","No search keywords."
-"No search modules were registered","No search modules were registered"
-"No wishlist item id defined.","No wishlist item id defined."
-"None","None"
-"Note:","Note:"
-"Notes","Notes"
-"Notifications","Notifications"
-"Number of Orders","Number of Orders"
-"Number of Uses","Number of Uses"
-"Number of records:","Number of records:"
-"Old rate:","Old rate:"
-"On my website","On my website"
-"Once you log into your Payflow Link account, navigate to the Service Settings - Hosted Checkout Pages - Set Up menu and set the options described below","Once you log into your Payflow Link account, navigate to the Service Settings - Hosted Checkout Pages - Set Up menu and set the options described below"
-"One or more media files failed to be synchronized during the media storages syncronization process. Refer to the log file for details.","One or more media files failed to be synchronized during the media storages syncronization process. Refer to the log file for details."
-"One or more of the Cache Types are invalidated:","One or more of the Cache Types are invalidated:"
-"Online Customers","Online Customers"
-"Only attributes with scope ""Global"", input type ""Dropdown"" and Use To Create Configurable Product ""Yes"" are available.","Only attributes with scope ""Global"", input type ""Dropdown"" and Use To Create Configurable Product ""Yes"" are available."
-"Only mapped fields","Only mapped fields"
-"Optional","Optional"
-"Options","Options"
-"Order","Order"
-"Order #%s","Order #%s"
-"Order #%s (%s)","Order #%s (%s)"
-"Order Created Date","Order Created Date"
-"Order ID","Order ID"
-"Order Totals","Order Totals"
-"Order Updated Date","Order Updated Date"
-"Order Updated Date report is real-time, does not need statistics refreshing.","Order Updated Date report is real-time, does not need statistics refreshing."
-"Orders","Orders"
-"Original Magento attribute names in first row:","Original Magento attribute names in first row:"
-"Out of stock","Out of stock"
-"PDT (Payment Data Transfer) Only","PDT (Payment Data Transfer) Only"
-"Package Extensions","Package Extensions"
-"Pages","Pages"
-"Parent Product Thumbnail","Parent Product Thumbnail"
-"Parent Transaction ID","Parent Transaction ID"
-"Passive mode","Passive mode"
-"Password","Password"
-"Password Confirmation","Password Confirmation"
-"Password confirmation must be same as password.","Password confirmation must be same as password."
-"Password must be at least of %d characters.","Password must be at least of %d characters."
-"Password must include both numeric and alphabetic characters.","Password must include both numeric and alphabetic characters."
-"Password:","Password:"
-"Path:","Path:"
-"Payment method instance is not available.","Payment method instance is not available."
-"Payment method is not available.","Payment method is not available."
-"Payment method must be specified.","Payment method must be specified."
-"Pending Reviews","Pending Reviews"
-"Pending Tags","Pending Tags"
-"Per Item","Per Item"
-"Per Order","Per Order"
-"Percent","Percent"
-"Performed At","Performed At"
-"Period","Period"
-"Permanent (301)","Permanent (301)"
-"Permissions","Permissions"
-"Personal Information","Personal Information"
-"Phone:","Phone:"
-"Please Select","Please Select"
-"Please confirm site switching. All data that hasn\'t been saved will be lost.","Please confirm site switching. All data that hasn\'t been saved will be lost."
-"Please enter 6 or more characters.","Please enter 6 or more characters."
-"Please enter a number greater than 0 in this field.","Please enter a number greater than 0 in this field."
-"Please enter a valid $ amount. For example $100.00.","Please enter a valid $ amount. For example $100.00."
-"Please enter a valid URL. For example http://www.example.com or www.example.com","Please enter a valid URL. For example http://www.example.com or www.example.com"
-"Please enter a valid URL. http:// is required","Please enter a valid URL. http:// is required"
-"Please enter a valid credit card number.","Please enter a valid credit card number."
-"Please enter a valid date.","Please enter a valid date."
-"Please enter a valid email address. For example johndoe@domain.com.","Please enter a valid email address. For example johndoe@domain.com."
-"Please enter a valid email.","Please enter a valid email."
-"Please enter a valid number in this field.","Please enter a valid number in this field."
-"Please enter a valid phone number. For example (123) 456-7890 or 123-456-7890.","Please enter a valid phone number. For example (123) 456-7890 or 123-456-7890."
-"Please enter a valid social security number. For example 123-45-6789.","Please enter a valid social security number. For example 123-45-6789."
-"Please enter a valid value from list","Please enter a valid value from list"
-"Please enter a valid value, ex: 10,20,30","Please enter a valid value, ex: 10,20,30"
-"Please enter a valid zip code.","Please enter a valid zip code."
-"Please enter a valid zip code. For example 90602 or 90602-1234.","Please enter a valid zip code. For example 90602 or 90602-1234."
-"Please enter another credit card number to complete your purchase.","Please enter another credit card number to complete your purchase."
-"Please enter valid password.","Please enter valid password."
-"Please make sure that all global admin search modules are installed and activated.","Please make sure that all global admin search modules are installed and activated."
-"Please make sure that your changes were saved before running the profile.","Please make sure that your changes were saved before running the profile."
-"Please make sure your passwords match.","Please make sure your passwords match."
-"Please navigate to <strong>Hosted Checkout Pages - Customize</strong> menu and select Layout C.","Please navigate to <strong>Hosted Checkout Pages - Customize</strong> menu and select Layout C."
-"Please select State/Province.","Please select State/Province."
-"Please select a customer.","Please select a customer."
-"Please select a store.","Please select a store."
-"Please select an option.","Please select an option."
-"Please select catalog searches.","Please select catalog searches."
-"Please select customer(s).","Please select customer(s)."
-"Please select message(s).","Please select message(s)."
-"Please select one of the above options.","Please select one of the above options."
-"Please select one of the options.","Please select one of the options."
-"Please select review(s).","Please select review(s)."
-"Please select tag(s).","Please select tag(s)."
-"Please specify at least start or end date.","Please specify at least start or end date."
-"Please specify the admin custom URL.","Please specify the admin custom URL."
-"Please try to logout and sign in again.","Please try to logout and sign in again."
-"Please use in this field only ""a-z,0-9,_"".","Please use in this field only ""a-z,0-9,_""."
-"Please use letters only (a-z) in this field.","Please use letters only (a-z) in this field."
-"Please use numbers only in this field. Please avoid spaces or other characters such as dots or commas.","Please use numbers only in this field. Please avoid spaces or other characters such as dots or commas."
-"Please use only letters (a-z) or numbers (0-9) only in this field. No spaces or other characters are allowed.","Please use only letters (a-z) or numbers (0-9) only in this field. No spaces or other characters are allowed."
-"Please use only letters (a-z) or numbers (0-9) or spaces and # only in this field.","Please use only letters (a-z) or numbers (0-9) or spaces and # only in this field."
-"Please use this date format: dd/mm/yyyy. For example 17/03/2006 for the 17th of March, 2006.","Please use this date format: dd/mm/yyyy. For example 17/03/2006 for the 17th of March, 2006."
-"Please wait while the indexes are being refreshed.","Please wait while the indexes are being refreshed."
-"Please wait, loading...","Please wait, loading..."
-"Please wait...","Please wait..."
-"Please, add some answers to this poll first.","Please, add some answers to this poll first."
-"Please, select ""Visible in Stores"" for this poll first.","Please, select ""Visible in Stores"" for this poll first."
-"Poll Manager","Poll Manager"
-"Polls","Polls"
-"Popular","Popular"
-"Position of Watermark for %s","Position of Watermark for %s"
-"Pregenerated product images files.","Pregenerated product images files."
-"Prev. month (hold for menu)","Prev. month (hold for menu)"
-"Prev. year (hold for menu)","Prev. year (hold for menu)"
-"Preview","Preview"
-"Preview Template","Preview Template"
-"Price alert subscription was saved.","Price alert subscription was saved."
-"Price:","Price:"
-"Processed <strong>%s%% %s/%d</strong> records","Processed <strong>%s%% %s/%d</strong> records"
-"Product","Product"
-"Product Reviews","Product Reviews"
-"Product Tax Classes","Product Tax Classes"
-"Product Thumbnail Itself","Product Thumbnail Itself"
-"Product is not loaded.","Product is not loaded."
-"Product:","Product:"
-"Products","Products"
-"Products Bestsellers Report","Products Bestsellers Report"
-"Products Ordered","Products Ordered"
-"Products in Carts","Products in Carts"
-"Profile Action","Profile Action"
-"Profile Actions XML","Profile Actions XML"
-"Profile Direction","Profile Direction"
-"Profile History","Profile History"
-"Profile Information","Profile Information"
-"Profile Name","Profile Name"
-"Profile Payments","Profile Payments"
-"Profile Schedule","Profile Schedule"
-"Profile Wizard","Profile Wizard"
-"Profiles","Profiles"
-"Promo","Promo"
-"Promotions","Promotions"
-"Purchased Item","Purchased Item"
-"Quantity","Quantity"
-"Queue Refresh","Queue Refresh"
-"Queued... Cancel","Queued... Cancel"
-"Radio Buttons","Radio Buttons"
-"Rates","Rates"
-"Read details","Read details"
-"Rebuild","Rebuild"
-"Rebuild Catalog Index","Rebuild Catalog Index"
-"Rebuild Flat Catalog Category","Rebuild Flat Catalog Category"
-"Rebuild Flat Catalog Product","Rebuild Flat Catalog Product"
-"Recent Orders","Recent Orders"
-"Recent statistics have been updated.","Recent statistics have been updated."
-"Recurring Profile View","Recurring Profile View"
-"Recursive Dir","Recursive Dir"
-"Redirect","Redirect"
-"Reference","Reference"
-"Reference ID","Reference ID"
-"Refresh","Refresh"
-"Refresh Now*","Refresh Now*"
-"Refresh Statistics","Refresh Statistics"
-"Region/State","Region/State"
-"Regular Price:","Regular Price:"
-"Release","Release"
-"Release Stability","Release Stability"
-"Release Version","Release Version"
-"Remote FTP","Remote FTP"
-"Remove","Remove"
-"Reports","Reports"
-"Request Path","Request Path"
-"Required","Required"
-"Required settings","Required settings"
-"Reset","Reset"
-"Reset Filter","Reset Filter"
-"Reset Password","Reset Password"
-"Reset a Password","Reset a Password"
-"Resize","Resize"
-"Resource Access","Resource Access"
-"Resources","Resources"
-"Results","Results"
-"Retrieve Password","Retrieve Password"
-"Return Html Version","Return Html Version"
-"Return URL: ","Return URL: "
-"Revenue","Revenue"
-"Reviews","Reviews"
-"Reviews and Ratings","Reviews and Ratings"
-"Rewrite Rules","Rewrite Rules"
-"Role ID","Role ID"
-"Role Info","Role Info"
-"Role Information","Role Information"
-"Role Name","Role Name"
-"Role Resources","Role Resources"
-"Role Users","Role Users"
-"Roles","Roles"
-"Roles Resources","Roles Resources"
-"Rotate CCW","Rotate CCW"
-"Rotate CW","Rotate CW"
-"Run","Run"
-"Run Profile","Run Profile"
-"Run Profile Inside This Window","Run Profile Inside This Window"
-"Run Profile in Popup","Run Profile in Popup"
-"Running... Kill","Running... Kill"
-"SKU","SKU"
-"SKU:","SKU:"
-"SSL Error: Invalid or self-signed certificate","SSL Error: Invalid or self-signed certificate"
-"Sales","Sales"
-"Sales Report","Sales Report"
-"Samples","Samples"
-"Save","Save"
-"Save & Generate","Save & Generate"
-"Save Account","Save Account"
-"Save Cache Settings","Save Cache Settings"
-"Save Config","Save Config"
-"Save Currency Rates","Save Currency Rates"
-"Save Profile","Save Profile"
-"Save Role","Save Role"
-"Save Template","Save Template"
-"Save User","Save User"
-"Save and Continue Edit","Save and Continue Edit"
-"Search","Search"
-"Search Index","Search Index"
-"Search Term","Search Term"
-"Search Terms","Search Terms"
-"Select","Select"
-"Select $0 Auth if your credit card processor supports $0 Auth capability and Reference Transactions, or if you are unsure what to select.  This setting provides the best experience for shoppers.","Select $0 Auth if your credit card processor supports $0 Auth capability and Reference Transactions, or if you are unsure what to select.  This setting provides the best experience for shoppers."
-"Select $1 Auth if your credit card processor does not support $0 Auth, but does support Reference Transactions. This will provide a very good shopper experience, but might require you to pay a small additional authorization fee from your merchant account provider for any cart abandoned after payment details are entered.  If you select $0 Auth, but your credit card processor does not support $0 Auth, your transaction will run as a $1 Auth instead.","Select $1 Auth if your credit card processor does not support $0 Auth, but does support Reference Transactions. This will provide a very good shopper experience, but might require you to pay a small additional authorization fee from your merchant account provider for any cart abandoned after payment details are entered.  If you select $0 Auth, but your credit card processor does not support $0 Auth, your transaction will run as a $1 Auth instead."
-"Select All","Select All"
-"Select Category","Select Category"
-"Select Date","Select Date"
-"Select Full Auth if you want to minimize your credit card processing fees, or if your credit card processor does not permit reference transactions.  Please note that in some cases, shoppers who abandon your cart late in the process may find that there is a payment authorization outstanding from your company, which will go away on its own in a few days/weeks. This authorization can be reversal by voiding it, however, there is no guarantee the card-issuing bank will accept this request.","Select Full Auth if you want to minimize your credit card processing fees, or if your credit card processor does not permit reference transactions.  Please note that in some cases, shoppers who abandon your cart late in the process may find that there is a payment authorization outstanding from your company, which will go away on its own in a few days/weeks. This authorization can be reversal by voiding it, however, there is no guarantee the card-issuing bank will accept this request."
-"Select Range","Select Range"
-"Select date","Select date"
-"Selected allowed currency ""%s"" is not available in installed currencies.","Selected allowed currency ""%s"" is not available in installed currencies."
-"Selected base currency is not available in installed currencies.","Selected base currency is not available in installed currencies."
-"Selected default display currency is not available in allowed currencies.","Selected default display currency is not available in allowed currencies."
-"Selected default display currency is not available in installed currencies.","Selected default display currency is not available in installed currencies."
-"Self-assigned roles cannot be deleted.","Self-assigned roles cannot be deleted."
-"Sender","Sender"
-"Separate Email","Separate Email"
-"Shipment #%s comment added","Shipment #%s comment added"
-"Shipment #%s created","Shipment #%s created"
-"Shipment Comments","Shipment Comments"
-"Shipment History","Shipment History"
-"Shipments","Shipments"
-"Shipping","Shipping"
-"Shipping Address","Shipping Address"
-"Shipping Address: ","Shipping Address: "
-"Shipping Origin","Shipping Origin"
-"Shipping Price","Shipping Price"
-"Shipping address selection is not applicable","Shipping address selection is not applicable"
-"Shipping method must be specified.","Shipping method must be specified."
-"Shipping method selection is not applicable","Shipping method selection is not applicable"
-"Shopping Cart","Shopping Cart"
-"Shopping Cart Price Rules","Shopping Cart Price Rules"
-"Shopping Cart from %s","Shopping Cart from %s"
-"Show By","Show By"
-"Show Report For","Show Report For"
-"Show Reviews","Show Reviews"
-"Show confirmation page: ","Show confirmation page: "
-"Silent Post URL:","Silent Post URL:"
-"Sitemap Information","Sitemap Information"
-"Size for %s","Size for %s"
-"Skip Category Selection","Skip Category Selection"
-"Some items in this order have different invoice and shipment types. You can create shipment only after the invoice is created.","Some items in this order have different invoice and shipment types. You can create shipment only after the invoice is created."
-"Some of the ordered items do not exist in the catalog anymore and will be removed if you try to edit the order.","Some of the ordered items do not exist in the catalog anymore and will be removed if you try to edit the order."
-"Sorry, this feature is coming soon...","Sorry, this feature is coming soon..."
-"Special Price:","Special Price:"
-"Specific Countries","Specific Countries"
-"Specified","Specified"
-"Specified profile does not exist.","Specified profile does not exist."
-"Spreadsheet Name:","Spreadsheet Name:"
-"Start Date","Start Date"
-"Starting profile execution, please wait...","Starting profile execution, please wait..."
-"State/Province:","State/Province:"
-"Static Blocks","Static Blocks"
-"Status","Status"
-"Status:","Status:"
-"Stock Quantity:","Stock Quantity:"
-"Stock notification was saved.","Stock notification was saved."
-"Store","Store"
-"Store Email Addresses Section","Store Email Addresses Section"
-"Store View","Store View"
-"Store:","Store:"
-"Stores","Stores"
-"Subject","Subject"
-"Submit","Submit"
-"Subpackage cannot be conflicting.","Subpackage cannot be conflicting."
-"Subtotal","Subtotal"
-"Switch/Solo/Maestro Only","Switch/Solo/Maestro Only"
-"Synchronization is required.","Synchronization is required."
-"Synchronization of media storages has been successfully completed.","Synchronization of media storages has been successfully completed."
-"Synchronize","Synchronize"
-"Synchronizing %s to %s","Synchronizing %s to %s"
-"Synchronizing...","Synchronizing..."
-"System","System"
-"System Section","System Section"
-"System busy","System busy"
-"Tags","Tags"
-"Target Path","Target Path"
-"Tax","Tax"
-"Tb","Tb"
-"Template","Template"
-"Template Content","Template Content"
-"Template Information","Template Information"
-"Template Name","Template Name"
-"Template Styles","Template Styles"
-"Template Subject","Template Subject"
-"Template Type","Template Type"
-"Temporary (302)","Temporary (302)"
-"Terms and Conditions","Terms and Conditions"
-"Text","Text"
-"The Catalog Rewrites were refreshed.","The Catalog Rewrites were refreshed."
-"The CatalogInventory Stock Status has been rebuilt.","The CatalogInventory Stock Status has been rebuilt."
-"The Comment Text field cannot be empty.","The Comment Text field cannot be empty."
-"The Flat Catalog Product was rebuilt","The Flat Catalog Product was rebuilt"
-"The JavaScript/CSS cache has been cleaned.","The JavaScript/CSS cache has been cleaned."
-"The JavaScript/CSS cache has been cleared.","The JavaScript/CSS cache has been cleared."
-"The Layered Navigation indexing has been queued.","The Layered Navigation indexing has been queued."
-"The Layered Navigation indexing queue has been canceled.","The Layered Navigation indexing queue has been canceled."
-"The Layered Navigation indices were refreshed.","The Layered Navigation indices were refreshed."
-"The Layered Navigation process has been queued to be killed.","The Layered Navigation process has been queued to be killed."
-"The Magento cache storage has been flushed.","The Magento cache storage has been flushed."
-"The URL Rewrite has been deleted.","The URL Rewrite has been deleted."
-"The URL Rewrite has been saved.","The URL Rewrite has been saved."
-"The account has been saved.","The account has been saved."
-"The archive can be uncompressed with <a href=""%s"">%s</a> on Windows systems","The archive can be uncompressed with <a href=""%s"">%s</a> on Windows systems"
-"The attribute set has been removed.","The attribute set has been removed."
-"The backup has been created.","The backup has been created."
-"The billing agreement has been canceled.","The billing agreement has been canceled."
-"The billing agreement has been deleted.","The billing agreement has been deleted."
-"The cache storage has been flushed.","The cache storage has been flushed."
-"The carrier needs to be specified.","The carrier needs to be specified."
-"The catalog index has been rebuilt.","The catalog index has been rebuilt."
-"The catalog rewrites have been refreshed.","The catalog rewrites have been refreshed."
-"The configuration has been saved.","The configuration has been saved."
-"The credit memo has been canceled.","The credit memo has been canceled."
-"The credit memo has been created.","The credit memo has been created."
-"The credit memo has been voided.","The credit memo has been voided."
-"The custom variable has been deleted.","The custom variable has been deleted."
-"The custom variable has been saved.","The custom variable has been saved."
-"The customer has been deleted.","The customer has been deleted."
-"The customer has been saved.","The customer has been saved."
-"The design change has been deleted.","The design change has been deleted."
-"The design change has been saved.","The design change has been saved."
-"The email address is empty.","The email address is empty."
-"The email template has been deleted.","The email template has been deleted."
-"The email template has been saved.","The email template has been saved."
-"The flat catalog category has been rebuilt.","The flat catalog category has been rebuilt."
-"The group node name must be specified with field node name.","The group node name must be specified with field node name."
-"The image cache was cleaned.","The image cache was cleaned."
-"The image cache was cleared.","The image cache was cleared."
-"The invoice and shipment have been created.","The invoice and shipment have been created."
-"The invoice and the shipment  have been created. The shipping label cannot be created at the moment.","The invoice and the shipment  have been created. The shipping label cannot be created at the moment."
-"The invoice has been canceled.","The invoice has been canceled."
-"The invoice has been captured.","The invoice has been captured."
-"The invoice has been created.","The invoice has been created."
-"The invoice has been voided.","The invoice has been voided."
-"The invoice no longer exists.","The invoice no longer exists."
-"The order does not allow creating an invoice.","The order does not allow creating an invoice."
-"The order no longer exists.","The order no longer exists."
-"The poll has been deleted.","The poll has been deleted."
-"The poll has been saved.","The poll has been saved."
-"The profile has been deleted.","The profile has been deleted."
-"The profile has been saved.","The profile has been saved."
-"The profile has been updated.","The profile has been updated."
-"The profile has no changes.","The profile has no changes."
-"The profile you are trying to save no longer exists","The profile you are trying to save no longer exists"
-"The rating has been deleted.","The rating has been deleted."
-"The rating has been saved.","The rating has been saved."
-"The role has been deleted.","The role has been deleted."
-"The role has been saved.","The role has been saved."
-"The role has been successfully saved.","The role has been successfully saved."
-"The search index has been rebuilt.","The search index has been rebuilt."
-"The shipment has been created.","The shipment has been created."
-"The shipment has been created. The shipping label has been created.","The shipment has been created. The shipping label has been created."
-"The shipment has been sent.","The shipment has been sent."
-"The tag has been deleted.","The tag has been deleted."
-"The tag has been saved.","The tag has been saved."
-"The user has been deleted.","The user has been deleted."
-"The user has been saved.","The user has been saved."
-"Themes JavaScript and CSS files combined to one file.","Themes JavaScript and CSS files combined to one file."
-"There is an error in one of the option rows.","There is an error in one of the option rows."
-"This Account is","This Account is"
-"This Email template no longer exists.","This Email template no longer exists."
-"This Role no longer exists","This Role no longer exists"
-"This Role no longer exists.","This Role no longer exists."
-"This account is","This account is"
-"This account is inactive.","This account is inactive."
-"This attribute set does not have attributes which we can use for configurable product","This attribute set does not have attributes which we can use for configurable product"
-"This attribute shares the same value in all the stores","This attribute shares the same value in all the stores"
-"This is a demo store. Any orders placed through this store will not be honored or fulfilled.","This is a demo store. Any orders placed through this store will not be honored or fulfilled."
-"This is a required field.","This is a required field."
-"This product is currently disabled.","This product is currently disabled."
-"This report depends on timezone configuration. Once timezone is changed, the lifetime statistics need to be refreshed.","This report depends on timezone configuration. Once timezone is changed, the lifetime statistics need to be refreshed."
-"This section is not allowed.","This section is not allowed."
-"This user no longer exists.","This user no longer exists."
-"Time","Time"
-"Time selection:","Time selection:"
-"Time:","Time:"
-"Timeout limit for response from synchronize process was reached.","Timeout limit for response from synchronize process was reached."
-"To","To"
-"To cancel pending authorizations and release amounts that have already been processed during this payment, click Cancel.","To cancel pending authorizations and release amounts that have already been processed during this payment, click Cancel."
-"To use Payflow Link, you must configure your Payflow Link account on the Paypal website.","To use Payflow Link, you must configure your Payflow Link account on the Paypal website."
-"Toggle Editor","Toggle Editor"
-"Tools","Tools"
-"Top 5 Search Terms","Top 5 Search Terms"
-"Total","Total"
-"Total Invoiced","Total Invoiced"
-"Total Order Amount","Total Order Amount"
-"Total Refunded","Total Refunded"
-"Total of %d record(s) have been deleted.","Total of %d record(s) have been deleted."
-"Total of %d record(s) have been updated.","Total of %d record(s) have been updated."
-"Total of %d record(s) were canceled.","Total of %d record(s) were canceled."
-"Total of %d record(s) were deleted.","Total of %d record(s) were deleted."
-"Track Order","Track Order"
-"Track this shipment","Track this shipment"
-"Tracking number %s for %s assigned","Tracking number %s for %s assigned"
-"Tracking number cannot be empty.","Tracking number cannot be empty."
-"Transaction Data","Transaction Data"
-"Transaction Details","Transaction Details"
-"Transaction ID","Transaction ID"
-"Transaction Type","Transaction Type"
-"Transactional Emails","Transactional Emails"
-"Transactions","Transactions"
-"Type","Type"
-"Type:","Type:"
-"URL Rewrite","URL Rewrite"
-"URL Rewrite Information","URL Rewrite Information"
-"URL Rewrite Management","URL Rewrite Management"
-"Unable to cancel the credit memo.","Unable to cancel the credit memo."
-"Unable to find a Email Template to delete.","Unable to find a Email Template to delete."
-"Unable to find a poll to delete.","Unable to find a poll to delete."
-"Unable to find a tag to delete.","Unable to find a tag to delete."
-"Unable to find a user to delete.","Unable to find a user to delete."
-"Unable to initialize import model","Unable to initialize import model"
-"Unable to refresh lifetime statistics.","Unable to refresh lifetime statistics."
-"Unable to refresh recent statistics.","Unable to refresh recent statistics."
-"Unable to save Cron expression","Unable to save Cron expression"
-"Unable to save the cron expression.","Unable to save the cron expression."
-"Unable to save the invoice.","Unable to save the invoice."
-"Unable to send the invoice email.","Unable to send the invoice email."
-"Unable to send the shipment email.","Unable to send the shipment email."
-"Unable to void the credit memo.","Unable to void the credit memo."
-"Unknown","Unknown"
-"Unlimited","Unlimited"
-"Update","Update"
-"Updated At","Updated At"
-"Upload File","Upload File"
-"Upload Files","Upload Files"
-"Upload HTTP Error","Upload HTTP Error"
-"Upload I/O Error","Upload I/O Error"
-"Upload Security Error","Upload Security Error"
-"Upload import file","Upload import file"
-"Use All Available Attributes","Use All Available Attributes"
-"Use Config Settings","Use Config Settings"
-"Use Default","Use Default"
-"Use Default Value","Use Default Value"
-"Use Default Variable Values","Use Default Variable Values"
-"Use Silent Post:","Use Silent Post:"
-"Use Website","Use Website"
-"Used Currently For","Used Currently For"
-"Used as Default For","Used as Default For"
-"User Email","User Email"
-"User ID","User ID"
-"User Info","User Info"
-"User Information","User Information"
-"User Name","User Name"
-"User Name is required field.","User Name is required field."
-"User Name:","User Name:"
-"User Role","User Role"
-"User Roles","User Roles"
-"User Roles Information","User Roles Information"
-"User name","User name"
-"Users","Users"
-"Validation Results","Validation Results"
-"Value","Value"
-"Value Delimiter:","Value Delimiter:"
-"Variable","Variable"
-"Variable Code","Variable Code"
-"Variable HTML Value","Variable HTML Value"
-"Variable ID","Variable ID"
-"Variable Name","Variable Name"
-"Variable Plain Value","Variable Plain Value"
-"View Actions XML","View Actions XML"
-"View Full Size","View Full Size"
-"View Memo","View Memo"
-"View Memo for #%s","View Memo for #%s"
-"View Shipment","View Shipment"
-"View Statistics For","View Statistics For"
-"Visibility:","Visibility:"
-"Warning! Empty value can cause problems with CSV format.","Warning! Empty value can cause problems with CSV format."
-"Warning!\r\nThis action will remove this user from already assigned role\r\nAre you sure?","Warning!\r\nThis action will remove this user from already assigned role\r\nAre you sure?"
-"Warning!\r\nThis action will remove those users from already assigned roles\r\nAre you sure?","Warning!\r\nThis action will remove those users from already assigned roles\r\nAre you sure?"
-"Warning: Please do not close the window during importing/exporting data","Warning: Please do not close the window during importing/exporting data"
-"Watermark File for %s","Watermark File for %s"
-"We appreciate our merchants\' feedback, please <a href=""#"" onclick=""surveyAction(\'yes\'); return false;"">take our survey</a> to provide insight on the features you would like included in Magento. <a href=""#"" onclick=""surveyAction(\'no\'); return false;"">Remove this notification</a>","We appreciate our merchants\' feedback, please <a href=""#"" onclick=""surveyAction(\'yes\'); return false;"">take our survey</a> to provide insight on the features you would like included in Magento. <a href=""#"" onclick=""surveyAction(\'no\'); return false;"">Remove this notification</a>"
-"We detected that your JavaScript seem to be disabled.","We detected that your JavaScript seem to be disabled."
-"We\'re in our typing table, coding away more features for Magento. Thank you for your patience.","We\'re in our typing table, coding away more features for Magento. Thank you for your patience."
-"Web Section","Web Section"
-"Web Services","Web Services"
-"Web services","Web services"
-"Website","Website"
-"When using Payflow Link in Magento, a payment authorization transaction must be performed after the shopper enters their credit card information on the Payment page of checkout.  If a full authorization is performed for the entire dollar amount of the transaction, then in some cases, the transaction amount might be reserved on the shopper\'s credit card for up to 30 days, even if they abandon their cart.  This is not an ideal customer experience.  Using this advanced setting in Magento, you can configure key details of this authorization.","When using Payflow Link in Magento, a payment authorization transaction must be performed after the shopper enters their credit card information on the Payment page of checkout.  If a full authorization is performed for the entire dollar amount of the transaction, then in some cases, the transaction amount might be reserved on the shopper\'s credit card for up to 30 days, even if they abandon their cart.  This is not an ideal customer experience.  Using this advanced setting in Magento, you can configure key details of this authorization."
-"Wishlist Report","Wishlist Report"
-"Wishlist item is not loaded.","Wishlist item is not loaded."
-"Wrong account specified.","Wrong account specified."
-"Wrong billing agreement ID specified.","Wrong billing agreement ID specified."
-"Wrong column format.","Wrong column format."
-"Wrong newsletter template.","Wrong newsletter template."
-"Wrong quote item.","Wrong quote item."
-"Wrong tab configuration.","Wrong tab configuration."
-"Wrong tag was specified.","Wrong tag was specified."
-"Wrong transaction ID specified.","Wrong transaction ID specified."
-"XML","XML"
-"XML data is invalid.","XML data is invalid."
-"XML object is not instance of ""Varien_Simplexml_Element"".","XML object is not instance of ""Varien_Simplexml_Element""."
-"YTD","YTD"
-"Year","Year"
-"Yes","Yes"
-"Yes (301 Moved Permanently)","Yes (301 Moved Permanently)"
-"Yes (302 Found)","Yes (302 Found)"
-"Yes (only price with tax)","Yes (only price with tax)"
-"You cannot delete your own account.","You cannot delete your own account."
-"You have %s unread message(s).","You have %s unread message(s)."
-"You have logged out.","You have logged out."
-"You have not enough permissions to use this functionality.","You have not enough permissions to use this functionality."
-"You must have JavaScript enabled in your browser to utilize the functionality of this website.","You must have JavaScript enabled in your browser to utilize the functionality of this website."
-"You need to specify order items.","You need to specify order items."
-"Your answers contain duplicates.","Your answers contain duplicates."
-"Your password has been updated.","Your password has been updated."
-"Your password reset link has expired.","Your password reset link has expired."
-"Your server PHP settings allow you to upload files not more than %s at a time. Please modify post_max_size (currently is %s) and upload_max_filesize (currently is %s) values in php.ini if you want to upload larger files.","Your server PHP settings allow you to upload files not more than %s at a time. Please modify post_max_size (currently is %s) and upload_max_filesize (currently is %s) values in php.ini if you want to upload larger files."
-"Your web server is configured incorrectly. As a result, configuration files with sensitive information are accessible from the outside. Please contact your hosting provider.","Your web server is configured incorrectly. As a result, configuration files with sensitive information are accessible from the outside. Please contact your hosting provider."
-"Zip/Postal Code","Zip/Postal Code"
-"Zip/Postal Code:","Zip/Postal Code:"
-"[ deleted ]","[ deleted ]"
-"[GLOBAL]","[GLOBAL]"
-"[STORE VIEW]","[STORE VIEW]"
-"[WEBSITE]","[WEBSITE]"
-"b","b"
-"close","close"
-"critical","critical"
-"example: ""sitemap/"" or ""/"" for base path (path must be writeable)","example: ""sitemap/"" or ""/"" for base path (path must be writeable)"
-"example: sitemap.xml","example: sitemap.xml"
-"from","from"
-"major","major"
-"minor","minor"
-"notice","notice"
-"store(%s) scope","store(%s) scope"
-"to","to"
-"website(%s) scope","website(%s) scope"
-"{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>.","{{base_url}} is not recommended to use in a production environment to declare the Base Unsecure URL / Base Secure URL. It is highly recommended to change this value in your Magento <a href=""%s"">configuration</a>."
-"You did not sign in correctly or your account is temporarily disabled.","You did not sign in correctly or your account is temporarily disabled."
-"Symlinks are enabled. This may expose security risks. We strongly recommend to disable them.","Symlinks are enabled. This may expose security risks. We strongly recommend to disable them."
diff --git app/locale/en_US/Mage_Core.csv app/locale/en_US/Mage_Core.csv
index 80f7e41bf13..1e578e07202 100644
--- app/locale/en_US/Mage_Core.csv
+++ app/locale/en_US/Mage_Core.csv
@@ -49,6 +49,7 @@
 "Can\'t retrieve entity config: %s","Can\'t retrieve entity config: %s"
 "Cancel","Cancel"
 "Cannot complete this operation from non-admin area.","Cannot complete this operation from non-admin area."
+"Disallowed template variable method.","Disallowed template variable method."
 "Card type does not match credit card number.","Card type does not match credit card number."
 "Code","Code"
 "Controller file was loaded but class does not exist","Controller file was loaded but class does not exist"
diff --git app/locale/en_US/Mage_Sales.csv app/locale/en_US/Mage_Sales.csv
index 7f3b61d745d..b93a388f541 100644
--- app/locale/en_US/Mage_Sales.csv
+++ app/locale/en_US/Mage_Sales.csv
@@ -282,6 +282,7 @@
 "Invalid draw line data. Please define ""lines"" array.","Invalid draw line data. Please define ""lines"" array."
 "Invalid entity model","Invalid entity model"
 "Invalid item option format.","Invalid item option format."
+"Invalid order data.","Invalid order data."
 "Invalid qty to invoice item ""%s""","Invalid qty to invoice item ""%s"""
 "Invalid qty to refund item ""%s""","Invalid qty to refund item ""%s"""
 "Invalid qty to ship for item ""%s""","Invalid qty to ship for item ""%s"""
diff --git app/locale/en_US/Mage_Sitemap.csv app/locale/en_US/Mage_Sitemap.csv
index 8ae5a947caf..df201861844 100644
--- app/locale/en_US/Mage_Sitemap.csv
+++ app/locale/en_US/Mage_Sitemap.csv
@@ -44,3 +44,4 @@
 "Valid values range: from 0.0 to 1.0.","Valid values range: from 0.0 to 1.0."
 "Weekly","Weekly"
 "Yearly","Yearly"
+"Please enter a sitemap name with at most %s characters.","Please enter a sitemap name with at most %s characters."
diff --git js/mage/adminhtml/wysiwyg/tiny_mce/setup.js js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
index e85fe59aae1..2f6a657f833 100644
--- js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
+++ js/mage/adminhtml/wysiwyg/tiny_mce/setup.js
@@ -108,6 +108,7 @@ tinyMceWysiwygSetup.prototype =
             theme_advanced_resizing : true,
             convert_urls : false,
             relative_urls : false,
+            media_disable_flash : this.config.media_disable_flash,
             content_css: this.config.content_css,
             custom_popup_css: this.config.popup_css,
             magentowidget_url: this.config.widget_window_url,
diff --git js/varien/js.js js/varien/js.js
index 9113f632b4e..22f66b24ddd 100644
--- js/varien/js.js
+++ js/varien/js.js
@@ -680,3 +680,40 @@ if ((typeof Range != "undefined") && !Range.prototype.createContextualFragment)
         return frag;
     };
 }
+
+/**
+ * Create form element. Set parameters into it and send
+ *
+ * @param url
+ * @param parametersArray
+ * @param method
+ */
+Varien.formCreator = Class.create();
+Varien.formCreator.prototype = {
+    initialize : function(url, parametersArray, method) {
+        this.url = url;
+        this.parametersArray = JSON.parse(parametersArray);
+        this.method = method;
+        this.form = '';
+
+        this.createForm();
+        this.setFormData();
+    },
+    createForm : function() {
+        this.form = new Element('form', { 'method': this.method, action: this.url });
+    },
+    setFormData : function () {
+        for (var key in this.parametersArray) {
+            Element.insert(
+                this.form,
+                new Element('input', { name: key, value: this.parametersArray[key], type: 'hidden' })
+            );
+        }
+    }
+};
+
+function customFormSubmit(url, parametersArray, method) {
+    var createdForm = new Varien.formCreator(url, parametersArray, method);
+    Element.insert($$('body')[0], createdForm.form);
+    createdForm.form.submit();
+}
